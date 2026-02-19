import '../models/chart_model.dart';
import 'data_manager.dart';
import 'dart:math';

class AiService {
  // MEGA ASTRO-ENGINE v2.0 (Infinite Sentence Generator)
  
  static Future<String> startJourney(ChartData chart) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final sunSign = chart.meta?.sunSign ?? "Bilinmiyor";
    final risingSign = chart.meta?.risingSign ?? "Bilinmiyor";
    
    final now = DateTime.now();
    final currentDate = "${now.day}.${now.month}.${now.year}";

    return """
Hoş geldin, yıldız tohumu. ✨
Bugün, $currentDate koza gibi açılan gökyüzünde senin için özel mesajlar var.

Güneş'in **$sunSign** burcundaki konumu, ruhunun ateşini simgeliyor.
Yükselen **$risingSign** ile dünyaya bakıyorsun.

Sonsuz olasılıklar denizi senin için dalgalanıyor.
Hangi kapıyı aralamak istersin? Aşağıdan seç, kaderin konuşsun... 🌌
""";
  }

  static Future<String> continueJourney(String historyCount, String topicCode) async {
    await Future.delayed(const Duration(milliseconds: 600)); 
    
    final chart = DataManager.instance.currentChart;
    final sunSign = chart?.meta?.sunSign ?? "Koç";
    final risingSign = chart?.meta?.risingSign ?? "Koç";
    
    // Generate a unique, combinatorial response
    return _generateMegaResponse(topicCode, sunSign, risingSign);
  }

  // --- ADVANCED PARAGRAPH ENGINE (Uzun Metin Üreticisi) ---

  static String _generateMegaResponse(String topic, String sun, String rising) {
    final rand = Random();
    
    // 1. GİRİŞ (Gökyüzü Durumu)
    String intro = _getRandomItem(_intros);
    
    // 2. KİŞİSEL ETKİ (Elemente Göre)
    String personalImpact = _getElementContext(sun, topic);
    
    // 3. SORUN / FIRSAT (Mücadele Alanı)
    String challenge = _getRandomItem(_challenges[topic] ?? _challenges['genel']!);
    
    // 4. TAVSİYE (Aksiyon)
    String action = _getRandomItem(_actions[topic] ?? _actions['genel']!);
    
    // 5. KAPANIŞ (Sonuç)
    String conclusion = _getRandomItem(_outcomes[topic] ?? _outcomes['genel']!);

    // Paragrafı İnşa Et (Akıcı geçişlerle)
    return "$intro $personalImpact\n\n"
           "$challenge Bu durum seni biraz zorlayabilir ancak sakın pes etme. "
           "$action. Bunu yapman senin en yüksek hayrına olacaktır.\n\n"
           "Unutma, $conclusion 🌟";
  }

  // --- DATA POOLS (Zenginleştirilmiş İçerik) ---

  static String _getRandomItem(List<String> list) => list[Random().nextInt(list.length)];

  static String _getElementContext(String sign, String topic) {
    final element = _getUserElement(sign);
    final contextList = _elementContexts[element]?[topic] ?? _elementContexts[element]?['genel'];
    return _getRandomItem(contextList!);
  }

  static String _getUserElement(String sign) {
    const fire = ['Koç', 'Aslan', 'Yay', 'Aries', 'Leo', 'Sagittarius'];
    const earth = ['Boğa', 'Başak', 'Oğlak', 'Taurus', 'Virgo', 'Capricorn'];
    const air = ['İkizler', 'Terazi', 'Kova', 'Gemini', 'Libra', 'Aquarius'];
    if (fire.contains(sign)) return 'ates';
    if (earth.contains(sign)) return 'toprak';
    if (air.contains(sign)) return 'hava';
    return 'su';
  }

  // 1. GİRİŞ CÜMLELERİ (Zaman ve Gök)
  static const List<String> _intros = [
    "Şu an gökyüzünde Venüs ve Mars'ın dansı devam ederken, kozmik enerjiler yoğunlaşıyor.",
    "Merkür'ün şu anki konumu zihinsel süreçleri hızlandırırken, evren sana önemli mesajlar fısıldıyor.",
    "Satürn disiplin evinde ilerlerken, hayat seni bazı sınavlardan geçiriyor olabilir.",
    "Dolunay'ın güçlü ışığı gizli kalmış duyguları açığa çıkarırken, iç dünyanda bir uyanış başlıyor.",
    "Jüpiter'in bolluk enerjisi haritanın tepe noktasına dokunurken, şans kapıları aralanıyor.",
    "Uranüs'ün sürprizlerle dolu enerjisi kapını çalarken, beklenmedik değişimlere hazır olmalısın.",
    "Kuzey Ay Düğümü kadersel yolunu aydınlatırken, geçmişi arkanda bırakma zamanı geldi.",
    "Neptün sezgilerini derinleştirip rüyalarını canlandırırken, gerçek ile hayal arasındaki çizgi inceliyor.",
    "Plüton dönüşüm rüzgarlarını estirirken, hayatında köklü bir temizlik yapma vaktindesin.",
    "Güneş'in şu anki açısı, yaşam enerjini yükseltiyor ve seni sahneye davet ediyor.",
  ];

  // 3. MÜCADELE / FIRSAT CÜMLELERİ (Devasa Havuz)
  static const Map<String, List<String>> _challenges = {
    'ask': [
      "İlişkilerde yanlış anlaşılmalara açık bir dönemdesin; kelimelerini özenle seç.",
      "Ego çatışmaları ve güç savaşları ruhunu yorabilir; alttan almayı dene.",
      "Geçmişten gelen bir sevgili aklını karıştırabilir; bugüne odaklan.",
      "Duygusal iniş çıkışların partnerini şaşırtıyor olabilir; dengede kalmaya çalış.",
      "Bağlanma korkun veya kaybetme endişen tetiklenebilir; akışa güven.",
      "Beklentilerin çok yüksek olabilir, biraz daha gerçekçi olmalısın.",
      "Kıskançlık krizleri aranızdaki güveni sarsabilir; kendine güven.",
      "İletişim kopuklukları veya cevapsız mesajlar moralini bozabilir.",
      "Ailenin veya çevrenin ilişkiniz üzerindeki baskısını hissedebilirsin.",
      "Özgürlük ihtiyacın ile bağlanma arzun arasında çelişki yaşayabilirsin.",
      "Gizli saklı konuların açığa çıkması gerginlik yaratabilir.",
      "Maddi sorunlar aşk hayatına gölge düşürebilir.",
      "Partnerinin soğuk tavırları seni endişelendirebilir, ancak bu geçici.",
      "Aşkta hayal kırıklığı yaşamamak için pembe gözlüklerini çıkarmalısın.",
      "Ani başlayan ilişkiler ani bitebilir, temkinli ol."
    ],
    'kariyer': [
      "İş yerinde rekabetin arttığı bir süreçten geçiyorsun; stratejik ol.",
      "Maddi konularda plansız harcamalar seni zorlayabilir; bütçeni koru.",
      "Üstlerinle iletişim kurarken yanlış anlaşılabilirsin; net ol.",
      "Yoğun iş temposu enerjini tüketiyor olabilir; mola ver.",
      "Odaklanma sorunu yaşayabilir ve detayları kaçırabilirsin; listele.",
      "Beklenmedik bir sorumluluk omuzlarına yüklenebilir; bunu fırsata çevir.",
      "İş arkadaşlarınla aranda gerginlik olabilir; profesyonelliğini koru.",
      "Hak ettiğin değeri görmediğini hissedebilirsin; sabırlı ol.",
      "Teknolojik aksaklıklar veya veri kayıpları işini yavaşlatabilir.",
      "Kariyer değişikliği için acele karar vermemen gereken bir dönem.",
      "Ofis dedikodularından uzak durman senin hayrına olacaktır.",
      "Yasal prosedürler veya evrak işleri seni bunaltabilir.",
      "Müşterilerle yaşanacak anlaşmazlıklarda diplomatik olmalısın.",
      "Gelirinde geçici bir dalgalanma yaşanabilir, panik yapma.",
      "Uzun saatler çalışmak zorunda kalacağın bir proje kapıda."
    ],
    'saglik': [
      "Bedeninin verdiği sinyalleri görmezden gelme eğilimindesin; dinlen.",
      "Uyku düzenindeki bozulmalar enerjini düşürebilir; ritmini bul.",
      "Stres kaynaklı baş ağrıları yaşayabilirsin; nefes al.",
      "Hareketsizlik kaslarını ve zihnini tembelleştiriyor olabilir; yürü.",
      "Beslenme alışkanlıkların şu sıralar dengesizleşmiş olabilir; dikkat et.",
      "Bağışıklık sistemin biraz hassaslaşabilir; vitamin almayı unutma.",
      "Mevsim geçişlerine karşı vücudun tepki verebilir.",
      "Aşırı kafein veya şeker tüketimi seni huzursuz edebilir.",
      "Sindirim sistemi problemleri yaşayabilirsin; hafif beslen.",
      "Duruş bozuklukları sırt veya boyun ağrılarına yol açabilir.",
      "Ruhsal yorgunluk fiziksel halsizliğe dönüşebilir.",
      "Kazalara veya sakarlıklara açık bir gün olabilir; acele etme.",
      "Göz yorgunluğu ve migren ataklarına dikkat etmelisin.",
      "İhmal ettiğin bir diş veya cilt sorunu nüksedebilir.",
      "Su içmeyi unutmak böbreklerini yorabilir."
    ],
    'aile': [
      "Aile içi eski defterler yeniden açılabilir; sakin kal.",
      "Evinle ilgilenmek yerine dışarıya odaklanmış olabilirsin; dengeni kur.",
      "Ebeveynlerinle fikir ayrılıkları yaşayabilirsin; saygını koru.",
      "Evdeki sorumluluklar omuzlarına ağır gelebilir; yardım iste.",
      "Köklerinden kopuk hissetme ihtimalin var; anılarını hatırla.",
      "Miras veya mülk konularında anlaşmazlıklar çıkabilir.",
      "Kardeşlerinle aranda rekabet veya kıskançlık oluşabilir.",
      "Evdeki bir eşyanın bozulması canını sıkabilir.",
      "Taşınma veya tadilat işleri planladığından uzun sürebilir.",
      "Ailenin senin kararlarına karışması özgürlüğünü kısıtlayabilir.",
      "Hasta bir yakınının bakımıyla ilgilenmek zorunda kalabilirsin.",
      "Misafir trafiği seni yorabilir, sınırlarını çiz.",
      "Komşularla yaşanacak küçük gerginliklere dikkat.",
      "Evcil hayvanınla ilgili ekstra sorumluluk alman gerekebilir.",
      "Çocukların eğitimiyle ilgili konularda endişelenebilirsin."
    ],
    'gelecek': [
      "Gelecek kaygısı anın tadını çıkarmanı engelliyor olabilir; ana dön.",
      "Belirsizlikler zihnini bulandırıyor olabilir; pusulan kalbin olsun.",
      "Hangi yöne gideceğine karar vermekte zorlanıyorsun; acele etme.",
      "Kadersel değişimlere direnç gösteriyorsun; akışa bırak.",
      "Hayallerin ile gerçekler arasında sıkışıp kalmış olabilirsin; dengeyi bul.",
      "Umutsuzluk dalgaları zaman zaman seni yoklayabilir.",
      "Hedeflerine ulaşmak sandığından daha fazla çaba gerektirebilir.",
      "Verdiğin sözleri tutmakta zorlanabilirsin.",
      "Yol ayrımındasın ve seçim yapmak seni korkutuyor olabilir.",
      "Geçmişteki hatalarının tekrar etmesinden korkabilirsin.",
      "Teknolojik gelişmelere ayak uydurmakta zorlanabilirsin.",
      "Eğitim hayatınla ilgili belirsizlikler canını sıkabilir.",
      "Yurt dışı planlarında gecikmeler yaşanabilir.",
      "Spiritüel yolculuğunda bir tıkanıklık hissedebilirsin.",
      "Kendini yetersiz hissetme yanılgısına düşme."
    ],
    'genel': [
      "Bazen her şey üstüne geliyormuş gibi hissedebilirsin; geçecek.",
      "Dengeyi bulmakta zorlandığın günler olabilir; kendine zaman tanı.",
      "Çevrendeki negatif enerjiler seni etkiliyor; sınırlarını çiz.",
      "Kendine olan inancın zaman zaman sarsılabilir; gücünü hatırla.",
      "Sabrının sınırları zorlanıyor olabilir; derin bir nefes al.",
      "Zaman yönetimi konusunda sıkıntılar yaşayabilirsin.",
      "Unutkanlık veya dalgınlık başına küçük işler açabilir.",
      "İnsanlara hayır demekte zorlanabilirsin.",
      "Kararsızlık enerjini bölebilir ve seni yavaşlatabilir.",
      "Aşırı mükemmelliyetçilik seni kilitleyebilir.",
      "Sosyal medyada gördüklerin moralini bozabilir.",
      "Beklenmedik bir masraf bütçeni sarsabilir.",
      "Hava durumundaki değişimler ruh halini etkileyebilir.",
      "İçsel bir boşluk hissi yaşayabilirsin.",
      "Rutinden sıkılmış ve değişiklik arıyor olabilirsin."
    ]
  };

  // 2. KİŞİSEL BAĞLAM (Elemente Göre - GENİŞLETİLMİŞ)
  static const Map<String, Map<String, List<String>>> _elementContexts = {
    'ates': {
      'ask': [
        "tutkulu doğanla alev almak üzeresin ve bu enerji partnerini büyülüyor.",
        "heyecan arayışın artabilir, ancak kalıcı bir bağ için sabır göstermelisin.",
        "kalbinin ritmi hızlanıyor; cesaretin aşkta sana yeni kapılar açacak.",
        "romantik konularda liderliği ele alman ilişkiyi canlandırabilir.",
        "dürtüsel tepkiler yerine sevgi dolu jestler yapman gereken bir dönem.",
        "ateşin bazen yakıcı olabilir, partnerine karşı daha yumuşak yaklaşmalısın.",
        "ilişkide monotonluk sana göre değil, bugün küçük bir sürpriz yapabilirsin.",
        "cesur bir itiraf her şeyi değiştirebilir, duygularını saklama."
      ],
      'kariyer': [
        "liderlik vasıflarını gösterme zamanı geldi; sahne senin.",
        "inisiyatif alman gerekiyor; beklemek sana göre değil.",
        "risk almaktan korkmamalısın; büyük ödüller cesaret ister.",
        "enerjini doğru kanalize etmelisin; dağılmak başarını engelleyebilir.",
        "rekabet ortamı seni besliyor; yeteneklerini parlatma vakti.",
        "yeni bir proje başlatmak için içindeki o güçlü dürtüyü takip et.",
        "kendi işini kurma veya terfi isteme fikri aklında dolaşıyor olabilir.",
        "başkalarını motive etme gücün bugün en büyük silahın."
      ],
      'saglik': [
        "yüksek enerjini spora kanalize etmen bedenin için şart.",
        "adrenalin ihtiyacın artabilir; doğa sporları sana iyi gelecektir.",
        "baş bölgeni korumalısın; strese bağlı ağrılar olabilir.",
        "hareket etmediğinde enerjin içinde birikip öfkeye dönüşebilir.",
        "göz sağlığına dikkat etmelisin; ekrana çok bakmak seni yorabilir.",
        "kalp atışlarını hızlandıracak kardiyo egzersizleri ruhunu da iyileştirir."
      ],
      'aile': [
        "aileni koruma içgüdün şu sıralar çok yüksek.",
        "evde sözünün geçmesini isteyebilirsin ancak dengeyi koru.",
        "aile bireylerine karşı sabırsız davranmamaya özen göster.",
        "yuvan senin kalen; orada huzuru sağlamak senin elinde.",
        "evdeki tadilat veya dekorasyon işleri için enerjin var.",
        "çocuklarla veya gençlerle vakit geçirmek neşeni artırabilir."
      ],
      'gelecek': [
        "geleceği fethetme arzun çok güçlü; vizyonuna güven.",
        "hayallerin için savaşmaya hazırsın ve evren seni destekliyor.",
        "kaderin iplerini eline almak istiyorsun; gücünü hisset.",
        "önündeki engelleri yıkıp geçecek enerjiye sahipsin.",
        "yurt dışı veya eğitimle ilgili planların hız kazanabilir.",
        "kendi efsaneni yazmak için doğru zamandasın."
      ],
      'genel': [
        "içindeki ateş sönmemeli; ilham perileri seninle.",
        "harekete geçmek için harika bir an; bekleme.",
        "dürtüsel davranmaktan kaçınmalısın, stratejik ol.",
        "yaşam enerjin çevrendekilere de ışık saçıyor."
      ]
    },
    'toprak': {
      'ask': [
        "güven arayışın karşılık bulacak; temelleri sağlam bir aşk doğuyor.",
        "somut adımlar atmak istiyorsun; belirsizlik sana göre değil.",
        "sadakat senin için her şey ve bunu partnerinden de bekliyorsun.",
        "huzurlu bir limana ihtiyacın var; fırtınalı aşklardan uzak dur.",
        "ilişkinde dokunsal temas ve fiziksel yakınlık önem kazanıyor.",
        "partnerine vereceğin maddi manevi destek aranızdaki bağı güçlendirir.",
        "sözler değil, davranışlar senin için sevgiyi kanıtlar.",
        "eski bir aşk yeniden gündeme gelebilir ancak mantığını elden bırakma."
      ],
      'kariyer': [
        "sabırlı çalışmaların meyve verecek; acele etmene gerek yok.",
        "detaylara odaklanman kazandıracak; mükemmelliyetçiliğini kullan.",
        "maddi konularda garantiye gitmelisin; riskli yatırımlardan kaçın.",
        "planlı ilerlemek başarını artırır; takvimine sadık kal.",
        "pratik çözümlerinle iş yerinde takdir toplayacaksın.",
        "uzun vadeli hedeflerine adım adım yaklaşıyorsun.",
        "yeni bir yetenek öğrenmek kazancını artırabilir.",
        "iş yerindeki otorite figürleriyle ilişkilerin güçleniyor."
      ],
      'saglik': [
        "bedenini dinlemeli ve topraklanma çalışmaları yapmalısın.",
        "beslenme düzenine göstereceğin özen enerjini artıracak.",
        "boyun ve boğaz bölgen hassas olabilir; kendine nazik davran.",
        "rutin kontrollerini aksatmamalısın; sağlık şakaya gelmez.",
        "cilt bakımı veya masaj yaptırmak için harika bir gün.",
        "kemiklerini güçlendirecek gıdalara ağırlık ver."
      ],
      'aile': [
        "evindeki düzen ve huzur senin için öncelik haline geliyor.",
        "aile büyüklerinden alacağın tavsiyeler yolunu aydınlatabilir.",
        "köklü geçmişine sahip çıkmak sana güç verecek.",
        "evinde yapacağın somut değişiklikler ruhuna iyi gelecek.",
        "aile bütçesini gözden geçirmek ve tasarruf yapmak isteyebilirsin.",
        "ev yapımı bir yemekle sevdiklerini bir araya toplayabilirsin."
      ],
      'gelecek': [
        "geleceğini tuğla tuğla, sağlam bir şekilde inşa ediyorsun.",
        "maddi güvence arayışın geleceğini şekillendiriyor.",
        "gerçekçi planların seni hayallerine ulaştıracak.",
        "zamanın senin lehine işlediğini unutma; sabır senin gücün.",
        "emeklilik veya uzun vadeli yatırım planların netleşiyor.",
        "kendi ayakların üzerinde durmak sana gurur veriyor."
      ],
      'genel': [
        "ayakların yere sağlam basmalı; hayallere kapılma.",
        "doğayla temas etmelisin; enerjini topraktan al.",
        "gerçekçi bakış açın seni olası hatalardan koruyacak.",
        "değişime direnmemeli, esnek olmayı öğrenmelisin."
      ]
    },
    'hava': {
      'ask': [
        "zihinsel uyum senin için ön planda; zeki insanlara çekiliyorsun.",
        "iletişim becerilerin kalpleri fethedecek; kelimelerin gücünü kullan.",
        "flörtöz enerjin çok yüksek; sosyal ortamlarda parlıyorsun.",
        "ilişkinde özgürlük alanına ihtiyaç duyabilirsin.",
        "partnerinle uzun sohbetler etmek ruhunu besleyecek.",
        "yüzeysel ilişkiler yerine derin entelektüel bağlar kurmalısın.",
        "bir arkadaşlık aşka dönüşebilir, sinyalleri iyi oku.",
        "mesajlaşmalar ve dijital iletişim aşk hayatını hareketlendirebilir."
      ],
      'kariyer': [
        "yeni fikirlerinle parlayacaksın; inovasyon senin işin.",
        "ağ kurmak (network) sana kazandıracak; insanlarla tanış.",
        "teknolojik çözümler üretmelisin; çağı yakala.",
        "ekip çalışması başarını katlar; yalnız kalma.",
        "iletişim yeteneğin sayesinde zorlu bir görüşmeyi başarabilirsin.",
        "birden fazla projeyi aynı anda yürütme kapasiten var.",
        "eğitim vermek veya bilgi paylaşmak sana prestij katacak.",
        "yazılı anlaşmalar ve sözleşmeler için uygun bir dönem."
      ],
      'saglik': [
        "zihnini susturmakta zorlanabilirsin; meditasyon şart.",
        "sinir sistemini yoracak ortamlardan uzak durmalısın.",
        "temiz hava almak ve nefes egzersizleri yapmak sana ilaç gibi gelecek.",
        "ellerin ve kolların hassas olabilir; aşırı yüklenmekten kaçın.",
        "zihinsel yorgunluk fiziksel ağrıya dönüşebilir, mola ver.",
        "sosyalleşmek ruh sağlığına iyi gelecek, evde kapanma."
      ],
      'aile': [
        "ailenle mantıklı ve açık iletişim kurman gereken bir dönem.",
        "kardeşlerin veya kuzenlerinle ilişkilerin gündeme gelebilir.",
        "evdeki havasızlığı dağıtmak için yenilikler yapabilirsin.",
        "ailevi sorunlara objektif ve akılcı çözümler getireceksin.",
        "yakın çevrenle yapacağın kısa ziyaretler moralini düzeltecek.",
        "evde teknolojik bir değişiklik yapmak hayatını kolaylaştırabilir."
      ],
      'gelecek': [
        "geleceğe dair vizyonların çok net; onları yazıya dök.",
        "yeni şeyler öğrenmek geleceğini şekillendirecek.",
        "sosyal çevren gelecekteki fırsatlarının anahtarı olabilir.",
        "değişen koşullara hızla adapte olabileceksin.",
        "yutdışı, medya veya yayıncılıkla ilgili planların olabilir.",
        "özgürlüğünü kısıtlayan kalıpları kırıyorsun."
      ],
      'genel': [
        "özgürlüğün kısıtlanmamalı; kanatlarını aç.",
        "merak duygunu takip et; öğrenmek seni canlı tutar.",
        "sosyalleşmek enerjini yükseltir; kabuğuna çekilme.",
        "kararsızlık enerjini tüketebilir; net olmaya çalış."
      ]
    },
    'su': {
      'ask': [
        "duygusal derinliğin artıyor; yüzeysel hiçbir şeye tahammülün yok.",
        "sezgilerin aşkta sana rehberlik edecek; iç sesini dinle.",
        "romantizm rüzgarlarına kapılabilirsin; hayallerin gerçek olabilir.",
        "şefkat görmek ve göstermek istiyorsun; kalbini aç.",
        "partnerinle ruhsal bir bütünleşme yaşayabilirsin.",
        "kırılganlığını göstermekten korkma; bu seni daha güçlü kılar.",
        "geçmiş bir aşkı affetmek kalbine hafiflik getirecek.",
        "rüyalarında aşk hayatınla ilgili mesajlar alabilirsin."
      ],
      'kariyer': [
        "empati yeteneğin iş yerinde fark yaratır; insanları anla.",
        "yaratıcılığını kullanmalısın; sanatsal yönün çok güçlü.",
        "huzurlu bir çalışma ortamı yarat; kaostan kaçın.",
        "iç sesini dinleyerek karar ver; mantık her zaman yetmez.",
        "başkalarına yardım etmek kariyerinde seni yükseltebilir.",
        "hayal gücün, başkalarının göremediği çözümleri bulmanı sağlar.",
        "gizli düşmanlıklara karşı sezgilerin seni koruyacak.",
        "psikoloji veya insan kaynakları gibi alanlarda parlayabilirsin."
      ],
      'saglik': [
        "duygusal yüklerin bedeninde ağırlık yapabilir; arınmalısın.",
        "su kenarında vakit geçirmek enerjini yenileyecektir.",
        "ayakların ve lenf sistemin hassas olabilir; ödemlere dikkat.",
        "ruhsal sağlığın fiziksel sağlığını doğrudan etkiliyor.",
        "uyku terapisi veya rüya çalışmaları yapmak şifa verebilir.",
        "bol su içmek ve vücudunu nemlendirmek şart."
      ],
      'aile': [
        "ailene karşı koruyucu ve şefkatli bir tutum sergiliyorsun.",
        "evde huzur ve güven ortamı yaratmak senin için çok önemli.",
        "geçmişten gelen duygusal bağlar gün yüzüne çıkabilir.",
        "anne veya anne figürleriyle ilişkilerin şifalanabilir.",
        "evde nostaljik objelerle vakit geçirmek seni mutlu edecek.",
        "aile sırları veya gizli kalmış konular aydınlanabilir."
      ],
      'gelecek': [
        "geleceğini sezgilerinle şekillendiriyorsun; hislerine güven.",
        "hayallerinin peşinden gitmekten korkma; evren seni duyuyor.",
        "kadersel akışa teslim olmak sana huzur getirecek.",
        "geçmişi şifalandırarak aydınlık bir geleceğe yürüyorsun.",
        "ruhsal bir yolculuğa çıkma isteğin artabilir.",
        "evrensel sevgiye olan inancın yolunu açıyor."
      ],
      'genel': [
        "akışa teslim olmalısın; direnç gösterme.",
        "rüyaların sana mesaj veriyor; onları not et.",
        "duygusal dalgalanmalara dikkat et; dengede kal.",
        "sezgilerine güvenmelisin; onlar senin pusulan."
      ]
    }
  };

  // 3. EYLEMLER (Topic Bazlı - Devasa Havuz)
  static const Map<String, List<String>> _actions = {
    'ask': [
      "Kalbini açmaktan korkma",
      "İlk adımı atan sen ol",
      "Duygularını açıkça ifade et",
      "Geçmişin yüklerinden kurtul",
      "Kendini sevmekle başla",
      "Partnerini gerçekten dinle",
      "Romantik bir sürpriz yap",
      "Ego savaşlarından uzak dur",
      "Affedici olmayı seç",
      "Yeni insanlarla tanışmaya açık ol",
      "Kıskançlık yapmaktan kaçın",
      "İçindeki sesi dinle ve sezgilerine güven",
      "İlişkindeki sorunları ertelemeden konuş",
      "Birlikte yapacağınız aktiviteleri planla",
      "Sevdiğin kişiye küçük bir hediye al",
      "Ona ne kadar değer verdiğini söyle"
    ],
    'kariyer': [
      "Yeni projeler için kolları sıva",
      "Bütçeni dikkatlice gözden geçir",
      "Yeteneklerine yatırım yap",
      "İş birliği tekliflerine açık ol",
      "Disiplinli çalışmayı elden bırakma",
      "Hedeflerini kağıda dök",
      "Mevcut pozisyonunu koru",
      "Riskli yatırımlardan kaçın",
      "Yaratıcı çözümler üret",
      "Mentorluk almayı düşün",
      "Eksik olduğun konularda eğitim al",
      "İş arkadaşlarınla iletişimini güçlendir",
      "Toplantılarda aktif rol al",
      "Zaman yönetimine özen göster",
      "Ertelediğin işleri bugün tamamla",
      "Profesyonel ağını genişletmek için adım at"
    ],
    'saglik': [
      "Bedenini dinlendir",
      "Su tüketimini artır",
      "Doğada yürüyüş yap",
      "Meditasyona zaman ayır",
      "Beslenme düzenini gözden geçir",
      "Uyku kalitene önem ver",
      "Negatif enerjilerden arın",
      "Yoga veya esneme hareketleri yap",
      "Doktora gitmeyi erteleme",
      "Ruhsal detoks yap",
      "Günde en az 10 bin adım atmayı hedefle",
      "Şeker ve glütenden bir süre uzak dur",
      "Nefes egzersizleriyle stresini yönet",
      "Bel ve sırt egzersizlerini ihmal etme",
      "Kendine bir masaj veya spa günü hediye et",
      "Vitamin değerlerini kontrol ettir"
    ],
    'aile': [
      "Evinde küçük bir değişiklik yap",
      "Ailenle kaliteli zaman geçir",
      "Köklerinle bağ kur",
      "Eski bir dostu ara",
      "Evindeki enerjiyi temizle",
      "Affet ve özgürleş",
      "Sevdiklerine sarıl",
      "Aile büyüklerini ziyaret et",
      "Evcil hayvanınla ilgilen",
      "Sofranı sevdiklerinle paylaş",
      "Evde biriken gereksiz eşyaları ayıkla",
      "Çocuklarla oyun oyna ve onlara vakit ayır",
      "Ailenle eski fotoğraf albümlerine bak",
      "Evde bozulan eşyaları tamir et",
      "Komşunla bir kahve iç",
      "Anne babanın halini hatrını sor"
    ],
    'gelecek': [
      "Niyetlerini netleştir",
      "Değişime kucak aç",
      "İçindeki sese güven",
      "Evrenin işaretlerini oku",
      "Karmik borçlarını öde",
      "Geleceğe umutla bak",
      "Negatif düşünceleri zihninden at",
      "Hayallerini vizyonla birleştir",
      "Ruhsal rehberliğini kabul et",
      "Anın tadını çıkar",
      "Günlük tutmaya başla",
      "Bir vizyon panosu hazırla",
      "Korkularının üzerine git",
      "Spiritüel kitaplar oku veya araştır",
      "Kendine yeni ve büyük bir hedef koy",
      "Evrene olumlu mesajlar gönder"
    ],
    'genel': [
      "Akışa güven",
      "Kendine şefkat göster",
      "Anı yaşa",
      "Gülümsemeyi unutma",
      "Sabırlı ol",
      "Dengede kal",
      "Şükret",
      "Hayata güven",
      "Kendi değerini bil",
      "Işığını yansıt",
      "Bugün bir iyilik yap",
      "Doğadaki güzellikleri fark et",
      "Kendini başkalarıyla kıyaslamayı bırak",
      "Her şeyin geçici olduğunu hatırla",
      "Olumlama cümleleri kur",
      "Kalbini mucizelere aç"
    ]
  };

  // 4. SONUÇLAR (Topic Bazlı - Devasa Havuz)
  static const Map<String, List<String>> _outcomes = {
    'ask': [
      "aşk kapını çalacak.",
      "ilişkin yeni bir boyut kazanacak.",
      "kalbin şifalanacak.",
      "ruh eşinle karşılaşabilirsin.",
      "tutku ateşi yeniden yanacak.",
      "huzurlu bir birliktelik seni bekliyor.",
      "beklediğin o mesaj bugün gelebilir.",
      "aranızdaki buzlar tamamen eriyecek.",
      "gözlerindeki ışıltı herkesi büyüleyecek.",
      "sevdiğin kişi sana sürpriz yapabilir.",
      "aldığın kararlar mutluluk getirecek.",
      "kaderin aşkla yazılıyor."
    ],
    'kariyer': [
      "bolluk ve bereket artacak.",
      "başarı basamaklarını hızla tırmanacaksın.",
      "beklediğin haber olumlu gelecek.",
      "finansal özgürlüğe yaklaşacaksın.",
      "yeteneklerin takdir görecek.",
      "yeni kapılar açılacak.",
      "maaş artışı veya prim alabilirsin.",
      "yöneticilerin seni destekleyecek.",
      "hayalindeki işe bir adım daha yaklaşacaksın.",
      "çabalarının karşılığını fazlasıyla alacaksın.",
      "iş yerinde yıldızın parlayacak.",
      "bereket enerjisi cüzdanına yansıyacak."
    ],
    'saglik': [
      "enerjin tavan yapacak.",
      "ruhun huzur bulacak.",
      "bedenin sana teşekkür edecek.",
      "şifa enerjisi seninle olacak.",
      "daha zinde hissedeceksin.",
      "içsel dengeni bulacaksın.",
      "kronik ağrılarında hafifleme hissedeceksin.",
      "uykunu almış bir şekilde uyanacaksın.",
      "cildin ışıl ışıl parlayacak.",
      "bağışıklık sistemin güçlenecek.",
      "zihinsel berraklığa kavuşacaksın.",
      "kendini yenilenmiş hissedeceksin."
    ],
    'aile': [
      "yuvan huzurla dolacak.",
      "köklerin güçlenecek.",
      "aile bağların sıkılaşacak.",
      "evinde bereket artacak.",
      "sevdiklerinle mutlu olacaksın.",
      "geçmişin ağırlığı kalkacak.",
      "evine neşe ve kahkaha hakim olacak.",
      "uzun süredir görmediğin biriyle hasret gidereceksin.",
      "ailendeki sorunlar tatlıya bağlanacak.",
      "evliliğinde veya ilişkinde güven tazelenecek.",
      "kendini ailene ait hissedeceksin.",
      "huzurlu bir akşam seni bekliyor."
    ],
    'gelecek': [
      "yolun aydınlanacak.",
      "kaderin sana gülümseyecek.",
      "hayallerin gerçeğe dönüşecek.",
      "mucizelere tanık olacaksın.",
      "her şey olması gerektiği gibi olacak.",
      "evren seni destekleyecek.",
      "beklemediğin bir yerden destek göreceksin.",
      "geleceğin sandığından daha parlak olacak.",
      "karşına çıkan fırsatları iyi değerlendireceksin.",
      "şans melekleri omuzlarında olacak.",
      "istediğin her şeye ulaşma gücün var.",
      "karanlık günler geride kaldı."
    ],
    'genel': [
      "hayat sana güzellikler sunacak.",
      "her şey yoluna girecek.",
      "mutluluk seninle olacak.",
      "karanlıklar aydınlığa çıkacak.",
      "şans senden yana olacak.",
      "mucizeler an meselesi.",
      "bugün senin günün olacak.",
      "hiç ummadığın bir anda sevineceksin.",
      "kalbinden geçenler gerçek olacak.",
      "evrenin hediyelerine kucak aç.",
      "pozitif enerjin her yeri saracak.",
      "güzel günler çok yakın."
    ]
  };
}
