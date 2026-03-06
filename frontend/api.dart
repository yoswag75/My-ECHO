import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class ApiService {
  // Ensure this matches your Render URL exactly
  static const String baseUrl = 'https://my-echo-backend-server.onrender.com'; 
  
  static String? _token;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    print("DEBUG: Init token: $_token");
  }

  static bool get hasToken => _token != null;

  static Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // Returns NULL on success, or an error message STRING on failure
  static Future<String?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      ).timeout(Duration(seconds: 60)); // Increased timeout for Cloud Cold Start

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['access_token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        return null; // Success
      } else {
        // Try to extract error message from backend
        try {
          final err = json.decode(response.body);
          return err['detail'] ?? "Login failed (${response.statusCode})";
        } catch (_) {
          return "Login failed (${response.statusCode})";
        }
      }
    } catch (e) {
      print("Login Error: $e");
      return "Connection Error: Please check your internet.";
    }
  }

  // Returns NULL on success, or an error message STRING on failure
  static Future<String?> register(String username, String password, String passcode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password, 'passcode': passcode}),
      ).timeout(Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['access_token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        return null; // Success
      } else {
        try {
          final err = json.decode(response.body);
          return err['detail'] ?? "Registration failed (${response.statusCode})";
        } catch (_) {
          return "Registration failed (${response.statusCode})";
        }
      }
    } catch (e) {
      print("Register Error: $e");
      return "Connection Error: Please check your internet.";
    }
  }

  static Future<bool> verifyPasscode(String passcode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-passcode'),
        headers: _headers,
        body: json.encode({'passcode': passcode}),
      ).timeout(Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> getUsername() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/me'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body)['username'];
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> updateProfile({String? username, String? password, String? passcode}) async {
    try {
      final body = {};
      if (username != null && username.isNotEmpty) body['username'] = username;
      if (password != null && password.isNotEmpty) body['password'] = password;
      if (passcode != null && passcode.isNotEmpty) body['passcode'] = passcode;

      final response = await http.put(
        Uri.parse('$baseUrl/profile'),
        headers: _headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['new_token'] != null) {
          _token = data['new_token'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', _token!);
        }
        return true;
      }
    } catch (e) {
      print("Update Profile Error: $e");
    }
    return false;
  }

  static Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // --- Existing Methods ---

  static Future<List<JournalEntry>> getEntries() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/journal'), headers: _headers);
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        return list.map((e) => JournalEntry.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<JournalEntry?> createEntry(String content) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/journal'),
        headers: _headers,
        body: json.encode({'content': content}),
      );
      if (response.statusCode == 200) {
        return JournalEntry.fromJson(json.decode(response.body));
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> deleteEntry(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/journal/$id'), headers: _headers);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Person>> getPeople() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/people'), headers: _headers);
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        return list.map((e) => Person.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<PersonAnalytics?> getPersonAnalytics(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/people/$id/analytics'), headers: _headers);
      if (response.statusCode == 200) {
        return PersonAnalytics.fromJson(json.decode(response.body));
      }
    } catch (_) {}
    return null;
  }

  static Future<WeeklyGoal?> getWeeklyCoach() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/coach/weekly'), headers: _headers);
      if (response.statusCode == 200) {
        return WeeklyGoal.fromJson(json.decode(response.body));
      }
    } catch (_) {}
    return null;
  }
}