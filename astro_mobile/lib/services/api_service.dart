import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'dart:io' show Platform;
import '../models/chart_model.dart';
import '../models/tarot_model.dart';

class ApiService {
  String get baseUrl {
    if (kIsWeb) return "http://127.0.0.1:8000/api";
    try {
      if (Platform.isAndroid) return "http://10.0.2.2:8000/api";
    } catch (e) {
      return "http://127.0.0.1:8000/api";
    }
    return "http://127.0.0.1:8000/api";
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
}
