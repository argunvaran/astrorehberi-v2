import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/data_manager.dart';

class SocialScreen extends StatelessWidget {
  final String lang;
  const SocialScreen({super.key, required this.lang});

  @override
  Widget build(BuildContext context) {
    // Uses DataManager (Celebrity Match)
    final chart = DataManager.instance.currentChart;
    // Mock matches if no data
    final matches = [
        {'name': 'Angelina Jolie', 'sign': 'Gemini', 'compatibility': 'High'},
        {'name': 'Brad Pitt', 'sign': 'Sagittarius', 'compatibility': 'Medium'},
        {'name': 'Leonardo DiCaprio', 'sign': 'Scorpio', 'compatibility': 'Very High'},
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(lang == 'tr' ? "Ünlü Eşleşmen" : "Celebrity Match", style: GoogleFonts.cinzel(color: const Color(0xFFFFD700))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFFee0979), Color(0xFFff6a00)]
          )
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                 Text(
                   lang == 'tr' ? "Hangi Ünlülerle Uyumlusun?" : "Which Celebs Are You Compatible With?",
                   textAlign: TextAlign.center,
                   style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                 ),
                 const SizedBox(height: 20),
                 Expanded(
                   child: ListView.builder(
                     itemCount: matches.length,
                     itemBuilder: (context, index) {
                       final m = matches[index];
                       return Card(
                         color: Colors.white.withOpacity(0.9),
                         margin: const EdgeInsets.only(bottom: 15),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                         child: ListTile(
                           leading: CircleAvatar(
                             backgroundColor: Colors.orangeAccent,
                             child: Text(m['name']!.substring(0,1)),
                           ),
                           title: Text(m['name']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                           subtitle: Text("${m['sign']} - ${m['compatibility']}"),
                           trailing: const Icon(Icons.favorite, color: Colors.red),
                         ),
                       );
                     },
                   ),
                 ),
                 if(chart == null)
                   Container(
                     padding: const EdgeInsets.all(10),
                     color: Colors.black45,
                     child: Text(
                       lang == 'tr' ? "Bu bir örnektir. Kendi eşleşmen için haritanı oluştur." : "This is a demo. Generate your chart for real matches.",
                       style: const TextStyle(color: Colors.white), textAlign: TextAlign.center
                     ),
                   )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
