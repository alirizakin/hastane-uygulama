import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  static const String address = 'Isparta Şehir Hastanesi, Isparta, Türkiye';
  static const String phone = '+90 246 214 10 00';
  static const String fax = '+90 246 214 10 01';
  static const String email = 'info@ispartasehir.saglik.gov.tr';
  static const String mapsUrl = 'https://www.google.com/maps/search/?api=1&query=Isparta+Sehir+Hastanesi';

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Açılamadı: $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İletişim'),
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InfoTile(
              icon: Icons.location_on,
              title: 'Adres',
              value: address,
              onTap: () => _launch(mapsUrl),
            ),
            _InfoTile(
              icon: Icons.phone,
              title: 'Telefon',
              value: phone,
              onTap: () => _launch('tel:$phone'),
            ),
            _InfoTile(
              icon: Icons.print,
              title: 'Faks',
              value: fax,
              onTap: null,
            ),
            _InfoTile(
              icon: Icons.email,
              title: 'E-posta',
              value: email,
              onTap: () => _launch('mailto:$email'),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                height: 220,
                color: Colors.grey.shade200,
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: Center(
                        child: Text(
                          'Harita görünümü için\ncihazdaki harita uygulaması açılabilir',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
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
