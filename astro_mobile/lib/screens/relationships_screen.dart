
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'synastry_screen.dart';
import 'social_screen.dart';

class RelationshipsScreen extends StatefulWidget {
  final String lang;
  const RelationshipsScreen({super.key, required this.lang});

  @override
  State<RelationshipsScreen> createState() => _RelationshipsScreenState();
}

class _RelationshipsScreenState extends State<RelationshipsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isTr = widget.lang == 'tr';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isTr ? "İlişkiler & Uyum" : "Relationships & Harmony",
          style: GoogleFonts.cinzel(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E1E2E), // Match app theme dark color
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.goldColor,
          labelColor: AppTheme.goldColor,
          unselectedLabelColor: Colors.white54,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          tabs: [
            Tab(
              icon: const Icon(Icons.favorite),
              text: isTr ? "Aşk Uyumu" : "Love Match",
            ),
            Tab(
              icon: const Icon(Icons.groups),
              text: isTr ? "Sosyal Analiz" : "Social Analysis",
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Aşk Uyumu (Synastry)
          // SynastryScreen normalde bir Scaffold döndürür. 
          // Burada iç içe Scaffold sorun olabilir ama Flutter bunu genellikle tolere eder.
          // En temiz çözüm SynastryScreen'in body'sini almaktır ama
          // Hızlı çözüm olarak direkt widget'ı çağırıyoruz.
          SynastryScreen(lang: widget.lang),

          // Tab 2: Sosyal Analiz
          SocialScreen(lang: widget.lang),
        ],
      ),
    );
  }
}
