import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/data_manager.dart';
import '../services/api_service.dart';

class DailyScreen extends StatefulWidget {
  final String lang;

  const DailyScreen({super.key, required this.lang});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;
  
  String _selectedSign = "Aries"; 
  bool _isLoading = false;
  
  List<dynamic> _allHoroscopes = [];
  String _currentText = "";
  
  // Weekly Data
  List<dynamic> _weeklyData = [];
  bool _weeklyLoaded = false;

  final List<Map<String, String>> _signs = [
    {'id': 'Koç', 'id_en': 'Aries', 'name_tr': 'Koç', 'name_en': 'Aries'},
    {'id': 'Boğa', 'id_en': 'Taurus', 'name_tr': 'Boğa', 'name_en': 'Taurus'},
    {'id': 'İkizler', 'id_en': 'Gemini', 'name_tr': 'İkizler', 'name_en': 'Gemini'},
    {'id': 'Yengeç', 'id_en': 'Cancer', 'name_tr': 'Yengeç', 'name_en': 'Cancer'},
    {'id': 'Aslan', 'id_en': 'Leo', 'name_tr': 'Aslan', 'name_en': 'Leo'},
    {'id': 'Başak', 'id_en': 'Virgo', 'name_tr': 'Başak', 'name_en': 'Virgo'},
    {'id': 'Terazi', 'id_en': 'Libra', 'name_tr': 'Terazi', 'name_en': 'Libra'},
    {'id': 'Akrep', 'id_en': 'Scorpio', 'name_tr': 'Akrep', 'name_en': 'Scorpio'},
    {'id': 'Yay', 'id_en': 'Sagittarius', 'name_tr': 'Yay', 'name_en': 'Sagittarius'},
    {'id': 'Oğlak', 'id_en': 'Capricorn', 'name_tr': 'Oğlak', 'name_en': 'Capricorn'},
    {'id': 'Kova', 'id_en': 'Aquarius', 'name_tr': 'Kova', 'name_en': 'Aquarius'},
    {'id': 'Balık', 'id_en': 'Pisces', 'name_tr': 'Balık', 'name_en': 'Pisces'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    final chart = DataManager.instance.currentChart;
    if (chart != null && chart.meta != null && chart.meta!.sunSign.isNotEmpty) {
       final s = chart.meta!.sunSign;
       final match = _signs.firstWhere(
         (element) => element['id'] == s || element['id_en'] == s || element['name_tr'] == s || element['name_en'] == s,
         orElse: () => _signs[0]
       );
       _selectedSign = widget.lang == 'tr' ? match['name_tr']! : match['name_en']!;
    } else {
       _selectedSign = widget.lang == 'tr' ? 'Koç' : 'Aries';
    }
    
    _fetchAll();
  }
  
  Future<void> _fetchAll() async {
    setState(() => _isLoading = true);
    await Future.wait([_fetchDaily(), _fetchWeekly()]);
    if(mounted) setState(() => _isLoading = false);
  }
  
  Future<void> _fetchDaily() async {
    try {
      final res = await _api.getDailyHoroscopes(widget.lang);
      if (res.containsKey('horoscopes')) {
         if(mounted) {
             setState(() {
               _allHoroscopes = res['horoscopes'];
               _updateCurrentText();
             });
         }
      }
    } catch (_) {
       if(mounted) setState(() => _currentText = widget.lang == 'tr' ? "Bağlantı hatası." : "Connection error.");
    }
  }

  Future<void> _fetchWeekly() async {
    try {
      final res = await _api.getWeeklyForecast(widget.lang);
      // Expected structure: {'forecast': [ {date, comment, total, ...} ]}
      if (res.containsKey('forecast') && res['forecast'] is List) {
         if(mounted) {
             setState(() {
               _weeklyData = res['forecast'];
               _weeklyLoaded = true;
             });
         }
      }
    } catch (_) {}
  }

  void _updateCurrentText() {
    if (_allHoroscopes.isEmpty) return;
    
    final found = _allHoroscopes.firstWhere(
      (h) => h['sign'].toString().toLowerCase() == _selectedSign.toLowerCase(),
      orElse: () => null
    );
    
    if (found != null) {
      _currentText = found['text'];
    } else {
      _currentText = widget.lang == 'tr' ? "Yorum bulunamadı." : "No forecast found.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.lang == 'tr' ? "Günlük & Haftalık" : "Daily & Weekly", style: GoogleFonts.cinzel(color: const Color(0xFFFFD700))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE94560),
          tabs: [
             Tab(text: widget.lang == 'tr' ? "Günlük" : "Daily"),
             Tab(text: widget.lang == 'tr' ? "Haftalık (Gökyüzü)" : "Weekly (Sky)"),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
           gradient: LinearGradient(
             begin: Alignment.topCenter, end: Alignment.bottomCenter,
             colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)]
           )
        ),
        child: SafeArea(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : TabBarView(
                controller: _tabController,
                children: [
                   _buildDailyTab(),
                   _buildWeeklyTab(),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildDailyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
           // Dropdown
           Container(
             margin: const EdgeInsets.only(bottom: 20),
             padding: const EdgeInsets.symmetric(horizontal: 20),
             decoration: BoxDecoration(
               color: Colors.white.withOpacity(0.1),
               borderRadius: BorderRadius.circular(20)
             ),
             child: DropdownButtonHideUnderline(
               child: DropdownButton<String>(
                 value: _selectedSign,
                 dropdownColor: const Color(0xFF2C3E50),
                 icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                 isExpanded: true,
                 items: _signs.map((s) {
                   final val = widget.lang == 'tr' ? s['name_tr']! : s['name_en']!;
                   return DropdownMenuItem(
                     value: val,
                     child: Text(val, style: const TextStyle(color: Colors.white)),
                   );
                 }).toList(),
                 onChanged: (v) {
                   if(v != null) {
                     setState(() {
                        _selectedSign = v;
                        _updateCurrentText();
                     });
                   }
                 },
               ),
             ),
           ),
           
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24)
              ),
              child: Column(
                children: [
                   const Icon(Icons.wb_sunny, color: Colors.orangeAccent, size: 50),
                   const SizedBox(height: 15),
                   Text(
                     widget.lang == 'tr' ? "$_selectedSign İçin Bugün" : "Today for $_selectedSign",
                     style: GoogleFonts.cinzel(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                   ),
                   const SizedBox(height: 15),
                   Text(
                     _currentText,
                     style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.6),
                     textAlign: TextAlign.center,
                   )
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTab() {
    if (!_weeklyLoaded || _weeklyData.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Text(
               widget.lang == 'tr' 
               ? "Haftalık veri şu an alınamıyor. Lütfen daha sonra deneyin."
               : "Weekly data not available at the moment.", 
               style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center
            ),
          ),
        );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _weeklyData.length,
      itemBuilder: (context, index) {
        final day = _weeklyData[index];
        // FIX: Match backend keys (day, score)
        final date = day['day'] ?? day['date'] ?? '';
        final comment = day['comment'] ?? '';
        final score = day['score'] ?? day['total'] ?? 50;
        
        return Card(
           margin: const EdgeInsets.only(bottom: 15),
           color: Colors.black.withOpacity(0.3),
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
           child: Padding(
             padding: const EdgeInsets.all(15),
             child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text(date, style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                         decoration: BoxDecoration(
                           color: _getScoreColor(score),
                           borderRadius: BorderRadius.circular(8)
                         ),
                         child: Text("$score%", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                       )
                     ],
                   ),
                   const SizedBox(height: 10),
                   Text(comment, style: const TextStyle(color: Colors.white, fontSize: 14)),
                ],
             ),
           ),
        );
      },
    );
  }
  
  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }
}
