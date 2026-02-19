import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
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
import 'blog_screen.dart'; 
import 'library_screen.dart'; 
import 'settings_screen.dart'; 
import 'rectification_screen.dart';
import 'mega_analysis_screen.dart';
import 'relationships_screen.dart';
import 'cosmic_journey_screen.dart';
import 'admin_screen.dart';

import '../theme/strings.dart';

class InputScreen extends StatefulWidget {
  final Map<String, dynamic>? initialAuthData;
  const InputScreen({super.key, this.initialAuthData});

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


  bool _isAuth = false;
  bool _isAdmin = false;
  bool _formLocked = false;
  String _username = "Guest";
  
  // Access Control
  bool _isPremium = false;
  bool _globalFreeMode = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialAuthData != null) {
      _applyAuthData(widget.initialAuthData!);
    }
    _checkAuth(); // Still check to get full profile if missing
  }

  void _applyAuthData(Map<String, dynamic> res) {
    if (res['authenticated'] == true || res['success'] == true) {
      setState(() {
        _isAuth = true;
        _isAdmin = (res['is_superuser'] == true);
        _username = res['username'] ?? "User";
        
        final level = (res['membership_level'] ?? 'free').toString().toLowerCase();
        _isPremium = level == 'premium' || _isAdmin || (res['is_global_free'] == true);
        
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

  Future<void> _checkAuth() async {
    final res = await _apiService.checkAuth();
    _applyAuthData(res);
  }

  void _checkPremiumAccess(VoidCallback onGranted) {
    // If Global Free Mode is On, allow everyone (even guests if that's the policy, but usually auth required)
    // Assuming Global Free overrides everything for testing.
    
    if (_isPremium || _globalFreeMode) {
      onGranted();
    } else {
      // Show Lock Dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          icon: const Icon(Icons.lock, color: Colors.amber, size: 40),
          title: Text(_lang == 'tr' ? "Premium İçerik" : "Premium Content", style: const TextStyle(color: Colors.white)),
          content: Text(
            _lang == 'tr' 
            ? "Bu alana erişmek için Premium üye olmalısınız." 
            : "You must be a Premium member to access this feature.",
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(_lang == 'tr' ? "Tamam" : "OK", style: const TextStyle(color: Colors.white)),
            )
          ],
        )
      );
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
      );
      
      DataManager.instance.setChartData(chartData);
      
      // Auto-save calculated signs to profile if authenticated
      if (_isAuth && chartData.meta != null) {
          final sun = chartData.meta!.sunSign;
          final rising = chartData.meta!.risingSign;
          if (sun.isNotEmpty || (rising != null && rising.isNotEmpty)) {
             // Fire and forget update
             _apiService.updateProfile(sun_sign: sun, rising_sign: rising).then((_) {
                if (kDebugMode) print("Profile signs updated: $sun / $rising");
             });
          }
      }

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
                   if (_formLocked) ...[
                      // --- EXISTING PROFILE VIEW ---
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.greenAccent.withOpacity(0.3))
                        ),
                        child: Column(
                          children: [
                             const Icon(Icons.check_circle, color: Colors.greenAccent, size: 40),
                             const SizedBox(height: 10),
                             Text(
                               _lang == 'tr' ? "Natal Haritanız Hazır" : "Your Natal Chart is Ready",
                               style: GoogleFonts.cinzel(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                             ),
                             const SizedBox(height: 10),
                             Text(
                               "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} - ${_selectedTime.format(context)}",
                               style: const TextStyle(color: Colors.white70, fontSize: 16),
                             ),
                             const SizedBox(height: 20),
                             _isLoading 
                             ? const CircularProgressIndicator(color: Colors.greenAccent)
                             : SizedBox(
                               width: double.infinity,
                               height: 50,
                               child: ElevatedButton.icon(
                                 icon: const Icon(Icons.visibility),
                                 label: Text(_lang == 'tr' ? "HARİTAMI GÖRÜNTÜLE" : "VIEW MY CHART"),
                                 style: ElevatedButton.styleFrom(
                                   backgroundColor: Colors.green,
                                   foregroundColor: Colors.white,
                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                 ),
                                 onPressed: _submit, // Uses loaded data
                               ),
                             ),
                             const SizedBox(height: 10),
                             TextButton(
                               onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                               child: Text(
                                 _lang == 'tr' ? "Bilgilerimi Düzenle" : "Edit My Info",
                                 style: const TextStyle(color: Colors.white54, decoration: TextDecoration.underline),
                               ),
                             )
                          ],
                        ),
                      )
                   ] else ...[
                       // --- NEW ANALYSIS FORM ---
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
                           onTap: _pickDate,
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
                           trailing: const Icon(Icons.access_time, color: Color(0xFFE94560)),
                           onTap: _pickTime,
                         ),
                       ),
    
                       const SizedBox(height: 16),
                       
                       // Location
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _latController,
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
                   ],
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

