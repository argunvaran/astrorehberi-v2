
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'blog_screen.dart';

class LibraryScreen extends StatefulWidget {
  final String lang;
  const LibraryScreen({super.key, required this.lang});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _categories = [];
  String _searchQuery = "";

  final Map<String, String> _staticContents = {
    // Burçlar
    "Koç": "Zodyak'ın ilk burcu olan Koç, ateş elementinin öncü niteliğindedir. Mars tarafından yönetilen Koçlar, cesur, girişimci ve enerjik yapılarıyla tanınırlar. Hayata karşı tutkulu bir yaklaşımları vardır ve liderlik vasıfları yüksektir. Gölge yönlerinde sabırsızlık ve dürtüsellik görülebilir.",
    "Boğa": "Venüs yönetimindeki Boğa burcu, toprak elementinin sabit niteliğini taşır. Güven, istikrar ve huzur arayışı ön plandadır. Sanata, estetiğe ve dünyevi zevklere düşkündürler. Sabırlı ve kararlı yapıları, onları hedeflerine ulaşma konusunda inatçı kılabilir.",
    "İkizler": "Merkür yönetimindeki İkizler, hava elementinin değişken niteliğindedir. İletişim, merak ve zeka onların anahtar kelimeleridir. Hızlı düşünen, uyumlu ve sosyal yapılarıyla bilinirler. Ancak odaklanma sorunu ve yüzeysellik gölge yönleri olabilir.",
    "Yengeç": "Ay yönetimindeki Yengeç, su elementinin öncü niteliğindedir. Duygusal derinlik, sezgiler ve koruyuculuk ön plandadır. Aileye ve köklerine bağlıdırlar. Empati yetenekleri yüksektir ancak alınganlık ve aşırı korumacılık gösterebilirler.",
    "Aslan": "Güneş tarafından yönetilen Aslan, ateş elementinin sabit niteliğindedir. Yaratıcılık, özgüven ve liderlik onların doğal halidir. Sahne ışıklarını severler ve cömerttirler. Gölge yönlerinde kibir ve onaylanma ihtiyacı baskın olabilir.",
    "Başak": "Merkür yönetimindeki Başak, toprak elementinin değişken niteliğindedir. Analitik zeka, detaycılık ve hizmet bilinci ön plandadır. Mükemmeliyetçi yapıları onları eleştirel yapabilir. Düzen ve sağlık konularına önem verirler.",
    "Terazi": "Venüs yönetimindeki Terazi, hava elementinin öncü niteliğindedir. Denge, uyum ve adalet arayışı hayatlarının merkezindedir. İlişkiler ve ortaklıklar onlar için çok önemlidir. Kararsızlık ve çatışmadan kaçınma gölge yönleridir.",
    "Akrep": "Mars ve Plüton yönetimindeki Akrep, su elementinin sabit niteliğindedir. Gizem, dönüşüm ve tutku onların ana temalarıdır. Derin sezgileri ve araştırmacı yapıları vardır. Kıskançlık ve güç savaşları gölge yönleri olabilir.",
    "Yay": "Jüpiter yönetimindeki Yay, ateş elementinin değişken niteliğindedir. Özgürlük, inanç ve keşif arayışı ön plandadır. İyimser ve felsefi bir bakış açıları vardır. Abartıya kaçma ve fanatizm gölge yönleri olabilir.",
    "Oğlak": "Satürn yönetimindeki Oğlak, toprak elementinin öncü niteliğindedir. Disiplin, sorumluluk ve başarı odaklılık onların özellikleridir. Sabırlı ve çalışkandırlar. Melankoli ve katılık gölge yönleri olabilir.",
    "Kova": "Satürn ve Uranüs yönetimindeki Kova, hava elementinin sabit niteliğindedir. Özgürlükçü, yenilikçi ve hümanist yapılarıyla bilinirler. Toplumsal konulara duyarlıdırlar. Duygusal mesafeli duruş ve isyankarlık gölge yönleri olabilir.",
    "Balık": "Jüpiter ve Neptün yönetimindeki Balık, su elementinin değişken niteliğindedir. Sınırsız hayal gücü, şefkat ve ruhsallık ön plandadır. Evrensel birleşim arzusundadırlar. Kurban psikolojisi ve gerçeklerden kaçış gölge yönleri olabilir.",
    
    // Tarot - Büyük Arkana
    "Joker": "Joker, yeni başlangıçları, saflığı ve potansiyeli temsil eder. Henüz şekillenmemiş olanın özgürlüğünü taşır. Bir uçurumun kenarında, korkusuzca durur; çünkü evrenin onu tutacağını bilir. Risk alma ve bilinmeyene atılma zamanıdır.",
    "Fool": "Joker, yeni başlangıçları, saflığı ve potansiyeli temsil eder. Henüz şekillenmemiş olanın özgürlüğünü taşır. Bir uçurumun kenarında, korkusuzca durur; çünkü evrenin onu tutacağını bilir. Risk alma ve bilinmeyene atılma zamanıdır.",
    "Büyücü": "Büyücü, irade gücünü, ustalığı ve tezahürü simgeler. Dört elementin (değnek, kupa, kılıç, tılsım) sahibidir ve bunları kullanarak arzularını gerçeğe dönüştürür. 'Yukarıda ne varsa, aşağıda da o vardır' ilkesinin vücut bulmuş halidir.",
    "Azize": "Azize, sezgiyi, bilinçaltını ve gizli bilgeliği temsil eder. Perdenin arkasındaki sırları korur. Size iç sesinizi dinlemenizi ve rüyalarınıza dikkat etmenizi söyler. Pasiflik ve bekleme zamanıdır, çünkü cevaplar dışarıda değil, içeridedir.",
    "İmparatoriçe": "İmparatoriçe, bereketi, doğurganlığı ve dişil gücü simgeler. Doğanın, sanatın ve güzelliğin koruyucusudur. Yaratıcılığın aktığı, duyuların uyandığı bir dönemi işaret eder. Bolluk ve sevgi enerjisi hakimdir.",
    "İmparator": "İmparator, otoriteyi, yapıyı ve eril gücü temsil eder. Düzen kurma, liderlik etme ve sınırları belirleme zamanıdır. Mantık ve strateji ile hareket etmeyi öğütler. İstikrarın ve güvenliğin sembolüdür.",
    "Aziz": "Aziz, gelenekleri, inanç sistemlerini ve ruhsal rehberliği simgeler. Toplumsal kurallara uyumu ve öğrenme sürecini işaret eder. Bir mentordan yardım alma veya bir gruba dahil olma zamanı olabilir.",
    "Aşıklar": "Aşıklar, sevgiyi, uyumu ve önemli seçimleri temsil eder. Sadece romantik aşkı değil, aynı zamanda değerler sisteminizle uyumlu kararlar almayı da simgeler. Kalbinizin sesini dinleyerek bir yol ayrımında olduğunuzu gösterir.",
    "Savaş Arabası": "Savaş Arabası, irade gücüyle elde edilen zaferi ve kontrolü simgeler. Zıt güçleri (siyah ve beyaz sfenksler) dengede tutarak hedefe ilerlemeyi anlatır. Kararlılık ve odaklanma başarıyı getirecektir.",
    "Güç": "Güç kartı, kaba kuvveti değil, içsel dayanıklılığı ve şefkati temsil eder. Aslanı (içgüdüleri) nazikçe ehlileştiren kadını gösterir. Sabır ve cesaretle zorlukların üstesinden gelinebileceğini müjdeler.",
    "Ermiş": "Ermiş, içe dönmeyi, yalnızlığı ve ruhsal arayışı simgeler. Dış dünyadan uzaklaşarak kendi iç ışığınızı bulma zamanıdır. Cevaplar sessizlikte ve tefekkürde gizlidir.",
    "Kader Çarkı": "Kader Çarkı, döngüleri, değişimi ve karmayı temsil eder. Hayatın inişli çıkışlı doğasını hatırlatır. Şansın sizden yana döndüğü bir dönemi işaret edebilir. Değişime direnmek yerine akışa uyum sağlamalısınız.",
    "Adalet": "Adalet, dengeyi, gerçeği ve sebep-sonuç ilişkisini simgeler. Ne ektiyseniz onu biçeceğiniz bir zamandır. Dürüstlük ve objektiflik gerektirir. Hukuki konular veya önemli kararlar gündeme gelebilir.",
    "Asılan Adam": "Asılan Adam, fedakarlığı, beklemeyi ve farklı bir bakış açısını temsil eder. Olaylara tersinden bakarak yeni bir anlayış kazanmayı öğütler. Bazen ilerlemek için durmak ve teslim olmak gerekir.",
    "Ölüm": "Ölüm kartı, bitişleri ve kaçınılmaz dönüşümü simgeler. Bu fiziksel bir ölüm değil, eski bir benliğin veya durumun sona ermesidir. Yeni bir başlangıç için yer açmaktır. Değişimden korkmayın.",
    "Denge": "Denge kartı, uyumu, ölçülülüğü ve sabrı temsil eder. Zıtlıkları bir araya getirerek yeni bir alaşım (simya) oluşturmayı anlatır. Ruhsal ve fiziksel sağlık için dengeyi bulma zamanıdır.",
    "Şeytan": "Şeytan, bağımlılıkları, maddi tutkuları ve kendi yarattığımız zincirleri temsil eder. Korkularınızın veya arzularınızın sizi esir almasına izin vermeyin. Özgürleşmek için önce sizi neyin bağladığını fark etmelisiniz.",
    "Yıkılan Kule": "Yıkılan Kule, ani değişimleri, şok edici olayları ve aydınlanmayı simgeler. Temeli sağlam olmayan yapıların çöküşüdür. Zorlayıcı olsa da, bu yıkım gerçeği görmenizi sağlar ve özgürleştiricidir.",
    "Yıldız": "Yıldız, umudu, şifayı ve ilhamı temsil eder. Fırtınadan (Kule) sonra gelen sakinliktir. Kozmik rehberliğe güvenmeyi ve hayallerinize inanmayı öğütler. Ruhsal yenilenme zamanıdır.",
    "Ay": "Ay, yanılsamaları, bilinçaltı korkularını ve belirsizliği temsil eder. Her şey göründüğü gibi olmayabilir. Rüyalarınıza ve sezgilerinize kulak verin ancak hayal dünyasında kaybolmamaya dikkat edin.",
    "Güneş": "Güneş, başarıyı, canlılığı ve neşeyi simgeler. Zodyak'ın en parlak kartıdır. Her şeyin netleştiği, enerjinizin yüksek olduğu ve mutluluğun hak edildiği bir dönemdir.",
    "Mahkeme": "Mahkeme, uyanışı, yargılamayı ve çağrıyı temsil eder. Geçmişi değerlendirip geleceğe yön verme zamanıdır. İçsel bir çağrıya kulak vererek hayatınızda köklü bir değişiklik yapabilirsiniz.",
    "Dünya": "Dünya, tamamlanmayı, bütünlüğü ve başarıyı simgeler. Bir döngünün sonuna gelinmiş ve hedefe ulaşılmıştır. Evrenle uyum içinde dans etme zamanıdır.",

    // Küçük Arkana
    "Değnek As": "Yeni bir ilham, yaratıcı bir kıvılcım ve potansiyel enerji. Bir fikir veya proje için harekete geçme zamanı.",
    "Değnek Altı": "Zafer, takdir edilme ve özgüven. Topluluk içinde öne çıkma ve başarıyı kutlama.",
    "Değnek Kral": "Vizyon, liderlik ve girişimcilik. İlham veren, kararlı ve etkileyici bir lider figürü.",
    // Değnek Kraliçe (yukarıda var, devamı...)
    
    // Kupa Serisi
    "Kupa As": "Yeni bir aşk, duygusal başlangıç ve ruhsal uyanış. Kalbin kapılarını açma zamanı.",
    "Kupa İkili": "Ruh eşi, uyum ve karşılıklı sevgi. İkili ilişkilerde derinleşme ve anlaşma.",
    "Kupa Üçlü": "Kutlama, dostluk ve topluluk. Sevdiklerinizle bir araya gelme ve keyifli zamanlar.",
    "Kupa Dörtlü": "Memnuniyetsizlik, içe kapanma ve fırsatları görememe. Duygusal bir durgunluk dönemi.",
    "Kupa Beşli": "Hayal kırıklığı, kayıp ve keder. Dökülen süte ağlamak yerine elde kalanlara odaklanmalı.",
    "Kupa Altı": "Nostalji, geçmişten gelen anılar ve masumiyet. Eski bir dostla karşılaşma veya çocukluk anılarına dönüş.",
    "Kupa Yedilisi": "Hayaller, seçenekler ve kafa karışıklığı. Gerçekçi olmayan beklentiler ve illüzyonlar.",
    "Kupa Sekizli": "Vazgeçiş, arayış ve duygusal bir yolculuk. Artık hizmet etmeyen bir durumu geride bırakma cesareti.",
    "Kupa Dokuzlu": "Dilek kartı! Duygusal tatmin, mutluluk ve arzuların gerçekleşmesi.",
    "Kupa Onlu": "Mutlu aile, tamamlanma ve huzur. Duygusal dünyada Nirvana'ya ulaşma.",
    "Kupa Prens": "Haberci, romantik teklif ve yaratıcı ilham. Duygusal bir mesaj getiren genç bir enerji.",
    "Kupa Şövalye": "Romantizm, hayalperestlik ve duygusal jestler. Kalbinin sesini dinleyen bir aşık.",
    "Kupa Kraliçe": "Şefkat, sezgi ve duygusal derinlik. Empati yeteneği yüksek, anaç bir kadın figürü.",
    "Kupa Kral": "Duygusal denge, olgunluk ve şifa. Duygularını kontrol edebilen, bilge bir lider.",

    // Kılıç Serisi
    "Kılıç As": "Zihinsel berraklık, yeni bir fikir ve keskin bir zeka. Bir gerçeğin ortaya çıkması.",
    "Kılıç İkili": "Kararsızlık, denge arayışı ve çıkmaz. Zor bir seçim yapmaktan kaçınma durumu.",
    "Kılıç Üçlü": "Kalp kırıklığı, üzüntü ve ayrılık. Zihinsel veya duygusal bir acı ile yüzleşme.",
    "Kılıç Dörtlü": "Dinlenme, geri çekilme ve meditasyon. Zihni sakinleştirmek için mola verme zamanı.",
    "Kılıç Beşli": "Yenilgi, ihanet ve boş zafer. Kaybet-kaybet durumu veya onursuz bir kazanım.",
    "Kılıç Altı": "Geçiş, iyileşme yolculuğu ve zorluklardan uzaklaşma. Daha sakin sulara doğru yelken açma.",
    "Kılıç Yedilisi": "Kurnazlık, strateji ve belki de biraz hile. Durumu kurtarmak için zekice ama riskli hamleler.",
    "Kılıç Sekizli": "Kısıtlanma, kurban psikolojisi ve çaresizlik hissi. Çoğu engel aslında zihinseldir.",
    "Kılıç Dokuzlu": "Endişe, uykusuzluk ve kabuslar. Zihinsel stresin ve korkuların tavan yaptığı bir an.",
    "Kılıç Onlu": "Bitiş, dibe vuruş ve acı bir son. En kötüsü geride kaldı, artık sadece yukarı çıkılabilir.",
    "Kılıç Prens": "Merak, dedikodu ve zihinsel çeviklik. Bilgi toplayan ve her şeyi sorgulayan genç bir zihin.",
    "Kılıç Şövalye": "Hırs, atılganlık ve bazen saldırganlık. Hedefe kilitlenmiş, hızlı düşünen bir savaşçı.",
    "Kılıç Kraliçe": "Bağımsızlık, dürüstlük ve keskin bir dil. Mantığı duygularının önüne koyan zeki bir kadın.",
    "Kılıç Kral": "Otorite, mantık ve entelektüel güç. Adil, kuralcı ve analitik düşünen bir lider.",

    // Tılsım (Para) Serisi
    "Tılsım As": "Maddi fırsat, bolluk ve yeni bir iş kapısı. Somut bir başarının tohumlarının atılması.",
    "Tılsım İkili": "Denge, esneklik ve çoklu görev. İki durumu veya bütçeyi idare etme becerisi.",
    "Tılsım Üçlü": "Takım çalışması, ustalık ve işbirliği. Yeteneklerin takdir edildiği ve inşa edilen bir proje.",
    "Tılsım Dörtlü": "Tasarruf, garanticilik ve bazen cimrilik. Sahip olduklarına sıkı sıkıya tutunma.",
    "Tılsım Beşli": "Yokluk, maddi sıkıntı ve dışlanmışlık. Zor zamanlarda yardım istemekten çekinmemeli.",
    "Tılsım Altı": "Cömertlik, yardımseverlik ve paylaşım. Alan el ile veren el arasındaki denge.",
    "Tılsım Yedilisi": "Sabır, yatırım ve bekleme. Emeklerin sonucunu almak için zamanın geçmesini bekleme.",
    "Tılsım Sekizli": "Çalışkanlık, detaycılık ve üretkenlik. Bir konuda uzmanlaşmak için yoğun çaba sarf etme.",
    "Tılsım Dokuzlu": "Bağımsızlık, lüks ve kendine yetme. Kendi emeğiyle elde edilen konforun tadını çıkarma.",
    "Tılsım Onlu": "Zenginlik, miras ve aile saadeti. Maddi ve manevi olarak tam bir doyuma ulaşma.",
    "Tılsım Prens": "Öğrenci, çalışkan ve güvenilir. Somut hedefleri olan ve adım adım ilerleyen bir genç.",
    "Tılsım Şövalye": "Sabır, sorumluluk ve garantici yaklaşım. Yavaş ama emin adımlarla hedefe giden kişi.",
    "Tılsım Kraliçe": "Pratiklik, bereket ve anaçlık. Maddi dünyayı ve evini çekip çeviren, güvenilir bir kadın.",
    "Tılsım Kral": "Zenginlik, başarı ve iş dünyasının lideri. Maddi kaynakları yöneten ve güvence sağlayan bir otorite.",
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLibraryItems();
  }

