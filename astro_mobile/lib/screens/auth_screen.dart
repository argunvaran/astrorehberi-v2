
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'input_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();
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
  
  // Location Data
  List<String> _countries = [];
  List<String> _provinces = [];
  List<String> _cities = []; // Just names or full objects? Web sends "lat,lon" in value.
  // The API returns dict of city_name -> {lat, lon}.
  Map<String, dynamic> _cityData = {}; 

  String? _selectedCountry;
  String? _selectedProvince;
  String? _selectedCity; // "City Name"

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    final list = await _api.getCountries();
    setState(() {
      _countries = list;
    });
  }

  Future<void> _loadProvinces(String country) async {
    setState(() { _provinces = []; _cities = []; _selectedProvince = null; _selectedCity = null; });
    final list = await _api.getProvinces(country);
    setState(() { _provinces = list; });
  }

  Future<void> _loadCities(String country, String province) async {
    setState(() { _cities = []; _cityData = {}; _selectedCity = null; });
    final data = await _api.getCities(country, province);
    // data is { "CityName": {lat:..., lon:...}, ... }
    setState(() {
      _cityData = data;
      _cities = data.keys.toList()..sort();
    });
  }

  Future<void> _doLogin() async {
    setState(() => _isLoading = true);
    try {
      await _api.login(_loginUserCtrl.text, _loginPassCtrl.text);
      if(mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const InputScreen()));
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _doRegister() async {
    if (_selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a city")));
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final cityInfo = _cityData[_selectedCity];
      final dateStr = "${_regDate.day}/${_regDate.month}/${_regDate.year}";
      final timeStr = "${_regTime.hour.toString().padLeft(2,'0')}:${_regTime.minute.toString().padLeft(2,'0')}";
      
      await _api.register({
        'username': _regUserCtrl.text,
        'email': _regEmailCtrl.text,
        'password': _regPassCtrl.text,
        'birth_date': dateStr,
        'birth_time': timeStr,
        'lat': cityInfo['lat'],
        'lon': cityInfo['lon'],
        'place': "$_selectedProvince, $_selectedCity", // Keeping web format "Prov, City" ? Web uses "Prov / City"
      });
      
      if(mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const InputScreen()));
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
                child: _buildGlassBtn(
                  "${_regTime.hour}:${_regTime.minute.toString().padLeft(2,'0')}", 
                  Icons.access_time,
                  () async {
                    final t = await showTimePicker(context: context, initialTime: _regTime);
                    if(t != null) setState(() => _regTime = t);
                  }
                )
              ),
            ],
          ),
          const SizedBox(height: 15),

          // Location Selectors
          LayoutBuilder(builder: (ctx, constraints) { return Column(children: [
            _buildDropdown("Ülke", _countries, _selectedCountry, (v) {
              setState(() => _selectedCountry = v);
              if(v != null) _loadProvinces(v);
            }),
            const SizedBox(height: 15),
            _buildDropdown("İl / Eyalet", _provinces, _selectedProvince, (v) {
              setState(() => _selectedProvince = v);
              if(v != null && _selectedCountry != null) _loadCities(_selectedCountry!, v);
            }),
            const SizedBox(height: 15),
            _buildDropdown("Şehir / İlçe", _cities, _selectedCity, (v) {
              setState(() => _selectedCity = v);
            }),
          ]); }),

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
  
  Widget _buildDropdown(String hint, List<String> items, String? value, ValueChanged<String?> onChanged) {
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
          dropdownColor: const Color(0xFF1E1E2E), // Dark bg for dropdown
          style: const TextStyle(color: Colors.white),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
