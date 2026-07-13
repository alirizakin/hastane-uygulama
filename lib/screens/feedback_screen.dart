import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  static const List<_LinkItem> items = [
    _LinkItem(
      title: 'Hasta Görüş ve Öneri Formu',
      url: 'https://ispartasehir.saglik.gov.tr/TR-1555428/oneri-ve-gorusleriniz.html',
      icon: Icons.people,
    ),
    _LinkItem(
      title: 'Personel Görüş ve Öneri Formu',
      url: 'https://ispartasehir.saglik.gov.tr/TR-1555428/oneri-ve-gorusleriniz.html',
      icon: Icons.badge,
    ),
    _LinkItem(
      title: 'Memnuniyet Bildirimi',
      url: 'https://ispartasehir.saglik.gov.tr/TR-1555428/oneri-ve-gorusleriniz.html',
      icon: Icons.thumb_up,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Öneri & Memnuniyet'),
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Aşağıdan ilgili formu seçin. Formlar uygulama içinde açılır.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                height: 64,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1C1C1C),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    child: Text(item.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
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
            const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F))),
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
