import 'package:flutter/material.dart';
import 'package:dztrainfay/home_screen.dart';
import 'package:dztrainfay/chat_screen.dart';
import 'package:dztrainfay/compte/compte_screen.dart';
import 'CustomBottomNavBar.dart';

class HomePage extends StatefulWidget {
  final String username;
  const HomePage({required this.username});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(), // Accueil
      ProfilePage(
        username: widget.username,
        toggleTheme: (_) {},
        changeLanguage: (_) {},
        toggleNotifications: (_) {},
      ), // Compte
      ChatScreen(), // Chat
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 500),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
