import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/data_manager.dart';
import '../services/api_service.dart';

class HoursScreen extends StatefulWidget {
  final String lang;
  final bool embed; // New parameter

  const HoursScreen({super.key, required this.lang, this.embed = false});

  @override
  State<HoursScreen> createState() => _HoursScreenState();
}

class _HoursScreenState extends State<HoursScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _hoursData = [];
  String _errorMessage = "";
  bool _isRestricted = false;

  @override
  void initState() {
    super.initState();
    _fetchHours();
  }
  Future<void> _fetchHours() async {
    final chart = DataManager.instance.currentChart;
    if (chart == null || chart.meta == null) {
      if(mounted) setState(() {
        _errorMessage = widget.lang == 'tr' ? "Konum verisi eksik." : "Location data missing.";
        _isLoading = false;
      });
      return;
    }

    final lat = chart.meta!.lat ?? 41.0;
    final lon = chart.meta!.lon ?? 28.0;

    try {
      final res = await _api.getPlanetaryHours(lat: lat, lon: lon);
      
      // Check Restriction first
      if (res['upgrade_required'] == true) {
         if(mounted) setState(() {
           _isRestricted = true;
           _isLoading = false;
         });
         return;
      }

      if (res['hours'] != null && (res['hours'] as List).isNotEmpty) {
        if(mounted) setState(() {
          _hoursData = res['hours'];
          _isLoading = false;
        });
      } else {
         // Empty list from backend usually means restricted in our logic
         if(mounted) setState(() {
           _isRestricted = true;
           _isLoading = false;
         });
      }
    } catch (e) {
      if(mounted) setState(() {
         // If error contains "Empty data", treat as restricted
         if (e.toString().contains("Empty data")) {
             _isRestricted = true;
         } else {
             _errorMessage = widget.lang == 'tr' ? "Yüklenemedi: $e" : "Could not load: $e";
         }
         _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embed) {
      return Container(
         decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)]
            )
         ),
         child: _buildBody(),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.lang == 'tr' ? "Gezegen Saatleri" : "Planetary Hours", style: GoogleFonts.cinzel(color: const Color(0xFFFFD700))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Container(
         decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)]
            )
         ),
         child: SafeArea(
           child: _buildBody(),
         ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
    
    if (_isRestricted) {
       return Center(
         child: Container(
           margin: const EdgeInsets.all(20),
           padding: const EdgeInsets.all(30),
           decoration: BoxDecoration(
             color: Colors.black45,
             borderRadius: BorderRadius.circular(20),
             border: Border.all(color: Colors.cyanAccent.withOpacity(0.5))
           ),
           child: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               const Icon(Icons.lock_clock, color: Colors.cyanAccent, size: 60),
               const SizedBox(height: 20),
               Text(
                 widget.lang == 'tr' ? "PREMIUM İÇERİK" : "PREMIUM CONTENT",
                 style: GoogleFonts.cinzel(color: Colors.cyanAccent, fontSize: 24, fontWeight: FontWeight.bold)
               ),
               const SizedBox(height: 10),
               Text(
                 widget.lang == 'tr' 
                 ? "Gezegen saatlerini takip ederek gününüzü planlamak için Premium üye olmalısınız."
                 : "You must be a Premium member to track planetary hours and plan your day.",
                 textAlign: TextAlign.center,
                 style: const TextStyle(color: Colors.white70),
               ),
             ],
           ),
         ),
       );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _hoursData.length,
      itemBuilder: (context, index) {
        final h = _hoursData[index];
        final rawPlanet = h['ruler'] ?? h['planet'] ?? 'Unknown';
        final planet = rawPlanet.toString();
        final isDay = h['type'] == 'day';
        final explanation = _getExplanation(planet, widget.lang);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isDay ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isDay ? Colors.orangeAccent.withOpacity(0.3) : Colors.blueGrey.withOpacity(0.3)
            )
          ),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: _getPlanetColor(planet),
              child: Text(planet.length > 0 ? planet.substring(0,1) : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            title: Text(planet, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text("${h['start']} - ${h['end']}", style: const TextStyle(color: Colors.white70)),
            trailing: Icon(
              isDay ? Icons.wb_sunny : Icons.nightlight_round,
              color: isDay ? Colors.orangeAccent : Colors.blueGrey,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(explanation, style: const TextStyle(color: Colors.white60, fontSize: 13)),
              )
            ],
          ),
        );
      },
    );
  }
  
  Color _getPlanetColor(String name) {
    name = name.toLowerCase();
    if(name.contains('sun') || name.contains('gün')) return Colors.orange; 
    if(name.contains('moo') || name.contains('ay')) return Colors.grey;
    if(name.contains('mar')) return Colors.redAccent;
    if(name.contains('mer')) return Colors.greenAccent;
    if(name.contains('ven')) return Colors.pinkAccent;
    if(name.contains('jup')) return Colors.purpleAccent;
    if(name.contains('sat')) return Colors.brown;
    return Colors.teal;
  }

  String _getExplanation(String planet, String lang) {
    final clean = planet.toLowerCase();
    if(lang == 'tr') {
       if(clean.contains('sun') || clean.contains('gün')) return "Otorite, canlılık ve liderlik konuları için uygundur.";
       if(clean.contains('moo') || clean.contains('ay')) return "Duygusal, ailevi konular ve derinleşme için uygundur.";
       if(clean.contains('mer')) return "İletişim, eğitim ve ticaret için idealdir.";
       if(clean.contains('ven')) return "Aşk, sanat ve güzellik konuları desteklenir.";
       if(clean.contains('mar')) return "Cesaret, mücadele ve fiziksel aktivite zamanı.";
       if(clean.contains('jup')) return "Şans, bolluk ve ruhsal genişleme zamanı.";
       if(clean.contains('sat')) return "Disiplin, planlama ve sabır gerektiren işler.";
    } else {
       if(clean.contains('sun')) return "Good for authority, vitality and leadership.";
       if(clean.contains('moo')) return "Good for emotions, family and reflection.";
       if(clean.contains('mer')) return "Ideal for communication, learning and trade.";
       if(clean.contains('ven')) return "Supports love, art and beauty.";
       if(clean.contains('mar')) return "Time for courage, action and physical activity.";
       if(clean.contains('jup')) return "Time for luck, abundance and expansion.";
       if(clean.contains('sat')) return "Good for discipline, planning and focus.";
    }
    return "";
  }
}
