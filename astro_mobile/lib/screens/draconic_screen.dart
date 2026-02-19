
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_html/flutter_html.dart';
import '../services/data_manager.dart';
import '../services/library_service.dart';
import '../models/chart_model.dart';
import '../models/article_model.dart';

class DraconicScreen extends StatefulWidget {
  final String lang;
  const DraconicScreen({super.key, required this.lang});

  @override
  State<DraconicScreen> createState() => _DraconicScreenState();
}

class _DraconicScreenState extends State<DraconicScreen> {
  List<Map<String, dynamic>> _draconicPlanets = [];
  bool _isLoading = true;
  double _nodeLon = 0.0;

  @override
  void initState() {
    super.initState();
    LibraryService.instance.loadLibrary().then((_) {
       _calculateDraconicChart();
    });
  }

  void _calculateDraconicChart() {
    final chart = DataManager.instance.currentChart;
    if (chart == null) {
      if(mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Find North Node Longitude
      final node = chart.planets.firstWhere(
        (p) => p.name.contains('Node') || p.name == 'Kuzey Ay Düğümü' || p.name == 'True Node' || p.name == 'Mean Node',
        orElse: () => Planet(name: 'Node', sign: 'Aries', lon: 0, interpretation: '') // Fallback
      );
      _nodeLon = node.lon;

      // 2. Calculate Draconic Positions for Key Planets
      final keys = ['Sun', 'Moon', 'Mercury', 'Venus', 'Mars', 'Jupiter', 'Saturn', 'Ascendant'];
      final List<Map<String, dynamic>> calculated = [];

      for (var key in keys) {
        final p = chart.planets.firstWhere(
          (p) => p.name.contains(key) || (key == 'Sun' && p.name == 'Güneş') || (key == 'Moon' && p.name == 'Ay') || (key == 'Ascendant' && (p.name == 'Yükselen' || p.name == 'AS')),
          orElse: () => Planet(name: '', sign: '', lon: -1, interpretation: '')
        );

        if (p.lon != -1) {
           double draconicLon = p.lon - _nodeLon;
           if (draconicLon < 0) draconicLon += 360;
           
           final sign = _getSignFromLon(draconicLon);
           final article = _getDeepInterpretation(key, sign);

           calculated.add({
             'name': p.name,
             'key': key, // Standard key for mapping
             'draconic_sign': sign,
             'draconic_lon': draconicLon,
             'article': article
           });
        }
      }

      if (mounted) {
        setState(() {
          _draconicPlanets = calculated;
          _isLoading = false;
        });
      }

    } catch (e) {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Article _getDeepInterpretation(String planetKey, String sign) {
    // Yerel üreticiyi öncelikli kullan (Daha tutarlı ve drakonik odaklı)
    // planetKey (Sun, Moon...), sign (Koç, Boğa...)
    
    return Article(
      id: "draconic_${planetKey}_$sign",
      title: "", // UI'da kullanılmıyor
      category: "Drakonik Analiz",
      content: _generateDraconicText(planetKey, sign, widget.lang == 'tr'),
      author: "Cosmic Soul"
    );
  }

  String _generateDraconicText(String planet, String sign, bool isTr) {
     final pInfo = _planetMeanings[planet] ?? (isTr ? {"prefix": "Bu gezegen", "core": "enerjisi"} : {"prefix": "This planet", "core": "energy"});
     final sInfo = _signMeanings[sign] ?? (isTr ? {"theme": "belirsiz bir enerji", "detail": "genel etkiler taşır."} : {"theme": "indefinite energy", "detail": "carries general effects."});

     if (isTr) {
       return """
       <p>${pInfo['prefix']}, ruhsal yolculuğunda <b>${sign}</b> burcunun ${sInfo['theme']} ile frekanslanıyor.</p>
       <br>
       <p><b>Ruhsal Çağrı:</b> ${sInfo['detail']}</p>
       <p>Drakonik haritandaki bu yerleşim, geçmiş yaşamlarından getirdiğin ve bu hayatta tamamlaman gereken bir misyonu işaret eder. ${pInfo['core']} deneyimin, ${sign} burcunun doğasıyla harmanlanarak seni daha yüksek bir farkındalığa taşıyacaktır.</p>
       """;
     } else {
       final enSign = _getEnglishSign(sign);
       return """
       <p>${pInfo['prefix_en']} resonates with the <b>${enSign}</b> energy of ${sInfo['theme_en']}.</p>
       <br>
       <p><b>Soul Call:</b> ${sInfo['detail_en']}</p>
       <p>This placement in your Draconic chart indicates a mission you carried from past lives. Your experience of ${pInfo['core_en']} blended with the nature of ${enSign} will elevate you to a higher awareness.</p>
       """;
     }
  }

  // --- Helper Methods ---

  String _getHumanIntro(String key, String sign, bool isTr) {
    if (isTr) {
      if (key == 'Sun') return "Ruhun bu dünyaya gelmeden önce, yolculuğunun ana teması olarak **$sign** enerjisini seçti. Öz benliğinde şunlar yankılanıyor:";
      if (key == 'Moon') return "Geçmişten getirdiğin, kalbinin en derin köşesinde saklı duygusal reflekslerin **$sign** doğasını taşıyor. İşte hislerinin kaynağı:";
      if (key == 'Ascendant') return "İnsanlarla ilk temasında ve ruhunun en saf halinde **$sign** enerjisini yayıyorsun. Senin maskesiz halin:";
      if (key == 'Saturn') return "Bu hayatta ustalaşman ve sabırla deneyimlemen gereken dersler **$sign** rehberliğinde şekilleniyor:";
      return "Ruhsal planında bu enerji, **$sign** arketipiyle şöyle tezahür ediyor:";
    } else {
      return "Your soul chose the energy of **${_getEnglishSign(sign)}** for this journey. Here is the whisper of your inner self:";
    }
  }

  String _getEnglishSign(String trSign) {
     const map = {
       "Koç": "Aries", "Boğa": "Taurus", "İkizler": "Gemini", "Yengeç": "Cancer",
       "Aslan": "Leo", "Başak": "Virgo", "Terazi": "Libra", "Akrep": "Scorpio",
       "Yay": "Sagittarius", "Oğlak": "Capricorn", "Kova": "Aquarius", "Balık": "Pisces"
     };
     return map[trSign] ?? trSign;
  }

  String _getSignFromLon(double lon) {
    final signs = [
      "Koç", "Boğa", "İkizler", "Yengeç", "Aslan", "Başak", 
      "Terazi", "Akrep", "Yay", "Oğlak", "Kova", "Balık"
    ]; 
    int index = (lon / 30).floor() % 12;
    return signs[index];
  }

  String _getPlanetTitle(String key, bool isTr) {
     if(key == 'Sun') return isTr ? "RUHSAL KİMLİĞİN" : "SOUL IDENTITY";
     if(key == 'Moon') return isTr ? "DUYGUSAL HAFIZAN" : "EMOTIONAL MEMORY";
     if(key == 'Ascendant') return isTr ? "DÜNYAYA BAKIŞIN" : "SOUL PERSONA";
     if(key == 'Mercury') return isTr ? "ZİHİNSEL KODLARIN" : "MENTAL CODES";
     if(key == 'Venus') return isTr ? "RUHSAL ARZULARIN" : "SOUL DESIRES";
     if(key == 'Mars') return isTr ? "İÇSEL GÜCÜN" : "INNER POWER";
     if(key == 'Jupiter') return isTr ? "RUHSAL BİLGELİĞİN" : "SOUL WISDOM";
     if(key == 'Saturn') return isTr ? "YAŞAM DERSLERİN" : "LIFE LESSONS";
     return key;
  }

  // Gezegenlerin Ruhsal Anlamları
  final Map<String, Map<String, String>> _planetMeanings = {
    'Sun': {
      'prefix': "Ruhunun özü ve varoluş amacı", 'core': "Benlik",
      'prefix_en': "The essence of your soul and purpose of existence", 'core_en': "Selfhood"
    },
    'Moon': {
      'prefix': "Duygusal hafızan ve içgüdüsel ihtiyaçların", 'core': "Duygu",
      'prefix_en': "Your emotional memory and instinctive needs", 'core_en': "Emotion"
    },
    'Mercury': {
      'prefix': "Ruhsal zekan ve iletişim biçimin", 'core': "Zihin",
      'prefix_en': "Your spiritual intelligence and mode of communication", 'core_en': "Mind"
    },
    'Venus': {
      'prefix': "Ruhunun sevgi dili ve estetik arayışı", 'core': "Sevgi",
      'prefix_en': "Your soul's language of love and aesthetic quest", 'core_en': "Love"
    },
    'Mars': {
      'prefix': "İçindeki spiritüel savaşçı ve eylem gücü", 'core': "Eylem",
      'prefix_en': "The spiritual warrior within and power of action", 'core_en': "Action"
    },
    'Jupiter': {
      'prefix': "Ruhsal gelişimin ve bilgeliğin kaynağı", 'core': "Bilgelik",
      'prefix_en': "Source of your spiritual growth and wisdom", 'core_en': "Wisdom"
    },
    'Saturn': {
      'prefix': "Karmik borçların ve bu hayattaki büyük sınavın", 'core': "Sorumluluk",
      'prefix_en': "Your karmic debts and great test in this life", 'core_en': "Responsibility"
    },
    'Ascendant': {
      'prefix': "Ruhunun bu dünyaya giriş kapısı ve ilk izlenimi", 'core': "Persona",
      'prefix_en': "Your soul's gateway to this world and first impression", 'core_en': "Persona"
    },
    'Node': {
      'prefix': "Ruhunun pusulası ve gitmesi gereken yön", 'core': "Kader",
      'prefix_en': "Your soul's compass and destined direction", 'core_en': "Destiny"
    },
  };

  // Burçların Drakonik Temaları
  final Map<String, Map<String, String>> _signMeanings = {
    'Koç': {
      'theme': "başlatma, cesaret ve öncülük enerjisi", 
      'detail': "Ruhun, bireyselliğini korkusuzca ortaya koymayı ve kendi ayakları üzerinde durmayı öğrenmek istiyor. Geçmişte başkaları için kendini feda etmiş olabilirsin; şimdi 'Ben' deme vaktidir. Liderlik vasıflarını ruhsal bir savaşçı gibi kullanmalısın.",
      'theme_en': "energy of initiation, courage and pioneering",
      'detail_en': "Your soul wants to learn to fearlessly express individuality and stand on its own feet. You may have sacrificed yourself for others in the past; now is the time to say 'I'. Use your leadership qualities like a spiritual warrior."
    },
    'Boğa': {
      'theme': "huzur, güven ve üretkenlik enerjisi", 
      'detail': "Ruhun, maddi ve manevi dünyada sarsılmaz bir güven inşa etmeyi arzuluyor. Doğayla uyumlanmak, sabrı öğrenmek ve sahip olduklarının değerini bilmek senin şifandır. Geçmişteki kaoslardan sonra şimdi köklenme zamanı.",
      'theme_en': "energy of peace, trust and productivity",
      'detail_en': "Your soul desires to build unshakable trust in both material and spiritual worlds. Tuning into nature, learning patience, and valuing what you have is your healing. After past chaos, it is time to root."
    },
    'İkizler': {
      'theme': "merak, iletişim ve esneklik enerjisi", 
      'detail': "Ruhun, bilginin peşinden gitmeyi ve gerçeği her yönüyle keşfetmeyi amaçlıyor. İnsanlarla fikirlerinizi paylaşmak ve zihinsel köprüler kurmak senin görevin. Dogmalardan sıyrılıp, hayatı bir öğrenci gibi deneyimlemelisin.",
      'theme_en': "energy of curiosity, communication and flexibility",
      'detail_en': "Your soul aims to pursue knowledge and explore truth from all angles. Sharing ideas with others and building mental bridges is your task. Break free from dogmas and experience life like a student."
    },
    'Yengeç': {
      'theme': "şefkat, aidiyet ve duygusal derinlik enerjisi", 
      'detail': "Ruhun, koşulsuz sevgiyi ve korumayı deneyimlemek için burada. Aileni, sevdiklerini ve hatta tüm insanlığı kucaklayan bir 'ruhsal ebeveyn' rolündesin. Kendi iç dünyanda güvenli bir liman yaratmalı ve duygularından korkmamalısın.",
      'theme_en': "energy of compassion, belonging and emotional depth",
      'detail_en': "Your soul is here to experience unconditional love and protection. You are in the role of a 'spiritual parent' embracing family, loved ones, and humanity. Create a safe haven in your inner world and do not fear your emotions."
    },
    'Aslan': {
      'theme': "yaratıcılık, coşku ve kendini ifade etme enerjisi", 
      'detail': "Ruhun, içindeki ilahi ışığı parlatmak ve sahnede (hayatta) başrolü oynamak istiyor. Yaratıcılığını utanmadan sergilemeli ve kalbinin sesini dinlemelisin. Başkalarına ilham olmak ve neşe saçmak senin karmik hediyendir.",
      'theme_en': "energy of creativity, enthusiasm and self-expression",
      'detail_en': "Your soul wants to shine the divine light within and play the lead role in life. Display your creativity without shame and listen to your heart. Being an inspiration and spreading joy is your karmic gift."
    },
    'Başak': {
      'theme': "hizmet, saflık ve düzenleme enerjisi", 
      'detail': "Ruhun, kaosu düzene çevirmek ve hayatı iyileştirmek için detaylarda gizli olan bilgeliği kullanıyor. Kendine ve dünyaya hizmet etmek, analiz etmek ve şifalandırmak senin doğanda var. Mükemmeliyetçiliği bir yük değil, bir ustalık aracı olarak kullan.",
      'theme_en': "energy of service, purity and order",
      'detail_en': "Your soul uses the wisdom hidden in details to turn chaos into order and heal life. Serving yourself and the world, analyzing, and healing is in your nature. Use perfectionism not as a burden, but as a tool of mastery."
    },
    'Terazi': {
      'theme': "denge, uyum ve adalet enerjisi", 
      'detail': "Ruhun, ilişkiler yoluyla kendini tanımayı ve zıtlıkları dengelemeyi öğreniyor. Diplomasi, zarafet ve barış yaratmak senin misyonun. Ancak başkalarının aynasında kaybolmadan, kendi merkezinde kalarak 'biz' demeyi öğrenmelisin.",
      'theme_en': "energy of balance, harmony and justice",
      'detail_en': "Your soul learns self-knowledge and balancing opposites through relationships. Diplomacy, grace, and creating peace are your mission. However, learn to say 'we' by staying in your center, without getting lost in the mirror of others."
    },
    'Akrep': {
      'theme': "dönüşüm, güç ve derinlik enerjisi", 
      'detail': "Ruhun, görünenin ötesine geçmeyi ve küllerinden yeniden doğmayı arzuluyor. Hayatın gizemlerini çözmek, krizleri güce dönüştürmek ve ruhsal simyayı gerçekleştirmek için buradasın. Korkularının üzerine gitmek seni özgürleştirecek.",
      'theme_en': "energy of transformation, power and depth",
      'detail_en': "Your soul desires to go beyond the visible and be reborn from ashes. You are here to solve life's mysteries, turn crises into power, and perform spiritual alchemy. Facing your fears will set you free."
    },
    'Yay': {
      'theme': "keşif, inanç ve özgürlük enerjisi", 
      'detail': "Ruhun, evrensel gerçekleri arayan ebedi bir gezgin. Farklı kültürler, felsefeler ve inançlar senin oyun alanın. Hayata geniş bir perspektiften bakmak ve umudu aşılamak senin görevin. Sınırları aş ve bilgeliğini paylaş.",
      'theme_en': "energy of exploration, belief and freedom",
      'detail_en': "Your soul is an eternal traveler seeking universal truths. Different cultures, philosophies, and beliefs are your playground. Looking at life from a broad perspective and instilling hope is your duty. Transcend boundaries and share your wisdom."
    },
    'Oğlak': {
      'theme': "disiplin, sorumluluk ve ustalık enerjisi", 
      'detail': "Ruhun, somut başarılar elde etmek ve topluma kalıcı bir miras bırakmak istiyor. Zorluklar seni yıldırmaz, aksine güçlendirir. İçindeki bilge yöneticiyi açığa çıkararak, zamanın ve maddenin efendisi olmayı öğreniyorsun.",
      'theme_en': "energy of discipline, responsibility and mastery",
      'detail_en': "Your soul wants to achieve tangible success and leave a lasting legacy. Difficulties do not daunt you; they strengthen you. By revealing the wise ruler within, you are learning to be the master of time and matter."
    },
    'Kova': {
      'theme': "yenilik, özgünlük ve evrensellik enerjisi", 
      'detail': "Ruhun, geleceği şekillendirmek ve toplumu ileriye taşımak için devrimci bir vizyon taşıyor. Farklı olmaktan korkma; senin dehan özgürlüğünde saklı. İnsanlık için kolektif bir bilinç uyandırmak senin karmik rolün.",
      'theme_en': "energy of innovation, originality and universality",
      'detail_en': "Your soul carries a revolutionary vision to shape the future and move society forward. Do not fear being different; your genius lies in your freedom. Awakening a collective consciousness for humanity is your karmic role."
    },
    'Balık': {
      'theme': "teslimiyet, birik ve sınırsızlık enerjisi", 
      'detail': "Ruhun, maddi dünyanın katılığını aşıp ilahi olanla bütünleşmek istiyor. Sezgilerin, rüyaların ve sanatın senin rehberlerin. Evrensel şefkati deneyimlemek ve 'her şeyin bir olduğu' gerçeğine uyanmak için buradasın.",
      'theme_en': "energy of surrender, unity and limitlessness",
      'detail_en': "Your soul wants to transcend the rigidity of the material world and merge with the divine. Intuition, dreams, and art are your guides. You are here to experience universal compassion and awaken to the truth that 'all is one'."
    },
  };

  @override
  Widget build(BuildContext context) {
    bool isTr = widget.lang == 'tr';
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(isTr ? "Ruhsal Kodların" : "Your Soul Codes", style: GoogleFonts.cinzel(color: const Color(0xFFE0AAFF), fontWeight: FontWeight.bold)),
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
              colors: [Color(0xFF10002B), Color(0xFF240046), Color(0xFF3C096C)]
          )
        ),
        child: SafeArea(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                children: [
                   // Header Card
                   Container(
                     padding: const EdgeInsets.all(20),
                     margin: const EdgeInsets.only(bottom: 20),
                     decoration: BoxDecoration(
                       gradient: const LinearGradient(colors: [Color(0xFF5A189A), Color(0xFF7B2CBF)]),
                       borderRadius: BorderRadius.circular(20),
                       boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))]
                     ),
                     child: Column(
                       children: [
                         const Icon(Icons.auto_awesome, color: Colors.white70, size: 50),
                         const SizedBox(height: 10),
                         Text(
                           isTr 
                           ? "Ruhunun Mektubu"
                           : "Letter from your Soul",
                           style: GoogleFonts.cinzel(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                           textAlign: TextAlign.center,
                         ),
                         const SizedBox(height: 10),
                         Text(
                           isTr
                           ? "Burada okuyacakların, dünyaya geldiğin kostümün (kişiliğin) ötesindeki 'Sen'i anlatır. Bu analiz, ruhunun en saf ve çıplak gerçeğine bir yolculuktur."
                           : "What you read here speaks to the 'You' beyond your earthly costume. This is a journey to the purest truth of your soul.",
                           style: GoogleFonts.merriweather(color: Colors.white70, fontSize: 13, height: 1.5),
                           textAlign: TextAlign.center,
                         )
                       ],
                     ),
                   ),

                   // Planet Cards
                   ..._draconicPlanets.map((data) => _buildDeepAnalysisCard(data, isTr)),
                   
                   const SizedBox(height: 40),
                ],
            ),
        ),
      ),
    );
  }

  Widget _buildDeepAnalysisCard(Map<String, dynamic> data, bool isTr) {
    final article = data['article'] as Article;
    final intro = _getHumanIntro(data['key'], data['draconic_sign'], isTr);
    final signName = isTr ? data['draconic_sign'] : _getEnglishSign(data['draconic_sign']);
    final planetTitle = _getPlanetTitle(data['key'], isTr);

    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: const Color(0xFF240046).withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15, spreadRadius: 1)]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
               color: Colors.white.withOpacity(0.05),
               borderRadius: const BorderRadius.vertical(top: Radius.circular(20))
            ),
            child: Row(
              children: [
                 CircleAvatar(
                   backgroundColor: Colors.amber.withOpacity(0.2),
                   child: Icon(_getPlanetIcon(data['key']), color: Colors.amber, size: 20),
                 ),
                 const SizedBox(width: 15),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(planetTitle, style: GoogleFonts.cinzel(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                       // "Burcunda" kısmı biraz teknik, onu da yumuşatalım
                       Text(isTr ? "$signName Enerjisiyle" : "With $signName Energy", style: TextStyle(color: Colors.amber.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w600)),
                     ],
                   ),
                 ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  intro,
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 15, fontStyle: FontStyle.italic, height: 1.4),
                ),
                const SizedBox(height: 15),
                const Divider(color: Colors.white10),
                const SizedBox(height: 15),
                Html(
                  data: article.content, // Show full content for deep analysis
                  style: {
                    "body": Style(
                        color: Colors.white70, 
                        fontSize: FontSize(15), 
                        lineHeight: LineHeight(1.8), // Increased line height for readability
                        fontFamily: "Merriweather",
                        textAlign: TextAlign.justify
                    ),
                    "strong": Style(color: Colors.purpleAccent, fontWeight: FontWeight.bold),
                    "h1": Style(display: Display.none), 
                    "h2": Style(color: Colors.amber, fontSize: FontSize(18), margin: Margins.only(top: 20, bottom: 10), fontFamily: "Cinzel"),
                    "p": Style(margin: Margins.only(bottom: 15)),
                  },
                ),
                
                // "Read More" Button for full article interaction (simulated for now, expanding the card could be option)
                // For now, full content is rendered by HTML above (I removed substring limit).
              ],
            ),
          )
        ],
      ),
    );
  }

  IconData _getPlanetIcon(String key) {
    switch(key) {
      case 'Sun': return Icons.wb_sunny;
      case 'Moon': return Icons.nightlight_round;
      case 'Mercury': return Icons.chat_bubble;
      case 'Venus': return Icons.favorite;
      case 'Mars': return Icons.local_fire_department;
      case 'Jupiter': return Icons.auto_awesome;
      case 'Saturn': return Icons.hourglass_empty;
      case 'Ascendant': return Icons.accessibility_new;
      default: return Icons.circle;
    }
  }
}
