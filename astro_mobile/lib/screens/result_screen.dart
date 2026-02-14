import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/chart_model.dart';
import 'dart:math' as math;
import '../theme/strings.dart';

// --- Gelişmiş Chart Painter (Fix: Smart Collision Avoidance) ---
class ChartPainter extends CustomPainter {
  final List<Planet> planets;
  ChartPainter(this.planets);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // FIX: Yarıçapı en küçük kenara göre belirle ve %10 pay bırak (0.9)
    final radius = math.min(size.width, size.height) / 2 * 0.9;
    
    // Arkaplan
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF1A1A2E), const Color(0xFF0F0C29)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, bgPaint);

    // Zodyak Halkası
    final zodiacPaint = Paint()
       ..style = PaintingStyle.stroke
       ..strokeWidth = 2.0
       ..color = Colors.white24;
    canvas.drawCircle(center, radius, zodiacPaint);
    canvas.drawCircle(center, radius * 0.85, zodiacPaint);

    // Ev Çizgileri
    final linePaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1.0;
    
    for (int i = 0; i < 12; i++) {
        final angleDeg = i * 30.0;
        final angleRad = (angleDeg + 180) * (math.pi / 180);
        
        final p2 = Offset(
            center.dx + radius * math.cos(angleRad),
            center.dy + radius * math.sin(angleRad)
        );
        canvas.drawLine(center, p2, linePaint);
    }

    // --- SMART LABEL PLACEMENT ---
    
    // 1. Sırala
    final sortedPlanets = List<Planet>.from(planets);
    sortedPlanets.sort((a, b) => a.lon.compareTo(b.lon));

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    
    // Çizilmiş Etiketlerin Kutularını Sakla
    List<Rect> drawnLabels = [];
    
    // Denenecek Radius Seviyeleri (Merkeze uzaklık oranları)
    // 0.75: Standart Orbit
    // 0.60: İç Orbit
    // 0.88: Dış Orbit
    // 0.45: En İç Orbit
    // 0.95: En Dış Orbit
    final levels = [0.75, 0.60, 0.88, 0.48, 0.95];

    for (int i = 0; i < sortedPlanets.length; i++) {
        final p = sortedPlanets[i];
        final drawAngleDeg = (-p.lon + 180); 
        final angleRad = drawAngleDeg * (math.pi / 180);

        // Optimal Level Bul
        double chosenRadiusFactor = levels[0];
        Rect? chosenRect;
        Offset? chosenPos;
        
        for (double level in levels) {
             final r = radius * level;
             final pos = Offset( center.dx + r * math.cos(angleRad), center.dy + r * math.sin(angleRad) );
             
             // Etiket Kutusunu Hesapla
             final labelRect = Rect.fromCenter(
                center: Offset(pos.dx, pos.dy - 12), // Text biraz yukarıda
                width: 26, height: 18 // Biraz genişletilmiş
             );
             
             // Çakışma Var mı?
             bool collision = false;
             for (final existing in drawnLabels) {
                if (labelRect.overlaps(existing)) {
                   collision = true;
                   break;
                }
             }
             
             if (!collision) {
                chosenRadiusFactor = level;
                chosenRect = labelRect;
                chosenPos = pos;
                break; // Bulduk!
             }
        }
        
        // Eğer her yerde çakışıyorsa, mecburen en boş olanı (şimdilik ilkini veya random) seç
        if (chosenPos == null) {
            // Fallback: Modulo ile seç (Eski yöntem ama çaresiz durumda)
            int fallbackIndex = i % levels.length;
            chosenRadiusFactor = levels[fallbackIndex];
             // Pozisyonu tekrar hesapla
            final r = radius * chosenRadiusFactor;
            chosenPos = Offset( center.dx + r * math.cos(angleRad), center.dy + r * math.sin(angleRad) );
             chosenRect = Rect.fromCenter(center: Offset(chosenPos.dx, chosenPos.dy - 12), width: 26, height: 18);
        }

        // --- ÇİZİM ---
        drawnLabels.add(chosenRect!); // Kaydet

        // Gezegen Noktası
        canvas.drawCircle(chosenPos!, 3, Paint()..color = _getPlanetColor(p.name));
        
        // Etiket
        final labelText = p.name.length > 2 ? p.name.substring(0, 2).toUpperCase() : p.name.toUpperCase();
        
        textPainter.text = TextSpan(
            text: labelText,
            style: GoogleFonts.roboto(
              color: Colors.white, 
              fontSize: 10, 
              fontWeight: FontWeight.bold,
              shadows: [const Shadow(blurRadius: 2, color: Colors.black)]
            )
        );
        textPainter.layout();
        
        // Etiket Arkaplanı
        canvas.drawRRect(
          RRect.fromRectAndRadius(chosenRect, const Radius.circular(4)), 
          Paint()..color = _getPlanetColor(p.name).withOpacity(0.9) // Daha opak
        );
        
        // Texti Ortala
        textPainter.paint(canvas, Offset(chosenRect.left + (chosenRect.width - textPainter.width)/2, chosenRect.top + (chosenRect.height - textPainter.height)/2));
    }
  }
  
  Color _getPlanetColor(String name) {
    name = name.toLowerCase();
    if(name.contains('sun') || name.contains('gü')) return const Color(0xFFFFA500); // Orange
    if(name.contains('moo') || name.contains('ay')) return const Color(0xFFB0BEC5); // BlueGrey
    if(name.contains('mer')) return const Color(0xFF69F0AE); // GreenAccent
    if(name.contains('ven')) return const Color(0xFFFF4081); // PinkAccent
    if(name.contains('mar')) return const Color(0xFFFF5252); // RedAccent
    if(name.contains('jup')) return const Color(0xFFE040FB); // PurpleAccent
    if(name.contains('sat')) return const Color(0xFF8D6E63); // Brown
    if(name.contains('ura')) return const Color(0xFF18FFFF); // CyanAccent
    if(name.contains('nep')) return const Color(0xFF536DFE); // IndigoAccent
    if(name.contains('plu')) return const Color(0xFF7C4DFF); // DeepPurpleAccent
    if(name.contains('as') || name.contains('asc')) return const Color(0xFFFFFFFF); // White for ASC
    return Colors.grey;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


class ResultScreen extends StatelessWidget {
  final ChartData data;
  final String lang;

  const ResultScreen({super.key, required this.data, required this.lang});

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('chart_title', lang), style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: const Color(0xFFFFD700))),
        backgroundColor: const Color(0xFF0F0C29),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // 1. Sabit Arkaplan (Gradient) - Hiçbir zaman kaymaz veya bitmez
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
              ),
            ),
          ),
          
          // 2. Kaydırılabilir İçerik
          SingleChildScrollView(
            physics: const ClampingScrollPhysics(), // Yaylanmayı engeller (Sıkı kaydırma)
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                 // Chart Area - FIX: Sabit boyutlu kare kutu
                 Center(
                   child: Container(
                     height: 320, 
                     width: 320,  
                     decoration: BoxDecoration(
                       shape: BoxShape.circle,
                       boxShadow: [
                         BoxShadow(color: Colors.blueAccent.withOpacity(0.1), blurRadius: 20, spreadRadius: 5)
                       ]
                     ),
                     child: CustomPaint(
                       painter: ChartPainter(data.planets),
                     ),
                   ),
                 ),
                 
                 const SizedBox(height: 30),
                 
                 // Cosmic Fingerprint (Planets)
                 Text(lang == 'tr' ? "Kozmik Parmak İzi" : "Your Cosmic Fingerprint", style: GoogleFonts.cinzel(fontSize: 22, color: const Color(0xFFFFD700))),
                 const SizedBox(height: 10),
                 ...data.planets.map((p) => _buildPlanetTile(p)).toList(),
                 
                 const SizedBox(height: 30),
                 
                 // Aspects
                 Text(AppStrings.get('aspects_title', lang), style: GoogleFonts.cinzel(fontSize: 22, color: const Color(0xFFFFD700))),
                 const SizedBox(height: 10),
                 ...data.aspects.map((a) => Container(
                   margin: const EdgeInsets.only(bottom: 10),
                   decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
                   child: ListTile(
                     title: Text("${_translatePlanet(a.p1)} - ${_translatePlanet(a.p2)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                     subtitle: Text(
                       lang == 'tr' 
                         ? "${_translatePlanet(a.p1)} ${_translateAspectType(a.type)} ${_translatePlanet(a.p2)}"
                         : a.interpretation, 
                       style: const TextStyle(color: Colors.white70)
                     ),
                     leading: const Icon(Icons.compare_arrows, color: Colors.amber),
                   ),
                 )).toList(),
                 
                 // En alta güvenli boşluk (Safe Area Padding)
                 const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanetTile(Planet p) {
    final pName = _translatePlanet(p.name);
    final sName = _translateSign(p.sign);
    final title = lang == 'tr' ? "$pName, $sName Burcunda" : "$pName in $sName";

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(p.interpretation, style: const TextStyle(color: Colors.white70)),
        leading: CircleAvatar(
          backgroundColor: Colors.white10,
          child: Text(
            pName.isNotEmpty ? pName[0] : "?", 
            style: const TextStyle(color: Colors.white),
          ),
        ), 
      ),
    );
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
    // Handle retro
    String clean = name.replaceAll(' Retrograde', '');
    return map[clean] ?? map[name] ?? name;
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

  String _translateAspectType(String type) {
    if (lang != 'tr') return type;
    const map = {
      'Conjunction': 'Kavuşum',
      'Opposition': 'Karşıt Açısı', // "Sun Opposition Moon" -> "Güneş Karşıt Açısı Ay" (Translation needs grammar, but simplified: "Güneş Karşıt Ay" is better)
      'Square': 'Kare Açısı',
      'Trine': 'Üçgen Açısı',
      'Sextile': 'Sekstil Açısı'
    };
    // Better simplified Turkish Astro Terminology
    if (type == 'Conjunction') return 'ile Kavuşumda'; 
    if (type == 'Opposition') return 'ile Karşıt Açıda';
    if (type == 'Square') return 'ile Kare Açıda';
    if (type == 'Trine') return 'ile Üçgen Açıda';
    if (type == 'Sextile') return 'ile Sekstil Açıda';
    
    return type;
  }
}
