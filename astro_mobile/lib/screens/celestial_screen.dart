import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/data_manager.dart';

class CelestialScreen extends StatefulWidget {
  final String lang;
  const CelestialScreen({super.key, required this.lang});

  @override
  State<CelestialScreen> createState() => _CelestialScreenState();
}

class _CelestialScreenState extends State<CelestialScreen> {
  final ApiService _api = ApiService();
  List<dynamic>? _events;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final chart = DataManager.instance.currentChart;
    String rising = 'Aries'; // Default
    
    // Yükselen burcu chart datasından al (İngilizce olmalı API için)
    if (chart != null && chart.meta != null && chart.meta!.risingSign != null) {
      rising = chart.meta!.risingSign!;
      // Eğer backend Türkçe rising dönüyorsa API'ye gönderirken İngilizce'ye çevirmek gerekebilir ancak backend rising_sign'ı genelde İngilizce dönüyor.
      // Emniyet için mapping yapılabilir ama şimdilik "Aries" gibi geldiğini varsayıyoruz.
    }
    
    // API Call
    final data = await _api.getCelestialEvents(rising, widget.lang);
    if (mounted) {
      setState(() {
        _events = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.lang == 'tr' ? "Göksel Olaylar" : "Celestial Events", style: GoogleFonts.cinzel(color: const Color(0xFFFFD700))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
           gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFF141E30), Color(0xFF243B55)]
           )
        ),
        child: SafeArea(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.amber))
            : (_events == null || _events!.isEmpty)
              ? Center(child: Text(widget.lang == 'tr' ? "Yaklaşan olay bulunamadı." : "No upcoming events found.", style: const TextStyle(color: Colors.white)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _events!.length,
                  itemBuilder: (context, index) {
                    final e = _events![index];
                    return _buildEventCard(e);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildEventCard(dynamic e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
             children: [
               const Icon(Icons.auto_awesome, color: Colors.amber, size: 28),
               const SizedBox(width: 12),
               Expanded(
                 child: Text(e['title'] ?? 'Event', style: GoogleFonts.cinzel(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
               ),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                 decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
                 child: Text(e['date'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12)),
               )
             ],
           ),
           const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(color: Colors.white10)),
           
           Text(e['general_text'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 15)),
           const SizedBox(height: 15),
           
           Container(
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
               color: Colors.purple.withOpacity(0.1),
               borderRadius: BorderRadius.circular(10),
               border: Border.all(color: Colors.purple.withOpacity(0.3))
             ),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(widget.lang == 'tr' ? "Sizin İçin Etkisi (${e['house']}. Ev)" : "Your Personal Impact (${e['house']} House)", 
                      style: GoogleFonts.cinzel(color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
                 const SizedBox(height: 5),
                 Text(e['personal_text'] ?? '', style: const TextStyle(color: Colors.white)),
               ],
             ),
           )
        ],
      ),
    );
  }
}
