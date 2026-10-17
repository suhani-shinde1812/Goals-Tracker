import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import '../models/dashboard_model.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api/v1';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // 10.0.2.2 is the special alias to the host loopback interface in Android emulator
      return 'http://10.0.2.2:8000/api/v1';
    } else {
      return 'http://127.0.0.1:8000/api/v1';
    }
  }

  static String? _token;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  static Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Map<String, String> get _headers {
    final map = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      map['Authorization'] = 'Bearer $_token';
    }
    return map;
  }

  static Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': email, 'password': password},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveToken(data['access_token']);
        return true;
      }
    } catch (e) {
      debugPrint('Login error: $e');
    }
    return false;
  }

  static Future<DashboardSummaryModel?> getDashboardSummary(String date) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/dashboard-summary?target_date=$date'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return DashboardSummaryModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('getDashboardSummary error: $e');
    }
    return null;
  }

  static Future<List<ScheduledTaskModel>> getTasks(String date) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tasks?target_date=$date'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.map((item) => ScheduledTaskModel.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('getTasks error: $e');
    }
    return [];
  }

  static Future<ScheduledTaskModel?> toggleTaskCompletion(int taskId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/tasks/$taskId/toggle'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return ScheduledTaskModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('toggleTaskCompletion error: $e');
    }
    return null;
  }

  static Future<bool> addHydration(String date, int amountMl) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/hydration/add'),
        headers: _headers,
        body: jsonEncode({'date': date, 'amount_ml': amountMl}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('addHydration error: $e');
      return false;
    }
  }
}
