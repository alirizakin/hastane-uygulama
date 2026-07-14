import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onHttpError: (_) => setState(() => _isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse('https://ispartasehir.saglik.gov.tr/'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            top: 0,
            child: WebViewWidget(controller: _controller),
          ),
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.92),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 132,
                      height: 132,
                    ),
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(
                      color: Color(0xFFD32F2F),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Isparta Şehir Hastanesi yükleniyor...',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}