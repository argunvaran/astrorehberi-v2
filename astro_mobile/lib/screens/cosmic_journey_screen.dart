
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ai_service.dart';
import '../services/library_service.dart';
import '../services/data_manager.dart';
import '../theme/app_theme.dart';
import 'hours_screen.dart';
import 'career_screen.dart';
import '../models/article_model.dart';

class CosmicJourneyScreen extends StatefulWidget {
  final String lang;
  const CosmicJourneyScreen({super.key, required this.lang});

  @override
  State<CosmicJourneyScreen> createState() => _CosmicJourneyScreenState();
}

class _CosmicJourneyScreenState extends State<CosmicJourneyScreen> with SingleTickerProviderStateMixin {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Ensure library is loaded
    LibraryService.instance.loadLibrary();
    _startJourney();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startJourney() async {
    if (!DataManager.instance.hasData) {
      if (mounted) {
        setState(() {
          _messages.add({
            "role": "ai", // UI checks this but displays human text
            "text": widget.lang == 'tr' 
              ? "Yolculuğa başlamak için önce doğum haritanı hesaplamalıyız. Lütfen ana ekrana dönüp bilgilerini gir."
              : "We need to calculate your birth chart first. Please return to home and enter your details."
          });
        });
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final welcome = await AiService.startJourney(DataManager.instance.currentChart!);
      if (mounted) {
        setState(() {
          _messages.add({"role": "ai", "text": welcome});
        });
      }
    } catch (e) {
      String errorMsg = "Kozmik bir parazit oluştu.";
      if (mounted) {
        setState(() {
          _messages.add({"role": "ai", "text": "$errorMsg\n$e"});
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleTopicSelection(String code, String label) async {
    if (_isLoading) return;
    
    setState(() {
      _messages.add({"role": "user", "text": label});
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await AiService.continueJourney(_messages.length.toString(), code);
      
      if (mounted) {
        setState(() {
          _messages.add({"role": "ai", "text": response});
        });
      }

      await Future.delayed(const Duration(milliseconds: 1200)); 
      
      Article article = LibraryService.instance.getRandomArticle();
      
      // Fallback: Eğer kütüphane boşsa yerel "Kadim Bilgelik" havuzunu kullan
      if (article.content.length < 50 || article.title.contains("Yükleniyor") || article.title.isEmpty) {
         article = _getAncientWisdom(widget.lang == 'tr');
      }

      if (mounted) {
        setState(() {
           String articleMsg = "📚 **Kadim Bilgilerden Bir Not:**\n\n"
                               "**${article.title}**\n"
                               "*${widget.lang == 'tr' ? "Kaynağından Mesaj" : "Message from Source"}*\n\n"
                               "${article.content}";
           
           _messages.add({"role": "library", "text": articleMsg});
           _isLoading = false;
        });
        _scrollToBottom();
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({"role": "ai", "text": "Kozmik bağlantıda bir dalgalanma oldu. Lütfen tekrar dene."});
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isTr = widget.lang == 'tr';
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(isTr ? "Kozmik Yolculuk" : "Cosmic Journey", style: GoogleFonts.cinzel(color: const Color(0xFFFFD700))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.white, onPressed: () => Navigator.pop(context)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.goldColor,
          labelColor: AppTheme.goldColor,
          unselectedLabelColor: Colors.white54,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: [
             Tab(icon: const Icon(Icons.auto_awesome), text: isTr ? "Kozmik Rehber" : "Cosmic Guide"),
             Tab(icon: const Icon(Icons.access_time), text: isTr ? "Saatler" : "Hours"),
             Tab(icon: const Icon(Icons.business_center), text: isTr ? "Kariyer" : "Career"),
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
              // TAB 1: Chat UI
              _buildChatTab(isTr),

              // TAB 2: Planetary Hours
              HoursScreen(lang: widget.lang, embed: true),

              // TAB 3: Career Path
              CareerScreen(lang: widget.lang, embed: true),
            ],
          ),
        ),
      ),
    );
  }

  // --- Chat Tab Content ---
  Widget _buildChatTab(bool isTr) {
    return Column(
      children: [
         Expanded(
           child: ListView.builder(
             controller: _scrollController,
             padding: const EdgeInsets.all(16),
             itemCount: _messages.length,
             itemBuilder: (context, index) {
               final m = _messages[index];
               if (m['role'] == 'library') {
                 return _buildArticleBubble(m['text'] ?? "");
               }
               final isAi = m['role'] == 'ai';
               return _buildChatBubble(m['text'] ?? "", isAi);
             },
           ),
         ),
         if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: AppTheme.goldColor),
            ),
         _buildInputArea(isTr),
      ],
    );
  }

  Widget _buildChatBubble(String text, bool isAi) {
    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isAi ? Colors.white.withOpacity(0.1) : AppTheme.accentColor.withOpacity(0.8),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isAi ? 0 : 20),
            bottomRight: Radius.circular(isAi ? 20 : 0),
          ),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Text(
          text,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, height: 1.4),
        ),
      ),
    );
  }

  Widget _buildArticleBubble(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.9),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E), // Koyu lacivert zemin
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppTheme.goldColor.withOpacity(0.5), width: 1), // Altın çerçeve
          boxShadow: [
             BoxShadow(
               color: AppTheme.goldColor.withOpacity(0.1),
               blurRadius: 15,
               spreadRadius: 2,
             )
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: AppTheme.goldColor, size: 20),
                SizedBox(width: 8),
                Text("KADİM BİLGELİK", style: TextStyle(color: AppTheme.goldColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              text.replaceAll("📚 **Kadim Bilgilerden Bir Not:**\n\n", ""), 
              style: GoogleFonts.merriweather( 
                color: Colors.white70,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isTr) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E), 
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30), 
          topRight: Radius.circular(30)
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, -5))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isTr ? "Yıldızlara Danış:" : "Consult the Stars:",
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 15),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTopicChip(isTr ? "💘 Aşk & İlişkiler" : "Love & Relations", "ask"),
                _buildTopicChip(isTr ? "💰 Kariyer & Para" : "Career & Money", "kariyer"),
                _buildTopicChip(isTr ? "🌿 Sağlık & Şifa" : "Health & Healing", "saglik"),
                _buildTopicChip(isTr ? "🏠 Aile & Yuva" : "Family & Home", "aile"),
                _buildTopicChip(isTr ? "🔮 Gelecek & Karma" : "Future & Karma", "gelecek"),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildTopicChip(String label, String topicCode) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ActionChip(
        label: Text(label),
        labelStyle: GoogleFonts.outfit(
          color: Colors.white, 
          fontWeight: FontWeight.w600,
          fontSize: 15
        ),
        backgroundColor: AppTheme.accentColor.withOpacity(0.2),
        side: const BorderSide(color: AppTheme.accentColor, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        onPressed: () => _handleTopicSelection(topicCode, label),
      ),
    );
  }

  Article _getAncientWisdom(bool isTr) {
    final List<Map<String, String>> trWisdom = [
      {"title": "Hermetik Prensip", "content": "Yukarıda ne varsa, aşağıda da o vardır. İçeride ne varsa, dışarıda da o vardır. Evren dev bir aynadır."},
      {"title": "Mevlana'dan", "content": "Yarana merhem arama, yaranın kendisi şifaya açılan kapıdır. Acı, ışığın içeri girdiği yerdir."},
      {"title": "Zamanın Ruhu", "content": "Her şeyin bir vakti vardır. Tohumun çatlaması için karanlığa, filizin büyümesi için ışığa ihtiyaç vardır. Acele etme, güven."},
      {"title": "İçsel Ses", "content": "Başkalarının gürültüsü, kendi iç sesini duymanı engellemesin. Cevaplar dışarıda değil, sessizliğinin içindedir."},
      {"title": "Değişim Yasası", "content": "Değişime direnmek, akıntıya karşı yüzmek gibidir. Bırak hayat aksın, seni gitmen gereken kıyıya o götürecektir."}
    ];

    final List<Map<String, String>> enWisdom = [
      {"title": "Hermetic Principle", "content": "As above, so below. As within, so without. The universe is a giant mirror reflecting your inner state."},
      {"title": "From Rumi", "content": "The wound is the place where the Light enters you. Do not seek a balm, let the wound itself be the cure."},
      {"title": "Spirit of Time", "content": "To everything there is a season. The seed needs darkness to crack open, the sprout needs light to grow. Trust the timing."},
      {"title": "Inner Voice", "content": "Do not let the noise of others drown out your own inner voice. The answers are not outside, but within your silence."},
      {"title": "Law of Change", "content": "Resisting change is like swimming against the current. Let life flow; it will carry you to the shore you are meant to reach."}
    ];

    final list = isTr ? trWisdom : enWisdom;
    final item = list[DateTime.now().second % list.length]; // Saniyeye göre rastgele

    return Article(
      id: "ancient_${DateTime.now().millisecondsSinceEpoch}",
      title: item['title']!,
      category: "Kadim Bilgelik",
      content: item['content']!,
      author: "Ancient Ones"
    );
  }
}
