import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  static const String _jsonUrl =
      'https://raw.githubusercontent.com/alirizakin/hastane-uygulama/main/data/menu.json';

  bool _loading = true;
  String? _error;
  DateTime _day = DateTime.now();
  Map<String, _MealItems>? _allMenus;

  @override
  void initState() {
    super.initState();
    _loadMenus();
  }

  Future<void> _loadMenus() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await http.get(Uri.parse(_jsonUrl));
      if (response.statusCode != 200) {
        throw Exception('Menü indirilemedi: ${response.statusCode}');
      }
      final Map<String, dynamic> raw = json.decode(response.body);
      final parsed = <String, _MealItems>{};
      for (final entry in raw.entries) {
        final v = entry.value;
        if (v is Map<String, dynamic>) {
          parsed[entry.key] = _MealItems(
            breakfast: _strings(v['breakfast']),
            lunch: _strings(v['lunch']),
            dinner: _strings(v['dinner']),
          );
        }
      }
      if (!mounted) return;
      setState(() => _allMenus = parsed);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  List<String> _strings(dynamic v) {
    if (v is List) return v.cast<String>();
    return [];
  }

  String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  _MealItems? get _todayMenu => _allMenus?[_dayKey(_day)];

  Future<void> _nextDay() async {
    setState(() => _day = _day.add(const Duration(days: 1)));
  }

  Future<void> _prevDay() async {
    setState(() => _day = _day.subtract(const Duration(days: 1)));
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        '${_day.day.toString().padLeft(2, '0')}.${_day.month.toString().padLeft(2, '0')}.${_day.year}';
    final menu = _todayMenu;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yemek Listesi'),
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadMenus,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HeaderCard(dateText: dateLabel),
            const SizedBox(height: 14),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFD32F2F))),
              )
            else if (_error != null)
              _ErrorBox(message: _error!)
            else if (menu == null)
              const _ErrorBox(
                  message: 'Bu tarihe ait menü bulunamadı.')
            else ...[
              _MealCard(
                  title: 'Sabah',
                  icon: Icons.free_breakfast_rounded,
                  items: menu.breakfast),
              const SizedBox(height: 12),
              _MealCard(
                  title: 'Öğle',
                  icon: Icons.lunch_dining_rounded,
                  items: menu.lunch),
              const SizedBox(height: 12),
              _MealCard(
                  title: 'Akşam',
                  icon: Icons.dinner_dining_rounded,
                  items: menu.dinner),
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

class _MealItems {
  final List<String> breakfast, lunch, dinner;
  _MealItems(
      {required this.breakfast,
      required this.lunch,
      required this.dinner});
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
            width: 54, height: 54,
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
                    style: TextStyle(
                        color: Colors.white.withOpacity(.92),
                        fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;
  const _MealCard(
      {required this.title,
      required this.icon,
      required this.items});

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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
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
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    if (items.isEmpty)
                      const Text('Veri yok',
                          style: TextStyle(
                              height: 1.4, fontSize: 15))
                    else
                      ...items.map((item) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: 2),
                            child: Row(
                              children: [
                                Container(
                                  width: 6, height: 6,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD32F2F)
                                        .withOpacity(.5),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(item,
                                      style: const TextStyle(
                                          height: 1.4,
                                          fontSize: 15)),
                                ),
                              ],
                            ),
                          )),
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
      child: Text(message,
          style: TextStyle(color: Colors.red.shade800)),
    );
  }
}