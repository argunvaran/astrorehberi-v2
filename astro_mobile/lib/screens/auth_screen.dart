import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'input_screen.dart';
import 'rectification_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _api = ApiService();
  bool _isLoading = false;

  // Login Controllers
  final _loginUserCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();

  // Register Controllers
  final _regUserCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  
  DateTime _regDate = DateTime(1990, 1, 1);
  TimeOfDay _regTime = const TimeOfDay(hour: 12, minute: 0);
  bool _isBirthTimeUnknown = false;
  
  // Location Data (All Maps now)
  List<Map<String, dynamic>> _countries = [];
  List<Map<String, dynamic>> _provinces = [];
  List<Map<String, dynamic>> _cities = []; 

  String? _selectedCountryCode; 
  String? _selectedProvinceCode; 
  String? _selectedCityName; 
  Map<String, dynamic>? _selectedCityData; 

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCountries();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _loginUserCtrl.dispose();
    _loginPassCtrl.dispose();
    _regUserCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    final list = await _api.getCountries();
    if(mounted) setState(() => _countries = list);
  }

  Future<void> _loadProvinces(String countryCode) async {
    print("DEBUG: Loading provinces for: $countryCode");
    setState(() { _provinces = []; _cities = []; _selectedProvinceCode = null; _selectedCityName = null; _selectedCityData = null; });
    
    // API returns [{code: "34", name: "İstanbul"}, ...]
    final list = await _api.getProvinces(countryCode);
    print("DEBUG: Loaded ${list.length} provinces.");

    if(mounted) {
      setState(() => _provinces = list);
      
      // If NO provinces found (small country like AI), load ALL cities for that country directly
      if (list.isEmpty) {
        print("DEBUG: No provinces found, loading all cities for $countryCode");
        _loadCities(countryCode, ''); // Empty province code for direct city fetch
      }
    }
  }

  Future<void> _loadCities(String countryCode, String provinceCode) async {
    print("DEBUG: Loading cities for Country: $countryCode, ProvinceCode: '$provinceCode'");
    setState(() { _cities = []; _selectedCityName = null; _selectedCityData = null; });

    try {
      // Sending Code (e.g. "34") or empty string
      final list = await _api.getCities(countryCode, provinceCode);
      print("DEBUG: Loaded ${list.length} cities.");
      
      if(mounted) setState(() => _cities = list);
    } catch (e) {
      print("DEBUG: Cities Error: $e");
    }
  }

  Future<void> _doLogin() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.login(_loginUserCtrl.text, _loginPassCtrl.text);
      if(mounted) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => InputScreen(initialAuthData: res))
        );
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _doRegister() async {
    if (_selectedCityData == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen bir şehir seçin")));
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final cityInfo = _selectedCityData!;
      final dateStr = "${_regDate.year}-${_regDate.month.toString().padLeft(2, '0')}-${_regDate.day.toString().padLeft(2, '0')}";
      final timeStr = _isBirthTimeUnknown 
          ? "12:00" 
          : "${_regTime.hour.toString().padLeft(2,'0')}:${_regTime.minute.toString().padLeft(2,'0')}";
      
      // Find province name for display if needed
      String provName = _selectedProvinceCode ?? "";
      if (_provinces.isNotEmpty && _selectedProvinceCode != null) {
         final provObj = _provinces.firstWhere((e) => e['code'] == _selectedProvinceCode, orElse: () => {});
         if (provObj.isNotEmpty) provName = provObj['name'];
      }

      await _api.register({
        'username': _regUserCtrl.text,
        'email': _regEmailCtrl.text,
        'password': _regPassCtrl.text,
        'date': isoDate, // Changed from birth_date to date
        'time': timeStr, // Changed from birth_time to time
        'lat': cityInfo['lat'],
        'lon': cityInfo['lon'],
        'place': "$provName, ${cityInfo['name']}",
      });
      
      if(mounted) {
        if (_isBirthTimeUnknown) {
          // Redirect to Rectification
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (_) => const RectificationScreen(lang: 'tr')) // Defaulting TR for now
          );
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const InputScreen()));
        }
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Kozmik Giriş", style: GoogleFonts.cinzel(color: const Color(0xFFFFD700))),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE94560),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: "Giriş Yap"),
            Tab(text: "Kayıt Ol"),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63)],
          ),
        ),
        child: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
        : TabBarView(
          controller: _tabController,
          children: [
            _buildLoginTab(),
            _buildRegisterTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          _buildInput(_loginUserCtrl, "Kullanıcı Adı", Icons.person),
          const SizedBox(height: 20),
          _buildInput(_loginPassCtrl, "Şifre", Icons.lock, obscure: true),
          const SizedBox(height: 40),
          _buildBtn("GİRİŞ YAP", _doLogin),
        ],
      ),
    );
  }

  Widget _buildRegisterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          _buildInput(_regUserCtrl, "Kullanıcı Adı", Icons.person),
          const SizedBox(height: 15),
          _buildInput(_regEmailCtrl, "E-Posta", Icons.email),
          const SizedBox(height: 15),
          _buildInput(_regPassCtrl, "Şifre", Icons.lock, obscure: true),
          const SizedBox(height: 25),
          
          // Date & Time
          Row(
            children: [
              Expanded(
                child: _buildGlassBtn(
                  "${_regDate.day}/${_regDate.month}/${_regDate.year}", 
                  Icons.calendar_today,
                  () async {
                    final d = await showDatePicker(context: context, initialDate: _regDate, firstDate: DateTime(1900), lastDate: DateTime.now());
                    if(d != null) setState(() => _regDate = d);
                  }
                )
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Opacity(
                  opacity: _isBirthTimeUnknown ? 0.5 : 1.0,
                  child: _buildGlassBtn(
                    _isBirthTimeUnknown ? "--:--" : "${_regTime.hour}:${_regTime.minute.toString().padLeft(2,'0')}", 
                    Icons.access_time,
                    _isBirthTimeUnknown ? () {} : () async {
                      final t = await showTimePicker(context: context, initialTime: _regTime);
                      if(t != null) setState(() => _regTime = t);
                    }
                  ),
                )
              ),
            ],
          ),
          
          // Unknown Time Checkbox
          Theme(
            data: ThemeData(unselectedWidgetColor: Colors.white54),
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Doğum saatimi bilmiyorum", style: TextStyle(color: Colors.white70, fontSize: 14)),
              value: _isBirthTimeUnknown, 
              activeColor: const Color(0xFFE94560),
              checkColor: Colors.white,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (val) => setState(() => _isBirthTimeUnknown = val ?? false)
            ),
          ),
          const SizedBox(height: 15),

          // Location Selectors (All using Map Dropdown)
          // 1. Country
          _buildMapDropdown("Ülke", _countries, _selectedCountryCode, 'code', 'name', (val) {
             setState(() => _selectedCountryCode = val);
             if(val != null) _loadProvinces(val);
          }),

          const SizedBox(height: 15),
          
          // 2. Province (Only show if provinces exist, or if country is selected)
          if (_selectedCountryCode != null && _provinces.isNotEmpty) ...[
            _buildMapDropdown("İl / Eyalet", _provinces, _selectedProvinceCode, 'code', 'name', (val) {
               setState(() => _selectedProvinceCode = val);
               if(val != null && _selectedCountryCode != null) _loadCities(_selectedCountryCode!, val);
            }),
            const SizedBox(height: 15),
          ],
          
          // 3. City
          _buildMapDropdown("Şehir / İlçe", _cities, _selectedCityName, 'name', 'name', (val) {
             final cityObj = _cities.firstWhere((e) => e['name'] == val, orElse: () => {});
             setState(() {
                _selectedCityName = val;
                _selectedCityData = cityObj;
             });
          }),

          const SizedBox(height: 40),
          _buildBtn("KAYIT OL & GİRİŞ", _doRegister),
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: const Color(0xFFE94560)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildBtn(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE94560),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildGlassBtn(String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.white70),
            const SizedBox(width: 8),
            Text(text, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
  
  // Generic Map Dropdown
  Widget _buildMapDropdown(String hint, List<Map<String, dynamic>> items, String? value, String valueKey, String labelKey, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
         color: Colors.white.withOpacity(0.05),
         borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(color: Colors.white54)),
          isExpanded: true,
          dropdownColor: const Color(0xFF1E1E2E),
          style: const TextStyle(color: Colors.white),
          items: items.map((e) {
             return DropdownMenuItem<String>(
               value: e[valueKey].toString(), 
               child: Text(e[labelKey].toString()), 
             );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
