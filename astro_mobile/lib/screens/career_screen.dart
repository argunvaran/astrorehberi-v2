import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/data_manager.dart';
import '../models/chart_model.dart';

class CareerScreen extends StatelessWidget {
  final String lang;

  const CareerScreen({super.key, required this.lang});

  @override
  Widget build(BuildContext context) {
    final chart = DataManager.instance.currentChart;

    if (chart == null) {
      return const Scaffold(body: Center(child: Text("Data missing")));
    }
    
    // Find Saturn and MC
    Planet? saturn;
    Planet? mc;
    Planet? northNode;
    
    try {
      saturn = chart.planets.firstWhere((p) => p.name.contains('Sat'));
    } catch (_) {}

    try {
      mc = chart.planets.firstWhere((p) => p.name.toUpperCase() == 'MC' || p.name.toUpperCase().contains('MID'));
    } catch (_) {}
    
    try {
       northNode = chart.planets.firstWhere((p) => p.name.contains('Node') || p.name.contains('True'));
    } catch (_) {}

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(lang == 'tr' ? "Kariyer Yolu" : "Career Path", style: GoogleFonts.cinzel(color: const Color(0xFFFFD700))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Container(
         decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFF002B36), Color(0xFF073642)] // Teal theme
            )
         ),
         child: SafeArea(
           child: ListView(
             padding: const EdgeInsets.all(20),
             children: [
                _buildHeaderCard(),
                const SizedBox(height: 20),
                
                if (chart.planets.isNotEmpty && chart.planets[0].isRestricted)
                   Center(
                     child: Container(
                       padding: const EdgeInsets.all(30),
                       decoration: BoxDecoration(
                         color: Colors.black45,
                         borderRadius: BorderRadius.circular(20),
                         border: Border.all(color: Colors.amber.withOpacity(0.5))
                       ),
                       child: Column(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           const Icon(Icons.lock_outline, color: Colors.amber, size: 60),
                           const SizedBox(height: 20),
                           Text(
                             lang == 'tr' ? "PREMIUM İÇERİK" : "PREMIUM CONTENT",
                             style: GoogleFonts.cinzel(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold)
                           ),
                           const SizedBox(height: 10),
                           Text(
                             lang == 'tr' 
                             ? "Kariyer Yolu detaylı analizini görüntülemek için Premium üye olmalısınız."
                             : "You must be a Premium member to view the detailed Career Path analysis.",
                             textAlign: TextAlign.center,
                             style: const TextStyle(color: Colors.white70),
                           ),
                         ],
                       ),
                     ),
                   )
                else
                   Column(
                   children: [
                if (saturn != null) 
                  _buildAnalysisCard(
                    lang == 'tr' ? "Disiplin ve Sorumluluk (Satürn)" : "Discipline & Responsibility (Saturn)", 
                    saturn.name, 
                    saturn.sign,
                    lang == 'tr' 
                    ? "Satürn, kariyerinizde nerede en çok çalışmanız gerektiğini ve en büyük başarıları nerede elde edeceğinizi gösterir. ${saturn.sign} burcundaki konumu, otorite figürleriyle ilişkinizi ve profesyonel disiplininizi belirler."
                    : "Saturn shows where you need to work hardest and where you can achieve the greatest success. Its position in ${saturn.sign} determines your relationship with authority figures and professional discipline."
                  ),
                
                if (mc != null) 
                  _buildAnalysisCard(
                    lang == 'tr' ? "Toplumsal Statü (MC)" : "Public Status (MC)", 
                    "Midheaven", 
                    mc.sign,
                    lang == 'tr'
                    ? "MC (Tepe Noktası), toplumdaki imajınızı ve hedeflediğiniz kariyer zirvesini temsil eder. ${mc.sign} burcundaki MC, profesyonel hayatta nasıl tanındığınızı gösterir."
                    : "MC represents your public image and career peak. MC in ${mc.sign} shows how you are recognized in professional life."
                  ),
                  
                if (northNode != null)
                   _buildAnalysisCard(
                    lang == 'tr' ? "Kadersel Yön (Kuzey Düğüm)" : "Destiny Direction (North Node)", 
                    "North Node", 
                    northNode.sign,
                    lang == 'tr'
                    ? "Kuzey Ay Düğümü, ruhunuzun bu hayatta gitmesi gereken yönü gösterir. Kariyerinizde ${northNode.sign} temasını benimsediğinizde en büyük tatmini yaşarsınız."
                    : "The North Node shows the direction your soul needs to go. You will find the greatest satisfaction in your career when you embrace the theme of ${northNode.sign}."
                   ),
                   
                 if (saturn == null && mc == null)
                    const Center(child: Text("Yeterli gezegen verisi bulunamadı.", style: TextStyle(color: Colors.white)))
                   ],
                 )
             ],
           ),
         ),
      ),
    );
  }
  
  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.tealAccent.withOpacity(0.3))
      ),
      child: Column(
        children: [
           const Icon(Icons.business_center, color: Colors.tealAccent, size: 40),
           const SizedBox(height: 10),
           Text(
             lang == 'tr' ? "Kozmik Kariyer Analizi" : "Cosmic Career Analysis",
             style: GoogleFonts.cinzel(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
             textAlign: TextAlign.center,
           ),
           const SizedBox(height: 10),
           Text(
             lang == 'tr' 
             ? "Haritanızdaki Satürn ve MC (Tepe Noktası) konumlarına göre otomatik oluşturulan temel kariyer göstergeleriniz."
             : "Basic career indicators automatically generated based on Saturn and MC positions in your chart.",
             style: const TextStyle(color: Colors.white70),
             textAlign: TextAlign.center,
           )
        ],
      ),
    );
  }
  
  Widget _buildAnalysisCard(String title, String pName, String sign, String desc) {
    // Translate inside the widget to ensure usage
    final trSign = _translateSign(sign);
    final trPlanet = _translatePlanet(pName);
    
    // Replace English sign in description if needed (Simple replace)
    String cleanDesc = desc;
    if (lang == 'tr') {
       cleanDesc = cleanDesc.replaceAll(sign, trSign);
    }
    
    return Container(
       margin: const EdgeInsets.only(bottom: 20),
       padding: const EdgeInsets.all(20),
       decoration: BoxDecoration(
         color: const Color(0xFF001F25), // Darker teal
         borderRadius: BorderRadius.circular(15),
         border: Border.all(color: Colors.white10)
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            Text(title, style: GoogleFonts.cinzel(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Row(
              children: [
                 Container(
                   padding: const EdgeInsets.all(8),
                   decoration: const BoxDecoration(color: Colors.teal, shape: BoxShape.circle),
                   child: Text(trPlanet.isNotEmpty ? trPlanet[0] : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                 ),
                 const SizedBox(width: 15),
                 Text(trSign, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))
              ],
            ),
            const SizedBox(height: 15),
            Text(cleanDesc, style: const TextStyle(color: Colors.white70, height: 1.5))
         ],
       ),
    );
  }

  String _translateSign(String sign) {
    if (lang != 'tr') return sign;
    const map = {
      'Aries': 'Koç', 'Taurus': 'Boğa', 'Gemini': 'İkizler', 'Cancer': 'Yengeç',
      'Leo': 'Aslan', 'Virgo': 'Başak', 'Libra': 'Terazi', 'Scorpio': 'Akrep',
      'Sagittarius': 'Yay', 'Capricorn': 'Oğlak', 'Aquarius': 'Kova', 'Pisces': 'Balık'
    };
    return map[sign] ?? sign;
  }
  
  String _translatePlanet(String name) {
     if (lang != 'tr') return name;
     const map = {
      'Sun': 'Güneş', 'Moon': 'Ay', 'Mercury': 'Merkür', 'Venus': 'Venüs',
      'Mars': 'Mars', 'Jupiter': 'Jüpiter', 'Saturn': 'Satürn', 'Uranus': 'Uranüs',
      'Neptune': 'Neptün', 'Pluto': 'Plüton', 'True Node': 'Kuzey Ay Düğümü',
      'Mean Node': 'Kuzey Ay Düğümü', 'North Node': 'Kuzey Ay Düğümü',
      'South Node': 'Güney Ay Düğümü', 'Ascendant': 'Yükselen', 
      'Midheaven': 'Tepe Noktası', 'Chiron': 'Kiron', 'Node': 'Düğüm'
     };
     String clean = name.replaceAll(' Retrograde', '');
     return map[clean] ?? map[name] ?? name;
  }
}
