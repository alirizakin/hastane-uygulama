import 'dart:typed_data';

import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  static const String _menuPageUrl =
      'https://ispartasehir.saglik.gov.tr/TR-471595/yemek-listesi.html';
  static const String _fallbackXlsxUrl =
      'https://raw.githubusercontent.com/alirizakin/hastane-uygulama/main/data/yemek_listesi.xlsx';

  bool _loading = true;
  String? _error;
  DateTime _day = DateTime.now();
  _DayMenu? _menu;
  DateTime? _matchedDate;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final xlsxUrl = await _resolveXlsxUrl();
      final response = await http.get(Uri.parse(xlsxUrl));
      if (response.statusCode != 200) {
        throw Exception('XLSX indirilemedi: ${response.statusCode}');
      }
      final bytes = response.bodyBytes;
      final parsed = _parseWorkbookRaw(bytes, _day);
      if (!mounted) return;
      setState(() {
        _menu = parsed.menu;
        _matchedDate = parsed.matchedDate;
        _error = parsed.error;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  // ── Fetch latest XLSX from the hospital page ────────────────
  Future<String> _resolveXlsxUrl() async {
    try {
      final html = (await http.get(Uri.parse(_menuPageUrl))).body;
      final matches = RegExp("https?://[^\\s\"'<>]+\\.xlsx[^\\s\"'<>]*",
              caseSensitive: false)
          .allMatches(html);
      final urls = matches.map((m) => m.group(0)!).toList();
      if (urls.isEmpty) return _fallbackXlsxUrl;

      final month = _turkishMonthName(_day.month);
      final year = _day.year.toString();
      for (final url in urls.reversed) {
        final lo = url.toLowerCase();
        if (lo.contains(month) && lo.contains(year)) return url;
      }
      for (final url in urls.reversed) {
        if (url.toLowerCase().contains(month)) return url;
      }
      return urls.last;
    } catch (_) {
      return _fallbackXlsxUrl;
    }
  }

  String _turkishMonthName(int month) {
    const m = [
      'ocak','şubat','mart','nisan','mayıs','haziran',
      'temmuz','ağustos','eylül','ekim','kasım','aralık',
    ];
    return m[month - 1];
  }

  // ── Robust XLSX parser (raw sheet, not tables) ─────────────
  _ParsedMenu _parseWorkbookRaw(Uint8List bytes, DateTime target) {
    final excel = Excel.decodeBytes(bytes);
    final sheetNames = excel.sheets.keys.toList();
    if (sheetNames.isEmpty) {
      // fallback: try tables
      return _parseWorkbookViaTables(bytes, target);
    }
    final sheet = excel.sheets[sheetNames.first]!;

    // Find all date anchors.  Column 0 = date (or leftover food text).
    // Each day block is 4 rows: date-row, soup-row, side-row, dessert-row.
    final List<_DateAnchor> anchors = [];
    for (var r = 0; r < sheet.maxRows; r++) {
      final date = _tryParseDate(_rawCellAsDynamic(sheet, r, 0));
      if (date != null) {
        anchors.add(_DateAnchor(row: r, date: date));
      }
    }
    if (anchors.isEmpty) {
      return _parseWorkbookViaTables(bytes, target);
    }

    // Try exact match first
    for (var i = 0; i < anchors.length; i++) {
      if (_sameDate(anchors[i].date, target)) {
        final endRow = i + 1 < anchors.length ? anchors[i + 1].row : sheet.maxRows;
        return _ParsedMenu(
          menu: _extractDayMenu(sheet, anchors[i].row, endRow),
          matchedDate: anchors[i].date,
          error: null,
        );
      }
    }

    // Fallback: nearest date in same month-year
    _DateAnchor? nearest;
    Duration? nearestDist;
    final targetOnly = DateTime(target.year, target.month, target.day);
    for (final a in anchors) {
      if (a.date.year != target.year || a.date.month != target.month) continue;
      final dist = a.date.difference(targetOnly).abs();
      if (nearestDist == null || dist < nearestDist) {
        nearestDist = dist;
        nearest = a;
      }
    }

    if (nearest != null) {
      final i = anchors.indexOf(nearest);
      final endRow = i + 1 < anchors.length ? anchors[i + 1].row : sheet.maxRows;
      return _ParsedMenu(
        menu: _extractDayMenu(sheet, nearest.row, endRow),
        matchedDate: nearest.date,
        error: 'Bugün için kayıt yok. En yakın gün gösteriliyor.',
      );
    }

    return const _ParsedMenu(menu: null, matchedDate: null, error: 'Menü bulunamadı.');
  }

  _ParsedMenu _parseWorkbookViaTables(Uint8List bytes, DateTime target) {
    final excel = Excel.decodeBytes(bytes);
    DateTime? nearestDate;
    _DayMenu? nearestMenu;
    Duration? nearestDist;
    final targetOnly = DateTime(target.year, target.month, target.day);

    for (final table in excel.tables.values) {
      final rows = table.rows;
      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        final date = _tryParseDate(row.isNotEmpty ? row[0]?.value : null);
        if (date == null) continue;

        final next = _nextDateIndex(rows, i + 1);
        final end = next == -1 ? rows.length : next;
        final menu = _buildMenuFromRows(rows.sublist(i, end));

        if (_sameDate(date, target)) {
          return _ParsedMenu(menu: menu, matchedDate: date, error: null);
        }
        if (date.year == target.year && date.month == target.month) {
          final dist = date.difference(targetOnly).abs();
          if (nearestDist == null || dist < nearestDist) {
            nearestDist = dist;
            nearestDate = date;
            nearestMenu = menu;
          }
        }
      }
    }
    if (nearestMenu != null && nearestDate != null) {
      return _ParsedMenu(menu: nearestMenu, matchedDate: nearestDate,
          error: 'En yakın gün gösteriliyor.');
    }
    return const _ParsedMenu(menu: null, matchedDate: null, error: 'Menü bulunamadı.');
  }

  // ── Extract one day's menu from raw sheet rows ─────────────
  _DayMenu _extractDayMenu(dynamic sheet, int startRow, int endRow) {
    final breakfast = <String>[];
    final lunch = <String>[];
    final dinner = <String>[];

    for (var r = startRow; r < endRow; r++) {
      // col 0 – date row: skip; other rows: breakfast soup / extra
      // col 7 – breakfast items
      // col 15 – lunch items
      // col 23 – dinner items
      final isDateRow = r == startRow;

      if (!isDateRow) {
        _addIfValid(breakfast, _rawCell(sheet, r, 0));
      }
      _addIfValid(breakfast, _rawCell(sheet, r, 7));
      _addIfValid(lunch, _rawCell(sheet, r, 15));
      _addIfValid(dinner, _rawCell(sheet, r, 23));
    }

    return _DayMenu(
      breakfast: breakfast.join(' • '),
      lunch: lunch.join(' • '),
      dinner: dinner.join(' • '),
    );
  }

  void _addIfValid(List<String> list, String? value) {
    if (value == null) return;
    final cleaned = _clean(value);
    if (cleaned.isEmpty) return;
    if (cleaned == 'null') return;
    // Filter out date-like strings
    if (RegExp(r'^\d{4}').hasMatch(cleaned) && cleaned.contains('-')) return;
    if (!list.contains(cleaned)) list.add(cleaned);
  }

  // ── Raw cell access (handles both sheet types) ─────────────
  String? _rawCell(dynamic sheet, int row, int col) {
    try {
      final val = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))?.value;
      if (val == null) return null;
      return val.toString();
    } catch (_) {
      return null;
    }
  }

  dynamic _rawCellAsDynamic(dynamic sheet, int row, int col) {
    try {
      return sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))?.value;
    } catch (_) {
      return null;
    }
  }

  _DayMenu _buildMenuFromRows(List<List<Data?>> block) {
    final breakfast = <String>[];
    final lunch = <String>[];
    final dinner = <String>[];
    for (var i = 0; i < block.length; i++) {
      final isDateRow = i == 0;
      if (!isDateRow) {
        _addIfValid(breakfast, _cellFromData(block[i], 0));
      }
      _addIfValid(breakfast, _cellFromData(block[i], 7));
      _addIfValid(lunch, _cellFromData(block[i], 15));
      _addIfValid(dinner, _cellFromData(block[i], 23));
    }
    return _DayMenu(
      breakfast: breakfast.join(' • '),
      lunch: lunch.join(' • '),
      dinner: dinner.join(' • '),
    );
  }

  String? _cellFromData(List<Data?> row, int index) {
    if (index >= row.length) return null;
    return row[index]?.value?.toString();
  }

  // ── Helpers ────────────────────────────────────────────────
  int _nextDateIndex(List<List<Data?>> rows, int start) {
    for (var i = start; i < rows.length; i++) {
      final row = rows[i];
      final date = _tryParseDate(row.isNotEmpty ? row[0]?.value : null);
      if (date != null) return i;
    }
    return -1;
  }

  String _clean(String value) =>
      value.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  DateTime? _tryParseDate(dynamic value) {
    if (value is DateTime) return DateTime(value.year, value.month, value.day);
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;

    final num = double.tryParse(text.replaceAll(',', '.'));
    if (num != null && num > 20000 && num < 60000) {
      return DateTime(1899, 12, 30).add(Duration(days: num.round()));
    }

    final n = text.replaceAll('.', '/').replaceAll('-', '/');
    final parts = n.split('/').where((e) => e.isNotEmpty).toList();
    if (parts.length >= 3) {
      final d = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final y = int.tryParse(parts[2]);
      if (d != null && m != null && y != null) return DateTime(y, m, d);
    }
    return null;
  }

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ── Navigation ─────────────────────────────────────────────
  Future<void> _nextDay() async {
    setState(() => _day = _day.add(const Duration(days: 1)));
    await _loadMenu();
  }

  Future<void> _prevDay() async {
    setState(() => _day = _day.subtract(const Duration(days: 1)));
    await _loadMenu();
  }

  // ── UI ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final shownDate = _matchedDate ?? _day;
    final titleDate =
        '${shownDate.day.toString().padLeft(2, '0')}.${shownDate.month.toString().padLeft(2, '0')}.${shownDate.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yemek Listesi'),
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadMenu,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HeaderCard(dateText: titleDate),
            const SizedBox(height: 14),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFD32F2F)),
                ),
              )
            else if (_error != null)
              _ErrorBox(message: _error!)
            else if (_menu == null)
              const _ErrorBox(message: 'Bugüne ait yemek listesi bulunamadı.')
            else ...[
              _MealCard(
                  title: 'Sabah',
                  icon: Icons.free_breakfast_rounded,
                  items: _menu!.breakfast),
              const SizedBox(height: 12),
              _MealCard(
                  title: 'Öğle',
                  icon: Icons.lunch_dining_rounded,
                  items: _menu!.lunch),
              const SizedBox(height: 12),
              _MealCard(
                  title: 'Akşam',
                  icon: Icons.dinner_dining_rounded,
                  items: _menu!.dinner),
            ],
            if (_error != null &&
                _error!.contains('En yakın')) ...[
              const SizedBox(height: 12),
              _ErrorBox(message: _error!),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _prevDay,
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('Önceki Gün'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _nextDay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BFA5),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.chevron_right),
                    label: const Text('Sonraki Gün'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Supporting classes ───────────────────────────────────────

class _ParsedMenu {
  final _DayMenu? menu;
  final DateTime? matchedDate;
  final String? error;
  const _ParsedMenu({required this.menu, required this.matchedDate, required this.error});
}

class _DateAnchor {
  final int row;
  final DateTime date;
  _DateAnchor({required this.row, required this.date});
}

class _DayMenu {
  final String breakfast, lunch, dinner;
  _DayMenu({required this.breakfast, required this.lunch, required this.dinner});
}

class _HeaderCard extends StatelessWidget {
  final String dateText;
  const _HeaderCard({required this.dateText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD32F2F), Color(0xFFEF5350)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD32F2F).withOpacity(.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.restaurant_menu_rounded,
                color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Yemek Listesi',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(dateText,
                    style:
                        TextStyle(color: Colors.white.withOpacity(.92), fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final String title, items;
  final IconData icon;
  const _MealCard({required this.title, required this.icon, required this.items});

  @override
  Widget build(BuildContext context) {
    final colors = switch (title) {
      'Sabah' => const [Color(0xFFFFF7E6), Color(0xFFFFE0B2)],
      'Öğle' => const [Color(0xFFE8F8F6), Color(0xFFB2DFDB)],
      _ => const [Color(0xFFF4F0FF), Color(0xFFD1C4E9)],
    };

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFD32F2F),
                  child: Icon(icon, color: Colors.white)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(items.isEmpty ? 'Veri yok' : items,
                        style: const TextStyle(height: 1.4, fontSize: 15)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(message, style: TextStyle(color: Colors.red.shade800)),
    );
  }
}