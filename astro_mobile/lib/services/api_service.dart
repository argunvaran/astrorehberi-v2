import 'package:shared_preferences/shared_preferences.dart';
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

    // 2. Debug Mode - Local Testing
    if (kIsWeb) return "http://127.0.0.1:8080/api";
    try {
      if (Platform.isAndroid) return "http://10.0.2.2:8080/api";
      if (Platform.isIOS) return "http://127.0.0.1:8080/api";
    } catch (e) {}
    return "http://127.0.0.1:8080/api";
  }

  String get rootUrl {
    if (!kDebugMode) {
      return "https://astrorehberi.com";
    }
    
    if (kIsWeb) return "http://127.0.0.1:8080";
    try {
      if (Platform.isAndroid) return "http://10.0.2.2:8080";
      if (Platform.isIOS) return "http://127.0.0.1:8080";
    } catch (e) {}
    return "http://127.0.0.1:8080";
  }

  static Map<String, String> _headers = {'Content-Type': 'application/json'};
  String? get debugToken => _headers['Authorization'];

  // Persistent Cookie Storage
  static Future<void> _saveToken() async {
    final prefs = await SharedPreferences.getInstance();
    if (_headers['cookie'] != null) {
      prefs.setString('auth_cookie', _headers['cookie']!);
    }
    if (_headers['Authorization'] != null) {
      prefs.setString('auth_token', _headers['Authorization']!);
    }
  }

  static Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Load Cookie
    final cookie = prefs.getString('auth_cookie');
    if (cookie != null && cookie.isNotEmpty) {
      _headers['cookie'] = cookie;
    }

    // 2. Load Token (Priority for Web)
    final token = prefs.getString('auth_token');
    if (token != null && token.isNotEmpty) {
      _headers['Authorization'] = token;
    }
  }

  Future<void> _updateCookie(http.Response response) async {
    String? rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      if (kDebugMode) print("DEBUG: Raw Set-Cookie: $rawCookie");

      Map<String, String> cookies = {};
      
      if (_headers['cookie'] != null && _headers['cookie']!.isNotEmpty) {
        _headers['cookie']!.split(';').forEach((c) {
          int idx = c.indexOf('=');
          if (idx != -1) {
            String key = c.substring(0, idx).trim();
            String val = c.substring(idx + 1).trim();
            if (key.isNotEmpty) cookies[key] = val;
          }
        });
      }

      RegExp regExp = RegExp(r'(astro_session|csrftoken|messages)=([^;,\s]+)');
      for (Match m in regExp.allMatches(rawCookie)) {
        String key = m.group(1)!;
        String val = m.group(2)!;
        cookies[key] = val;
      }

      if (cookies.isNotEmpty) {
        _headers['cookie'] = cookies.entries.map((e) => "${e.key}=${e.value}").join('; ');
        
        // Also set Authorization header for Web/Cross-Origin Fallback
        if (cookies.containsKey('astro_session')) {
            _headers['Authorization'] = 'Bearer ${cookies['astro_session']}';
        }
        
<<<<<<< HEAD
        _saveToken(); 
=======
        await _saveToken(); 
>>>>>>> a3db2cd (Social interactions, admin notifications, and UI improvements)
      }
    }
  }

  Future<Map<String, dynamic>> checkAuth() async {
    await _loadToken(); 
    final url = Uri.parse('$baseUrl/check-auth/');
    try {
      final response = await http.get(url, headers: _headers);
      await _updateCookie(response);
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
<<<<<<< HEAD
    _updateCookie(response);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['token'] != null) {
         _headers['Authorization'] = 'Bearer ${data['token']}';
         _saveToken();
=======
    await _updateCookie(response);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data['token'] != null) {
         _headers['Authorization'] = 'Bearer ${data['token']}';
         await _saveToken();
>>>>>>> a3db2cd (Social interactions, admin notifications, and UI improvements)
      }
      return data;
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
    await _updateCookie(response);
     if (response.statusCode == 200) {
<<<<<<< HEAD
      final resData = jsonDecode(response.body);
      if (resData['token'] != null) {
         _headers['Authorization'] = 'Bearer ${resData['token']}';
         _saveToken();
=======
      final resData = jsonDecode(utf8.decode(response.bodyBytes));
      if (resData['token'] != null) {
         _headers['Authorization'] = 'Bearer ${resData['token']}';
         await _saveToken();
>>>>>>> a3db2cd (Social interactions, admin notifications, and UI improvements)
      }
      return resData;
    } else {
      String errorMessage = 'Registration Failed';
      try {
        final errData = jsonDecode(response.body);
        if (errData['error'] != null) errorMessage = errData['error'];
        else if (errData['detail'] != null) errorMessage = errData['detail'];
        else if (errData['username'] != null) errorMessage = "Username taken: ${errData['username'][0]}";
      } catch(_) {}
      
      throw Exception(errorMessage);
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
  
  Future<List<Map<String, dynamic>>> getCountries() async {
      try {
        final url = Uri.parse('$baseUrl/countries/');
        final res = await http.get(url, headers: _headers);
        if(res.statusCode == 200) {
           final data = jsonDecode(utf8.decode(res.bodyBytes));
           return List<Map<String, dynamic>>.from(data['countries']);
        }
      } catch(e) {
        if (kDebugMode) print("getCountries Error: $e");
      }
      return [];
  }
  Future<List<Map<String, dynamic>>> getProvinces(String c) async {
       try {
        // Backend expects 'code' for country code
        final url = Uri.parse('$baseUrl/provinces/?code=$c');
        if (kDebugMode) print("getProvinces URL: $url");
        final res = await http.get(url, headers: _headers);
        if(res.statusCode == 200) {
            final decoded = jsonDecode(utf8.decode(res.bodyBytes));
            return List<Map<String, dynamic>>.from(decoded['provinces']);
        } else {
             if (kDebugMode) print("getProvinces Error Status: ${res.statusCode} Body: ${res.body}");
        }
      } catch(e) {
        if (kDebugMode) print("getProvinces Err: $e");
      }
      return [];
  }
  
  Future<List<Map<String, dynamic>>> getCities(String c, String p) async {
        try {
        // Backend expects 'code' and 'admin_code'
        final url = Uri.parse('$baseUrl/cities/?code=$c&admin_code=$p'); 
        if (kDebugMode) print("getCities URL: $url");
        final res = await http.get(url, headers: _headers);
        if(res.statusCode == 200) {
           final decoded = jsonDecode(utf8.decode(res.bodyBytes));
           
           if (decoded['cities'] is List) {
             return List<Map<String, dynamic>>.from(decoded['cities']);
           } else if (decoded is Map) {
             List<Map<String, dynamic>> list = [];
             decoded.forEach((k, v) => list.add({'name': k, ...v}));
             list.sort((a,b) => (a['name'] as String).compareTo(b['name']));
             return list;
           }
        }
      } catch(e) {
        if (kDebugMode) print("getCities Err: $e");
      }
      return [];
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
    final url = Uri.parse('$rootUrl/interactive/wall/api/like/');
    final response = await http.post(
      url, 
      headers: _headers,
      body: jsonEncode({'post_id': postId})
    );
    if (response.statusCode != 200) throw Exception('Failed to like');
  }

  Future<void> addComment(int postId, String content) async {
    final url = Uri.parse('$rootUrl/interactive/wall/api/comment/');
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({'post_id': postId, 'content': content}),
    );
    if (response.statusCode != 200) throw Exception('Failed to comment');
  }

  Future<List<PostComment>> getComments(int postId) async {
    final url = Uri.parse('$rootUrl/interactive/wall/api/comments/$postId/');
    final response = await http.get(url, headers: _headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return (data['comments'] as List).map((e) => PostComment.fromJson(e)).toList();
    }
    return [];
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
    // Determine URL based on app (Assuming mobile uses contact form mostly)
    // But keeping original logic attempt:
    final url = Uri.parse('$rootUrl/interactive/appointment/create/');
    final res = await http.post(
      url, 
      headers: _headers, 
      body: jsonEncode({'topic': topic, 'message': message, 'contact_info': contact})
    );
    if(res.statusCode != 200 && res.statusCode != 201) throw Exception('Failed to submit appointment');
  }

  // --- Rectification ---
  Future<Map<String, dynamic>> rectifyBirthTime({
    required String date, required double lat, required double lon, 
    required String lang, required List<Map<String, dynamic>> events
  }) async {
    if (kDebugMode) print("DEBUG Headers: $_headers");
    try {
      final url = Uri.parse('$baseUrl/rectify-time/');
      if (kDebugMode) print("Rectify URL: $url");
      
      final body = jsonEncode({
        'date': date,
        'lat': lat,
        'lon': lon,
        'lang': lang,
        'events': events
      });
      
      final res = await http.post(url, headers: _headers, body: body);
      
      if(res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      } else {
        if (kDebugMode) print("Rectify Failed: ${res.statusCode} Body: ${res.body}");
        try {
             final errJson = jsonDecode(utf8.decode(res.bodyBytes));
             if (errJson.containsKey('error')) return errJson;
        } catch(e) {}
        return {'error': 'Server Error: ${res.statusCode}. Body: ${res.body}'};
      }
    } catch (e) {
      if (kDebugMode) print("Rectify Err: $e");
      return {'error': 'Connection Error: $e'};
    }
  }

  // --- Profile Update ---
  Future<Map<String, dynamic>> updateProfile({
    String? username, String? birth_date, String? birth_time, 
<<<<<<< HEAD
    String? birth_city, String? bio, double? lat, double? lon
=======
    String? birth_city, String? bio, double? lat, double? lon,
    String? sun_sign, String? rising_sign,
>>>>>>> a3db2cd (Social interactions, admin notifications, and UI improvements)
  }) async {
    final url = Uri.parse('$baseUrl/update-profile/');
     try {
       final body = jsonEncode({
         if (username != null) 'username': username,
         if (birth_date != null) 'birth_date': birth_date,
         if (birth_time != null) 'birth_time': birth_time,
         if (birth_city != null) 'birth_city': birth_city,
         if (bio != null) 'bio': bio,
         if (lat != null) 'lat': lat,
         if (lon != null) 'lon': lon,
<<<<<<< HEAD
=======
         if (sun_sign != null) 'sun_sign': sun_sign,
         if (rising_sign != null) 'rising_sign': rising_sign,
>>>>>>> a3db2cd (Social interactions, admin notifications, and UI improvements)
       });

       final res = await http.post(url, headers: _headers, body: body);
       
       if (res.statusCode == 200) {
          final data = jsonDecode(utf8.decode(res.bodyBytes));
          _updateCookie(res); // Important if session is refreshed
          return data;
       } else {
         return {'error': 'Update failed: ${res.statusCode}'};
       }
     } catch (e) {
       return {'error': 'Connection Error: $e'};
     }
  }

  // 6. Admin Panel API
  
  // Fetch Appointments (Filtered & Paginated)
  Future<Map<String, dynamic>> getAdminAppointments({String status = 'all', int page = 1}) async {
    await _loadToken();
    final url = Uri.parse('$rootUrl/interactive/admin/appointments/?status=$status&page=$page');
    final response = await http.get(url, headers: _headers);
    if (response.statusCode == 200) {
       return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
       String errMsg = 'Admin appointments error: ${response.statusCode}';
       try {
         final body = jsonDecode(utf8.decode(response.bodyBytes));
         if (body['error'] != null) errMsg = body['error'];
       } catch(_) {}
       throw Exception(errMsg);
    }
  }

  Future<void> reviewAppointment(int id, String action, String note) async {
    await _loadToken();
    final url = Uri.parse('$rootUrl/interactive/admin/review-appointment/');
    final res = await http.post(
      url, headers: _headers,
      body: jsonEncode({'id': id, 'action': action, 'note': note})
    );
    if(res.statusCode != 200) throw Exception('Review failed');
  }

  Future<void> updateMembership(int userId, String level) async {
    await _loadToken();
    final url = Uri.parse('$baseUrl/custom-admin/update-membership/'); // Correct in Astrology App
    final res = await http.post(
      url, headers: _headers,
      body: jsonEncode({'user_id': userId, 'level': level})
    );
    if(res.statusCode != 200) throw Exception('Update failed');
  }

  Future<void> sendNotification({dynamic userId, required String title, required String message}) async {
    await _loadToken();
    final url = Uri.parse('$rootUrl/interactive/admin/send-notification/');
    final res = await http.post(
      url, headers: _headers,
      body: jsonEncode({
        'user_id': userId, // can be int or 'all'
        'title': title,
        'message': message
      })
    );
    if (res.statusCode != 200) {
       String err = 'Gönderim başarısız';
       try {
         final body = jsonDecode(utf8.decode(res.bodyBytes));
         if(body['error'] != null) err = body['error'];
       } catch(_) {}
       throw Exception(err);
    }
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
    await _loadToken();
    String query = '?msgPage=$msgPage&logPage=$logPage&userPage=$userPage'; 
    
    if(startDate != null && startDate.isNotEmpty) query += '&start_date=$startDate';
    if(endDate != null && endDate.isNotEmpty) query += '&end_date=$endDate';
    if(logSearch != null && logSearch.isNotEmpty) query += '&logSearch=$logSearch';
    if(msgSearch != null && msgSearch.isNotEmpty) query += '&msgSearch=$msgSearch';
    if(msgStart != null && msgStart.isNotEmpty) query += '&msg_start=$msgStart';
    if(msgEnd != null && msgEnd.isNotEmpty) query += '&msg_end=$msgEnd';
    if(userSearch != null && userSearch.isNotEmpty) query += '&userSearch=$userSearch';

    final url = Uri.parse('$baseUrl/custom-admin/data/$query');
    final response = await http.get(url, headers: _headers);
    
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
       String errMsg = 'Admin data error: ${response.statusCode}';
       try {
         final body = jsonDecode(utf8.decode(response.bodyBytes));
         if (body['error'] != null) errMsg = body['error'];
       } catch(_) {}
       throw Exception(errMsg);
    }
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

  Future<void> editLibraryItem(int id, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/api/library/edit/');
    final body = jsonEncode({'id': id, ...data});
    final response = await http.post(
      url, 
      headers: _headers, 
      body: body
    );
    
    if (response.statusCode == 200) {
      return; 
    } else {
      throw Exception('Failed to update: ${response.statusCode}');
    }
  }

  Future<void> saveDailyHoroscopes(List<dynamic> items) async {
    final url = Uri.parse('$baseUrl/api/daily-horoscopes/save/');
    final body = jsonEncode({'horoscopes': items});
    
    final response = await http.post(
      url, 
      headers: _headers, 
      body: body
    );
    
    if (response.statusCode == 200) {
      return; 
    } else {
      throw Exception('Failed to save horoscopes: ${response.statusCode}');
    }
  }
}


