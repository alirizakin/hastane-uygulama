import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/contact_screen.dart';
import 'screens/feedback_screen.dart';

void main() => runApp(HastaneApp());

class HastaneApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Isparta Şehir Hastanesi',
      theme: ThemeData(
        primaryColor: Color(0xFFD32F2F), // Sağlık Bakanlığı kırmızısı
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFFD32F2F),
          secondary: Color(0xFF00BFA5), // turkuaz
        ),
        useMaterial3: true,
      ),
      home: MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    HomeScreen(),
    MenuScreen(),
    ContactScreen(),
    FeedbackScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFFD32F2F),
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Yemekler'),
          BottomNavigationBarItem(icon: Icon(Icons.contact_phone), label: 'İletişim'),
          BottomNavigationBarItem(icon: Icon(Icons.rate_review), label: 'Öneri'),
        ],
      ),
    );
  }
}