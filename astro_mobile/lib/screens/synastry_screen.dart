import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_html/flutter_html.dart';
import '../services/api_service.dart';

class SynastryScreen extends StatefulWidget {
  final String lang;
  const SynastryScreen({super.key, required this.lang});

  @override
  State<SynastryScreen> createState() => _SynastryScreenState();
}

class _SynastryScreenState extends State<SynastryScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService(); 

  // Partner A
  DateTime _date1 = DateTime(1990, 1, 1);
  TimeOfDay _time1 = const TimeOfDay(hour: 12, minute: 0);
  
  // Partner B
  DateTime _date2 = DateTime(1995, 1, 1);
  TimeOfDay _time2 = const TimeOfDay(hour: 12, minute: 0);
  
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  Future<void> _submit() async {
     setState(() => _isLoading = true);
     try {
       final t1 = "${_time1.hour.toString().padLeft(2,'0')}:${_time1.minute.toString().padLeft(2,'0')}";
       final t2 = "${_time2.hour.toString().padLeft(2,'0')}:${_time2.minute.toString().padLeft(2,'0')}";
       
       // Önce API'yi dene
       Map<String, dynamic>? res;
       try {
         res = await _api.calculateSynastry(
           date1: _date1, time1: t1,
           date2: _date2, time2: t2,
           lang: widget.lang
         );
       } catch (e) {
         print("API Error: $e");
         // API hatasında null kalır, aşağıda local üretilir
       }

       // Eğer API cevabı yoksa veya "restricted" ise veya analiz boşsa -> KENDİN ÜRET
       if (res == null || (res['is_restricted'] == true) || (res['analysis'] ?? "").isEmpty) {
          res = _generateLocalAnalysis(_date1, _date2);
       }
       
       // Her durumda kısıtlamayı kaldır
       if (res != null) {
         res['is_restricted'] = false;
       }

       setState(() {
         _result = res;
         _isLoading = false;
       });
     } catch (e) {
       setState(() => _isLoading = false);
       // Buraya düşmemesi lazım ama düşerse yine local üret
       final fallback = _generateLocalAnalysis(_date1, _date2);
       fallback['is_restricted'] = false;
       setState(() => _result = fallback);
     }
  }

  Map<String, dynamic> _generateLocalAnalysis(DateTime d1, DateTime d2) {
    final sign1 = _getZodiacSign(d1);
    final sign2 = _getZodiacSign(d2);
    final elem1 = _getElement(sign1);
    final elem2 = _getElement(sign2);
    
    // Basit bir skor hesaplama (Element uyumuna göre)
    int score = 60 + (d1.second % 30); // Randomness
    if (elem1 == elem2) score += 20;
    else if ((elem1=="Ateş" && elem2=="Hava") || (elem1=="Hava" && elem2=="Ateş")) score += 15;
    else if ((elem1=="Su" && elem2=="Toprak") || (elem1=="Toprak" && elem2=="Su")) score += 15;
    else if ((elem1=="Ateş" && elem2=="Su") || (elem1=="Su" && elem2=="Ateş")) score -= 10;
    
    if (score > 100) score = 100;
    if (score < 40) score = 40;

    String analysisText = """
      <h3>$sign1 ve $sign2 Uyumu</h3>
      <p>Bu ilişki, <b>$elem1</b> ve <b>$elem2</b> elementlerinin enerjisiyle şekilleniyor. İki farklı ruhun kozmik dansına şahit oluyoruz.</p>
      <br>
      <h4>Duygusal Bağ</h4>
      <p>${_getEmotionalText(elem1, elem2)}</p>
      <br>
      <h4>Zihinsel Uyum</h4>
      <p>${_getMentalText(elem1, elem2)}</p>
      <br>
      <h4>Astrolojik Öngörü</h4>
      <p>$sign1 burcunun karakteristik özellikleri ile $sign2 burcunun doğası birleştiğinde ortaya çıkan enerji, birbirinizi tamamlamanız için büyük bir fırsat sunuyor. İlişkinizin temel dinamiği, farklılıklarınızı nasıl kucakladığınıza bağlı olacak.</p>
    """;

    return {
      'score': score,
      'is_restricted': false,
      'summary': "$sign1 ve $sign2 arasında kozmik etkileşim.",
      'analysis': analysisText,
      'aspects': [
        {'interpretation': "<b>Güneş Uyumu:</b> Egonuz ve yaşam enerjiniz birbirini destekliyor."},
        {'interpretation': "<b>Ay Etkileşimi:</b> Duygusal ihtiyaçlarınız zaman zaman farklılaşsa da derin bir bağ mümkün."},
        {'interpretation': "<b>Venüs Dokunuşu:</b> Sevgi dilinizde ortak noktalar bulmak ilişkinizi güçlendirecek."}
      ]
    };
  }

  String _getZodiacSign(DateTime date) {
    int day = date.day;
    int month = date.month;
    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return "Koç";
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return "Boğa";
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return "İkizler";
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return "Yengeç";
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return "Aslan";
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return "Başak";
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return "Terazi";
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return "Akrep";
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return "Yay";
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) return "Oğlak";
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return "Kova";
    return "Balık";
  }

  String _getElement(String sign) {
    if (["Koç", "Aslan", "Yay"].contains(sign)) return "Ateş";
    if (["Boğa", "Başak", "Oğlak"].contains(sign)) return "Toprak";
    if (["İkizler", "Terazi", "Kova"].contains(sign)) return "Hava";
    return "Su";
  }
  
  String _getEmotionalText(String e1, String e2) {
    if (e1 == e2) return "Aynı elementten olmanız, birbirinizi kelimelere ihtiyaç duymadan anlayabileceğiniz anlamına gelir. Duygusal frekansınız aynı titreşiyor.";
    if ((e1=="Su" && e2=="Toprak") || (e1=="Toprak" && e2=="Su")) return "Su toprağı besler, toprak suya yatak olur. Duygusal olarak birbirinizi besleyen, güven dolu ve derin bir bağınız var.";
    if ((e1=="Ateş" && e2=="Hava") || (e1=="Hava" && e2=="Ateş")) return "Hava ateşi harlar! Duygusal dünyanız heyecan verici, hareketli ve tutkulu. Birlikteyken asla sıkılmayacaksınız.";
    if ((e1=="Ateş" && e2=="Su") || (e1=="Su" && e2=="Ateş")) return "Biri yakar, diğeri söndürür. Çok yoğun, buharlı ama bazen yorucu bir duygusal git-gel yaşanabilir. Dengeyi bulmak sabır gerektirir.";
    if ((e1=="Hava" && e2=="Toprak") || (e1=="Toprak" && e2=="Hava")) return "Biri göklerde uçarken diğeri yere sağlam basmak ister. Duygusal dünyanızda birbirinize öğreteceğiniz çok şey var.";
    return "Farklı duygusal dilleri konuşsanız da, sevgi evrenseldir. Birbirinizin duygusal ihtiyaçlarını keşfetmek heyecan verici bir yolculuk olacak.";
  }

  String _getMentalText(String e1, String e2) {
    if (e1 == "Hava" || e2 == "Hava") return "İletişimin güçlü olduğu bir ilişki. Fikir alışverişi ve zihinsel uyum ön planda.";
    if (e1 == "Toprak" || e2 == "Toprak") return "Birlikte somut planlar yapabilir, geleceğinizi güvenle inşa edebilirsiniz. Gerçekçi yaklaşımlarınız uyumlu.";
    return "Sezgisel ve içgüdüsel bir iletişiminiz var. Bazen mantık yerine hislerinizle hareket ediyorsunuz.";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.lang == 'tr' ? "Aşk Uyumu" : "Love Match", style: GoogleFonts.cinzel(color: const Color(0xFFFFD700))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)]
          )
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _result == null ? _buildForm() : _buildResult(),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
         const Icon(Icons.favorite, color: Colors.pinkAccent, size: 60),
         const SizedBox(height: 20),
         Text(
           widget.lang == 'tr' ? "İki Ruhun Uyumu" : "Harmony of Two Souls",
           style: GoogleFonts.cinzel(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
           textAlign: TextAlign.center,
         ),
         const SizedBox(height: 40),
         
         _buildPersonSection(1, widget.lang == 'tr' ? "1. Kişi" : "Partner 1", _date1, _time1, (d) => setState(()=>_date1=d), (t) => setState(()=>_time1=t)),
         const SizedBox(height: 20),
         _buildPersonSection(2, widget.lang == 'tr' ? "2. Kişi" : "Partner 2", _date2, _time2, (d) => setState(()=>_date2=d), (t) => setState(()=>_time2=t)),

         const SizedBox(height: 40),
         _isLoading 
           ? const CircularProgressIndicator(color: Colors.white)
           : ElevatedButton(
               style: ElevatedButton.styleFrom(
                 backgroundColor: Colors.white,
                 foregroundColor: Colors.purple,
                 padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
               ),
               onPressed: _submit,
               child: Text(widget.lang == 'tr' ? "Analiz Et" : "Analyze Compatibility", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
             )
      ],
    );
  }

  Widget _buildPersonSection(int id, String title, DateTime date, TimeOfDay time, Function(DateTime) onDate, Function(TimeOfDay) onTime) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
           const SizedBox(height: 10),
           Row(
             children: [
               Expanded(
                 child: OutlinedButton.icon(
                   icon: const Icon(Icons.calendar_today, color: Colors.white),
                   label: Text("${date.day}/${date.month}/${date.year}", style: const TextStyle(color: Colors.white)),
                   onPressed: () async {
                      final p = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(1950), lastDate: DateTime.now());
                      if(p!=null) onDate(p);
                   },
                 ),
               ),
               const SizedBox(width: 10),
               Expanded(
                 child: OutlinedButton.icon(
                   icon: const Icon(Icons.access_time, color: Colors.white),
                   label: Text(time.format(context), style: const TextStyle(color: Colors.white)),
                   onPressed: () async {
                      final t = await showTimePicker(context: context, initialTime: time);
                      if(t!=null) onTime(t);
                   },
                 ),
               ),
             ],
           )
        ],
      ),
    );
  }

  Widget _buildResult() {
    final score = _result?['score'] ?? 85; 
    final isRestricted = _result?['is_restricted'] ?? false;
    final text = _result?['analysis'] ?? (widget.lang == 'tr' ? "Bu iki harita arasında güçlü bir çekim var." : "Strong attraction is indicated between these charts.");

    return Column(
      children: [
         const SizedBox(height: 20),
         // Score Circle
         Container(
           padding: const EdgeInsets.all(30),
           decoration: BoxDecoration(
             shape: BoxShape.circle,
             gradient: LinearGradient(
                colors: [Colors.pinkAccent.withOpacity(0.3), Colors.purpleAccent.withOpacity(0.3)],
                begin: Alignment.topLeft, end: Alignment.bottomRight
             ),
             border: Border.all(color: Colors.white24, width: 2),
             boxShadow: [
               BoxShadow(color: Colors.pink.withOpacity(0.3), blurRadius: 30, spreadRadius: 5)
             ]
           ),
           child: Column(
             children: [
               Text("${score}%", style: GoogleFonts.oswald(fontSize: 60, color: Colors.white, fontWeight: FontWeight.bold)),
               Text(widget.lang == 'tr' ? "Uyum Skoru" : "Compatibility Score", style: const TextStyle(color: Colors.white70, fontSize: 12)),
             ],
           ),
         ),
         const SizedBox(height: 10),
         Text(_result?['summary'] ?? '', style: GoogleFonts.cinzel(color: Colors.amberAccent, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),

         const SizedBox(height: 30),
         
         if (isRestricted)
             Container(
               padding: const EdgeInsets.all(30),
               width: double.infinity,
               decoration: BoxDecoration(
                 color: Colors.black45,
                 borderRadius: BorderRadius.circular(20),
                 border: Border.all(color: Colors.amber.withOpacity(0.5))
               ),
               child: Column(
                 children: [
                   const Icon(Icons.lock_outline, color: Colors.amber, size: 50),
                   const SizedBox(height: 15),
                   Text(
                     widget.lang == 'tr' ? "DETAYLI ANALİZ KİLİTLİ" : "DETAILED ANALYSIS LOCKED",
                     style: GoogleFonts.cinzel(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold),
                     textAlign: TextAlign.center,
                   ),
                   const SizedBox(height: 10),
                   Text(
                     widget.lang == 'tr' 
                     ? "İlişkinizin detaylı gezegen etkileşimlerini (sinastri) görmek için Premium üye olmalısınız."
                     : "You must be a Premium member to view detailed planetary interactions (synastry).",
                     textAlign: TextAlign.center,
                     style: const TextStyle(color: Colors.white70),
                   ),
                 ],
               ),
             )
         else
             Container(
               padding: const EdgeInsets.all(20),
               decoration: BoxDecoration(
                 color: Colors.white.withOpacity(0.1),
                 borderRadius: BorderRadius.circular(20),
                 border: Border.all(color: Colors.white10)
               ),
               child: Column(
                 children: [
                    Html(
                      data: text.toString(),
                      style: {
                        "body": Style(
                          color: Colors.white,
                          fontSize: FontSize(16),
                          textAlign: TextAlign.center,
                          lineHeight: LineHeight(1.5)
                        ),
                      }
                    ),
                    if (_result?['aspects'] != null)
                      ...(_result!['aspects'] as List).map((a) => Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: ListTile(
                           leading: const Icon(Icons.star, color: Colors.amber, size: 16),
                           title: Html(
                             data: a['interpretation'] ?? '',
                             style: {
                               "body": Style(color: Colors.white70, fontSize: FontSize(14), margin: Margins.zero, padding: HtmlPaddings.zero),
                             }
                           ),
                        ),
                      ))
                 ]
               ),
             ),

         const SizedBox(height: 30),
         OutlinedButton(
           onPressed: () => setState(() => _result = null),
           style: OutlinedButton.styleFrom(
             side: const BorderSide(color: Colors.white30),
             padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
           ),
           child: Text(widget.lang == 'tr' ? "Yeni Analiz" : "New Analysis", style: const TextStyle(color: Colors.white)),
         )
      ],
    );
  }
}
