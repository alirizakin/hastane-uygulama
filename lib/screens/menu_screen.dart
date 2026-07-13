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
  static const String _githubXlsxUrl =
      'https://raw.githubusercontent.com/alirizakin/hastane-uygulama/main/data/yemek_listesi.xlsx';

  bool _loading = true;
  String? _error;
  DateTime _day = DateTime.now();
  _DayMenu? _menu;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await http.get(Uri.parse(_githubXlsxUrl));
      if (response.statusCode != 200) {
        throw Exception('XLSX indirilemedi: ${response.statusCode}');
      }
      final bytes = response.bodyBytes;
      final parsed = _parseWorkbook(bytes, _day);
      setState(() => _menu = parsed);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _nextDay() async {
    setState(() {
      _day = _day.add(const Duration(days: 1));
    });
    await _loadMenu();
  }

  Future<void> _prevDay() async {
    setState(() {
      _day = _day.subtract(const Duration(days: 1));
    });
    await _loadMenu();
  }

  _DayMenu? _parseWorkbook(Uint8List bytes, DateTime target) {
    final excel = Excel.decodeBytes(bytes);
    for (final table in excel.tables.values) {
      for (final row in table.rows) {
        final date = _tryParseDate(row.isNotEmpty ? row[0]?.value : null);
        if (date == null) continue;
        if (!_sameDate(date, target)) continue;

        final breakfast = _clean(_cell(row, 7));
        final lunch = _clean(_cell(row, 15));
        final dinner = _clean(_cell(row, 23));

        final fallbackBreakfast = _collectColumn(rows: table.rows, dateRowIndex: table.rows.indexOf(row), columnIndex: 7);
        final fallbackLunch = _collectColumn(rows: table.rows, dateRowIndex: table.rows.indexOf(row), columnIndex: 15);
        final fallbackDinner = _collectColumn(rows: table.rows, dateRowIndex: table.rows.indexOf(row), columnIndex: 23);

        return _DayMenu(
          date: date,
          breakfast: breakfast.isNotEmpty ? breakfast : fallbackBreakfast,
          lunch: lunch.isNotEmpty ? lunch : fallbackLunch,
          dinner: dinner.isNotEmpty ? dinner : fallbackDinner,
        );
      }
    }
    return null;
  }

  String _collectColumn({
    required List<List<Data?>> rows,
    required int dateRowIndex,
    required int columnIndex,
  }) {
    final items = <String>[];
    for (var i = dateRowIndex + 1; i < rows.length; i++) {
      final row = rows[i];
      final date = _tryParseDate(row.isNotEmpty ? row[0]?.value : null);
      if (date != null) break;
      final value = _clean(_cell(row, columnIndex));
      if (value.isNotEmpty) items.add(value);
    }
    return items.join(' • ');
  }

  String _cell(List<Data?> row, int index) {
    if (index >= row.length) return '';
    return row[index]?.value?.toString() ?? '';
  }

  String _clean(String value) => value.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  DateTime? _tryParseDate(dynamic value) {
    if (value is DateTime) return DateTime(value.year, value.month, value.day);
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;

    // Excel bazen tarihleri string ya da seri sayı olarak verebilir.
    final asNumber = double.tryParse(text.replaceAll(',', '.'));
    if (asNumber != null && asNumber > 20000 && asNumber < 60000) {
      // Excel serial date -> 1899-12-30 base
      final base = DateTime(1899, 12, 30);
      return DateTime(base.year, base.month, base.day).add(Duration(days: asNumber.round()));
    }

    final normalized = text.replaceAll('.', '/').replaceAll('-', '/');
    final parts = normalized.split('/').where((e) => e.isNotEmpty).toList();
    if (parts.length >= 3) {
      final d = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final y = int.tryParse(parts[2]);
      if (d != null && m != null && y != null) {
        return DateTime(y, m, d);
      }
    }
    return null;
  }

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final titleDate = '${_day.day.toString().padLeft(2, '0')}.${_day.month.toString().padLeft(2, '0')}.${_day.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Günün Menüsü'),
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Bugün • $titleDate',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (_loading) ...[
              const Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: Color(0xFFD32F2F)),
              )),
            ] else if (_error != null) ...[
              _ErrorBox(message: _error!),
            ] else if (_menu == null) ...[
              const _ErrorBox(message: 'Bugüne ait menü bulunamadı.'),
            ] else ...[
              _MealCard(title: 'Sabah', icon: Icons.free_breakfast, items: _menu!.breakfast),
              _MealCard(title: 'Öğle', icon: Icons.lunch_dining, items: _menu!.lunch),
              _MealCard(title: 'Akşam', icon: Icons.dinner_dining, items: _menu!.dinner),
            ],
            const Spacer(),
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

class _DayMenu {
  final DateTime date;
  final String breakfast;
  final String lunch;
  final String dinner;

  _DayMenu({
    required this.date,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
  });
}

class _MealCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String items;

  const _MealCard({required this.title, required this.icon, required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFD32F2F).withOpacity(.12),
              child: Icon(icon, color: const Color(0xFFD32F2F)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(items.isEmpty ? 'Veri yok' : items, style: const TextStyle(height: 1.4)),
                ],
              ),
            ),
          ],
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(message, style: TextStyle(color: Colors.red.shade800)),
    );
  }
}
