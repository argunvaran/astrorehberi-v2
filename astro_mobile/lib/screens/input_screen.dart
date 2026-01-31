import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';

import '../models/chart_model.dart';
import '../services/api_service.dart';
import '../services/data_manager.dart';
import 'result_screen.dart';
import 'daily_screen.dart';
import 'social_screen.dart'; 
import 'tarot_screen.dart';
import 'synastry_screen.dart';
import 'draconic_screen.dart';
import 'hours_screen.dart';
import 'career_screen.dart';
import 'celestial_screen.dart'; 
import 'social/social_hub_screen.dart'; // New Social Hub
import 'landing_screen.dart';
import 'contact_screen.dart';
import 'admin_screen.dart';
import 'blog_screen.dart'; // Added Import

import '../theme/strings.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  DateTime _selectedDate = DateTime(1990, 1, 1);
  TimeOfDay _selectedTime = const TimeOfDay(hour: 12, minute: 0);
  final TextEditingController _latController = TextEditingController(text: "41.0082"); 
  final TextEditingController _lonController = TextEditingController(text: "28.9784");
  
  bool _isLoading = false;
  String _lang = 'tr';
  bool _simulatePremium = false; // Added for testing

  bool _isAuth = false;
  bool _isAdmin = false;
  bool _formLocked = false;
  String _username = "Guest";

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final res = await _apiService.checkAuth();
    if (res['authenticated'] == true) {
      if(mounted) {
        setState(() {
          _isAuth = true;
          _isAdmin = res['is_superuser'] == true;
          _username = res['username'] ?? "User";
          if (res['profile'] != null) {
             final p = res['profile'];
             _formLocked = true;
             if(p['date'] != null && p['date'].toString().isNotEmpty) {
               try {
                 final parts = p['date'].toString().split('-');
                 _selectedDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
               } catch (_) {}
             }
             if(p['time'] != null && p['time'].toString().isNotEmpty) {
                try {
                  final parts = p['time'].toString().split(':');
                  _selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
                } catch (_) {}
             }
             _latController.text = p['lat']?.toString() ?? "0";
             _lonController.text = p['lon']?.toString() ?? "0";
          }
        });
      }
    }
  }
  
  Future<void> _logout() async {
    await _apiService.logout();
    DataManager.instance.clear();
    if(mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LandingScreen()));
    }
  } 

  void _toggleLanguage() {
    setState(() {
      _lang = _lang == 'en' ? 'tr' : 'en';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final timeStr = "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}";
      
      final chartData = await _apiService.calculateChart(
        date: _selectedDate,
        time: timeStr,
        lat: double.parse(_latController.text),
        lon: double.parse(_lonController.text),
        lang: _lang,
        simulatePremium: _simulatePremium,
      );
      
      DataManager.instance.setChartData(chartData);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(data: chartData, lang: _lang),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${AppStrings.get('error_title', _lang)}: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
               primary: Color(0xFFE94560),
               onPrimary: Colors.white,
               surface: Color(0xFF16213E),
               onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      }
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
       builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
             timePickerTheme: TimePickerThemeData(
               backgroundColor: const Color(0xFF16213E),
               hourMinuteTextColor: Colors.white,
               dayPeriodTextColor: Colors.white,
               dialHandColor: const Color(0xFFE94560),
               dialBackgroundColor: const Color(0xFF1A1A2E),
             )
          ),
          child: child!,
        );
      }
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }
  
  void _scrollToForm() {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut
      );
  }

  void _checkDataAndNavigate(Widget screen) {
      if (DataManager.instance.hasData) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      } else {
          _scrollToForm();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(_lang == 'tr' ? "Lütfen önce doğum haritanızı hesaplayın." : "Please generate your natal chart first."),
              backgroundColor: Colors.orange));
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: kIsWeb 
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 8),
                Image.asset('assets/icon/app_icon.png', height: 40),
                const SizedBox(width: 12),
                Text("DEEP COSMOS", style: GoogleFonts.cinzel(color: const Color.fromARGB(255, 237, 236, 236), fontWeight: FontWeight.bold, fontSize: 24)),
              ],
            ) 
          : const SizedBox.shrink(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), 
        actions: [
          TextButton.icon(
            onPressed: _toggleLanguage,
            icon: const Icon(Icons.language, color: Color(0xFFE94560)),
            label: Text(
              AppStrings.get('language_btn', _lang), 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
            ),
            style: TextButton.styleFrom(backgroundColor: Colors.black26),
          ),
          const SizedBox(width: 16),
        ],
      ),
      drawer: _buildDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   const SizedBox(height: 10),
                   Text(
                     AppStrings.get('app_title', _lang),
                     textAlign: TextAlign.center,
                     style: GoogleFonts.cinzel(
                       fontSize: 36,
                       color: const Color(0xFFFFD700),
                       fontWeight: FontWeight.bold,
                       shadows: [
                         const Shadow(blurRadius: 10, color: Colors.amber, offset: Offset(0, 0))
                       ]
                     ),
                   ),
                   const SizedBox(height: 5),
                   Text(
                     AppStrings.get('subtitle', _lang),
                     textAlign: TextAlign.center,
                     style: Theme.of(context).textTheme.bodyMedium,
                   ),

                   const SizedBox(height: 30),

                   // --- DASHBOARD GRID ---
                   _buildDashboardGrid(),

                   const SizedBox(height: 40),
                   
                   // Form Header
                   Text(
                     _lang == 'tr' ? "Hızlı Analiz Oluştur" : "Quick Chart",
                     style: GoogleFonts.cinzel(fontSize: 22, color: Colors.white70),
                     textAlign: TextAlign.center,
                   ),
                   const SizedBox(height: 10),
                   const Icon(Icons.keyboard_arrow_down, color: Colors.amber, size: 30),

                   const SizedBox(height: 20),

                   // Date Picker
                   _buildGlassContainer(
                     child: ListTile(
                       title: Text(AppStrings.get('date_label', _lang), style: const TextStyle(color: Colors.white70)),
                       subtitle: Text(
                         "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                         style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                       ),
                       trailing: const Icon(Icons.calendar_today, color: Color(0xFFE94560)),
                       onTap: _formLocked ? null : _pickDate,
                     ),
                   ),

                   const SizedBox(height: 16),

                   // Time Picker
                   _buildGlassContainer(
                     child: ListTile(
                       title: Text(AppStrings.get('time_label', _lang), style: const TextStyle(color: Colors.white70)),
                       subtitle: Text(
                         _selectedTime.format(context),
                         style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                       ),
                       trailing: Icon(Icons.access_time, color: _formLocked ? Colors.grey : const Color(0xFFE94560)),
                       onTap: _formLocked ? null : _pickTime,
                     ),
                   ),

                   const SizedBox(height: 16),
                   
                   // Location
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latController,
                            enabled: !_formLocked,
                            decoration: InputDecoration(
                              labelText: AppStrings.get('lat_label', _lang), 
                              suffixIcon: const Icon(Icons.location_on_outlined, color: Colors.white54)
                            ),
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _lonController,
                            enabled: !_formLocked,
                            decoration: InputDecoration(
                              labelText: AppStrings.get('lon_label', _lang), 
                              suffixIcon: const Icon(Icons.location_on_outlined, color: Colors.white54)
                            ),
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),

                   const SizedBox(height: 30),

                   _isLoading 
                   ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
                   : ElevatedButton(
                     style: ElevatedButton.styleFrom(
                       backgroundColor: const Color(0xFFE94560),
                       padding: const EdgeInsets.symmetric(vertical: 16),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                     ),
                     onPressed: _submit,
                     child: Text(AppStrings.get('btn_generate', _lang), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                   ),
                   const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final bool isTr = _lang == 'tr';
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF1a0b2e), Color(0xFF4a148c)],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white24)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 50),
                  const SizedBox(height: 10),
                  Text("DEEP COSMOS", style: GoogleFonts.cinzel(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  if(_isAuth)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(_username, style: const TextStyle(color: Color(0xFFE94560), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            _drawerItem(Icons.star, isTr ? "Natal Harita" : "Natal Chart", () => Navigator.pop(context)),
            _drawerItem(Icons.calendar_month, isTr ? "Günlük & Haftalık" : "Daily & Weekly", () {
                 Navigator.pop(context);
                 Navigator.push(context, MaterialPageRoute(builder: (_) => DailyScreen(lang: _lang)));
            }),
            _drawerItem(Icons.auto_awesome, isTr ? "Göksel Olaylar" : "Celestial Events", () {
                 Navigator.pop(context);
                 _checkDataAndNavigate(CelestialScreen(lang: _lang));
            }),
            _drawerItem(Icons.groups, isTr ? "Sosyal Analiz" : "Social Analysis", () {
                 Navigator.pop(context);
                 Navigator.push(context, MaterialPageRoute(builder: (_) => SocialScreen(lang: _lang)));
            }),
            const Divider(color: Colors.white24),
            _drawerItem(Icons.favorite, isTr ? "Aşk Uyumu (Synastry)" : "Love Match", () {
                 Navigator.pop(context);
                 Navigator.push(context, MaterialPageRoute(builder: (_) => SynastryScreen(lang: _lang)));
            }),
            _drawerItem(Icons.fingerprint, isTr ? "Drakonik Ruh" : "Draconic Soul", () {
                 Navigator.pop(context);
                 _checkDataAndNavigate(DraconicScreen(lang: _lang));
            }),
            _drawerItem(Icons.access_time_filled, isTr ? "Gezegen Saatleri" : "Planetary Hours", () {
                 Navigator.pop(context);
                 // Planetary hours requires lat/lon/date, which are in chartData
                 _checkDataAndNavigate(HoursScreen(lang: _lang));
            }),
            _drawerItem(Icons.business_center, isTr ? "Kariyer Yolu" : "Career Path", () {
                 Navigator.pop(context);
                 _checkDataAndNavigate(CareerScreen(lang: _lang));
            }),
            const Divider(color: Colors.white24),
            _drawerItem(Icons.grid_view, isTr ? "Kozmik Duvar" : "Cosmic Wall", () {
                 Navigator.pop(context);
                 Navigator.push(context, MaterialPageRoute(builder: (_) => SocialHubScreen(lang: _lang)));
            }, highlight: true),
            
            _drawerItem(Icons.article, isTr ? "Kozmik Yazılar" : "Cosmic Articles", () {
                 Navigator.pop(context);
                 Navigator.push(context, MaterialPageRoute(builder: (_) => BlogScreen(lang: _lang)));
            }),

            _drawerItem(Icons.style, isTr ? "Mistik Tarot" : "Mystic Tarot", () {
                 Navigator.pop(context);
                 Navigator.push(context, MaterialPageRoute(builder: (_) => TarotScreen(lang: _lang)));
            }, highlight: true),
            
            _drawerItem(Icons.headset_mic, isTr ? "İletişim & Randevu" : "Contact & Appointment", () {
                 Navigator.pop(context);
                 Navigator.push(context, MaterialPageRoute(builder: (_) => ContactScreen(lang: _lang)));
            }),
            
            if (_isAdmin)
              _drawerItem(Icons.admin_panel_settings, "Kozmik Panel", () {
                 Navigator.pop(context);
                 Navigator.push(context, MaterialPageRoute(builder: (_) => AdminScreen(lang: _lang)));
              }, highlight: true),

            const Divider(color: Colors.white24),
            SwitchListTile(
              title: const Text("Premium Modu (Test)", style: TextStyle(color: Colors.white70)),
              value: _simulatePremium,
              activeColor: Colors.amber,
              onChanged: (val) {
                setState(() => _simulatePremium = val);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(val ? "Premium Modu Aktif (Geçici)" : "Premium Modu Kapalı"),
                  duration: const Duration(seconds: 1),
                  backgroundColor: val ? Colors.amber : Colors.grey,
                ));
              },
            ),

            const Spacer(),
            if(_isAuth)
             ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: Text(isTr ? "Çıkış Yap" : "Logout", style: const TextStyle(color: Colors.redAccent)),
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap, {bool highlight = false}) {
    return ListTile(
      leading: Icon(icon, color: highlight ? const Color(0xFFFFD700) : Colors.white70),
      title: Text(title, style: TextStyle(color: highlight ? const Color(0xFFFFD700) : Colors.white, fontWeight: highlight ? FontWeight.bold : FontWeight.normal)),
      onTap: onTap,
    );
  }

  Widget _buildGlassContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: child,
    );
  }

  Widget _buildDashboardGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.1,
      children: [
        _buildDashboardCard(
          icon: Icons.public,
          title: _lang == 'tr' ? "Doğum Haritası" : "Natal Chart",
          color: Colors.blueAccent,
          onTap: () {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut
            );
          }
        ),
        _buildDashboardCard(
          icon: Icons.favorite,
          title: _lang == 'tr' ? "Aşk Uyumu" : "Love Match",
          color: const Color(0xFFE91E63),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => SynastryScreen(lang: _lang))),
        ),
        _buildDashboardCard(
          icon: Icons.style,
          title: _lang == 'tr' ? "Tarot Odası" : "Tarot Room",
          color: const Color(0xFF7C4DFF),
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => TarotScreen(lang: _lang))),
        ),
        _buildDashboardCard(
          icon: Icons.star,
          title: _lang == 'tr' ? "Günlük Burç" : "Daily Scope",
          color: const Color(0xFFFF9800),
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => DailyScreen(lang: _lang))),
        ),
        _buildDashboardCard(
          icon: Icons.fingerprint,
          title: _lang == 'tr' ? "Drakonik Ruh" : "Draconic Soul",
          color: Colors.deepPurple,
          onTap: () => _checkDataAndNavigate(DraconicScreen(lang: _lang))
        ),
        _buildDashboardCard(
          icon: Icons.hub, 
          title: "Kozmik Bağlantı",
          color: Colors.pink,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SocialHubScreen(lang: _lang)))
        ),
        _buildDashboardCard(
          icon: Icons.work,
          title: _lang == 'tr' ? "Kariyer Yolu" : "Career Path",
          color: Colors.teal,
          onTap: () => _checkDataAndNavigate(CareerScreen(lang: _lang))
        ),
        
        // Added Blog
        _buildDashboardCard(
          icon: Icons.article,
          title: _lang == 'tr' ? "Kozmik Yazılar" : "Cosmic Articles",
          color: Colors.amber,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BlogScreen(lang: _lang)))
        ),

        // Added Admin Shortcut
        if(_isAdmin)
        _buildDashboardCard(
          icon: Icons.admin_panel_settings,
          title: "Kozmik Panel",
          color: Colors.redAccent,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminScreen(lang: _lang)))
        ),
      ],
    );
  }

  Widget _buildDashboardCard({required IconData icon, required String title, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.15),
              Colors.transparent
            ]
          )
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
                boxShadow: [
                   BoxShadow(color: color.withOpacity(0.4), blurRadius: 15, spreadRadius: 0)
                ]
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14
              ),
            )
          ],
        ),
      ),
    );
  }
}