<<<<<<< HEAD
            _drawerItem(Icons.style, isTr ? "Mistik Tarot" : "Mystic Tarot", () {
                 Navigator.pop(context);
                 Navigator.push(context, MaterialPageRoute(builder: (_) => TarotScreen(lang: _lang)));
            }, highlight: true),
            
             _drawerItem(Icons.headset_mic, isTr ? "İletişim & Randevu" : "Contact & Appointment", () {
=======
            // ADMIN DASHBOARD (Priority)
            if (_isAdmin)
              _drawerItem(
                Icons.admin_panel_settings, 
                "KOZMİK PANEL (ADMİN)", 
                () {
                   Navigator.pop(context);
                   Navigator.push(context, MaterialPageRoute(builder: (_) => AdminScreen(lang: _lang)));
                }, 
                highlight: true
              ),

            // 1. ANALİZLER KATEGORİSİ
            _buildExpansionCategory(
              icon: Icons.analytics,
              title: isTr ? "Temel Analizler" : "Core Analysis",
              initiallyExpanded: true,
              children: [
                _drawerItem(
                  Icons.auto_awesome_mosaic, 
                  isTr ? "Yıldızların Rehberliği" : "Guidance of Stars", 
                  () {
                     Navigator.pop(context);
                     _checkDataAndNavigate(MegaAnalysisScreen(lang: _lang));
                  },
                  highlight: true
                ),
                _drawerItem(Icons.star, isTr ? "Natal Harita" : "Natal Chart", () {
                   Navigator.pop(context);
                   _scrollToForm();
                }),
                _drawerItem(Icons.favorite, isTr ? "İlişkiler & Uyum" : "Relationships & Harmony", () {
                     Navigator.pop(context);
                     Navigator.push(context, MaterialPageRoute(builder: (_) => RelationshipsScreen(lang: _lang)));
                }),
              ]
            ),

            // 2. KOZMİK ARAÇLAR KATEGORİSİ
            _buildExpansionCategory(
              icon: Icons.psychology, 
              title: isTr ? "Kozmik Araçlar" : "Cosmic Tools",
              initiallyExpanded: true,
              children: [
                _drawerItem(Icons.rocket_launch, isTr ? "Kozmik Yolculuk" : "Cosmic Journey", () {
                     Navigator.pop(context);
                     Navigator.push(context, MaterialPageRoute(builder: (_) => CosmicJourneyScreen(lang: _lang)));
                }, highlight: true),
                _drawerItem(Icons.fingerprint, isTr ? "Ruhsal Kodlar" : "Soul Codes", () {
                     Navigator.pop(context);
                     _checkPremiumAccess(() {
                         _checkDataAndNavigate(DraconicScreen(lang: _lang));
                     });
                }),
                _drawerItem(Icons.style, isTr ? "Mistik Tarot" : "Mystic Tarot", () {
                     Navigator.pop(context);
                     Navigator.push(context, MaterialPageRoute(builder: (_) => TarotScreen(lang: _lang)));
                }, highlight: true),
                _drawerItem(Icons.timelapse, isTr ? "Rektifikasyon" : "Rectification", () {
                     Navigator.pop(context);
                     Navigator.push(context, MaterialPageRoute(builder: (_) => RectificationScreen(lang: _lang)));
                }),
              ]
            ),

            // 3. KÜTÜPHANE VE TOPLULUK
            _buildExpansionCategory(
              icon: Icons.local_library_outlined,
              title: isTr ? "Kozmik Kütüphane" : "Cosmic Library",
              initiallyExpanded: false,
              children: [
                _drawerItem(Icons.grid_view, isTr ? "Kozmik Duvar" : "Cosmic Wall", () {
                     Navigator.pop(context);
                     Navigator.push(context, MaterialPageRoute(builder: (_) => SocialHubScreen(lang: _lang)));
                }),
                _drawerItem(Icons.local_library, isTr ? "Astro Kütüphane" : "Astro Library", () {
                     Navigator.pop(context);
                     Navigator.push(context, MaterialPageRoute(builder: (_) => LibraryScreen(lang: _lang)));
                }),
              ]
            ),

            const Divider(color: Colors.white24),

            // SABİT MENÜLER (GENEL)
            _drawerItem(Icons.headset_mic, isTr ? "İletişim & Randevu" : "Contact & Appointment", () {
>>>>>>> a3db2cd (Social interactions, admin notifications, and UI improvements)
                 Navigator.pop(context);
                 Navigator.push(context, MaterialPageRoute(builder: (_) => ContactScreen(lang: _lang)));
            }),

             _drawerItem(Icons.timelapse, isTr ? "Rektifikasyon (Doğum Saati)" : "Rectification (Birth Time)", () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => RectificationScreen(lang: _lang)));
                  if (result == true) {
                    _checkAuth(); // Refresh profile if time was saved
                  }
             }, highlight: true),
            
            _drawerItem(Icons.settings, isTr ? "Kozmik Ayarlar" : "Cosmic Settings", () async {
                 Navigator.pop(context);
                 final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                 if (result == true) {
                   _checkAuth(); // Refresh profile after return
                 }
            }),
            
             if (_isAdmin)
               _drawerItem(Icons.admin_panel_settings, isTr ? "Yönetici Paneli" : "Admin Panel", () {
                   Navigator.pop(context);
                   Navigator.push(context, MaterialPageRoute(builder: (_) => AdminScreen(lang: _lang)));
               }, highlight: true),

            if (_isAuth)
               _drawerItem(Icons.logout, isTr ? "Oturumu Kapat" : "Logout", () {
                  Navigator.pop(context);
                  _logout();
               }, highlight: false),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildExpansionCategory({required IconData icon, required String title, required List<Widget> children, bool initiallyExpanded = false}) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: Icon(icon, color: Colors.white70),
        title: Text(
          title, 
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
        ),
        iconColor: const Color(0xFFFFD700),
        collapsedIconColor: Colors.white54,
        childrenPadding: const EdgeInsets.only(left: 20),
        children: children,
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
          icon: Icons.rocket_launch,
          title: _lang == 'tr' ? "Kozmik Yolculuk" : "Cosmic Journey",
          color: Colors.cyanAccent,
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => CosmicJourneyScreen(lang: _lang))),
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
          title: _lang == 'tr' ? "Ruhsal Kodlar" : "Soul Codes",
          color: Colors.deepPurple,
          onTap: () => _checkPremiumAccess(() {
             _checkDataAndNavigate(DraconicScreen(lang: _lang));
          })
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
          onTap: () => _checkPremiumAccess(() {
              _checkDataAndNavigate(CareerScreen(lang: _lang));
          })
        ),
        
        _buildDashboardCard(
          icon: Icons.local_library,
          title: _lang == 'tr' ? "Kozmik Kütüphane" : "Cosmic Library",
          color: Colors.indigo,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LibraryScreen(lang: _lang)))
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
