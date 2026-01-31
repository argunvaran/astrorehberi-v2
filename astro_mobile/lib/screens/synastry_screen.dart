import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
       
       final res = await _api.calculateSynastry(
         date1: _date1, time1: t1,
         date2: _date2, time2: t2,
         lang: widget.lang
       );
       setState(() {
         _result = res;
         _isLoading = false;
       });
     } catch (e) {
       setState(() => _isLoading = false);
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Analysis failed: $e. Try checking connection.")));
     }
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
                    Text(text.toString(), style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5), textAlign: TextAlign.center),
                    if (_result?['aspects'] != null)
                      ...(_result!['aspects'] as List).map((a) => Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: ListTile(
                           leading: const Icon(Icons.star, color: Colors.amber, size: 16),
                           title: Text(a['interpretation'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 14)),
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
