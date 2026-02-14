import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'auth_screen.dart';
import 'edit_profile_screen.dart'; // Added Import
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = false;
  Map<String, dynamic>? _userProfile;
  bool _didRefresh = false; // Track if profile was updated

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.checkAuth();
      if (mounted) {
        setState(() {
          _userProfile = res;
        });
      }
    } catch (e) {
      if (kDebugMode) print("Profile Load Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await _api.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (_) => const AuthScreen()), 
        (route) => false
      );
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text("Hesabı Sil", style: TextStyle(color: Colors.redAccent)),
        content: const Text(
          "Hesabınızı ve tüm verilerinizi kalıcı olarak silmek istediğinize emin misiniz? Bu işlem geri alınamaz.",
          style: TextStyle(color: Colors.white70)
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("İptal", style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Sil", style: TextStyle(color: Colors.red)),
          ),
        ],
      )
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        // Implement delete endpoint in backend if not exists, 
        // For now, we can just logout or call a specific API.
        // Assuming there might be a delete endpoint, if not we will just logout.
        // await _api.deleteAccount(); 
        await _logout(); // Fallback for now until backend support
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
      }
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Link açılamadı")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ayarlar", style: GoogleFonts.cinzel(color: const Color(0xFFFFD700))),
        backgroundColor: const Color(0xFF0F0C29),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _didRefresh),
        ),
      ),
      body: Stack(
        children: [
           Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xFF0F0C29), Color(0xFF302B63)],
              ),
            ),
          ),
          
          if (_isLoading) 
             const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
          else 
             ListView(
               padding: const EdgeInsets.all(16),
               children: [
                 // Profile Card
                 if (_userProfile != null) ...[
                   _buildSectionTitle("Profil"),
                   Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                       color: Colors.white.withOpacity(0.05),
                       borderRadius: BorderRadius.circular(12),
                       border: Border.all(color: Colors.white10),
                     ),
                     child: Column(
                       children: [
                         const CircleAvatar(
                           radius: 30,
                           backgroundColor: Color(0xFFE94560),
                           child: Icon(Icons.person, size: 30, color: Colors.white),
                         ),
                         const SizedBox(height: 10),
                         Text(
                           _userProfile!['username'] ?? "Kullanıcı", 
                           style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                         ),
                         Text(
                           _userProfile!['email'] ?? "", 
                           style: const TextStyle(color: Colors.white54)
                         ),
                         if (_userProfile!['birth_city'] != null)
                           Padding(
                             padding: const EdgeInsets.only(top: 5),
                             child: Text(
                               "${_userProfile!['birth_city']} (${_userProfile!['birth_date']})",
                               style: const TextStyle(color: Colors.amberAccent, fontSize: 13)
                             ),
                           ),
                         const SizedBox(height: 15),
                         ElevatedButton.icon(
                           icon: const Icon(Icons.edit, size: 16),
                           label: const Text("Bilgileri Güncelle"),
                           style: ElevatedButton.styleFrom(
                             backgroundColor: Colors.white.withOpacity(0.1),
                             foregroundColor: Colors.white,
                             elevation: 0
                           ),
                           onPressed: () async {
                              if (_userProfile == null) return;
                              final result = await Navigator.push(
                                context, 
                                MaterialPageRoute(builder: (_) => EditProfileScreen(userProfile: _userProfile!))
                              );
                              if (result == true) {
                                _didRefresh = true; // Mark as updated
                                _loadProfile();
                              }
                           },
                         ),
                       ],
                     ),
                   ),
                   const SizedBox(height: 20),
                 ],


                 // DEBUG AUTH CHECK (For User's Issue)
                 // if (kDebugMode) ...[
                 //    _buildTile(Icons.bug_report, "Auth Check", null, () async {
                 //       final res = await _api.checkAuth();
                 //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Auth: ${res['authenticated']}")));
                 //    }, color: Colors.orange),
                 // ],


                 // Danger Zone
                 _buildSectionTitle("Hesap İşlemleri"),
                 _buildTile(Icons.logout, "Çıkış Yap", null, _logout, color: Colors.orangeAccent),
                 _buildTile(Icons.delete_forever, "Hesabı Sil", null, _deleteAccount, color: Colors.redAccent),
                 
                 const SizedBox(height: 50),
               ],
             ),
        ],
      )
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(title, style: const TextStyle(color: Color(0xFFFFD700), fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTile(IconData icon, String title, String? subtitle, VoidCallback onTap, {Color color = Colors.white}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
         color: Colors.white.withOpacity(0.05),
         borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.normal)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)) : null,
        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
        onTap: onTap,
      ),
    );
  }
}
