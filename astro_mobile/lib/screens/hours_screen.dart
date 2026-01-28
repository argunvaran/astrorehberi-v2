import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/data_manager.dart';
import '../services/api_service.dart';

class HoursScreen extends StatefulWidget {
  final String lang;

  const HoursScreen({super.key, required this.lang});

  @override
  State<HoursScreen> createState() => _HoursScreenState();
}

class _HoursScreenState extends State<HoursScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _hoursData = [];
  String _errorMessage = "";

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
      if (res['hours'] != null) {
        if(mounted) setState(() {
          _hoursData = res['hours'];
          _isLoading = false;
        });
      } else {
        throw Exception("Empty data");
      }
    } catch (e) {
      if(mounted) setState(() {
         _errorMessage = widget.lang == 'tr' ? "Yüklenemedi: $e" : "Could not load: $e";
         _isLoading = false;
         // Fallback Mock Data if needed, but let's stick to error message for honesty
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
           child: _isLoading 
             ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
             : _errorMessage.isNotEmpty 
               ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent)))
               : ListView.builder(
                   padding: const EdgeInsets.all(20),
                   itemCount: _hoursData.length,
                   itemBuilder: (context, index) {
                     final h = _hoursData[index];
                     
                     // FIX: Use 'ruler' then 'planet'
                     final rawPlanet = h['ruler'] ?? h['planet'] ?? 'Unknown';
                     final time = h['start'] ?? ''; 
                     // Backend sends 'start'/'end' times, step 734 confirms this.
                     
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
                 ),
         ),
      ),
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
