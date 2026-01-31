import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class ContactScreen extends StatefulWidget {
  final String lang;
  const ContactScreen({super.key, required this.lang});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = false;

  // Contact Form
  final _contactFormKey = GlobalKey<FormState>();
  final TextEditingController _cName = TextEditingController();
  final TextEditingController _cEmail = TextEditingController();
  final TextEditingController _cMsg = TextEditingController();

  // Appointment Form
  final _appFormKey = GlobalKey<FormState>();
  final TextEditingController _aTopic = TextEditingController();
  final TextEditingController _aMsg = TextEditingController();
  final TextEditingController _aContact = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _submitContact() async {
    if(!_contactFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _api.submitContactMessage(_cName.text, _cEmail.text, _cMsg.text);
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.lang == 'tr' ? 'Mesajınız iletildi!' : 'Message sent!'),
          backgroundColor: Colors.green
        ));
        _cMsg.clear();
      }
    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitAppointment() async {
    if(!_appFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _api.submitAppointment(_aTopic.text, _aMsg.text, _aContact.text);
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.lang == 'tr' ? 'Randevu talebiniz alındı!' : 'Request received!'),
          backgroundColor: Colors.green
        ));
        _aMsg.clear();
      }
    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isTr = widget.lang == 'tr';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          isTr ? "İletişim Noktası" : "Contact Hub", 
          style: GoogleFonts.cinzel(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE94560),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: [
            Tab(text: isTr ? "Mesaj Gönder" : "Send Message", icon: const Icon(Icons.mail)),
            Tab(text: isTr ? "Randevu Talep" : "Book Appt", icon: const Icon(Icons.calendar_month)),
          ],
        ),
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63)],
          ),
        ),
        child: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              // 1. Contact Tab
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _contactFormKey,
                  child: Column(
                    children: [
                       _glassBox(
                         child: Column(
                           children: [
                             Text(isTr ? "Bize Ulaşın" : "Contact Us", style: GoogleFonts.cinzel(color: Colors.white, fontSize: 24)),
                             const SizedBox(height: 10),
                             Text(
                               isTr ? "Soru ve görüşleriniz için formu doldurun." : "Fill the form for any inquiries.",
                               textAlign: TextAlign.center,
                               style: const TextStyle(color: Colors.white70),
                             ),
                             const SizedBox(height: 20),
                             _field(_cName, isTr ? "Ad Soyad" : "Name"),
                             const SizedBox(height: 10),
                             _field(_cEmail, isTr ? "E-posta" : "Email", type: TextInputType.emailAddress),
                             const SizedBox(height: 10),
                             _field(_cMsg, isTr ? "Mesajınız" : "Message", maxLines: 5),
                             const SizedBox(height: 20),
                             _isLoading 
                               ? const CircularProgressIndicator(color: Color(0xFFE94560))
                               : ElevatedButton.icon(
                                 onPressed: _submitContact,
                                 icon: const Icon(Icons.send),
                                 label: Text(isTr ? "GÖNDER" : "SEND"),
                                 style: ElevatedButton.styleFrom(
                                   backgroundColor: const Color(0xFFE94560),
                                   padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)
                                 ),
                               )
                           ],
                         )
                       )
                    ],
                  ),
                ),
              ),
              
              // 2. Appointment Tab
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _appFormKey,
                  child: Column(
                    children: [
                       _glassBox(
                         child: Column(
                           children: [
                             Text(isTr ? "Danışmanlık Al" : "Consultation", style: GoogleFonts.cinzel(color: Colors.white, fontSize: 24)),
                             const SizedBox(height: 10),
                             Text(
                               isTr ? "Özel astrolojik danışmanlık talep edin." : "Request a private astrological reading.",
                               textAlign: TextAlign.center,
                               style: const TextStyle(color: Colors.white70),
                             ),
                             const SizedBox(height: 20),
                             DropdownButtonFormField<String>(
                               dropdownColor: const Color(0xFF1E1E2E),
                               value: 'Natal Harita',
                               style: const TextStyle(color: Colors.white),
                               decoration: _inputDec(isTr ? "Konu" : "Topic"),
                               items: [
                                 'Natal Harita', 'Sinastri (İlişki)', 'Kariyer', 'Yıllık Öngörü', 'Horary (Soru)', 'Diğer'
                               ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                               onChanged: (v) => _aTopic.text = v!,
                             ),
                             const SizedBox(height: 10),
                             _field(_aContact, isTr ? "İletişim (Tel/E-mail)" : "Contact (Tel/Email)", hint: isTr ? "Örn: 0555..." : "e.g. +90..."),
                             const SizedBox(height: 10),
                             _field(_aMsg, isTr ? "Notunuz (Opsiyonel)" : "Note (Optional)", maxLines: 3),
                             const SizedBox(height: 20),
                             _isLoading 
                               ? const CircularProgressIndicator(color: Color(0xFFE94560))
                               : ElevatedButton.icon(
                                 onPressed: _submitAppointment,
                                 icon: const Icon(Icons.event_available),
                                 label: Text(isTr ? "TALEP OLUŞTUR" : "REQUEST"),
                                 style: ElevatedButton.styleFrom(
                                   backgroundColor: Colors.purpleAccent,
                                   padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)
                                 ),
                               )
                           ],
                         )
                       )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassBox({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: child,
    );
  }

  Widget _field(TextEditingController controller, String label, {int maxLines = 1, TextInputType? type, String? hint}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDec(label, hint: hint),
      validator: (v) => v!.isEmpty && label != 'Notunuz (Opsiyonel)' ? 'Gerekli' : null,
    );
  }

  InputDecoration _inputDec(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24),
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFE94560)), borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: Colors.black26
    );
  }
}
