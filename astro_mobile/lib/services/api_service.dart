import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'dart:io' show Platform;
import '../models/chart_model.dart';
import '../models/tarot_model.dart';
import '../models/interactive_models.dart';

class ApiService {
  String get baseUrl {
    // 1. Production (Release Mode)
    if (!kDebugMode) {
      return "https://astrorehberi.com/api";
    }

    // 2. Development (Debug Mode)
    if (kIsWeb) return "http://127.0.0.1:8000/api";
    try {
      if (Platform.isAndroid) return "http://10.0.2.2:8000/api";
    } catch (e) {
      return "http://127.0.0.1:8000/api";
    }
    return "http://127.0.0.1:8000/api";
  }

  String get rootUrl {
     if (!kDebugMode) {
      return "https://astrorehberi.com";
    }
    if (kIsWeb) return "http://127.0.0.1:8000";
    try {
      if (Platform.isAndroid) return "http://10.0.2.2:8000";
    } catch(e){
       return "http://127.0.0.1:8000";
    }
    return "http://127.0.0.1:8000";
  }

  static Map<String, String> _headers = {'Content-Type': 'application/json'};

  void _updateCookie(http.Response response) {
    String? rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      int index = rawCookie.indexOf(';');
      _headers['cookie'] = (index == -1) ? rawCookie : rawCookie.substring(0, index);
    }
  }

  Future<Map<String, dynamic>> checkAuth() async {
    final url = Uri.parse('$baseUrl/check-auth/');
    try {
      final response = await http.get(url, headers: _headers);
      _updateCookie(response);
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'authenticated': false};
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/login/');
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({'username': username, 'password': password}),
    );
    _updateCookie(response);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Login Failed');
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/register/');
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode(data),
    );
    _updateCookie(response);
     if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Registration Failed');
    }
  }
  
  Future<void> logout() async {
     final url = Uri.parse('$baseUrl/logout/');
     await http.post(url, headers: _headers);
     _headers.remove('cookie');
  }

  Future<Map<String, dynamic>> getDailyHoroscopes(String lang) async {
    final url = Uri.parse('$baseUrl/daily-horoscopes/?lang=$lang');
    final response = await http.get(url, headers: _headers); 
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Failed to load horoscopes');
    }
  }

  // ADDED: Weekly Forecast (Day-by-Day)
  Future<Map<String, dynamic>> getWeeklyForecast(String lang) async {
    final url = Uri.parse('$baseUrl/weekly-forecast/?lang=$lang');
    final response = await http.get(url, headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Failed to load weekly forecast');
    }
  }
  
  Future<Map<String, dynamic>> getPlanetaryHours({required double lat, required double lon, String? date}) async {
    String d = date ?? DateTime.now().toIso8601String().split('T')[0];
    final url = Uri.parse('$baseUrl/planetary-hours/?lat=$lat&lon=$lon&date=$d');
    final response = await http.get(url, headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Failed to load hours');
    }
  }

  Future<ChartData> calculateChart({
    required DateTime date,
    required String time, // HH:MM
    required double lat,
    required double lon,
    String lang = 'en',
  }) async {
    final url = Uri.parse('$baseUrl/calculate-chart/');
    final dateStr = "${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}";

    try {
      final response = await http.post(
        url,
        headers: _headers, 
        body: jsonEncode({
          'date': dateStr,
          'time': time,
          'lat': lat,
          'lon': lon,
          'lang': lang,
        }),
      );
      _updateCookie(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return ChartData.fromJson(data);
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load chart: $e');
    }
  }

  Future<Map<String, dynamic>?> getDailyPlanner(Map<String, dynamic> params) async {
    final sign = params['horoscope'] ?? 'aries';
    final lang = params['lang'] ?? 'en';
    final url = Uri.parse('$baseUrl/daily-planner/?sign=$sign&lang=$lang'); 
    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (_) {}
    return null; 
  }

  Future<TarotResponse> drawTarot(String lang) async {
    final url = Uri.parse('$baseUrl/draw-tarot/?lang=$lang');
    final response = await http.get(url, headers: _headers);
    if (response.statusCode == 200) {
      return TarotResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Server Error');
    }
  }

  Future<Map<String, dynamic>> getCareerAnalysis(Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl/career-analysis/');
    final response = await http.post(url, headers: _headers, body: jsonEncode(body));
    _updateCookie(response);
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Server Error');
    }
  }

  Future<Map<String, dynamic>> calculateSynastry({
    required DateTime date1,
    required String time1,
    required DateTime date2,
    required String time2,
    String lang = 'en',
  }) async {
    final url = Uri.parse('$baseUrl/calculate-synastry/');
    final d1 = "${date1.year}/${date1.month.toString().padLeft(2, '0')}/${date1.day.toString().padLeft(2, '0')}";
    final d2 = "${date2.year}/${date2.month.toString().padLeft(2, '0')}/${date2.day.toString().padLeft(2, '0')}";

    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'date1': d1, 'time1': time1,
          'date2': d2, 'time2': time2,
          'lang': lang,
        }),
      );
      _updateCookie(response);
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Server Error');
      }
    } catch (e) {
      throw Exception('Failed to calculate synastry: $e');
    }
  }
  
  Future<List<String>> getCountries() async {
      try {
        final url = Uri.parse('$baseUrl/countries/');
        final res = await http.get(url, headers: _headers);
        if(res.statusCode == 200) return List<String>.from(jsonDecode(utf8.decode(res.bodyBytes))['countries']);
      } catch(_) {}
      return [];
  }
  Future<List<String>> getProvinces(String c) async {
       try {
        final url = Uri.parse('$baseUrl/provinces/?country=$c');
        final res = await http.get(url, headers: _headers);
        if(res.statusCode == 200) return List<String>.from(jsonDecode(utf8.decode(res.bodyBytes))['provinces']);
      } catch(_) {}
      return [];
  }
  Future<Map<String, dynamic>> getCities(String c, String p) async {
        try {
        final url = Uri.parse('$baseUrl/cities/?country=$c&province=$p');
        final res = await http.get(url, headers: _headers);
        if(res.statusCode == 200) return jsonDecode(utf8.decode(res.bodyBytes));
      } catch(_) {}
      return {};
  }

  Future<List<dynamic>?> getCelestialEvents(String risingSign, String lang) async {
    try {
      final url = Uri.parse('$baseUrl/celestial-events/?rising=$risingSign&lang=$lang');
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        return decoded['events'];
      }
    } catch (e) {
      if (kDebugMode) print("Celestial Error: $e");
    }
    return null;
  }



  // --- INTERACTIVE / SOCIAL API ---

  // 1. Wall / Posts
  Future<Map<String, dynamic>> getWallPosts({String filter = 'all', int page = 1, String? username}) async {
    String query = '?filter=$filter&page=$page';
    if(username != null) query += '&username=$username';
    
    // Correct URL: /interactive/wall/api/posts/
    final url = Uri.parse('$rootUrl/interactive/wall/api/posts/$query');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Failed to load posts');
    }
  }

  Future<void> createPost(String content) async {
    final url = Uri.parse('$rootUrl/interactive/wall/api/create/');
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({'content': content}),
    );
    if (response.statusCode != 200) throw Exception('Failed to post');
  }

  Future<void> toggleLike(int postId) async {
    final url = Uri.parse('$rootUrl/interactive/wall/api/like/$postId/');
    final response = await http.post(url, headers: _headers);
    if (response.statusCode != 200) throw Exception('Failed to like');
  }

  // 2. Following / Users
  Future<Map<String, dynamic>> toggleFollow(String username) async {
    final url = Uri.parse('$rootUrl/interactive/api/follow/');
    final response = await http.post(
      url, 
      headers: _headers,
      body: jsonEncode({'username': username})
    );
     if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to follow');
    }
  }
  
  Future<List<UserSummary>> searchUsers(String query) async {
    final url = Uri.parse('$rootUrl/interactive/api/search-users/?q=$query');
    final response = await http.get(url, headers: _headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return (data['users'] as List).map((e) => UserSummary.fromJson(e)).toList();
    }
    return [];
  }

  // 3. Inbox / Notifications
  Future<Map<String, dynamic>> getNotifications({int page = 1}) async {
    final url = Uri.parse('$rootUrl/interactive/api/inbox/?page=$page');
    final response = await http.get(url, headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    throw Exception('Failed to load notifs');
  }
  
  Future<void> markRead() async {
    await http.post(Uri.parse('$rootUrl/interactive/inbox/mark-read/'), headers: _headers);
  }

  // 4. Messaging
  Future<List<Conversation>> getConversations() async {
    final url = Uri.parse('$rootUrl/interactive/api/messages/conversations/');
    final response = await http.get(url, headers: _headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return (data['conversations'] as List).map((e) => Conversation.fromJson(e)).toList();
    }
    return [];
  }
  
  Future<List<DirectMessage>> getMessages(String username) async {
    final url = Uri.parse('$rootUrl/interactive/api/messages/$username/');
    final response = await http.get(url, headers: _headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return (data['messages'] as List).map((e) => DirectMessage.fromJson(e)).toList();
    }
    return [];
  }
  
  Future<void> sendMessage(String to, String body) async {
    final url = Uri.parse('$rootUrl/interactive/api/messages/send/');
    final res = await http.post(url, headers: _headers, body: jsonEncode({'to': to, 'body': body}));
    if(res.statusCode != 200) throw Exception('Failed to send');
  }

  // 5. Contact & Appointments (User)
  Future<void> submitContactMessage(String name, String email, String message) async {
    final url = Uri.parse('$baseUrl/submit-contact/'); // Correct in Astrology App
    final res = await http.post(
      url, 
      headers: _headers, 
      body: jsonEncode({'name': name, 'email': email, 'message': message})
    );
    if(res.statusCode != 200) throw Exception('Failed to submit message');
  }

  Future<void> submitAppointment(String topic, String message, String contact) async {
    // Correct URL in Interactive App
    final url = Uri.parse('$rootUrl/interactive/appointment/create/');
    final res = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({'topic': topic, 'message': message, 'contact': contact}) // 'contact' key matches view logic
    );
    if(res.statusCode != 200) throw Exception('Failed to submit request');
  }

  // 6. Admin Panel API
  
  // Fetch Appointments (Filtered & Paginated)
  Future<Map<String, dynamic>> getAdminAppointments({String status = 'all', int page = 1}) async {
    final url = Uri.parse('$rootUrl/interactive/admin/appointments/?status=$status&page=$page');
    final response = await http.get(url, headers: _headers);
    if (response.statusCode == 200) {
       return jsonDecode(utf8.decode(response.bodyBytes));
    }
    throw Exception('Failed to load appointments');
  }

  Future<void> reviewAppointment(int id, String action, String note) async {
    final url = Uri.parse('$rootUrl/interactive/admin/review-appointment/');
    final res = await http.post(
      url, headers: _headers,
      body: jsonEncode({'id': id, 'action': action, 'note': note})
    );
    if(res.statusCode != 200) throw Exception('Review failed');
  }

  Future<void> updateMembership(int userId, String level) async {
    final url = Uri.parse('$baseUrl/custom-admin/update-membership/'); // Correct in Astrology App
    final res = await http.post(
      url, headers: _headers,
      body: jsonEncode({'user_id': userId, 'level': level})
    );
    if(res.statusCode != 200) throw Exception('Update failed');
  }

  // Fetch Dashboard Data (Stats, Logs, Messages)
  Future<Map<String, dynamic>> getAdminDashboardData({
      String? startDate, 
      String? endDate, 
      String? logSearch, 
      String? msgSearch,
      String? msgStart,
      String? msgEnd,
      String? userSearch, 
      int msgPage = 1,
      int logPage = 1,
      int userPage = 1, 
  }) async {
    String query = '?msg_page=$msgPage&page=$logPage&user_page=$userPage'; 
    if(startDate != null && startDate.isNotEmpty) query += '&start_date=$startDate';
    if(endDate != null && endDate.isNotEmpty) query += '&end_date=$endDate';
    if(logSearch != null && logSearch.isNotEmpty) query += '&log_search=$logSearch';
    
    if(msgSearch != null && msgSearch.isNotEmpty) query += '&msg_search=$msgSearch';
    if(msgStart != null && msgStart.isNotEmpty) query += '&msg_start=$msgStart';
    if(msgEnd != null && msgEnd.isNotEmpty) query += '&msg_end=$msgEnd';
    
    if(userSearch != null && userSearch.isNotEmpty) query += '&user_search=$userSearch';

    // Correct URL for Custom Admin Data
    final url = Uri.parse('$baseUrl/custom-admin/data/$query');
    final response = await http.get(url, headers: _headers);
    
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else if (response.statusCode == 403) {
      throw Exception('Unauthorized');
    }
    throw Exception('Failed to load admin data');
  }

  // --- 7. Content / Blog API ---
  Future<Map<String, dynamic>> getBlogPosts({int page = 1}) async {
    // UPDATED: Now fetches real "Cosmic Articles" (BlogPosts)
    final url = Uri.parse('$baseUrl/api/blog/?page=$page'); 
    final response = await http.get(url, headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    throw Exception('Failed to load blog posts');
  }

  Future<Map<String, dynamic>> getBlogDetail(String slug) async {
    final url = Uri.parse('$baseUrl/api/blog/$slug/');
    final response = await http.get(url, headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    throw Exception('Failed to load blog detail');
  }

  // --- 8. Moderation API ---
  Future<void> banUser(int userId) async {
    final url = Uri.parse('$rootUrl/cms/moderation/ban/$userId/');
    final response = await http.post(url, headers: _headers);
    if (response.statusCode != 200) throw Exception('Failed to ban user');
  }

  Future<void> deleteUserPosts(int userId) async {
    final url = Uri.parse('$rootUrl/cms/moderation/delete-posts/$userId/');
    final response = await http.post(url, headers: _headers);
    if (response.statusCode != 200) throw Exception('Failed to delete posts');
  }
  Future<List<dynamic>> getLibraryItems() async {
    final url = Uri.parse('$baseUrl/api/library/');
    try {
      final response = await http.get(url, headers: _headers);
      _updateCookie(response);
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['categories'] ?? [];
      } else {
        throw Exception("Failed to load library");
      }
    } catch (e) {
      throw Exception('Error loading library: $e');
    }
  }

  Future<Map<String, dynamic>> getLibraryItemDetail(String slug) async {
    final url = Uri.parse('$baseUrl/api/library/$slug/');
    try {
      final response = await http.get(url, headers: _headers);
      _updateCookie(response);
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception("Failed to load item detail");
      }
    } catch (e) {
      throw Exception('Error loading item: $e');
    }
  }
}


