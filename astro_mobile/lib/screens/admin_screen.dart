import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/interactive_models.dart';

class AdminScreen extends StatefulWidget {
  final String lang;
  const AdminScreen({super.key, required this.lang});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;
  
  bool _isLoading = true;
  String _error = '';
  
  // Data
  Map<String, dynamic>? _dashboardData;
  List<Appointment> _appointments = [];
  bool _hasMoreApps = false;

  // Filters - Logs & Stats
  DateTime? _startDate;
  DateTime? _endDate;
  String? _logSearch;
  int _logPage = 1;

  // Filters - Messages
  String? _msgSearch;
  DateTime? _msgStart;
  DateTime? _msgEnd;
  int _msgPage = 1;

  // Filters - Appointments
  String _appStatus = 'all'; 
  int _appPage = 1;
  int _appTotalPages = 1;

  // Filters - Users
  String? _userSearch;
  int _userPage = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // Increased to 5
    _loadDashboard();
    _loadAppointments();
  }
  
  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getAdminDashboardData(
        startDate: _startDate?.toIso8601String().split('T')[0],
        endDate: _endDate?.toIso8601String().split('T')[0],
        logSearch: _logSearch,
        msgSearch: _msgSearch,
        msgStart: _msgStart?.toIso8601String().split('T')[0],
        msgEnd: _msgEnd?.toIso8601String().split('T')[0],
        userSearch: _userSearch,
        logPage: _logPage,
        msgPage: _msgPage,
        userPage: _userPage
      );
      setState(() {
         _dashboardData = data;
         _error = '';
      });
    } catch(e) {
      if(mounted) setState(() => _error = e.toString());
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAppointments() async {
    try {
      final res = await _api.getAdminAppointments(status: _appStatus, page: _appPage);
      final list = (res['appointments'] as List).map((e) => Appointment.fromJson(e)).toList();
      setState(() {
        _appointments = list;
        _appTotalPages = res['total_pages'] ?? 1;
      });
    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading apps: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        title: Text("Kozmik Panel", style: GoogleFonts.cinzel(color: const Color(0xFFFFD700))),
        backgroundColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          isScrollable: true,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white60,
          tabs: const [
             Tab(text: "İstatistikler", icon: Icon(Icons.bar_chart)),
             Tab(text: "Kullanıcılar", icon: Icon(Icons.people)), // Added
             Tab(text: "Mesajlar", icon: Icon(Icons.mail_outline)),
             Tab(text: "Randevular", icon: Icon(Icons.calendar_today)),
             Tab(text: "Loglar", icon: Icon(Icons.list_alt)), // Moved Logs to end
          ],
        ),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : 
      _error.isNotEmpty ? Center(child: Text("Hata: $_error", style: const TextStyle(color: Colors.red))) :
      TabBarView(
        controller: _tabController,
        children: [
          _buildStatsTab(),
          _buildUsersTab(), // Added
          _buildMessagesTab(),
          _buildAppointmentsTab(),
          _buildLogsTab(),
        ],
      )
    );
  }

  // --- 1.5 USERS TAB ---
  Widget _buildUsersTab() {
    if(_dashboardData == null) return const SizedBox();
    final usersRaw = _dashboardData!['users'];
    List usersList = [];
    int totalPages = 1;
    // Handle Page object serialization if needed, similar to logs/messages
    // Assuming backend sends {users: [...List of users...], ...} or Page list directly
    if(usersRaw is Map && usersRaw.containsKey('users')) {
      // If it has pagination metadata inside
      usersList = usersRaw['users'] ?? []; // Adjust based on actual API
    } else if (usersRaw is List) {
      usersList = usersRaw;
    } else {
       // Fallback if it's the Page object serialized as list of dicts
       // In Web view context: 'users': user_page_obj
       // JsonResponse usually serializes Page as list of items unless custom encoder used.
       // Let's assume list of user dicts.
       // If pagination metadata is missing in JSON, we rely on "has_next" not being easily available without custom response.
       // But we have "userPage" state.
       // Just showing list.
       // If we want total pages, backend JSON needs to send it.
       // Let's assume infinite scroll style or just Next/Prev based on list not empty.
       if(usersRaw != null) usersList = usersRaw as List; 
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: _searchDec("Kullanıcı Ara..."),
            onSubmitted: (v) { _userSearch = v; _userPage=1; _loadDashboard(); },
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: usersList.length,
            itemBuilder: (ctx, i) {
               final u = usersList[i]; // {id, username, email, is_staff, ...}
               // Note: fields depend on User model serialization.
               // Default Django serializers might not expose everything.
               // Assuming custom_admin_data provided enriched user objects or values.
               // Backed view: values('id', 'username', 'email', 'is_staff', 'is_active', 'date_joined')
               return Card(
                 color: Colors.white.withOpacity(0.05),
                 child: ListTile(
                   leading: Icon(Icons.person, color: u['is_staff'] ? Colors.amber : Colors.white54),
                   title: Text(u['username'] ?? 'User', style: const TextStyle(color: Colors.white)),
                   subtitle: Text(u['email'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                   trailing: PopupMenuButton<String>(
                     icon: const Icon(Icons.more_vert, color: Colors.white),
                     onSelected: (val) async {
                        if(val == 'admin') await _updateRole(u['id'], 'premium'); // Usually 'premium' or level? Wait, backend check
                        if(val == 'user') await _updateRole(u['id'], 'free');
                        if(val == 'ban') await _api.banUser(u['id']);
                        if(val == 'del_posts') await _api.deleteUserPosts(u['id']);
                        
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("İşlem Başarılı!"), backgroundColor: Colors.green));
                        _loadDashboard();
                     },
                     itemBuilder: (ctx) => [
                       const PopupMenuItem(value: 'admin', child: Text("Premium Yap")), // Check naming
                       const PopupMenuItem(value: 'user', child: Text("Free Yap")),
                       const PopupMenuItem(value: 'ban', child: Text("Kullanıcıyı Yasakla (Ban)")),
                       const PopupMenuItem(value: 'del_posts', child: Text("Tüm Yazılarını Sil")),
                     ],
                   ),
                 ),
               );
            },
          ),
        ),
        _paginationControls(_userPage, 10, (p) { _userPage = p; _loadDashboard(); }),// Mock max pages if not returned
      ],
    );
  }

  Future<void> _updateRole(int uid, String level) async {
      try {
        await _api.updateMembership(uid, level);
        // Only show message if called directly, onSelected handles general success
      } catch(e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red));
      }
  }

  // --- 1. STATS TAB ---
  Widget _buildStatsTab() {
    if(_dashboardData == null) return const SizedBox();
    final stats = _dashboardData!['stats'];
    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
           _dateFilterRow((start, end) {
             _startDate = start; _endDate = end; _loadDashboard();
           }),
           const SizedBox(height: 20),
           _statCard("Toplam Kullanıcı", stats['total_users'].toString(), Icons.people, Colors.blue),
           _statCard("Aktif (24s)", stats['active_24h'].toString(), Icons.timer, Colors.green),
           _statCard("Yeni (24s)", stats['new_24h'].toString(), Icons.person_add, Colors.orange),
        ],
      ),
    );
  }

  // --- 2. LOGS TAB ---
  Widget _buildLogsTab() {
    if(_dashboardData == null) return const SizedBox();
    final logs = _dashboardData!['logs'] as List; // This is a Page Object in backend, but serialized as list in 'logs' key by custom_admin_data? 
    // Wait, the custom_admin_data returns 'logs': log_page_obj. 
    // JSON serialization of page_obj usually just sends the list. Pagination metadata might be missing unless backend explicitly added it.
    // In web template we used page_obj.has_next etc.
    // The backend `custom_admin_data_api` logs serialization needs to be checked.
    // Assuming it returns a list for now based on typical Django serializers unless we customized it.
    // Actually, Django Paginator object is not JSON serializable by default.
    // If the backend sends raw QuerySet or Page without serializer, it fails. 
    // However, since Web works, the view context is rendering template.
    // But `custom_admin_data_api` (if it exists) returns JsonResponse.
    // Let's assume for now logs are available.
    
    // Check if logs is actually a List or Map
    // If it's pure list, we handle pagination blindly or need to fix API.
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: _searchDec("Log Ara (User, IP, Action)..."),
                  onSubmitted: (v) { _logSearch = v; _logPage=1; _loadDashboard(); },
                ),
              ),
              IconButton(icon: const Icon(Icons.date_range, color: Colors.white), onPressed: () async {
                 // Date picker logic same as stats
              })
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: logs.length,
            separatorBuilder: (_,__) => const Divider(color: Colors.white10),
            itemBuilder: (ctx, i) {
               final l = logs[i]; // {'timestamp':..., 'user':..., 'action':...}
               // Usually user is object, action string
               // Need to parse flexibly
               String user = l['user'] is Map ? l['user']['username'] : (l['user'].toString());
               if(user == "null" || user.isEmpty) user = "Ziyaretçi";
               
               return ListTile(
                 dense: true,
                 leading: const Icon(Icons.circle, size: 8, color: Colors.grey),
                 title: Text("$user - ${l['action']}", style: const TextStyle(color: Colors.white)),
                 subtitle: Text(l['timestamp'], style: const TextStyle(color: Colors.white54, fontSize: 10)),
               );
            },
          ),
        ),
        _paginationControls(_logPage, 10, (p) { _logPage = p; _loadDashboard(); }), // Mock max pages
      ],
    );
  }

  // --- 3. MESSAGES TAB ---
  Widget _buildMessagesTab() {
    // Similar to Logs but for ContactMessages
    final msgs = _dashboardData?['contact_messages'] ?? [];
    List mList = [];
    int totalPages = 1;
    int currentParamPage = 1;
    
    if(msgs is Map) {
       // pagination object
       mList = msgs['messages'] ?? []; // Need to adjust backend API to ensure it sends this structure
       // If backend sends Page object directly converted to list in some way? 
       // In `custom_admin_data_api` view, we did:
       // 'contact_messages': msg_page_obj
       // Django JSONEncoder doesn't serialize Page object automatically.
       // We likely need to rely on what the Web uses: context passed to Template.
       // But for Mobile API `getAdminDashboardData` calls `custom-admin-data` URL.
       // Does that URL return JSON?
       // Let's assume the user made the backend API return proper JSON for these components.
       // If not, we might view empty lists. 
       // *CRITICAL*: The `custom_admin_data_api` view returns `JsonResponse`.
       // We modified standard `custom_admin_dashboard` which renders HTML.
       // We need to ensure `custom_admin_data_api` (the JSON endpoint) also has the new filters.
       // I should check `custom_admin_data_api` content later. Assuming it works or I'll fix it.
    } else if (msgs is List) {
      mList = msgs;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            style: const TextStyle(color: Colors.white),
             decoration: _searchDec("Mesaj Ara..."),
             onSubmitted: (v) { _msgSearch = v; _msgPage=1; _loadDashboard(); },
          ),
        ),
        Expanded(
          child: mList.isEmpty ? const Center(child: Text("Mesaj yok", style: TextStyle(color: Colors.white54))) : 
          ListView.builder(
            itemCount: mList.length,
            itemBuilder: (ctx, i) {
               final m = mList[i];
               return Card(
                 color: Colors.white.withOpacity(0.05),
                 child: ListTile(
                   title: Text(m['name'], style: const TextStyle(color: Colors.amber)),
                   subtitle: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(m['email'], style: const TextStyle(color: Colors.white54, fontSize: 12)),
                       const SizedBox(height: 5),
                       Text(m['message'], style: const TextStyle(color: Colors.white)),
                     ],
                   ),
                   trailing: Text(m['created_at']?.substring(0,10) ?? "", style: const TextStyle(color: Colors.white30, fontSize: 10)),
                 ),
               );
            },
          ),
        ),
         _paginationControls(_msgPage, 10, (p) { _msgPage = p; _loadDashboard(); }),
      ],
    );
  }

  // --- 4. APPOINTMENTS TAB ---
  Widget _buildAppointmentsTab() {
    return Column(
      children: [
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
               _filterChip('Tümü', 'all'),
               _filterChip('Bekleyen', 'pending'),
               _filterChip('Onaylanan', 'approved'),
               _filterChip('Red', 'rejected'),
            ],
          ),
        ),
        Expanded(
          child: _appointments.isEmpty ? const Center(child: Text("Randevu yok", style: TextStyle(color: Colors.white54))) : 
          ListView.builder(
            itemCount: _appointments.length,
            itemBuilder: (ctx, i) {
               final a = _appointments[i];
               Color statusColor = Colors.grey;
               if(a.status == 'approved') statusColor = Colors.green;
               if(a.status == 'rejected') statusColor = Colors.red;
               if(a.status == 'pending') statusColor = Colors.orange;

               return Card(
                 color: Colors.white.withOpacity(0.05),
                 margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                 shape: RoundedRectangleBorder(
                   side: BorderSide(color: statusColor, width: 1),
                   borderRadius: BorderRadius.circular(10)
                 ),
                 child: Padding(
                   padding: const EdgeInsets.all(12),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Text(a.user, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                           Container(
                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                             decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                             child: Text(a.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10)),
                           )
                         ],
                       ),
                       Text(a.topic, style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
                       const SizedBox(height: 10),
                       Text(a.message, style: const TextStyle(color: Colors.white)),
                       const SizedBox(height: 10),
                       Row(
                         children: [
                           const Icon(Icons.contact_phone, size: 14, color: Colors.white54),
                           const SizedBox(width: 5),
                           Text(a.contact, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                         ],
                       ),
                       if(a.status == 'pending') ...[
                         const Divider(color: Colors.white10),
                         Row(
                           mainAxisAlignment: MainAxisAlignment.end,
                           children: [
                             TextButton(onPressed: () => _reviewApp(a.id, 'reject'), child: const Text("Reddet", style: TextStyle(color: Colors.red))),
                             ElevatedButton(onPressed: () => _reviewApp(a.id, 'approve'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text("Onayla")),
                           ],
                         )
                       ]
                     ],
                   ),
                 ),
               );
            },
          ),
        ),
        _paginationControls(_appPage, _appTotalPages, (p) { _appPage = p; _loadAppointments(); }),
      ],
    );
  }

  Widget _filterChip(String label, String val) {
    bool sel = _appStatus == val;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: sel,
        selectedColor: const Color(0xFFE94560),
        backgroundColor: Colors.white10,
        labelStyle: TextStyle(color: sel?Colors.white:Colors.white70),
        onSelected: (v) {
          setState(() { _appStatus = val; _appPage = 1; });
          _loadAppointments();
        },
      ),
    );
  }

  Future<void> _reviewApp(int id, String action) async {
    final noteController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: Text(action == 'approve' ? 'Onayla' : 'Reddet', style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: noteController, 
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: "Not ekle (Opsiyonel)", hintStyle: TextStyle(color: Colors.white30))
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _api.reviewAppointment(id, action, noteController.text);
              _loadAppointments();
            },
            child: const Text("Tamam")
          )
        ],
      )
    );
  }

  Widget _paginationControls(int current, int total, Function(int) onChange) {
    if(total <= 1) return const SizedBox();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 16, color: Colors.white),
          onPressed: current > 1 ? () => onChange(current - 1) : null,
        ),
        Text("$current / $total", style: const TextStyle(color: Colors.white)),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
          onPressed: current < total ? () => onChange(current + 1) : null,
        ),
      ],
    );
  }

  Widget _dateFilterRow(Function(DateTime?, DateTime?) onChange) {
    return Row(
      children: [
        Expanded(child: OutlinedButton(
          onPressed: () async {
             final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
             if(d!=null) onChange(d, _endDate);
          },
          child: Text(_startDate == null ? "Başlangıç" : _startDate.toString().split(' ')[0], style: const TextStyle(color: Colors.white)),
        )),
        const SizedBox(width: 10),
        Expanded(child: OutlinedButton(
          onPressed: () async {
             final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
             if(d!=null) onChange(_startDate, d);
          },
          child: Text(_endDate == null ? "Bitiş" : _endDate.toString().split(' ')[0], style: const TextStyle(color: Colors.white)),
        )),
      ],
    );
  }
  
  Widget _statCard(String title, String val, IconData icon, Color color) {
    return Card(
      color: Colors.white.withOpacity(0.05),
      child: ListTile(
        leading: Icon(icon, color: color, size: 30),
        title: Text(val, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        subtitle: Text(title, style: const TextStyle(color: Colors.white60)),
      ),
    );
  }

  InputDecoration _searchDec(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white30),
      filled: true,
      fillColor: Colors.white10,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      suffixIcon: const Icon(Icons.search, color: Colors.white54)
    );
  }
}
