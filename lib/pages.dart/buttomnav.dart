import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:myproject/pages.dart/chat.dart';
import 'package:myproject/pages.dart/home.dart';
import 'package:myproject/pages.dart/payment.dart';
import 'package:myproject/pages.dart/profile.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const Home(),
    const Chat(),
    const Payment(),
    const Profile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: CurvedNavigationBar(
        height: 65,
        backgroundColor: Colors.white,
        color: Colors.black,
        animationDuration: const Duration(milliseconds: 500),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          Icon(Icons.home_outlined, color: Colors.white),
          Icon(Icons.chat_bubble_outline, color: Colors.white),
          Icon(Icons.payment, color: Colors.white),
          Icon(Icons.person_outline, color: Colors.white),
        ],
      ),
    );
  }
}
