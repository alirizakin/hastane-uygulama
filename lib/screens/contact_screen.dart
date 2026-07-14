import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  static const String address = 'Sanayi Mahallesi 104. Cad. No:51 32200 Merkez/ISPARTA';
  static const String phone = '+90.246 213 44 00 - 99 (100 Hat)';
  static const String email = 'ispartasehir@saglik.gov.tr';
  static const String mapsUrl = 'https://www.google.com/maps/search/?api=1&query=Isparta+Sehir+Hastanesi';
  static const String mapsEmbedUrl = 'https://www.google.com/maps?q=Isparta+Sehir+Hastanesi&output=embed';

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Açılamadı: $url';
    }
  }

  String _dialablePhone() => phone.replaceAll(RegExp(r'[^\d+]'), '');

  @override
  Widget build(BuildContext context) {
    final mapController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(mapsEmbedUrl));

    return Scaffold(
      appBar: AppBar(
        title: const Text('İletişim'),
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _HeaderStrip(
            title: 'Isparta Şehir Hastanesi',
            subtitle: 'İletişim ve konum bilgileri',
          ),
          const SizedBox(height: 16),
          _InfoTile(
            icon: Icons.location_on_rounded,
            title: 'Adres',
            value: address,
            onTap: () => _launch(mapsUrl),
          ),
          _InfoTile(
            icon: Icons.phone_rounded,
            title: 'Telefon',
            value: phone,
            onTap: () => _launch('tel:${_dialablePhone()}'),
          ),
          _InfoTile(
            icon: Icons.email_rounded,
            title: 'E-Posta',
            value: email,
            onTap: () => _launch('mailto:$email'),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 260,
              child: Stack(
                children: [
                  Positioned.fill(child: WebViewWidget(controller: mapController)),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: ElevatedButton.icon(
                      onPressed: () => _launch(mapsUrl),
                      icon: const Icon(Icons.directions),
                      label: const Text('Yol Tarifi Al'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00BFA5),
                        foregroundColor: Colors.white,
                      ),
                    ),
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

class _HeaderStrip extends StatelessWidget {
  final String title;
  final String subtitle;
  const _HeaderStrip({required this.title, required this.subtitle});

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
      child: Row(
        children: [
          Image.asset('assets/images/logo.png', width: 54, height: 54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(.92))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFD32F2F).withOpacity(.12),
          child: Icon(icon, color: const Color(0xFFD32F2F)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(value),
        onTap: onTap,
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      ),
    );
  }
}
