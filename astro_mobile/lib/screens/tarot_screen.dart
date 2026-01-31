import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/tarot_model.dart';

class TarotScreen extends StatefulWidget {
  final String lang;

  const TarotScreen({super.key, required this.lang});

  @override
  State<TarotScreen> createState() => _TarotScreenState();
}

class _TarotScreenState extends State<TarotScreen> {
  final ApiService _api = ApiService(); 
  
  bool _isLoading = true;
  TarotResponse? _tarotData;
  List<bool> _revealed = [false, false, false];

  @override
  void initState() {
    super.initState();
    _fetchTarot();
  }

  Future<void> _fetchTarot() async {
    try {
      final res = await _api.drawTarot(widget.lang);
      if (mounted) {
        setState(() {
          _tarotData = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
           _isLoading = false;
           // Updated Dummy Data matching TarotModel
           _tarotData = TarotResponse(
              cards: [
                 TarotCard(
                   id: "0", name: "The Fool", position: "Past",
                   isReversed: false, meaning: "New beginnings, optimism, trust in life.",
                   element: "Air", color: "#FFD700" 
                 ),
                 TarotCard(
                   id: "1", name: "The Magician", position: "Present",
                   isReversed: false, meaning: "Action, the power to manifest.",
                   element: "Air", color: "#FFD700"
                 ),
                 TarotCard(
                   id: "2", name: "The High Priestess", position: "Future",
                   isReversed: false, meaning: "Inaction, going within, the subconscious.",
                   element: "Water", color: "#C0C0C0"
                 ),
              ],
              synthesis: "A journey from beginning to mastery.",
              wish: WishOutcome(title: "Maybe", text: "It depends heavily on your next step.", score: 50)
           );
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Demo Mode: $e")));
      }
    }
  }

  void _revealCard(int index) {
    if (!_revealed[index]) {
      setState(() {
        _revealed[index] = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.lang == 'tr' ? "Mistik Tarot" : "Mystic Tarot",
          style: GoogleFonts.cinzel(color: const Color(0xFFFFD700))
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
               setState(() {
                 _isLoading = true;
                 _revealed = [false, false, false];
                 _tarotData = null;
               });
               _fetchTarot();
            },
          )
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF240b36), Color(0xFFc31432)]
          )
        ),
        child: SafeArea(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.amber))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      widget.lang == 'tr' ? "Kartlarını Seç" : "Reveal Your Destiny",
                      style: GoogleFonts.cinzel(color: Colors.white70, fontSize: 18),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildCardSlot(0, widget.lang == 'tr' ? "Geçmiş" : "Past"),
                        _buildCardSlot(1, widget.lang == 'tr' ? "Şimdi" : "Present"),
                        _buildCardSlot(2, widget.lang == 'tr' ? "Gelecek" : "Future"),
                      ],
                    ),
                    const SizedBox(height: 30),
                    if (_revealed.contains(true)) ..._buildInterpretations(),
                    
                    // Wish/Synthesis Section
                    if (_revealed.every((r) => r) && _tarotData != null)
                       Padding(
                         padding: const EdgeInsets.only(top: 20),
                         child: Container(
                           padding: const EdgeInsets.all(15),
                           decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.amber)
                           ),
                             child: Column(
                               children: [
                                 Text(widget.lang == 'tr' ? "SENTEZ & YORUM" : "SYNTHESIS", style: GoogleFonts.cinzel(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold)),
                                 const SizedBox(height: 10),
                                 Text(_tarotData!.synthesis, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, height: 1.4)),
                                 
                                 const Divider(color: Colors.amber, height: 30),
                                 
                                 // WISH OUTCOME
                                 Text(_tarotData!.wish.title, style: GoogleFonts.cinzel(color: const Color(0xFF00E5FF), fontSize: 18, fontWeight: FontWeight.bold)),
                                 const SizedBox(height: 5),
                                 Text(_tarotData!.wish.text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                                 const SizedBox(height: 10),
                                 
                                 // Score Indicator
                                 Container(
                                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                   decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20)),
                                   child: Text(
                                     "Enerji Puanı: ${_tarotData!.wish.score}",
                                     style: TextStyle(
                                       color: _tarotData!.wish.score > 0 ? Colors.greenAccent : Colors.redAccent,
                                       fontWeight: FontWeight.bold
                                     ),
                                   ),
                                 )
                               ],
                             ),
                         ),
                       )
                  ],
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildCardSlot(int index, String label) {
    if (_tarotData == null || _tarotData!.cards.length <= index) return const SizedBox();

    final card = _tarotData!.cards[index];
    final isRevealed = _revealed[index];

    return GestureDetector(
      onTap: () => _revealCard(index),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            width: 100,
            height: 160,
            decoration: BoxDecoration(
              color: isRevealed ? Colors.white : const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(0.5), width: 2),
              boxShadow: [
                 BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)
              ]
            ),
            child: isRevealed 
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     const Icon(Icons.auto_awesome, color: Colors.purple, size: 30),
                     const SizedBox(height: 10),
                     Padding(
                       padding: const EdgeInsets.symmetric(horizontal: 4),
                       child: Text(
                         card.name,
                         textAlign: TextAlign.center,
                         style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                       ),
                     )
                  ],
                )
              : Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(colors: [Color(0xFF2C3E50), Color(0xFF000000)])
                  ),
                  child: const Center(
                    child: Icon(Icons.help_outline, color: Colors.white24, size: 40),
                  ),
                ),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  List<Widget> _buildInterpretations() {
    List<Widget> list = [];
    final labels = widget.lang == 'tr' ? ["Geçmiş", "Şimdi", "Gelecek"] : ["Past", "Present", "Future"];

    for(int i=0; i<3; i++) {
       if (_revealed[i] && _tarotData != null && _tarotData!.cards.length > i) {
          final card = _tarotData!.cards[i];
          list.add(
            Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white10)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                     children: [
                        Text(labels[i], style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 10),
                        Text("- ${card.name} ${card.isReversed ? '(Rev)' : ''}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                     ],
                   ),
                   const SizedBox(height: 8),
                   // FIX: Use 'meaning' instead of 'interpretation'
                   Text(card.meaning, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            )
          );
       }
    }
    return list;
  }
}