  Future<void> _loadLibraryItems() async {
    try {
      final items = await _apiService.getLibraryItems();
      if (mounted) {
        setState(() {
          _categories = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isTr = widget.lang == 'tr';
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(isTr ? "Kozmik Kütüphane" : "Cosmic Library", style: GoogleFonts.cinzel(color: const Color(0xFFFFD700))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.goldColor,
          labelColor: AppTheme.goldColor,
          unselectedLabelColor: Colors.white54,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: isTr ? "Astro Bilgi" : "Astro Info"),
            Tab(text: isTr ? "Kozmik Blog" : "Cosmic Blog"),
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
          child: TabBarView(
            controller: _tabController,
            children: [
              // TAB 1: API Library
              _buildTab1_AstroLibrary(isTr),

              // TAB 2: Blog Screen
              BlogScreen(lang: widget.lang, embed: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab1_AstroLibrary(bool isTr) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.goldColor));
    
    final filtered = _categories.where((cat) {
       final title = (cat['title'] ?? cat['name'] ?? "").toString().toLowerCase();
       return title.contains(_searchQuery.toLowerCase());
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          isTr ? "Kategori bulunamadı." : "No categories found.",
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: isTr ? "Konu ara..." : "Search topics...",
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final cat = filtered[index];
              final title = cat['title'] ?? cat['name'] ?? (isTr ? "Bilinmeyen Başlık" : "Unknown Title");
              final description = cat['description'] ?? cat['desc'] ?? "";
              final subItems = (cat['sub_items'] ?? cat['items'] ?? []) as List;

              return Card(
                color: Colors.white.withOpacity(0.05),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.white.withOpacity(0.1))),
                child: ExpansionTile(
                  leading: const Icon(Icons.star, color: AppTheme.goldColor),
                  title: Text(title, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                  iconColor: AppTheme.goldColor,
                  collapsedIconColor: Colors.white54,
                  children: [
                    if (description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        description,
                        style: const TextStyle(color: Colors.white70, height: 1.5),
                      ),
                    ),
                    if (subItems.isNotEmpty)
                      ...subItems.map((sub) {
                        final subTitle = sub['title'] ?? sub['name'] ?? sub['content'] ?? '';
                        final subDesc = sub['description'] ?? sub['desc'] ?? sub['content'] ?? '';
                        
                        return Card(
                          color: Colors.white.withOpacity(0.08),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.white.withOpacity(0.05))),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                               // İçerik anahtarını bulmaya çalışıyoruz
                               String content = sub['content'] ?? sub['description'] ?? sub['desc'] ?? sub['text'] ?? sub['body'] ?? sub['detail'] ?? sub['meaning'] ?? sub['interpretation'] ?? "";
                               if (content.isEmpty) content = "Detaylı içerik şu an mevcut değil.";
                               
                               _showSubItemDetail(
                                 context, 
                                 subTitle, 
                                 content
                               );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.auto_awesome, size: 16, color: AppTheme.goldColor),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(subTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
                                      const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white30),
                                    ],
                                  ),
                                  if (subDesc.isNotEmpty && subDesc != subTitle)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0, left: 24),
                                      child: Text(
                                        subDesc.length > 100 ? "${subDesc.substring(0, 100)}..." : subDesc,
                                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showSubItemDetail(BuildContext context, String title, String content) {
    // API içeriği boşsa veya varsayılan mesajsa statik içerikten bulmaya çalış
    if (content.isEmpty || content.contains("Detaylı içerik şu an mevcut değil") || content.startsWith("İçerik bulunamadı")) {
      String foundContent = _getStaticContent(title);
      if (foundContent.isNotEmpty) {
        content = foundContent;
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E), // Koyu mor-lacivert
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, 
                  height: 4, 
                  margin: const EdgeInsets.only(bottom: 20, top: 8),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppTheme.goldColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title, 
                      style: GoogleFonts.cinzel(color: AppTheme.goldColor, fontSize: 24, fontWeight: FontWeight.bold)
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white10),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    content,
                    style: GoogleFonts.merriweather(color: Colors.white70, fontSize: 16, height: 1.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStaticContent(String title) {
    // 1. Tam Eşleşme
    if (_staticContents.containsKey(title)) return _staticContents[title]!;

    // 2. İçeren Kelime (Case Insensitive)
    final lowerTitle = title.toLowerCase();
    
    // Burçlar için özel kontrol ("Koç Burcu" -> "Koç")
    for (var key in _staticContents.keys) {
      if (lowerTitle.contains(key.toLowerCase())) {
        return _staticContents[key]!;
      }
    }

    // İngilizce -> Türkçe Eşleşmeler (Tarot vb.)
    if (lowerTitle.contains("fool")) return _staticContents["Joker"]!;
    if (lowerTitle.contains("magician")) return _staticContents["Büyücü"]!;
    if (lowerTitle.contains("priestess")) return _staticContents["Azize"]!;
    if (lowerTitle.contains("empress")) return _staticContents["İmparatoriçe"]!;
    if (lowerTitle.contains("emperor")) return _staticContents["İmparator"]!;
    if (lowerTitle.contains("hierophant")) return _staticContents["Aziz"]!;
    if (lowerTitle.contains("lovers")) return _staticContents["Aşıklar"]!;
    if (lowerTitle.contains("chariot")) return _staticContents["Savaş Arabası"]!;
    if (lowerTitle.contains("strength")) return _staticContents["Güç"]!;
    if (lowerTitle.contains("hermit")) return _staticContents["Ermiş"]!;
    if (lowerTitle.contains("wheel")) return _staticContents["Kader Çarkı"]!;
    if (lowerTitle.contains("justice")) return _staticContents["Adalet"]!;
    if (lowerTitle.contains("hanged")) return _staticContents["Asılan Adam"]!;
    if (lowerTitle.contains("death")) return _staticContents["Ölüm"]!;
    if (lowerTitle.contains("temperance")) return _staticContents["Denge"]!;
    if (lowerTitle.contains("devil")) return _staticContents["Şeytan"]!;
    if (lowerTitle.contains("tower")) return _staticContents["Yıkılan Kule"]!;
    if (lowerTitle.contains("star")) return _staticContents["Yıldız"]!;
    if (lowerTitle.contains("moon")) return _staticContents["Ay"]!;
    if (lowerTitle.contains("sun")) return _staticContents["Güneş"]!;
    if (lowerTitle.contains("judgement")) return _staticContents["Mahkeme"]!;
    if (lowerTitle.contains("world")) return _staticContents["Dünya"]!;
    
    // Değnek serisi (Ace -> As)
    if (lowerTitle.contains("wands") || lowerTitle.contains("değnek")) {
       if (lowerTitle.contains("ace")) return _staticContents["Değnek As"]!;
       if (lowerTitle.contains("two")) return _staticContents["Değnek İkili"]!;
       if (lowerTitle.contains("three")) return _staticContents["Değnek Üçlü"]!;
       if (lowerTitle.contains("four")) return _staticContents["Değnek Dörtlü"]!;
       if (lowerTitle.contains("five")) return _staticContents["Değnek Beşli"]!;
       if (lowerTitle.contains("six")) return _staticContents["Değnek Altı"]!;
       if (lowerTitle.contains("seven")) return _staticContents["Değnek Yedilisi"]!;
       if (lowerTitle.contains("eight")) return _staticContents["Değnek Sekizli"]!;
       if (lowerTitle.contains("nine")) return _staticContents["Değnek Dokuzlu"]!;
       if (lowerTitle.contains("ten")) return _staticContents["Değnek Onlu"]!;
       if (lowerTitle.contains("page")) return _staticContents["Değnek Prens"]!;
       if (lowerTitle.contains("knight") || lowerTitle.contains("şövalye")) return _staticContents["Değnek Şövalye"]!;
       if (lowerTitle.contains("queen")) return _staticContents["Değnek Kraliçe"]!;
       if (lowerTitle.contains("king")) return _staticContents["Değnek Kral"]!;
    }

    // Kupa serisi
    if (lowerTitle.contains("cups") || lowerTitle.contains("kupa")) {
       if (lowerTitle.contains("ace")) return _staticContents["Kupa As"]!;
       if (lowerTitle.contains("two")) return _staticContents["Kupa İkili"]!;
       if (lowerTitle.contains("three")) return _staticContents["Kupa Üçlü"]!;
       if (lowerTitle.contains("four")) return _staticContents["Kupa Dörtlü"]!;
       if (lowerTitle.contains("five")) return _staticContents["Kupa Beşli"]!;
       if (lowerTitle.contains("six")) return _staticContents["Kupa Altı"]!;
       if (lowerTitle.contains("seven")) return _staticContents["Kupa Yedilisi"]!;
       if (lowerTitle.contains("eight")) return _staticContents["Kupa Sekizli"]!;
       if (lowerTitle.contains("nine")) return _staticContents["Kupa Dokuzlu"]!;
       if (lowerTitle.contains("ten")) return _staticContents["Kupa Onlu"]!;
       if (lowerTitle.contains("page")) return _staticContents["Kupa Prens"]!;
       if (lowerTitle.contains("knight") || lowerTitle.contains("şövalye")) return _staticContents["Kupa Şövalye"]!;
       if (lowerTitle.contains("queen")) return _staticContents["Kupa Kraliçe"]!;
       if (lowerTitle.contains("king")) return _staticContents["Kupa Kral"]!;
    }

    // Kılıç serisi
    if (lowerTitle.contains("swords") || lowerTitle.contains("kılıç")) {
       if (lowerTitle.contains("ace")) return _staticContents["Kılıç As"]!;
       if (lowerTitle.contains("two")) return _staticContents["Kılıç İkili"]!;
       if (lowerTitle.contains("three")) return _staticContents["Kılıç Üçlü"]!;
       if (lowerTitle.contains("four")) return _staticContents["Kılıç Dörtlü"]!;
       if (lowerTitle.contains("five")) return _staticContents["Kılıç Beşli"]!;
       if (lowerTitle.contains("six")) return _staticContents["Kılıç Altı"]!;
       if (lowerTitle.contains("seven")) return _staticContents["Kılıç Yedilisi"]!;
       if (lowerTitle.contains("eight")) return _staticContents["Kılıç Sekizli"]!;
       if (lowerTitle.contains("nine")) return _staticContents["Kılıç Dokuzlu"]!;
       if (lowerTitle.contains("ten")) return _staticContents["Kılıç Onlu"]!;
       if (lowerTitle.contains("page")) return _staticContents["Kılıç Prens"]!;
       if (lowerTitle.contains("knight") || lowerTitle.contains("şövalye")) return _staticContents["Kılıç Şövalye"]!;
       if (lowerTitle.contains("queen")) return _staticContents["Kılıç Kraliçe"]!;
       if (lowerTitle.contains("king")) return _staticContents["Kılıç Kral"]!;
    }

    // Tılsım serisi
    if (lowerTitle.contains("pentacles") || lowerTitle.contains("coins") || lowerTitle.contains("tılsım") || lowerTitle.contains("para")) {
       if (lowerTitle.contains("ace")) return _staticContents["Tılsım As"]!;
       if (lowerTitle.contains("two")) return _staticContents["Tılsım İkili"]!;
       if (lowerTitle.contains("three")) return _staticContents["Tılsım Üçlü"]!;
       if (lowerTitle.contains("four")) return _staticContents["Tılsım Dörtlü"]!;
       if (lowerTitle.contains("five")) return _staticContents["Tılsım Beşli"]!;
       if (lowerTitle.contains("six")) return _staticContents["Tılsım Altı"]!;
       if (lowerTitle.contains("seven")) return _staticContents["Tılsım Yedilisi"]!;
       if (lowerTitle.contains("eight")) return _staticContents["Tılsım Sekizli"]!;
       if (lowerTitle.contains("nine")) return _staticContents["Tılsım Dokuzlu"]!;
       if (lowerTitle.contains("ten")) return _staticContents["Tılsım Onlu"]!;
       if (lowerTitle.contains("page")) return _staticContents["Tılsım Prens"]!;
       if (lowerTitle.contains("knight") || lowerTitle.contains("şövalye")) return _staticContents["Tılsım Şövalye"]!;
       if (lowerTitle.contains("queen")) return _staticContents["Tılsım Kraliçe"]!;
       if (lowerTitle.contains("king")) return _staticContents["Tılsım Kral"]!;
    }
    
    return "";
  }
}
