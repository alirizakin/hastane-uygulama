import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  static const List<_LinkItem> _items = [
    _LinkItem(
      title: 'Hasta Görüş ve Öneri Formu',
      url: 'https://ispartasehir.saglik.gov.tr/Form-TR/1911/hasta-gorus-ve-oneri-formu.html',
      icon: Icons.people_alt_rounded,
    ),
    _LinkItem(
      title: 'Çalışan Görüş ve Öneri Formu',
      url: 'https://ispartasehir.saglik.gov.tr/Form-TR/4326/calisan-gorus-ve-oneri-formu.html',
      icon: Icons.badge_rounded,
    ),
    _LinkItem(
      title: 'Çalışan Personeller İçin Yönetimden Randevu Alma Sistemi',
      url: 'https://ispartasehir.saglik.gov.tr/Form-TR/4900/calisan-personeller-icin-yonetimden-randevu-alma.html',
      icon: Icons.event_available_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Öneri Memnuniyet'),
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _HeaderBox(),
          const SizedBox(height: 16),
          for (final item in _items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                height: 66,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1C1C1C),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InAppBrowserScreen(title: item.title, url: item.url),
                      ),
                    );
                  },
                  icon: Icon(item.icon, color: const Color(0xFFD32F2F)),
                  label: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderBox extends StatelessWidget {
  const _HeaderBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD32F2F), Color(0xFFEF5350)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.edit_note_rounded, color: Colors.white, size: 44),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Öneri Memnuniyet',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                ),
                SizedBox(height: 4),
                Text(
                  'Formları uygulama içinden açın.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InAppBrowserScreen extends StatefulWidget {
  final String title;
  final String url;
  const InAppBrowserScreen({super.key, required this.title, required this.url});

  @override
  State<InAppBrowserScreen> createState() => _InAppBrowserScreenState();
}

class _InAppBrowserScreenState extends State<InAppBrowserScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFFD32F2F)),
            ),
        ],
      ),
    );
  }
}

class _LinkItem {
  final String title;
  final String url;
  final IconData icon;

  const _LinkItem({required this.title, required this.url, required this.icon});
}
