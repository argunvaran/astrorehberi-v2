
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'auth_screen.dart'; // We will create this next
import 'input_screen.dart'; // The main app screen

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _horoscopes = [];
  bool _isLoading = true;
  String _expandedSign = "";

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final res = await _api.checkAuth();
    if (res['authenticated'] == true) {
      // Navigate to Main App if already logged in
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const InputScreen()),
        );
      }
    } else {
      _loadHoroscopes();
    }
  }

  Future<void> _loadHoroscopes() async {
    try {
      final res = await _api.getDailyHoroscopes('tr'); // Default TR
      setState(() {
        _horoscopes = res['horoscopes'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const _Header(),
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: () {
                           Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                        },
                        icon: const Icon(Icons.rocket_launch),
                        label: const Text("Giriş Yap / Kayıt Ol"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE94560),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        "✨ Günlük Burç Yorumları",
                        style: TextStyle(color: Color(0xFFE94560), fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        "Burcunuza tıklayarak bugünün mesajını okuyun.",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 20),
                      _buildGrid(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 Columns for mobile
        childAspectRatio: 0.85,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemCount: _horoscopes.length,
      itemBuilder: (context, index) {
        final h = _horoscopes[index];
        final isExpanded = _expandedSign == h['sign'];
        
        // If expanded, we might want to show a full dialog or modal bottom sheet instead of in-place expansion for grid
        // In-place expansion in grid is tricky. 
        // Let's use a Dialog for details on mobile! It's cleaner.
        
        return GestureDetector(
          onTap: () => _showDetailDialog(h),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  h['mood'], 
                  style: const TextStyle(fontSize: 40),
                ),
                const SizedBox(height: 10),
                Text(
                  h['sign'],
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  h['date'],
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDetailDialog(Map<String, dynamic> horo) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(horo['sign'], style: const TextStyle(color: Colors.white)),
            Text(horo['mood'], style: const TextStyle(fontSize: 24)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              horo['text'],
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE94560),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text("Daha Fazlası İçin Giriş Yap"),
            )
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "DEEP COSMOS",
          style: GoogleFonts.cinzel(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFFD700),
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          "Günlük Burç Yorumları & Kozmik Rehberlik",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
  }
}
