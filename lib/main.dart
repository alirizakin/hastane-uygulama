import 'package:flutter/material.dart';
import 'screens/contact_screen.dart';
import 'screens/feedback_screen.dart';
import 'screens/home_screen.dart';
import 'screens/menu_screen.dart';

void main() => runApp(const HastaneApp());

class HastaneApp extends StatelessWidget {
  const HastaneApp({super.key});

  @override
  Widget build(BuildContext context) {
    const hospitalRed = Color(0xFFD32F2F);
    const hospitalTurquoise = Color(0xFF00BFA5);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Isparta Şehir Hastanesi',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: hospitalRed,
          primary: hospitalRed,
          secondary: hospitalTurquoise,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: hospitalRed,
          foregroundColor: Colors.white,
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 2,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: hospitalRed,
          unselectedItemColor: Color(0xFF8A8A8A),
          backgroundColor: Colors.white,
          elevation: 14,
        ),
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  int _homeReloadToken = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(key: ValueKey(_homeReloadToken)),
      const MenuScreen(),
      const ContactScreen(),
      const FeedbackScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            if (index == 0) {
              _homeReloadToken++;
            }
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu_rounded),
            label: 'Yemek Listesi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contact_phone_rounded),
            label: 'İletişim',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_emotions_rounded),
            label: 'Öneri Memnuniyet',
          ),
        ],
      ),
    );
  }
}
