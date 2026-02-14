import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'auth_screen.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  const EditProfileScreen({Key? key, required this.userProfile}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = false;

  final TextEditingController _bioCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  
  late DateTime _birthDate;
  late TimeOfDay _birthTime;

  // Location Data
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
    _initData();
  }

  void _initData() {
    _bioCtrl.text = widget.userProfile['bio'] ?? "";
    _nameCtrl.text = widget.userProfile['username'] ?? ""; // Username might be immutable, but here editable? Usually not. Let's assume Name field or just Update logic.

    // Date Parse
    try {
        final dParts = (widget.userProfile['birth_date'] ?? "1990-01-01").split('-');
        _birthDate = DateTime(int.parse(dParts[0]), int.parse(dParts[1]), int.parse(dParts[2]));
    } catch (e) {
        _birthDate = DateTime(1990, 1, 1);
    }

    // Time Parse
    try {
        final tParts = (widget.userProfile['birth_time'] ?? "12:00").split(':');
        _birthTime = TimeOfDay(hour: int.parse(tParts[0]), minute: int.parse(tParts[1]));
    } catch(e) {
        _birthTime = const TimeOfDay(hour: 12, minute: 0);
    }

    _loadCountries();
  }

  Future<void> _loadCountries() async {
    final list = await _api.getCountries();
    if (mounted) setState(() => _countries = list);
  }

  Future<void> _loadProvinces(String countryCode) async {
    setState(() { _provinces = []; _cities = []; _selectedProvinceCode = null; _selectedCityName = null; _selectedCityData = null; });
    final list = await _api.getProvinces(countryCode);
    if (mounted) {
      setState(() => _provinces = list);
      if (list.isEmpty) _loadCities(countryCode, '');
    }
  }

  Future<void> _loadCities(String countryCode, String provinceCode) async {
    setState(() { _cities = []; _selectedCityName = null; _selectedCityData = null; });
    try {
      final list = await _api.getCities(countryCode, provinceCode);
      if (mounted) setState(() => _cities = list);
    } catch (e) {
      print("Cities Error: $e");
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      // Prepare Data
      final dateStr = DateFormat('yyyy-MM-dd').format(_birthDate);
      final timeStr = "${_birthTime.hour.toString().padLeft(2,'0')}:${_birthTime.minute.toString().padLeft(2,'0')}";
      
      String? cityStr = _selectedCityName;
      // If user didn't change location, keep original? Or require re-selection?
      // For simplicity, if _selectedCityData is null, we assume NO CHANGE in location unless user picked something.
      // BUT if user wants to update location, they must select properly.
      
      double? lat;
      double? lon;
      
      if (_selectedCityData != null) {
         lat = _selectedCityData!['lat'];
         lon = _selectedCityData!['lon'];
         
         // Construct full place string if needed, backend usually takes city name or just lat/lon
         // The backend updateProfile accepts 'birth_city', 'lat', 'lon'.
         cityStr = _selectedCityData!['name'];
      }

      final res = await _api.updateProfile(
        // username: _nameCtrl.text, // Optional: Disable username change if not allowed
        birth_date: dateStr,
        birth_time: timeStr,
        birth_city: cityStr, // Only send if selected
        lat: lat,
        lon: lon,
        bio: _bioCtrl.text
      );

      if (res.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['error'])));
        // If auth error, redirect
        if (res['error'].toString().contains("Giriş") || res['error'].toString().contains("Auth")) {
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AuthScreen()), (r) => false);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil başarıyla güncellendi!")));
        Navigator.pop(context, true); // Return success
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        title: Text("Profili Düzenle", style: GoogleFonts.cinzel(color: const Color(0xFFFFD700))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
         decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFF0F0C29), Color(0xFF24243E)],
            ),
          ),
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("Kişisel Bilgiler"),
                  // Username (Read Only or Editable?) - Let's keep it read-only for now to avoid complexity
                  _buildReadOnlyField("Kullanıcı Adı", widget.userProfile['username']),
                  const SizedBox(height: 15),
                  
                  _buildInput(_bioCtrl, "Biyografi / Notlar", Icons.edit, maxLines: 3),
                  const SizedBox(height: 25),

                  _buildSectionHeader("Doğum Bilgileri"),
                  Row(
                    children: [
                      Expanded(
                        child: _buildGlassBtn(
                          DateFormat('dd.MM.yyyy').format(_birthDate),
                          Icons.calendar_today,
                          () async {
                             final d = await showDatePicker(
                               context: context, 
                               initialDate: _birthDate, 
                               firstDate: DateTime(1900), 
                               lastDate: DateTime.now(),
                               builder: (context, child) => Theme(data: ThemeData.dark(), child: child!)
                             );
                             if(d != null) setState(() => _birthDate = d);
                          }
                        )
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildGlassBtn(
                          "${_birthTime.hour}:${_birthTime.minute.toString().padLeft(2,'0')}",
                          Icons.access_time,
                          () async {
                             final t = await showTimePicker(
                               context: context, 
                               initialTime: _birthTime,
                               builder: (context, child) => Theme(data: ThemeData.dark(), child: child!)
                             );
                             if(t != null) setState(() => _birthTime = t);
                          }
                        )
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),
                  _buildSectionHeader("Konum Güncelleme"),
                  const Text("Konumunuzu değiştirmek için aşağıdan seçim yapın. Değiştirmek istemiyorsanız boş bırakın.", style: TextStyle(color: Colors.white38, fontSize: 12)),
                  const SizedBox(height: 10),

                  _buildMapDropdown("Ülke Seçin", _countries, _selectedCountryCode, 'code', 'name', (val) {
                      setState(() => _selectedCountryCode = val);
                      if(val != null) _loadProvinces(val);
                  }),
                  const SizedBox(height: 15),

                  if (_selectedCountryCode != null && _provinces.isNotEmpty) ...[
                    _buildMapDropdown("İl / Eyalet Seçin", _provinces, _selectedProvinceCode, 'code', 'name', (val) {
                       setState(() => _selectedProvinceCode = val);
                       if(val != null) _loadCities(_selectedCountryCode!, val);
                    }),
                    const SizedBox(height: 15),
                  ],

                  if (_selectedCountryCode != null)
                  _buildMapDropdown("Şehir / İlçe Seçin", _cities, _selectedCityName, 'name', 'name', (val) {
                      final cityObj = _cities.firstWhere((e) => e['name'] == val, orElse: () => {});
                      setState(() {
                         _selectedCityName = val;
                         _selectedCityData = cityObj;
                      });
                  }), 

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE94560),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 5
                      ),
                      child: const Text("KAYDET & GÜNCELLE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: const TextStyle(color: Color(0xFFFFD700), fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildReadOnlyField(String label, String? value) {
     return Container(
       width: double.infinity,
       padding: const EdgeInsets.all(16),
       decoration: BoxDecoration(
         color: Colors.white.withOpacity(0.05),
         borderRadius: BorderRadius.circular(12),
         border: Border.all(color: Colors.white10)
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
           const SizedBox(height: 5),
           Text(value ?? "-", style: const TextStyle(color: Colors.white, fontSize: 16)),
         ],
       ),
     );
  }

  Widget _buildInput(TextEditingController ctrl, String label, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
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

  Widget _buildGlassBtn(String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10)
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
  
  Widget _buildMapDropdown(String hint, List<Map<String, dynamic>> items, String? value, String valueKey, String labelKey, ValueChanged<String?> onChanged) {
    return Container(
       padding: const EdgeInsets.symmetric(horizontal: 16),
       decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10)
       ),
       child: DropdownButtonHideUnderline(
         child: DropdownButton<String>(
           value: value,
           hint: Text(hint, style: const TextStyle(color: Colors.white54)),
           isExpanded: true,
           dropdownColor: const Color(0xFF1E1E2E), // Dark theme
           style: const TextStyle(color: Colors.white),
           items: items.map((e) {
              return DropdownMenuItem<String>(
                value: e[valueKey].toString(), 
                child: Text(e[labelKey].toString(), maxLines: 1, overflow: TextOverflow.ellipsis), 
              );
           }).toList(),
           onChanged: onChanged,
         ),
       ),
    );
  }
}
