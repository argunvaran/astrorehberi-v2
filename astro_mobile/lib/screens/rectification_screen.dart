import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'result_screen.dart'; // To show generated chart
import 'package:flutter/cupertino.dart';
import 'input_screen.dart';

class RectificationScreen extends StatefulWidget {
  final String lang;
  const RectificationScreen({super.key, required this.lang});

  @override
  State<RectificationScreen> createState() => _RectificationScreenState();
}

class _RectificationScreenState extends State<RectificationScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  
  // Birth Data
  DateTime _birthDate = DateTime(1990, 1, 1);
  final TextEditingController _latCtrl = TextEditingController(text: "41.0082");
  final TextEditingController _lonCtrl = TextEditingController(text: "28.9784");
  
  // Events
  // Each event: { type: 'marriage', date: DateTime }
  List<Map<String, dynamic>> _events = [];
  
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  // Event Types
  final Map<String, String> _eventTypesTr = {
    'marriage': 'Evlilik',
    'divorce': 'Boşanma',
    'child_birth': 'Çocuk Doğumu',
    'relocation': 'Taşınma / Göç',
    'job_change': 'İş Değişikliği / Terfi',
    'accident': 'Kaza / Ameliyat',
    'graduation': 'Mezuniyet',
    'loss': 'Vefat (Yakın)',
    'award': 'Ödül / Başarı'
  };
  
  final Map<String, String> _eventTypesEn = {
    'marriage': 'Marriage',
    'divorce': 'Divorce',
    'child_birth': 'Child Birth',
    'relocation': 'Relocation',
    'job_change': 'Job Change / Promotion',
    'accident': 'Accident / Surgery',
    'graduation': 'Graduation',
    'loss': 'Loss (Close Relative)',
    'award': 'Award / Success'
  };

  @override
  void initState() {
    super.initState();
    // Start with one empty event
    _addEvent();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final auth = await _api.checkAuth();
    if (auth['authenticated'] != true) {
       // Not authenticated
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bu özellik için giriş yapmalısınız.", style: TextStyle(color: Colors.white))));
         // Optional: Redirect to login or just warn
       }
    }
  }

  void _addEvent() {
    setState(() {
      _events.add({
        'type': 'marriage', 
        'date': DateTime.now().subtract(const Duration(days: 365 * 5))
      });
    });
  }

  void _removeEvent(int index) {
    setState(() {
      _events.removeAt(index);
    });
  }

  Future<void> _pickDate(Function(DateTime) onPicked, DateTime initial) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
        builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFE94560),
              onPrimary: Colors.white,
              surface: Color(0xFF16213E),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1A1A2E),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => onPicked(picked));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_events.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("En az bir olay eklemelisiniz.")));
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      // Format Events
      final eventList = _events.map((e) => {
        'type': e['type'],
        'date': DateFormat('yyyy-MM-dd').format(e['date'] as DateTime)
      }).toList();

      final res = await _api.rectifyBirthTime(
        date: DateFormat('yyyy-MM-dd').format(_birthDate),
        lat: double.tryParse(_latCtrl.text) ?? 41.0,
        lon: double.tryParse(_lonCtrl.text) ?? 29.0,
        lang: widget.lang,
        events: eventList
      );

      if (res.containsKey('error')) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['error'])));
      } else {
         setState(() {
           _result = res;
         });
      }
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isTr = widget.lang == 'tr';
    final typeMap = isTr ? _eventTypesTr : _eventTypesEn;

    return Scaffold(
      appBar: AppBar(
        title: Text(isTr ? "Rektifikasyon" : "Rectification", style: GoogleFonts.cinzel(color: const Color(0xFFFFD700))),
        backgroundColor: const Color(0xFF0F0C29),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0C29), Color(0xFF24243E)],
          ),
        ),
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
          : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   // Explanation
                   Container(
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                     child: Row(
                       children: [
                         const Icon(Icons.info_outline, color: Colors.blueAccent),
                         const SizedBox(width: 10),
                         Expanded(child: Text(
                           isTr ? "Doğum saatinizi bilmiyorsanız, hayatınızdaki önemli olayları girerek sizin için hesaplayabiliriz." 
                                : "If you don't know your birth time, enter major life events and we will calculate it for you.",
                           style: const TextStyle(color: Colors.white70, fontSize: 13)
                         )),
                       ],
                     ),
                   ),
                   const SizedBox(height: 20),
                   
                   // Birth Date & Place
                   Text(isTr ? "Doğum Bilgileri" : "Birth Information", style: GoogleFonts.cinzel(fontSize: 18, color: Colors.white)),
                   const SizedBox(height: 10),
                   
                   _buildGlassContainer(
                     padding: const EdgeInsets.all(16),
                     child: Column(
                       children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(isTr ? "Doğum Tarihi" : "Birth Date", style: const TextStyle(color: Colors.white70)),
                            subtitle: Text(DateFormat('dd MMMM yyyy').format(_birthDate), style: const TextStyle(color: Colors.white, fontSize: 16)),
                            trailing: const Icon(Icons.calendar_today, color: Color(0xFFE94560)),
                            onTap: () => _pickDate((d) => _birthDate = d, _birthDate),
                          ),
                          const Divider(color: Colors.white12),
                          // Simplified manual Enter for now (Assuming Lat/Lon is known or defaulted)
                          // Ideally use same dropdown logic as InputScreen but kept simple here
                          Row(
                            children: [
                               Expanded(child: TextFormField(
                                 controller: _latCtrl,
                                 style: const TextStyle(color: Colors.white),
                                 decoration: const InputDecoration(labelText: "Enlem (Lat)", labelStyle: TextStyle(color: Colors.white54)),
                                 keyboardType: TextInputType.number,
                               )),
                               const SizedBox(width: 10),
                               Expanded(child: TextFormField(
                                 controller: _lonCtrl,
                                 style: const TextStyle(color: Colors.white),
                                 decoration: const InputDecoration(labelText: "Boylam (Lon)", labelStyle: TextStyle(color: Colors.white54)),
                                 keyboardType: TextInputType.number,
                               )),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(isTr ? "*Varsayılan İstanbul (41, 28)" : "*Default Istanbul", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                       ],
                     )
                   ),
                   
                   const SizedBox(height: 25),
                   
                   // Events
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                        Text(isTr ? "Hayat Olayları" : "Life Events", style: GoogleFonts.cinzel(fontSize: 18, color: Colors.white)),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Color(0xFFE94560)),
                          onPressed: _addEvent,
                        )
                     ],
                   ),
                   
                   ..._events.asMap().entries.map((entry) {
                      final i = entry.key;
                      final e = entry.value;
                      return Dismissible(
                        key: ValueKey(e),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _removeEvent(i),
                        background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                        child: _buildGlassContainer(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Column(
                            children: [
                               DropdownButtonFormField<String>(
                                 value: e['type'],
                                 dropdownColor: const Color(0xFF1A1A2E),
                                 style: const TextStyle(color: Colors.white),
                                 decoration: InputDecoration(
                                   labelText: isTr ? "Olay Tipi" : "Event Type",
                                   labelStyle: const TextStyle(color: Colors.white54),
                                   border: InputBorder.none
                                 ),
                                 items: typeMap.entries.map((me) => DropdownMenuItem(value: me.key, child: Text(me.value))).toList(),
                                 onChanged: (val) => setState(() => e['type'] = val),
                               ),
                               const Divider(color: Colors.white10, height: 1),
                               ListTile(
                                 contentPadding: EdgeInsets.zero,
                                 title: Text(isTr ? "Tarih" : "Date", style: const TextStyle(color: Colors.white54, fontSize: 14)),
                                 trailing: Text(DateFormat('dd/MM/yyyy').format(e['date']), style: const TextStyle(color: Colors.white)),
                                 onTap: () => _pickDate((d) => e['date'] = d, e['date']),
                               )
                            ],
                          )
                        ),
                      );
                   }).toList(),
                   
                   const SizedBox(height: 30),
                   
                   // Submit Btn
                   SizedBox(
                     height: 55,
                     child: ElevatedButton(
                       onPressed: _submit,
                       style: ElevatedButton.styleFrom(
                         backgroundColor: const Color(0xFFE94560),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                         elevation: 5
                       ),
                       child: Text(isTr ? "DOĞUM SAATİMİ HESAPLA" : "CALCULATE BIRTH TIME", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                     ),
                   ),
                   
                   const SizedBox(height: 30),
                   
                   // Result Area
                   if (_result != null) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.greenAccent.withOpacity(0.3))
                        ),
                        child: Column(
                          children: [
                             Icon(Icons.check_circle, color: Colors.greenAccent, size: 50),
                             const SizedBox(height: 10),
                             Text(isTr ? "Tahmini Doğum Saatiniz:" : "Estimated Birth Time:", style: const TextStyle(color: Colors.white70)),
                             const SizedBox(height: 5),
                             Text(
                               "${_result!['best_time']}",
                               style: GoogleFonts.orbitron(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                             ),
                             const SizedBox(height: 10),
                             Text(
                               isTr ? "Güven Skoru: %${_result!['confidence'] ?? 80}" : "Confidence: %${_result!['confidence'] ?? 80}",
                               style: const TextStyle(color: Colors.greenAccent),
                             ),
                             const SizedBox(height: 20),
                             ElevatedButton.icon(
                               icon: const Icon(Icons.check),
                               label: Text(isTr ? "Bu Saati Kaydet & Devam Et" : "Save Time & Continue"),
                               style: ElevatedButton.styleFrom(
                                 backgroundColor: Colors.amberAccent,
                                 foregroundColor: Colors.black,
                               ),
                               onPressed: () => _updateProfileAndContinue(),
                             ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 50),
                   ]
                ],
              ),
            ),
          ),
      ),
    );
  }

  Future<void> _updateProfileAndContinue() async {
    if (_result == null) return;
    
    setState(() => _isLoading = true);
    try {
      final bestTime = _result!['best_time'].toString(); // e.g., "14:30"
      
      // Call Update Profile
      final res = await _api.updateProfile(birth_time: bestTime);
      
      if (res.containsKey('error')) {
         if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['error'])));
      } else {
         if(mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil güncellendi!")));
           // Navigate to Input Screen (which will reload profile)
           Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const InputScreen()));
         }
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }


  Widget _buildGlassContainer({required Widget child, EdgeInsets? padding, EdgeInsets? margin}) {
    return Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: child,
    );
  }
}
