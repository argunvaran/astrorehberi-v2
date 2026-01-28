import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/data_manager.dart';
import '../models/chart_model.dart';

class DraconicScreen extends StatelessWidget {
  final String lang;

  const DraconicScreen({super.key, required this.lang});

  @override
  Widget build(BuildContext context) {
    final chart = DataManager.instance.currentChart;

    if (chart == null) {
      return const Scaffold(body: Center(child: Text("Data missing")));
    }
    
    // 1. Try Backend Data first (Premium users get this enriched data)
    List<Map<String, dynamic>> draconicPlanets = [];
    final backendData = chart.meta?.draconicChart;

    if (backendData != null && backendData.isNotEmpty) {
       draconicPlanets = backendData.map((e) => e as Map<String, dynamic>).toList();
    } else {
      // 2. Fallback: Client-Side Calc (No interpretation)
      // Find North Node
      Planet? northNode;
      try {
          northNode = chart.planets.firstWhere((p) => p.name.contains('Node') || p.name.contains('True') || p.name.contains('Mean'));
      } catch (_) {}
  
      final offset = northNode?.lon ?? 0.0; 
  
      draconicPlanets = chart.planets.map((p) {
          double newLon = p.lon - offset;
          if (newLon < 0) newLon += 360;
          return {
             'name': p.name,
             'sign': _getZodiacSign(newLon),
             'lon': newLon,
             'interpretation': null 
          };
      }).toList();
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(lang == 'tr' ? "Drakonik Ruh" : "Draconic Soul", style: GoogleFonts.cinzel(color: const Color(0xFFFFD700))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Container(
         decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFF2E003E), Color(0xFF10002B)]
            )
         ),
         child: SafeArea(
           child: ListView.builder(
             padding: const EdgeInsets.all(16),
             itemCount: draconicPlanets.length + 1,
             itemBuilder: (context, index) {
               if (index == 0) {
                 return Padding(
                   padding: const EdgeInsets.only(bottom: 20),
                   child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purpleAccent.withOpacity(0.3))
                      ),
                      child: Text(
                        lang == 'tr' 
                        ? "Drakonik harita, ruhunuzun asıl amacını ve bilinçaltındaki kodlarını gösterir. Kuzey Ay Düğümü'nün 0 derece Koç kabul edildiği ruhsal bir haritadır. Kartlara tıklayarak detayları görebilirsiniz."
                        : "The Draconic chart reveals your soul's purpose. Tap on cards to see details.",
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                   ),
                 );
               }
               
               final p = draconicPlanets[index-1];
               return GestureDetector(
                 onTap: () => _showDetails(context, p),
                 child: Container(
                   margin: const EdgeInsets.only(bottom: 10),
                   decoration: BoxDecoration(
                     color: Colors.white.withOpacity(0.05),
                     borderRadius: BorderRadius.circular(10),
                     border: Border.all(color: Colors.white10)
                   ),
                   child: ListTile(
                     leading: CircleAvatar(
                       backgroundColor: Colors.purple.withOpacity(0.2),
                       child: Text(_getPlanetName(p['name'].toString(), lang).substring(0,1), style: const TextStyle(color: Colors.white)),
                     ),
                     title: Text(_getPlanetName(p['name'].toString(), lang), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                     trailing: Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         Text(p['sign'].toString(), style: GoogleFonts.cinzel(color: const Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 16)),
                         const SizedBox(width: 8),
                         const Icon(Icons.info_outline, color: Colors.white30, size: 18)
                       ],
                     ),
                   ),
                 ),
               );
             },
           ),
         ),
      ),
    );
  }

  void _showDetails(BuildContext context, Map<String, dynamic> p) {
     final interp = p['interpretation'];
     final hasInterp = interp != null && interp.toString().length > 10;
     
     showDialog(
       context: context,
       builder: (context) => Dialog(
         backgroundColor: const Color(0xFF1A1A2E),
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
         child: Padding(
           padding: const EdgeInsets.all(24.0),
           child: SingleChildScrollView(
             child: Column(
               mainAxisSize: MainAxisSize.min,
               children: [
                 Text(_getPlanetName(p['name'].toString(), lang), style: GoogleFonts.cinzel(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold)),
                 const SizedBox(height: 10),
                 Text(p['sign'].toString(), style: const TextStyle(color: Colors.white70, fontSize: 18)),
                 const Divider(color: Colors.white10, height: 30),
                 
                 if (hasInterp)
                   Text(interp.toString(), style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5), textAlign: TextAlign.center)
                 else 
                   Column(
                     children: [
                       const Icon(Icons.lock, color: Colors.white24, size: 40),
                       const SizedBox(height: 10),
                       Text(
                         lang == 'tr' 
                         ? "Detaylı Drakonik Yorumları görüntüleyebilmek için Premium üye olmalısınız veya haritanızı tekrar hesaplamalısınız."
                         : "To view detailed Draconic interpretations, you must be a Premium member or recalculate your chart.",
                         style: const TextStyle(color: Colors.white54), textAlign: TextAlign.center
                       ),
                     ],
                   ),
                 const SizedBox(height: 30),
               ],
             ),
           ),
         ),
       ),
     );
  }

  String _getZodiacSign(double lon) {
    final signs = ["Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo", "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"];
    final trSigns = ["Koç", "Boğa", "İkizler", "Yengeç", "Aslan", "Başak", "Terazi", "Akrep", "Yay", "Oğlak", "Kova", "Balık"];
    
    int index = (lon / 30).floor() % 12;
    return lang == 'tr' ? trSigns[index] : signs[index];
  }

  String _getPlanetName(String name, String lang) {
    if (lang != 'tr') return name;
    const map = {
      'Sun': 'Güneş', 'Moon': 'Ay', 'Mercury': 'Merkür', 'Venus': 'Venüs',
      'Mars': 'Mars', 'Jupiter': 'Jüpiter', 'Saturn': 'Satürn', 'Uranus': 'Uranüs',
      'Neptune': 'Neptün', 'Pluto': 'Plüton', 'True Node': 'Kuzey Ay Düğümü',
      'Mean Node': 'Kuzey Ay Düğümü', 'North Node': 'Kuzey Ay Düğümü',
      'South Node': 'Güney Ay Düğümü', 'Ascendant': 'Yükselen', 
      'Midheaven': 'Tepe Noktası', 'Chiron': 'Kiron'
    };
    String clean = name.replaceAll(' Retrograde', '');
    return map[clean] ?? map[name] ?? name;
  }
}
