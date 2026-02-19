import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/data_manager.dart';
import '../models/chart_model.dart';
import 'dart:math';

class SocialPerson {
  final String id;
  String name;
  DateTime birthDate;
  String group; // Aile, Arkadaş, İş, Aşk

  SocialPerson({required this.id, required this.name, required this.birthDate, required this.group});

  String get sign => _calculateSign(birthDate);

  String _calculateSign(DateTime date) {
    int day = date.day;
    int month = date.month;
    
    // Turkish signs hardcoded as it seems preferred based on previous context, 
    // or return English/Turkish based on locale which is passed to screen. 
    // Let's return Turkish as default for display, logic will normalize.
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
}

class SocialScreen extends StatefulWidget {
  final String lang;
  const SocialScreen({super.key, required this.lang});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  // Temporary storage (in-memory)
  final List<SocialPerson> _people = []; // Start empty

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime? _selectedDate;
  String _selectedGroup = 'Arkadaş';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isTr = widget.lang == 'tr';
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      // We don't need AppBar here because RelationshipsScreen has one. 
      // But RelationshipsScreen uses TabBarView.
      // If we put Scaffold inside TabBarView, it works fine.
      backgroundColor: Colors.transparent, 
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)]
          )
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
               Padding(
                 padding: const EdgeInsets.all(20.0),
                 child: Text(
                   isTr ? "Sosyal Çevren & Uyum Analizi" : "Social Circle & Harmony",
                   style: GoogleFonts.cinzel(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                   textAlign: TextAlign.center,
                 ),
               ),

               // Add & Group Analysis Buttons
               Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.end,
                   children: [
                     if (_people.isNotEmpty)
                       Padding(
                         padding: const EdgeInsets.only(right: 10),
                         child: ElevatedButton.icon(
                           onPressed: () => _showGroupAnalysis(isTr),
                           icon: const Icon(Icons.pie_chart, color: Colors.white, size: 20),
                           label: Text(isTr ? "Grup Analizi" : "Group Analysis"),
                           style: ElevatedButton.styleFrom(
                             backgroundColor: Colors.purpleAccent.withOpacity(0.8),
                             foregroundColor: Colors.white,
                             padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                             elevation: 5
                           ),
                         ),
                       ),
                     ElevatedButton.icon(
                       onPressed: () => _showAddPersonDialog(isTr),
                       icon: const Icon(Icons.person_add, color: Colors.white, size: 20),
                       label: Text(isTr ? "Kişi Ekle" : "Add Person"),
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.pinkAccent.withOpacity(0.8),
                         foregroundColor: Colors.white,
                         padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                         elevation: 5
                       ),
                     ),
                   ],
                 ),
               ),
               
               // List
               Expanded(
                 child: _people.isEmpty 
                  ? _buildEmptyState(isTr)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _people.length,
                      itemBuilder: (context, index) {
                        final person = _people[index];
                        return _buildPersonCard(person, isTr, index);
                      },
                    ),
               ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isTr) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups, size: 80, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 10),
          Text(
            isTr ? "Henüz kimseyi eklemediniz." : "No one added yet.",
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 5),
          Text(
            isTr 
            ? "Arkadaş, aile veya partner ekleyerek\nuyumunuzu hemen analiz edin."
            : "Add friends, family or partners\nto analyze compatibility.",
            style: const TextStyle(color: Colors.white38, fontSize: 14),
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }

  Widget _buildPersonCard(SocialPerson person, bool isTr, int index) {
    return Card(
      color: const Color(0xFF1F1E33),
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), 
        side: BorderSide(color: Colors.white.withOpacity(0.05))
      ),
      child: InkWell(
        onTap: () => _showCompatibilityAnalysis(person, isTr),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              // Avatar with Sign or Initials
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: _getGroupColor(person.group).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: _getGroupColor(person.group).withOpacity(0.5))
                ),
                child: Center(
                  child: Text(
                    person.name.isNotEmpty ? person.name[0].toUpperCase() : "?",
                    style: TextStyle(color: _getGroupColor(person.group), fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(person.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(_getGroupIcon(person.group), color: Colors.white54, size: 14),
                        const SizedBox(width: 5),
                        Text(
                          "${person.group} • ${person.sign}",
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Action
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle
                ),
                child: const Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 14),
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- Dialog & Analyzers ---

  void _showAddPersonDialog(bool isTr) {
    _nameController.clear();
    _selectedDate = null;
    _selectedGroup = isTr ? 'Arkadaş' : 'Friend';

    showDialog(
      context: context, 
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF252540),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(isTr ? "Yeni Kişi Ekle" : "Add New Person", style: const TextStyle(color: Colors.white)),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: isTr ? "İsim Soyisim" : "Full Name",
                          hintStyle: TextStyle(color: Colors.white30),
                          filled: true,
                          fillColor: Colors.black12,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          prefixIcon: const Icon(Icons.person, color: Colors.white54),
                        ),
                        validator: (v) => v!.isEmpty ? (isTr ? "İsim giriniz" : "Enter name") : null,
                      ),
                      const SizedBox(height: 15),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime(1995),
                            firstDate: DateTime(1950),
                            lastDate: DateTime.now(),
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData.dark().copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: Colors.pinkAccent,
                                    onPrimary: Colors.white,
                                    surface: const Color(0xFF1A1A2E),
                                    onSurface: Colors.white,
                                  ),
                                ),
                                child: child!,
                              );
                            }
                          );
                          if (date != null) {
                             setDialogState(() => _selectedDate = date);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(10)
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.white54),
                              const SizedBox(width: 10),
                              Text(
                                _selectedDate == null 
                                ? (isTr ? "Doğum Tarihi Seç" : "Select Birth Date")
                                : DateFormat('dd.MM.yyyy').format(_selectedDate!),
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: _selectedGroup,
                        dropdownColor: const Color(0xFF2A2A40),
                        style: const TextStyle(color: Colors.white),
                        items: (isTr 
                          ? ['Arkadaş', 'Aile', 'İş', 'Aşk'] 
                          : ['Friend', 'Family', 'Work', 'Love']
                        ).map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                        onChanged: (v) => setDialogState(() => _selectedGroup = v!),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.black12,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          prefixIcon: const Icon(Icons.group, color: Colors.white54),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: Text(isTr ? "İptal" : "Cancel", style: const TextStyle(color: Colors.white54))
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate() && _selectedDate != null) {
                       setState(() {
                         _people.add(SocialPerson(
                           id: DateTime.now().toString(),
                           name: _nameController.text,
                           birthDate: _selectedDate!,
                           group: _selectedGroup
                         ));
                       });
                       Navigator.pop(context);
                    } else if (_selectedDate == null) {
                       ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(content: Text(isTr ? "Lütfen tarih seçin" : "Please select date"))
                       );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
                  child: Text(isTr ? "Kaydet" : "Save"),
                )
              ],
            );
          }
        );
      }
    );
  }

  void _showGroupAnalysis(bool isTr) {
    if (_people.isEmpty) return;

    // 1. Calculate Elements
    Map<String, int> elementCounts = {"Fire": 0, "Earth": 0, "Air": 0, "Water": 0};
    Map<String, int> modalityCounts = {"Cardinal": 0, "Fixed": 0, "Mutable": 0};

    for (var p in _people) {
      String elem = _getElement(p.sign);
      elementCounts[elem] = (elementCounts[elem] ?? 0) + 1;
      
      String mod = _getModality(p.sign);
      modalityCounts[mod] = (modalityCounts[mod] ?? 0) + 1;
    }

    // Find Dominants
    var sortedElements = elementCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    var sortedModalities = modalityCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    String domElement = sortedElements.first.key;
    String domModality = sortedModalities.first.key;

    // Create Analysis Text
    String analysisTitle = isTr ? "Grubun Enerjisi: ${_translateElement(domElement, isTr)}" 
                                : "Group Energy: $domElement";
                                
    String analysisDesc = _generateGroupDescription(domElement, domModality, isTr);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
         return Container(
           height: MediaQuery.of(context).size.height * 0.7,
           decoration: const BoxDecoration(
             gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)]
             ),
             borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
             boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20)]
           ),
           padding: const EdgeInsets.all(25),
           child: Column(
             children: [
               Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(10))),
               const SizedBox(height: 20),
               
               Icon(_getElementIcon(domElement), size: 60, color: Colors.white),
               const SizedBox(height: 15),
               
               Text(
                 analysisTitle,
                 style: GoogleFonts.cinzel(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                 textAlign: TextAlign.center,
               ),
               const SizedBox(height: 10),
               Text(
                 isTr 
                 ? "Bu grupta ${_translateElement(domElement, true)} ve ${_translateModality(domModality, true)} enerjisi hakim."
                 : "Dominated by $domElement and $domModality energy.",
                 style: const TextStyle(color: Colors.white70),
               ),
               
               const SizedBox(height: 30),
               
               // Stats Row
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                 children: elementCounts.entries.map((e) {
                    return Column(
                      children: [
                        Icon(_getElementIcon(e.key), color: e.key == domElement ? Colors.amber : Colors.white54),
                        const SizedBox(height: 5),
                        Text("${e.value}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text(
                          _translateElement(e.key, isTr).length > 3 
                              ? _translateElement(e.key, isTr).substring(0, 3) 
                              : _translateElement(e.key, isTr),
                          style: const TextStyle(color: Colors.white54, fontSize: 10)
                        )
                      ],
                    );
                 }).toList(),
               ),
               
               const SizedBox(height: 30),
               
               Expanded(
                 child: SingleChildScrollView(
                   child: Container(
                     padding: const EdgeInsets.all(20),
                     decoration: BoxDecoration(
                       color: Colors.black26,
                       borderRadius: BorderRadius.circular(15),
                     ),
                     child: Text(
                       analysisDesc,
                       style: GoogleFonts.merriweather(color: Colors.white, fontSize: 15, height: 1.6),
                       textAlign: TextAlign.justify,
                     ),
                   ),
                 ),
               )
             ],
           ),
         );
      }
    );
  }

  void _showCompatibilityAnalysis(SocialPerson person, bool isTr) {
     final myChart = DataManager.instance.currentChart;
     final String mySign = _getMySign(myChart); // e.g., "Koç"
     final String personSign = person.sign; // e.g., "Boğa"
     
     // Calculate Score
     final int score = _calculateHarmonyScore(mySign, personSign);
     final String comment = _getHarmonyComment(score, isTr);

     showModalBottomSheet(
       context: context,
       backgroundColor: Colors.transparent,
       isScrollControlled: true,
       builder: (context) {
         return Container(
           height: MediaQuery.of(context).size.height * 0.65,
           decoration: const BoxDecoration(
             gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xFF202040), Color(0xFF10101E)]
             ),
             borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
             boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20)]
           ),
           child: Column(
             children: [
               // Drag Handle
               Container(
                 width: 50, height: 5, 
                 margin: const EdgeInsets.symmetric(vertical: 15),
                 decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))
               ),
               
               // Content
               Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 30),
                 child: Column(
                   children: [
                     Text(
                       "$mySign & $personSign",
                       style: GoogleFonts.cinzel(color: Colors.pinkAccent, fontSize: 26, fontWeight: FontWeight.bold),
                     ),
                     const SizedBox(height: 5),
                     Text(
                       isTr ? "Arasındaki Uyum" : "Compatibility",
                       style: const TextStyle(color: Colors.white54, fontSize: 14),
                     ),
                     const SizedBox(height: 30),
                     
                     // Score Circle with Glow
                     Container(
                       width: 140, height: 140,
                       decoration: BoxDecoration(
                         shape: BoxShape.circle,
                         boxShadow: [
                           BoxShadow(color: _getScoreColor(score).withOpacity(0.3), blurRadius: 30, spreadRadius: 5)
                         ]
                       ),
                       child: Stack(
                         alignment: Alignment.center,
                         children: [
                           SizedBox(
                             width: 140, height: 140,
                             child: CircularProgressIndicator(
                               value: score / 100,
                               strokeWidth: 12,
                               backgroundColor: Colors.white10,
                               color: _getScoreColor(score),
                             ),
                           ),
                           Column(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                               Text(
                                 "%$score",
                                 style: GoogleFonts.poppins(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                               ),
                               Text(
                                 isTr ? "UYUM" : "MATCH",
                                 style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 2),
                               )
                             ],
                           )
                         ],
                       ),
                     ),
                     const SizedBox(height: 30),
                     
                     Text(
                       isTr ? "Analiz Sonucu" : "Analysis Result",
                       style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                     ),
                     const SizedBox(height: 15),
                     Container(
                       padding: const EdgeInsets.all(20),
                       decoration: BoxDecoration(
                         color: Colors.white.withOpacity(0.05),
                         borderRadius: BorderRadius.circular(15),
                         border: Border.all(color: Colors.white10)
                       ),
                       child: Text(
                         comment,
                         style: GoogleFonts.merriweather(color: Colors.white70, height: 1.6, fontSize: 15),
                         textAlign: TextAlign.center,
                       ),
                     )
                   ],
                 ),
               )
             ],
           ),
         );
       }
     );
  }

  // --- Helpers ---

  Color _getGroupColor(String group) {
    if (group == 'Aile' || group == 'Family') return Colors.purpleAccent;
    if (group == 'İş' || group == 'Work') return Colors.blueAccent;
    if (group == 'Aşk' || group == 'Love') return Colors.redAccent;
    return Colors.orangeAccent; // Friend
  }

  IconData _getGroupIcon(String group) {
    if (group == 'Aile' || group == 'Family') return Icons.home;
    if (group == 'İş' || group == 'Work') return Icons.work;
    if (group == 'Aşk' || group == 'Love') return Icons.favorite;
    return Icons.sentiment_satisfied; // Friend
  }
  
  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF00FF88); // Neon Green
    if (score >= 60) return const Color(0xFFFFD700); // Gold
    if (score >= 40) return Colors.orangeAccent;
    return const Color(0xFFFF3366); // Neon Red
  }

  String _getMySign(ChartData? chart) {
    if (chart == null) return "Koç";
    try {
      final sun = chart.planets.firstWhere(
        (p) => p.name == "Güneş" || p.name == "Sun", 
        orElse: () => Planet(name: "", sign: "Koç", lon: 0, interpretation: "")
      );
      // Ensure Turkish
      return _normalizeSign(sun.sign);
    } catch (e) {
      return "Koç";
    }
  }
  
  String _normalizeSign(String s) {
     const translation = {
       "Aries": "Koç", "Taurus": "Boğa", "Gemini": "İkizler", "Cancer": "Yengeç",
       "Leo": "Aslan", "Virgo": "Başak", "Libra": "Terazi", "Scorpio": "Akrep",
       "Sagittarius": "Yay", "Capricorn": "Oğlak", "Aquarius": "Kova", "Pisces": "Balık"
     };
     return translation[s] ?? s;
  }

  String _getElement(String sign) {
    const elements = {
      "Koç": "Fire", "Aslan": "Fire", "Yay": "Fire",
      "Boğa": "Earth", "Başak": "Earth", "Oğlak": "Earth",
      "İkizler": "Air", "Terazi": "Air", "Kova": "Air",
      "Yengeç": "Water", "Akrep": "Water", "Balık": "Water"
    };
    return elements[sign] ?? "Fire";
  }

  int _calculateHarmonyScore(String s1, String s2) {
    String e1 = _getElement(s1);
    String e2 = _getElement(s2);

    // TRINE (Same Element) - 120 deg approx in logic
    if (e1 == e2) return 95; 
    
    // SEXTILE (Fire/Air or Earth/Water)
    if ((e1 == "Fire" && e2 == "Air") || (e1 == "Air" && e2 == "Fire")) return 85; 
    if ((e1 == "Water" && e2 == "Earth") || (e1 == "Earth" && e2 == "Water")) return 85;

    // OPPOSITION (Polarities - often same modality but opposing element)
    // Simplified checks for opposition pairs
    // Koç-Terazi, Boğa-Akrep, İkizler-Yay, Yengeç-Oğlak, Aslan-Kova, Başak-Balık
    if (_isOpposition(s1, s2)) return 70; // Attraction but tension

    // SQUARE (Incompatible Elements usually)
    // Fire/Water, Fire/Earth, Air/Water, Air/Earth
    if ((e1 == "Fire" && e2 == "Water") || (e1 == "Water" && e2 == "Fire")) return 45;
    if ((e1 == "Fire" && e2 == "Earth") || (e1 == "Earth" && e2 == "Fire")) return 50;
    if ((e1 == "Air" && e2 == "Water") || (e1 == "Water" && e2 == "Air")) return 55;
    if ((e1 == "Air" && e2 == "Earth") || (e1 == "Earth" && e2 == "Air")) return 60;
    
    return 65; // Neutral
  }

  bool _isOpposition(String s1, String s2) {
    final pairs = [
      {"Koç", "Terazi"}, {"Boğa", "Akrep"}, {"İkizler", "Yay"},
      {"Yengeç", "Oğlak"}, {"Aslan", "Kova"}, {"Başak", "Balık"}
    ];
    for (var p in pairs) {
      if (p.contains(s1) && p.contains(s2)) return true;
    }
    return false;
  }

  String _getHarmonyComment(int score, bool isTr) {
    if (isTr) {
      if (score >= 90) return "Mükemmel bir element uyumu! Enerjileriniz doğal bir şekilde akıyor ve birbirinizi besliyorsunuz.";
      if (score >= 80) return "Oldukça uyumlu bir ilişki. Elementleriniz birbirini destekliyor, iletişim ve anlayış güçlü.";
      if (score >= 70) return "Zıt kutupların çekimi! Aranızdaki farklar yoğun bir çekim yaratıyor, ancak dengeyi bulmak zaman alabilir.";
      if (score >= 50) return "Dengeli ve öğretici. Farklı bakış açılarına sahipsiniz, birbirinizden çok şey öğrenebilirsiniz.";
      return "Zorlayıcı ama geliştirici. Enerjileriniz farklı frekanslarda çalışıyor, bu da sabır gerektiren dersler sunabilir.";
    } else {
      if (score >= 90) return "Perfect elemental harmony! Your energies flow naturally and feed each other.";
      if (score >= 80) return "Highly compatible. Your elements support each other, communication is strong.";
      if (score >= 70) return "Attraction of opposites! Differences create intense attraction, but finding balance may take time.";
      if (score >= 50) return "Balanced and educational. You have different perspectives and can learn a lot from each other.";
      return "Challenging but developmental. Your energies work on different frequencies, offering lessons that require patience.";
    }
  }

  // --- Group Analysis Helpers ---

  String _getModality(String sign) {
    const modalities = {
      "Koç": "Cardinal", "Yengeç": "Cardinal", "Terazi": "Cardinal", "Oğlak": "Cardinal",
      "Boğa": "Fixed", "Aslan": "Fixed", "Akrep": "Fixed", "Kova": "Fixed",
      "İkizler": "Mutable", "Başak": "Mutable", "Yay": "Mutable", "Balık": "Mutable"
    };
    return modalities[sign] ?? "Cardinal"; 
  }

  String _translateElement(String elem, bool isTr) {
    if (!isTr) return elem;
    switch(elem) {
      case "Fire": return "Ateş";
      case "Earth": return "Toprak";
      case "Air": return "Hava";
      case "Water": return "Su";
      default: return elem;
    }
  }

  String _translateModality(String mod, bool isTr) {
    if (!isTr) return mod;
    switch(mod) {
      case "Cardinal": return "Öncü";
      case "Fixed": return "Sabit";
      case "Mutable": return "Değişken";
      default: return mod;
    }
  }
  
  IconData _getElementIcon(String elem) {
    switch(elem) {
      case "Fire": return Icons.local_fire_department;
      case "Earth": return Icons.terrain;
      case "Air": return Icons.air;
      case "Water": return Icons.water_drop;
      default: return Icons.wb_sunny;
    }
  }

  String _generateGroupDescription(String domElem, String domMod, bool isTr) {
    if (isTr) {
      String elemDesc = "";
      if (domElem == "Fire") elemDesc = "Bu grup son derece enerjik, hevesli ve hareket odaklı. Birlikteyken macera, rekabet ve başlatma enerjisi yüksek olur.";
      if (domElem == "Earth") elemDesc = "Grubun ayakları yere sağlam basıyor. Pratik, güvenilir ve somut sonuçlara odaklı bir yapı var. Finansal konular ve yaşam kalitesi ön planda.";
      if (domElem == "Air") elemDesc = "İletişim ve fikir alışverişi bu grubun kalbi. Sohbetler asla bitmez, entelektüel tartışmalar ve sosyal etkinlikler yoğundur.";
      if (domElem == "Water") elemDesc = "Duygusal derinliği olan, birbirine empatik yaklaşan bir grup. Sırlar paylaşılır, manevi destek verilir. Sezgiler güçlüdür.";
      
      String modDesc = "";
      if (domMod == "Cardinal") modDesc = "Öncü nitelik baskın olduğu için, grupta lider ruhlu kişiler var. Harekete geçmek kolaydır.";
      if (domMod == "Fixed") modDesc = "Sabit nitelik baskın. Grup birbirine sadık ve alışkanlıklarına bağlı. Değişim zor olabilir ama bağlar kalıcıdır.";
      if (domMod == "Mutable") modDesc = "Değişken nitelik baskın. Grup her duruma ayak uydurabilir, esnektir. Kaosun içinde bile eğlenmeyi bilirsiniz.";
      
      return "$elemDesc\n\n$modDesc";
    } else {
      return "This group is dominated by $domElem ($domMod). High energy and specific dynamics tailored to these qualities.";
    }
  }
}
