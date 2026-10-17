import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import '../models/dashboard_model.dart';

class ApiService {
  // Production Render API URL
  static const String productionApiUrl = 'https://bloomtrack-api.onrender.com/api/v1';

  static String get baseUrl {
    // When running release APK on a physical phone, always use the live production API
    if (kReleaseMode) {
      return productionApiUrl;
    }
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api/v1';
    } else {
      return productionApiUrl;
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
      ).timeout(const Duration(seconds: 4));
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
      ).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        return DashboardSummaryModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('getDashboardSummary network error, using local offline fallback: $e');
    }

    // Offline fallback so app is ALWAYS functional on device even if offline or server is waking up
    return DashboardSummaryModel.defaultOffline(date);
  }

  static Future<List<ScheduledTaskModel>> getTasks(String date) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tasks?target_date=$date'),
        headers: _headers,
      ).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.map((item) => ScheduledTaskModel.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('getTasks network error, using offline schedule: $e');
    }

    return getOfflineTasks(date);
  }

  static Future<ScheduledTaskModel?> toggleTaskCompletion(int taskId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/tasks/$taskId/toggle'),
        headers: _headers,
      ).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        return ScheduledTaskModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('toggleTaskCompletion network error: $e');
    }
    return null;
  }

  static Future<bool> addHydration(String date, int amountMl) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/hydration/add'),
        headers: _headers,
        body: jsonEncode({'date': date, 'amount_ml': amountMl}),
      ).timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('addHydration network error: $e');
      return true; // Optimistic local success
    }
  }

  static List<ScheduledTaskModel> getOfflineTasks(String date) {
    final defaultRoutine = [
      ScheduledTaskModel(id: 1, userId: 1, title: 'Wake up, drink water, and get daylight', category: 'Morning', date: date, scheduledTime: '06:30', durationMinutes: 15, priority: 'high', isCompleted: false),
      ScheduledTaskModel(id: 2, userId: 1, title: 'Home workout or brisk walking', category: 'Health', date: date, scheduledTime: '06:45 - 07:20', durationMinutes: 35, priority: 'high', isCompleted: false),
      ScheduledTaskModel(id: 3, userId: 1, title: 'Bath, skincare, and breakfast', category: 'Morning', date: date, scheduledTime: '07:20 - 08:00', durationMinutes: 40, priority: 'medium', isCompleted: false),
      ScheduledTaskModel(id: 4, userId: 1, title: 'GATE CS focused study', category: 'GATE', date: date, scheduledTime: '08:00 - 10:00', durationMinutes: 120, priority: 'high', isCompleted: false),
      ScheduledTaskModel(id: 5, userId: 1, title: 'Break and optional snack', category: 'Wellness', date: date, scheduledTime: '10:00 - 10:20', durationMinutes: 20, priority: 'low', isCompleted: false),
      ScheduledTaskModel(id: 6, userId: 1, title: 'Semester subject study', category: 'Semester', date: date, scheduledTime: '10:20 - 12:00', durationMinutes: 100, priority: 'high', isCompleted: false),
      ScheduledTaskModel(id: 7, userId: 1, title: 'Lunch and rest', category: 'Wellness', date: date, scheduledTime: '12:00 - 13:00', durationMinutes: 60, priority: 'medium', isCompleted: false),
      ScheduledTaskModel(id: 8, userId: 1, title: 'GATE practice and previous-year questions', category: 'GATE', date: date, scheduledTime: '13:00 - 14:30', durationMinutes: 90, priority: 'high', isCompleted: false),
      ScheduledTaskModel(id: 9, userId: 1, title: 'Break and movement', category: 'Wellness', date: date, scheduledTime: '14:30 - 15:00', durationMinutes: 30, priority: 'low', isCompleted: false),
      ScheduledTaskModel(id: 10, userId: 1, title: 'Semester revision or ExcelR practice', category: 'Study', date: date, scheduledTime: '15:00 - 16:00', durationMinutes: 60, priority: 'medium', isCompleted: false),
      ScheduledTaskModel(id: 11, userId: 1, title: 'Snack and training preparation', category: 'Wellness', date: date, scheduledTime: '16:00 - 16:30', durationMinutes: 30, priority: 'low', isCompleted: false),
      ScheduledTaskModel(id: 12, userId: 1, title: 'ExcelR placement training', category: 'Placement', date: date, scheduledTime: '17:00 - 20:00', durationMinutes: 180, priority: 'high', isCompleted: false),
      ScheduledTaskModel(id: 13, userId: 1, title: 'Dinner (chew slowly, high fiber)', category: 'Nutrition', date: date, scheduledTime: '20:00 - 20:30', durationMinutes: 30, priority: 'medium', isCompleted: false),
      ScheduledTaskModel(id: 14, userId: 1, title: 'Gentle walk if comfortable', category: 'Health', date: date, scheduledTime: '20:30 - 20:45', durationMinutes: 15, priority: 'low', isCompleted: false),
      ScheduledTaskModel(id: 15, userId: 1, title: 'Light revision and planning', category: 'Study', date: date, scheduledTime: '20:45 - 21:15', durationMinutes: 30, priority: 'medium', isCompleted: false),
      ScheduledTaskModel(id: 16, userId: 1, title: 'Relaxation, skincare, and bedtime routine', category: 'Evening', date: date, scheduledTime: '21:15 - 22:15', durationMinutes: 60, priority: 'medium', isCompleted: false),
      ScheduledTaskModel(id: 17, userId: 1, title: 'Sleep (restful recovery)', category: 'Evening', date: date, scheduledTime: '22:15', durationMinutes: 480, priority: 'high', isCompleted: false),
    ];
    return defaultRoutine;
  }
}
