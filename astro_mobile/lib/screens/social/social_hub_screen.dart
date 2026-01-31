import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'wall_feed_screen.dart';
import 'explore_screen.dart';
import 'inbox_screen.dart';

class SocialHubScreen extends StatefulWidget {
  final String lang;
  const SocialHubScreen({super.key, required this.lang});

  @override
  State<SocialHubScreen> createState() => _SocialHubScreenState();
}

class _SocialHubScreenState extends State<SocialHubScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    WallFeedScreen(),
    ExploreScreen(),
    InboxScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        title: Text("Kozmik Bağlantılar", style: GoogleFonts.cinzel(color: const Color(0xFFFFD700))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63)]
          )
        ),
        child: SafeArea(child: _screens[_currentIndex]),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E1E2E),
        selectedItemColor: const Color(0xFFE94560),
        unselectedItemColor: Colors.white54,
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.public), label: "Akış"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Keşfet"),
          BottomNavigationBarItem(icon: Icon(Icons.mail), label: "Inbox"),
        ],
      ),
    );
  }
}
