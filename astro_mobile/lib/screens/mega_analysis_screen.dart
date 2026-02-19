
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/library_service.dart';
import '../services/data_manager.dart';
import '../models/chart_model.dart';
import '../models/article_model.dart';
import '../theme/app_theme.dart';
import 'package:flutter_html/flutter_html.dart';

class MegaAnalysisScreen extends StatefulWidget {
  final String lang;
  const MegaAnalysisScreen({super.key, required this.lang});

  @override
  State<MegaAnalysisScreen> createState() => _MegaAnalysisScreenState();
}

class _MegaAnalysisScreenState extends State<MegaAnalysisScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ChartData? _chart;
  
  // Dynamic Content (Articles)
  Article? sunArticle;
  Article? moonArticle;
  Article? risingArticle;
  Article? dailyFocusArticle;
  Article? cosmicVoiceArticle;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  void _loadData() {
    _chart = DataManager.instance.currentChart;
    if (_chart == null) return;
    
    // Asenkron yükleme beklerken UI donmasın diye
    LibraryService.instance.loadLibrary().then((_) {
        if (!mounted) return;

        setState(() {
            final sunSign = _getPlanetSign("Güneş");
            final moonSign = _getPlanetSign("Ay");
            final risingSign = _getPlanetSign("Yükselen");

            // 1. GÜNEŞ: Önce kütüphaneden bak, yoksa üret
            Article sun = LibraryService.instance.findBestMatch("Güneş", sunSign, "");
            if (sun.content.length < 50 || sun.title.contains("Yükleniyor")) {
               sun = Article(
                 id: "gen_sun",
                 title: "Güneş $sunSign Burcunda",
                 category: "Natal Analiz",
                 content: _generateNatalText("Güneş", sunSign, widget.lang == 'tr'),
                 author: "Cosmic AI"
               );
            }
            sunArticle = sun;

            // 2. AY: Önce kütüphaneden bak, yoksa üret
            Article moon = LibraryService.instance.findBestMatch("Ay", moonSign, "");
            if (moon.content.length < 50 || moon.title.contains("Yükleniyor")) {
               moon = Article(
                 id: "gen_moon",
                 title: "Ay $moonSign Burcunda",
                 category: "Natal Analiz",
                 content: _generateNatalText("Ay", moonSign, widget.lang == 'tr'),
                 author: "Cosmic AI"
               );
            }
            moonArticle = moon;

            // 3. YÜKSELEN: Önce kütüphaneden bak, yoksa üret
            Article rising = LibraryService.instance.findBestMatch("Yükselen", risingSign, "");
            if (rising.content.length < 50 || rising.title.contains("Yükleniyor")) {
               rising = Article(
                 id: "gen_rising",
                 title: "Yükselen $risingSign",
                 category: "Natal Analiz",
                 content: _generateNatalText("Yükselen", risingSign, widget.lang == 'tr'),
                 author: "Cosmic AI"
               );
            }
            risingArticle = rising;
            
            // 4. GÜNLÜK ODAK
            Article daily = LibraryService.instance.getRandomArticle();
            if (daily.content.length < 50 || daily.title.contains("Yükleniyor")) {
               daily = _generateDailyAdvice(widget.lang == 'tr');
            }
            dailyFocusArticle = daily;

            // 5. EVRENİN SESİ (Kozmik Ritmi)
            // It needs risingSign.
            cosmicVoiceArticle = _generateCosmicVoice(risingSign, widget.lang == 'tr');
        });
    });
  }

  String _getPlanetSign(String planetName) {
    String rawSign = "Koç";
    
    if (_chart == null) {
      return "Koç"; 
    }
    
    // Yükselen için özel kontrol (Meta verisinde olabilir)
    if (planetName == 'Yükselen' || planetName == 'Ascendant') {
       if (_chart!.meta?.risingSign != null && _chart!.meta!.risingSign!.isNotEmpty) {
         rawSign = _chart!.meta!.risingSign!;
       } else {
         // Meta yoksa gezegen listesinden AS bul
         try {
           rawSign = _chart!.planets.firstWhere((p) => p.name == 'AS' || p.name == 'Ascendant' || p.name == 'Yükselen').sign;
         } catch (_) {}
       }
    } else {
      try {
        final p = _chart!.planets.firstWhere(
          (p) => p.name.toLowerCase() == planetName.toLowerCase() || 
                 (planetName == 'Güneş' && (p.name == 'Sun' || p.name == 'Güneş')) ||
                 (planetName == 'Ay' && (p.name == 'Moon' || p.name == 'Ay')),
          orElse: () => Planet(name: '', sign: 'Koç', lon: 0, interpretation: '')
        );
        rawSign = p.sign;
      } catch (e) {
        rawSign = "Koç";
      }
    }

    // NORMALIZE TO TURKISH
    // If rawSign is English (e.g. "Gemini"), convert to "İkizler"
    const englishToTurkish = {
      "Aries": "Koç", "Taurus": "Boğa", "Gemini": "İkizler", "Cancer": "Yengeç",
      "Leo": "Aslan", "Virgo": "Başak", "Libra": "Terazi", "Scorpio": "Akrep",
      "Sagittarius": "Yay", "Capricorn": "Oğlak", "Aquarius": "Kova", "Pisces": "Balık",
      "Ari": "Koç", "Tau": "Boğa", "Gem": "İkizler", "Can": "Yengeç",
      "Vir": "Başak", "Lib": "Terazi", "Sco": "Akrep",
      "Sag": "Yay", "Cap": "Oğlak", "Aqu": "Kova", "Pis": "Balık"
    };

    return englishToTurkish[rawSign] ?? englishToTurkish[rawSign.trim()] ?? rawSign;
  }

  // --- LOCAL CONTENT GENERATORS ---

  String _generateNatalText(String planet, String sign, bool isTr) {
    final pMap = _natalPlanetMeanings[planet] ?? {};
    final sMap = _natalSignMeanings[sign] ?? {};

    if (isTr) {
      String pDesc = pMap['desc_tr'] ?? "";
      String sTheme = sMap['theme_tr'] ?? "";
      String sC = sMap['char_tr'] ?? "";
      
      return """
      <p><b>$planet $sign burcunda:</b> $pDesc, $sTheme enerjisiyle birleşiyor.</p>
      <p>$sC</p>
      <p>Bu yerleşim, senin en güçlü potansiyellerinden birini gösteriyor. Doğandaki bu enerjiyi kabul edip, gölge yönlerini (aşırılıklarını) dengelediğinde, hayatının direksiyonuna tam anlamıyla geçmiş olacaksın.</p>
      """;
    } else {
      String enSign = _getEnglishSign(sign);
      String pDesc = pMap['desc_en'] ?? "";
      String sTheme = sMap['theme_en'] ?? "";
      String sC = sMap['char_en'] ?? "";

      return """
      <p><b>$planet in $enSign:</b> $pDesc merges with the energy of $sTheme.</p>
      <p>$sC</p>
      <p>This placement reveals one of your strongest potentials. When you accept this nature and balance its shadow sides, you will fully take the wheel of your life.</p>
      """;
    }
  }

  Article _generateDailyAdvice(bool isTr) {
    // Basit bir rastgele mesaj havuzu
    final List<String> trMessages = [
      "Bugün iç sesini dinlemek için harika bir gün. Gürültüden uzaklaş ve kalbinin ne fısıldadığını duy.",
      "Karşına çıkan engeller aslında birer basamak. Bugün pes etmek yerine, farklı bir çözüm yolu dene.",
      "Evren seni destekliyor. Niyetin ne kadar net olursa, sonuçlar o kadar hızlı gelir. Bugün bir dilek tut.",
      "Geçmişi değiştiremezsin ama şu anı şekillendirebilirsin. Bugün, affetmek ve yüklerinden arınmak için mükemmel.",
      "Küçük bir nezaket dalgası büyük bir okyanusu etkileyebilir. Bugün birine gülümse veya yardım et.",
    ];
    final List<String> enMessages = [
      "Today is a great day to listen to your inner voice. Step away from the noise and hear what your heart whispers.",
      "Obstacles are actually stepping stones. Instead of giving up today, try a different solution.",
      "The universe supports you. The clearer your intention, the faster the results. Make a wish today.",
      "You cannot change the past, but you can shape the present. Today is perfect for forgiving and letting go.",
      "A small wave of kindness can affect a vast ocean. Smile at someone or help out today.",
    ];

    int index = DateTime.now().day % 5; // Günlük değişsin
    
    return Article(
      id: "daily_gen",
      title: isTr ? "Günün İlhamı" : "Daily Inspiration",
      category: "Günlük",
      content: isTr ? trMessages[index] : enMessages[index],
      author: "Cosmic Guide"
    );
  }

  String _getEnglishSign(String trSign) {
     const map = {
       "Koç": "Aries", "Boğa": "Taurus", "İkizler": "Gemini", "Yengeç": "Cancer",
       "Aslan": "Leo", "Başak": "Virgo", "Terazi": "Libra", "Akrep": "Scorpio",
       "Yay": "Sagittarius", "Oğlak": "Capricorn", "Kova": "Aquarius", "Balık": "Pisces"
     };
     return map[trSign] ?? trSign;
  }

  // --- STATIC DATA MAPS ---
  final Map<String, Map<String, String>> _natalPlanetMeanings = {
    'Güneş': {
      'desc_tr': "Öz benliğin ve yaşam enerjin",
      'desc_en': "Your core self and life energy"
    },
    'Ay': {
      'desc_tr': "Duygusal tepkilerin ve bilinçaltın",
      'desc_en': "Your emotional responses and subconscious"
    },
    'Yükselen': {
      'desc_tr': "Hayata bakış açın ve dış dünyaya gösterdiğin yüzün",
      'desc_en': "Your outlook on life and the face you show to the world"
    }
  };

  final Map<String, Map<String, String>> _natalSignMeanings = {
    'Koç': {
      'theme_tr': "cesaret ve yenilik",
      'char_tr': "Harekete geçmekten korkmuyorsun. Liderlik vasfın ve, enerjik duruşunla çevrendekilere ilham veriyorsun. Ancak bazen sabırsızlık seni yorabilir.",
      'theme_en': "courage and innovation",
      'char_en': "You are not afraid to take action. You inspire those around you with your leadership and energetic stance. However, impatience can sometimes exhaust you."
    },
    'Boğa': {
      'theme_tr': "güven ve istikrar",
      'char_tr': "Sağlam adımlarla ilerlemeyi seviyorsun. Huzur, konfor ve güzellik senin için vazgeçilmez. Sadakatin en büyük gücün, ancak değişime direnmek seni zorlayabilir.",
      'theme_en': "trust and stability",
      'char_en': "You like to move forward with solid steps. Peace, comfort, and beauty are indispensable for you. Loyalty is your greatest strength, but resisting change can challenge you."
    },
    'İkizler': {
      'theme_tr': "merak ve iletişim",
      'char_tr': "Zihnin her zaman aktif ve öğrenmeye aç. Kelimeler senin süper gücün. Çok yönlüsün ama bazen odaklanmakta zorlanabilirsin.",
      'theme_en': "curiosity and communication",
      'char_en': "Your mind is always active and hungry to learn. Words are your superpower. You are versatile, but sometimes you may struggle to focus."
    },
    'Yengeç': {
      'theme_tr': "şefkat ve koruma",
      'char_tr': "Sevdiklerin için yapamayacağın şey yok. Duygusal zekan çok yüksek ve sezgilerin seni nadiren yanıltır. Geçmişe takılı kalmamaya dikkat etmelisin.",
      'theme_en': "compassion and protection",
      'char_en': "There is nothing you wouldn't do for your loved ones. Your emotional intelligence is high, and your intuition rarely misleads you. Be careful not to get stuck in the past."
    },
    'Aslan': {
      'theme_tr': "yaratıcılık ve özgüven",
      'char_tr': "Parlamak için doğdun. Cömertliğin ve sıcakkanlılığınla girdiğin her ortamı ısıtıyorsun. Takdir edilmek ruhsal gıdan, ama kendine yetmeyi de öğrenmelisin.",
      'theme_en': "creativity and self-confidence",
      'char_en': "You were born to shine. You warm up every environment with your generosity and warmth. Appreciation is your spiritual food, but you must also learn to be self-sufficient."
    },
    'Başak': {
      'theme_tr': "analiz ve hizmet",
      'char_tr': "Detaylar senin işin. Mükemmeli arıyor ve çevreni iyileştirmek için çabalıyorsun. Pratik zekan hayranlık uyandırıcı, ancak kendine karşı çok acımasız olma.",
      'theme_en': "analysis and service",
      'char_en': "Details are your business. You seek perfection and strive to improve your surroundings. Your practical intelligence is admirable, but don't be too harsh on yourself."
    },
    'Terazi': {
      'theme_tr': "uyum ve estetik",
      'char_tr': "Hayatında denge arayışı ön planda. Adalet duygun çok gelişmiş ve çatışmadan hoşlanmıyorsun. Diplomatiksin ama karar verirken başkalarını değil kendini dinlemelisin.",
      'theme_en': "harmony and aesthetics",
      'char_en': "The search for balance is at the forefront of your life. Your sense of justice is highly developed, and you dislike conflict. You are diplomatic, but listen to yourself, not others, when making decisions."
    },
    'Akrep': {
      'theme_tr': "tutku ve dönüşüm",
      'char_tr': "Yüzeysel olan hiçbir şey seni tatmin etmez. Derinlere inmek, gizemleri çözmek senin doğanda var. Güçlü sezgilerin var, ancak şüphecilik kalbini yorabilir.",
      'theme_en': "passion and transformation",
      'char_en': "Nothing superficial satisfies you. Diving deep and solving mysteries is in your nature. You have strong intuition, but skepticism can weary your heart."
    },
    'Yay': {
      'theme_tr': "keşif ve iyimserlik",
      'char_tr': "Hayat senin için bir macera. Özgürlüğüne düşkünsün ve sınır tanımıyorsun. Bilgeliğini paylaşmak istiyorsun, ancak bazen patavatsızlık yapabilirsin.",
      'theme_en': "discovery and optimism",
      'char_en': "Life is an adventure for you. You value your freedom and know no boundaries. You want to share your wisdom, but sometimes you can be blunt."
    },
    'Oğlak': {
      'theme_tr': "disiplin ve başarı",
      'char_tr': "Hedeflerine ulaşmak için sabırla çalışırsın. Sorumluluk sahibisin ve engeller seni yıldırmaz. Zirveye tırmanırken manzarayı (hayatı) izlemeyi unutma.",
      'theme_en': "discipline and success",
      'char_en': "You work patiently to achieve your goals. You are responsible, and obstacles do not daunt you. Don't forget to watch the view (life) while climbing to the summit."
    },
    'Kova': {
      'theme_tr': "yenilik ve özgürlük",
      'char_tr': "Sıradışı bir bakış açın var. Toplumu ileriye taşımak ve kalıpları yıkmak istiyorsun. Dost canlısısın ama duygusal bağ kurmakta mesafeli olabilirsin.",
      'theme_en': "innovation and freedom",
      'char_en': "You have an unusual perspective. You want to move society forward and break molds. You are friendly but can be distant in forming emotional bonds."
    },
    'Balık': {
      'theme_tr': "hayal gücü ve şefkat",
      'char_tr': "Bu dünya sana bazen çok katı geliyor. Rüyaların, sezgilerin ve sanatın sığınağın. Empati yeteneğin muazzam, ancak başkalarının yükünü üstlenmemeyi öğrenmelisin.",
      'theme_en': "imagination and compassion",
      'char_en': "This world sometimes feels too rigid for you. Dreams, intuition, and art are your refuge. Your empathy is immense, but you must learn not to take on others' burdens."
    },
  };

  @override
  Widget build(BuildContext context) {
    bool isTr = widget.lang == 'tr';
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(isTr ? "Kozmik Rehberlik" : "Cosmic Guidance", style: GoogleFonts.cinzel(color: const Color(0xFFFFD700))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.goldColor,
          labelColor: AppTheme.goldColor,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: isTr ? "Ruhun Sesi" : "Soul's Voice"),
            Tab(text: isTr ? "Bugünün Mesajı" : "Today's Msg"),
            Tab(text: isTr ? "Evrenin Ritmi" : "Universe"),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
               // User Greeting
               if (_chart != null)
                 Padding(
                   padding: const EdgeInsets.all(16.0),
                   child: Text(
                     isTr ? "Yıldızlar bugün senin için parlıyor." : "Stars shine for you today.",
                     style: GoogleFonts.outfit(color: Colors.white70, fontStyle: FontStyle.italic),
                   ),
                 ),

               Expanded(
                 child: TabBarView(
                   controller: _tabController,
                   children: [
                     _buildSoulTab(isTr), // Tab 1: Natal Insights (Humanized)
                     _buildDailyTab(isTr), // Tab 2: Daily Focus
                     _buildSkyTab(isTr), // Tab 3: Transits
                   ],
                 ),
               ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSoulTab(bool isTr) {
    if (sunArticle == null) return const Center(child: CircularProgressIndicator(color: AppTheme.goldColor));

    // Get canonical Turkish signs
    final sunSign = _getPlanetSign('Güneş');
    final moonSign = _getPlanetSign('Ay');
    final risingSign = _getPlanetSign('Yükselen');

    // Translate for display if needed
    final sunSignDisplay = isTr ? sunSign : _getEnglishSign(sunSign);
    final moonSignDisplay = isTr ? moonSign : _getEnglishSign(moonSign);
    final risingSignDisplay = isTr ? risingSign : _getEnglishSign(risingSign);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSoulCard(
          isTr ? "Öz Benliğin" : "Your Essence", 
          isTr ? "Güneşin $sunSignDisplay burcunda parlıyor. Bu, senin yaşam enerjinin kaynağıdır. Bak, ruhun sana ne fısıldıyor:" 
               : "Your Sun shines in $sunSignDisplay. This is the source of your life energy. Listen to what your soul whispers:",
          sunArticle!
        ),
        _buildSoulCard(
          isTr ? "Duygusal Dünyan" : "Emotional World", 
          isTr ? "Ay, $moonSignDisplay burcunda dinleniyor. Kalbinin en derin köşesinde hissettiklerin bunlardır:"
               : "The Moon rests in $moonSignDisplay. These are the feelings deep in your heart:",
          moonArticle!
        ),
        _buildSoulCard(
          isTr ? "Dünyaya Yüzün" : "Face to the World", 
          isTr ? "Yükselen burcun $risingSignDisplay, senin hayata açılan pencerendir. İnsanlar senin ışığını böyle görüyor:"
               : "Your Rising sign $risingSignDisplay is your window to life. This is how people see your light:",
          risingArticle!
        ),
      ],
    );
  }

  Widget _buildDailyTab(bool isTr) {
     if (dailyFocusArticle == null) return const Center(child: CircularProgressIndicator(color: AppTheme.goldColor));
     
     return ListView(
       padding: const EdgeInsets.all(20),
       children: [
         Container(
           padding: const EdgeInsets.all(20),
           decoration: BoxDecoration(
             gradient: const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]),
             borderRadius: BorderRadius.circular(20),
             boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0,5))]
           ),
           child: Column(
             children: [
               const Icon(Icons.wb_sunny, color: Colors.amberAccent, size: 50),
               const SizedBox(height: 10),
               Text(
                 isTr ? "GÜNÜN REHBERİ" : "TODAY'S GUIDE",
                 style: GoogleFonts.cinzel(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
               ),
               const SizedBox(height: 10),
               Text(
                 isTr 
                 ? "Bugün gökyüzü sana özel bir mesaj gönderiyor. Enerjini doğru yönlendirmek için bu sese kulak ver."
                 : "The sky sends a special message for you today. Listen to this voice to guide your energy.",
                 style: GoogleFonts.merriweather(color: Colors.white70, fontSize: 14, height: 1.5),
                 textAlign: TextAlign.center,
               )
             ],
           ),
         ),
         const SizedBox(height: 20),
         _buildSoulCard(isTr ? "Günün Odak Noktası" : "Focus of the Day", "", dailyFocusArticle!)
       ],
     );
  }

  Widget _buildSkyTab(bool isTr) {
    if (cosmicVoiceArticle == null) return const Center(child: CircularProgressIndicator(color: AppTheme.goldColor));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
           padding: const EdgeInsets.all(20),
           decoration: BoxDecoration(
             gradient: const LinearGradient(colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)]),
             borderRadius: BorderRadius.circular(20),
             boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0,5))]
           ),
           child: Column(
             children: [
               const Icon(Icons.auto_awesome, color: Colors.cyanAccent, size: 50),
               const SizedBox(height: 10),
               Text(
                 isTr ? "EVRENİN SESİ" : "VOICE OF THE COSMOS",
                 style: GoogleFonts.cinzel(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
               ),
               const SizedBox(height: 10),
               Text(
                 isTr 
                 ? "Şu an gökyüzündeki enerjilerin senin doğum haritan üzerindeki teknik ve ruhsal yansımaları."
                 : "Technical and spiritual reflections of current celestial energies on your natal chart.",
                 style: GoogleFonts.merriweather(color: Colors.white70, fontSize: 13, height: 1.5),
                 textAlign: TextAlign.center,
               )
             ],
           ),
         ),
         const SizedBox(height: 20),
         _buildSoulCard(isTr ? "Kozmik Analiz" : "Cosmic Analysis", "", cosmicVoiceArticle!)
      ],
    );
  }

  // --- NEW GENERATOR FOR COSMIC VOICE ---
  Article _generateCosmicVoice(String risingSign, bool isTr) {
    // Current imitation of transits (approximate for context)
    // Pluto is in Aquarius (Kova), Saturn in Pisces (Balık)
    
    final Map<String, int> signIndexes = {
      "Koç": 1, "Boğa": 2, "İkizler": 3, "Yengeç": 4, 
      "Aslan": 5, "Başak": 6, "Terazi": 7, "Akrep": 8, 
      "Yay": 9, "Oğlak": 10, "Kova": 11, "Balık": 12
    };

    int risingIdx = signIndexes[risingSign] ?? 1;
    
    // Calculate Transit Pluto House (Aquarius - Kova is 11th sign)
    int plutoHouse = (11 - risingIdx + 12) % 12 + 1;
    
    // Calculate Transit Saturn House (Pisces - Balık is 12th sign)
    int saturnHouse = (12 - risingIdx + 12) % 12 + 1;

    String contentTr = """
    <p>Şu anda gökyüzü, kolektif bilinçte devrimsel bir dönüşümün (Plüton Kova transiti) sancılarını yaşarken, senin doğum haritanda bu enerji <b>$plutoHouse. Ev</b> alanına iz düşüyor. Bu, teknik olarak hayatının bu alanında "geri döndürülemez bir metamorfoz" sürecinin başladığını işaret eder. Eski yapıların yıkıldığı, yerine daha özgür ve yenilikçi sistemlerin kurulduğu bir dönemdesin.</p>
    
    <p>Eş zamanlı olarak, Satürn'ün Balık burcundaki seyri, senin <b>$saturnHouse. Ev</b> konularında karmik bir sınavdan geçtiğini gösteriyor. Satürn, zamanın ve kısıtlamaların lordu olarak, bu yaşam alanında senden "ruhsal olgunluk ve sınırları yeniden yapılandırma" talep ediyor. Eğer bu evde gezegenlerin varsa, onlarla yapacağı transit açılar (özellikle kavuşum veya kare), zorlanmaların aslında birer tekamül basamağı olduğunu hatırlatmalıdır.</p>
    
    <p>Özellikle Güneş ve Yükselen yöneticinin aldığı açılar incelendiğinde, şu anki göksel atmosfer seni "içe dönük bir yeniden değerlendirme" sürecine itiyor olabilir. Kozmik hava durumu, dış dünyadaki kaotik akışın aksine, senin iç dünyanda derin bir sessizlik ve stratejik planlama yapmanı destekliyor. Bu transitler altında, aceleci kararlar (Marsiyen dürtüler) yerine, Satürnyen bir sabır ve strateji geliştirmek, önümüzdeki 6 aylık döngüde kaderini yeniden yazman için en güçlü anahtar olacaktır.</p>
    """;

    String contentEn = """
    <p>While the sky is experiencing the pangs of a revolutionary transformation in collective consciousness (Pluto in Aquarius transit), this energy projects onto your <b>$plutoHouse. House</b> in your natal chart. Technically, this indicates the beginning of an "irreversible metamorphosis" in this area of your life. You are in a period where old structures are demolished and freer, innovative systems are established.</p>
    
    <p>Simultaneously, Saturn's transit in Pisces shows that you are undergoing a karmic test in your <b>$saturnHouse. House</b> matters. Saturn, the lord of time and restrictions, demands "spiritual maturity and restructuring of boundaries" from you in this life area. If you have planets in this house, the transit aspects (especially conjunction or square) remind you that difficulties are actually steps of evolution.</p>
    
    <p>Considering the aspects received by your Sun and Ascendant ruler, the current celestial atmosphere may be pushing you into an "introverted re-evaluation" process. Contrary to the chaotic flow in the outer world, cosmic weather supports deep silence and strategic planning in your inner world. Under these transits, instead of hasty decisions (Martian impulses), developing Saturnian patience and strategy will be the strongest key for you to rewrite your destiny in the upcoming 6-month cycle.</p>
    """;

    return Article(
      id: "cosmic_voice",
      title: isTr ? "Evrenin Sesi" : "Voice of Cosmos",
      category: "Transit Analiz",
      content: isTr ? contentTr : contentEn,
      author: "Cosmic Watcher"
    );
  }

  Widget _buildSoulCard(String title, String intro, Article article) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: AppTheme.goldColor, size: 20),
              const SizedBox(width: 10),
              Text(title, style: GoogleFonts.cinzel(color: AppTheme.goldColor, fontSize: 18, fontWeight: FontWeight.bold))
            ],
          ),
          const SizedBox(height: 10),
          if (intro.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Text(intro, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 15, fontStyle: FontStyle.italic)),
            ),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white10),
            ),
            child: Html(
              data: _cleanContent(article.content), // Cleaned content
              style: {
                "body": Style(
                  color: Colors.white60, 
                  fontSize: FontSize(15), 
                  lineHeight: LineHeight(1.8),
                  fontFamily: "Merriweather",
                  textAlign: TextAlign.justify
                ),
                "h1": Style(display: Display.none),
                "h2": Style(color: Colors.amberAccent, fontSize: FontSize(16), margin: Margins.only(top: 15)),
                "p": Style(margin: Margins.only(bottom: 15)),
              },
            ),
          ),
        ],
      ),
    );
  }

  String _cleanContent(String content) {
    // 1. Remove markdown bold headers e.g. **Akademik Analiz:**
    // Matches **Text** or **Text**: 
    String cleaned = content.replaceAll(RegExp(r'\*\*.*?\*\*'), ''); 
    
    // 2. Remove leading colons or junk if leftover (e.g. ": Content")
    cleaned = cleaned.replaceAll(RegExp(r'^\s*[:,-]\s*', multiLine: true), '');
    
    return cleaned;
  }
}
