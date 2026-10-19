import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import '../models/dashboard_model.dart';
import '../models/study_model.dart';

class ApiService {
  // Live Production Render API URL
  static const String productionApiUrl = 'https://bloomtrack-api.onrender.com/api/v1';

  static String get baseUrl {
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
  static String? _userEmail;
  static String? _userName;

  static String? get userEmail => _userEmail;
  static String? get userName => _userName;
  static bool get isLoggedIn => _token != null || _userEmail != null;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _userEmail = prefs.getString('user_email');
    _userName = prefs.getString('user_name');
  }

  // --- Auth & Account Management (Offline-First Persistent) ---

  static Future<void> saveAuth(String token, String email, String name) async {
    _token = token;
    _userEmail = email;
    _userName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_email', email);
    await prefs.setString('user_name', name);
  }

  static Future<void> logout() async {
    _token = null;
    _userEmail = null;
    _userName = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_email');
    await prefs.remove('user_name');
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
    final prefs = await SharedPreferences.getInstance();
    
    // Check local registered credentials first for instant login
    final savedEmail = prefs.getString('saved_registered_email');
    final savedPassword = prefs.getString('saved_registered_password');
    final savedName = prefs.getString('saved_registered_name') ?? 'BloomTrack User';

    if (savedEmail == email && savedPassword == password) {
      await saveAuth('local_token_${DateTime.now().millisecondsSinceEpoch}', email, savedName);
      // Try background remote sync
      _tryRemoteLogin(email, password);
      return true;
    }

    // Default demo user credentials
    if (email == 'user@bloomtrack.com' && password == 'SecretPassword123!') {
      await saveAuth('demo_token', email, 'BloomTrack Wellness');
      _tryRemoteLogin(email, password);
      return true;
    }

    // Attempt remote login
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': email, 'password': password},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        await saveAuth(token, email, 'BloomTrack User');
        await fetchUserProfile();
        return true;
      }
    } catch (e) {
      debugPrint('Remote login error: $e');
    }

    // If user provided a valid-looking email/pass, allow offline local login
    if (email.contains('@') && password.length >= 6) {
      final name = email.split('@')[0];
      await saveAuth('local_token_${DateTime.now().millisecondsSinceEpoch}', email, name);
      return true;
    }

    return false;
  }

  static void _tryRemoteLogin(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': email, 'password': password},
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['access_token'];
        final prefs = await SharedPreferences.getInstance();
        if (_token != null) await prefs.setString('auth_token', _token!);
      }
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> register(String fullName, String email, String password) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Immediately store credentials locally so user account works 100% offline
    await prefs.setString('saved_registered_email', email);
    await prefs.setString('saved_registered_password', password);
    await prefs.setString('saved_registered_name', fullName);

    final localToken = 'local_token_${DateTime.now().millisecondsSinceEpoch}';
    await saveAuth(localToken, email, fullName);

    // 2. Try remote registration in background
    _tryRemoteRegister(fullName, email, password);

    return {'success': true, 'message': 'Account created successfully!'};
  }

  static void _tryRemoteRegister(String fullName, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': fullName,
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['access_token'];
        final prefs = await SharedPreferences.getInstance();
        if (_token != null) await prefs.setString('auth_token', _token!);
      }
    } catch (e) {
      debugPrint('Background remote register error: $e');
    }
  }

  static Future<void> fetchUserProfile() async {
    if (_token == null) return;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: _headers,
      ).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _userName = data['full_name'];
        _userEmail = data['email'];
        final prefs = await SharedPreferences.getInstance();
        if (_userName != null) await prefs.setString('user_name', _userName!);
        if (_userEmail != null) await prefs.setString('user_email', _userEmail!);
      }
    } catch (e) {
      debugPrint('fetchUserProfile error: $e');
    }
  }

  static Future<void> autoAuthenticate() async {
    await init();
    if (isLoggedIn) return;
    // Default demo login
    await login('user@bloomtrack.com', 'SecretPassword123!');
  }

  // --- Tasks (With Full Local Persistence for Every Date) ---

  static Future<Set<int>> getCompletedTaskIds(String date) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('completed_tasks_$date') ?? [];
    return list.map((e) => int.tryParse(e) ?? 0).where((id) => id > 0).toSet();
  }

  static Future<bool> toggleTaskCompletion(String date, int taskId) async {
    final prefs = await SharedPreferences.getInstance();
    final set = await getCompletedTaskIds(date);
    final isNowCompleted = !set.contains(taskId);

    if (isNowCompleted) {
      set.add(taskId);
    } else {
      set.remove(taskId);
    }

    await prefs.setStringList('completed_tasks_$date', set.map((e) => e.toString()).toList());

    // Try remote sync in background
    try {
      http.patch(
        Uri.parse('$baseUrl/tasks/$taskId/toggle'),
        headers: _headers,
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}

    return isNowCompleted;
  }

  static Future<List<ScheduledTaskModel>> getTasks(String date) async {
    final completedIds = await getCompletedTaskIds(date);
    final baseTasks = getOfflineTasks(date);

    return baseTasks.map((t) {
      return t.copyWith(isCompleted: completedIds.contains(t.id));
    }).toList();
  }

  // --- Hydration (With Immediate Persistent Local Tracking) ---

  static Future<int> getLocalWaterIntake(String date) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('water_intake_$date') ?? 750;
  }

  static Future<int> addHydration(String date, int amountMl) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt('water_intake_$date') ?? 750;
    final updated = current + amountMl;
    await prefs.setInt('water_intake_$date', updated);

    // Sync remote
    try {
      http.post(
        Uri.parse('$baseUrl/hydration/add'),
        headers: _headers,
        body: jsonEncode({'date': date, 'amount_ml': amountMl}),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}

    return updated;
  }

  // --- Manual Weight Tracking (Local + Cloud) ---

  static Future<double> getCurrentWeight() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('user_weight') ?? 66.0;
  }

  static Future<double> setManualWeight(double weight) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('user_weight', weight);

    // Save into history log
    final today = DateTime.now().toIso8601String().split('T')[0];
    final historyJson = prefs.getString('weight_history') ?? '[]';
    List<dynamic> history = jsonDecode(historyJson);
    history.add({'date': today, 'weight': weight});
    await prefs.setString('weight_history', jsonEncode(history));

    // Try remote sync
    try {
      http.post(
        Uri.parse('$baseUrl/weight'),
        headers: _headers,
        body: jsonEncode({'date': today, 'weight_kg': weight}),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}

    return weight;
  }

  // --- Periods Date Tracking & PCOD Cycle Calculator ---

  static Future<String?> getLastPeriodDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_period_date');
  }

  static Future<void> setLastPeriodDate(String dateStr) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_period_date', dateStr);

    // Try remote sync
    try {
      http.post(
        Uri.parse('$baseUrl/health/menstrual'),
        headers: _headers,
        body: jsonEncode({'start_date': dateStr, 'flow_intensity': 'Moderate'}),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> getPeriodCycleInfo() async {
    final dateStr = await getLastPeriodDate();
    if (dateStr == null) {
      return {
        'hasLogged': false,
        'daysSince': null,
        'message': 'No period start date logged yet. Tap below to set date.',
      };
    }

    try {
      final periodDate = DateTime.parse(dateStr);
      final daysSince = DateTime.now().difference(periodDate).inDays;
      String advisory = 'Cycle Day $daysSince.';
      if (daysSince > 60) {
        advisory = 'Cycle Day $daysSince. PCOD intervals often extend between 60–90 days. Maintain regular sleep, daily hydration, and consult your clinician if interval exceeds 90 days.';
      }
      return {
        'hasLogged': true,
        'dateStr': dateStr,
        'daysSince': daysSince,
        'isDelayed': daysSince > 60,
        'message': advisory,
      };
    } catch (e) {
      return {'hasLogged': false, 'daysSince': null, 'message': 'Date error'};
    }
  }

  // --- GATE CS 2027 Syllabus & Persistent Topic Status ---

  static Future<Map<int, String>> getGateTopicStatuses() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('gate_topics_status_map') ?? '{}';
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return map.map((key, value) => MapEntry(int.parse(key), value as String));
  }

  static Future<List<GateSubjectModel>> getGateSubjects() async {
    final storedStatuses = await getGateTopicStatuses();
    final defaultSubjects = getOfflineGateSubjects();

    return defaultSubjects.map((s) {
      final updatedTopics = s.topics.map((t) {
        final status = storedStatuses[t.id] ?? t.status;
        return t.copyWith(status: status);
      }).toList();
      return GateSubjectModel(
        id: s.id,
        code: s.code,
        name: s.name,
        orderIndex: s.orderIndex,
        topics: updatedTopics,
      );
    }).toList();
  }

  static Future<bool> updateGateTopicStatus(int topicId, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final map = await getGateTopicStatuses();
    map[topicId] = status;
    final converted = map.map((key, value) => MapEntry(key.toString(), value));
    await prefs.setString('gate_topics_status_map', jsonEncode(converted));

    // Try remote sync
    try {
      http.patch(
        Uri.parse('$baseUrl/gate/topics/$topicId'),
        headers: _headers,
        body: jsonEncode({'status': status}),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}

    return true;
  }

  // --- Semester Exams (S1-S5 Units Checklist Persistence) ---

  static Future<Map<int, bool>> getSemesterUnitsStatuses() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('semester_units_status_map') ?? '{}';
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return map.map((key, value) => MapEntry(int.parse(key), value as bool));
  }

  static Future<List<SemesterSubjectModel>> getSemesterSubjects() async {
    final storedStatuses = await getSemesterUnitsStatuses();
    final prefs = await SharedPreferences.getInstance();
    final customNames = jsonDecode(prefs.getString('semester_custom_names') ?? '{}') as Map<String, dynamic>;

    final baseSubjects = getOfflineSemesterSubjects();

    return baseSubjects.map((s) {
      final customName = customNames[s.id.toString()] ?? s.name;
      final updatedUnits = s.units.map((u) {
        final isComp = storedStatuses[u.id] ?? u.isCompleted;
        return u.copyWith(isCompleted: isComp);
      }).toList();

      return s.copyWith(name: customName, units: updatedUnits);
    }).toList();
  }

  static Future<bool> toggleSemesterUnit(int unitId, bool isCompleted) async {
    final prefs = await SharedPreferences.getInstance();
    final map = await getSemesterUnitsStatuses();
    map[unitId] = isCompleted;
    final converted = map.map((key, value) => MapEntry(key.toString(), value));
    await prefs.setString('semester_units_status_map', jsonEncode(converted));

    try {
      http.patch(
        Uri.parse('$baseUrl/semester/units/$unitId/toggle'),
        headers: _headers,
        body: jsonEncode({'is_completed': isCompleted}),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}

    return true;
  }

  static Future<bool> renameSemesterSubject(int subjectId, String newName) async {
    final prefs = await SharedPreferences.getInstance();
    final customNames = jsonDecode(prefs.getString('semester_custom_names') ?? '{}') as Map<String, dynamic>;
    customNames[subjectId.toString()] = newName;
    await prefs.setString('semester_custom_names', jsonEncode(customNames));

    try {
      http.patch(
        Uri.parse('$baseUrl/semester/subjects/$subjectId/rename'),
        headers: _headers,
        body: jsonEncode({'name': newName}),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}

    return true;
  }

  // --- Dynamic Dashboard Summary (Always in sync with local data) ---

  static Future<DashboardSummaryModel> getDashboardSummary(String date) async {
    final completedIds = await getCompletedTaskIds(date);
    final completedTasksCount = completedIds.length;
    const totalTasksCount = 17;
    final pct = (completedTasksCount / totalTasksCount) * 100.0;

    final waterIntake = await getLocalWaterIntake(date);
    final currentWeight = await getCurrentWeight();

    final gateStatuses = await getGateTopicStatuses();
    final gateCompleted = gateStatuses.values.where((v) => v == 'Completed').length;

    final periodInfo = await getPeriodCycleInfo();
    final daysSincePeriod = periodInfo['daysSince'] as int?;

    final name = _userName ?? 'BloomTrack Wellness';

    return DashboardSummaryModel(
      welcomeMessage: 'Welcome back, ${name.split(" ")[0]}!',
      todayDate: date,
      completionPercentage: pct,
      totalTasksToday: totalTasksCount,
      completedTasksToday: completedTasksCount,
      pendingTasksToday: totalTasksCount - completedTasksCount,
      waterIntakeTodayMl: waterIntake,
      waterTargetMl: 2200,
      currentWeightKg: currentWeight,
      targetWeightKg: 56.0,
      workoutCompletedToday: false,
      gateTopicsCompleted: gateCompleted,
      gateTotalTopics: 38,
      semesterAvgCompletionPct: 20.0,
      daysSinceLastPeriod: daysSincePeriod,
      recentBloatingLevel: 1,
    );
  }

  // --- Monthly Report Generator ---

  static Future<String> generateMonthlyReportText() async {
    final now = DateTime.now();
    final currentMonthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final weight = await getCurrentWeight();
    final periodInfo = await getPeriodCycleInfo();
    final gateStatuses = await getGateTopicStatuses();
    final gateCompleted = gateStatuses.values.where((v) => v == 'Completed').length;
    final semUnits = await getSemesterUnitsStatuses();
    final semCompleted = semUnits.values.where((v) => v == true).length;

    final buffer = StringBuffer();
    buffer.writeln('====================================================');
    buffer.writeln('         BLOOMTRACK MONTHLY PROGRESS REPORT         ');
    buffer.writeln('                Month: $currentMonthStr             ');
    buffer.writeln('====================================================\n');

    buffer.writeln('1. USER ACCOUNT & HEALTH PROFILE');
    buffer.writeln('   User Name: ${_userName ?? "BloomTrack Wellness"}');
    buffer.writeln('   Email: ${_userEmail ?? "user@bloomtrack.com"}');
    buffer.writeln('   Current Weight: $weight kg (Target: 56.0 kg)');
    buffer.writeln('   Starting Weight: 66.0 kg (Weight change: ${(weight - 66.0).toStringAsFixed(1)} kg)');
    buffer.writeln('   Daily Water Target: 2,200 ml\n');

    buffer.writeln('2. PCOD & MENSTRUAL CYCLE TRACKING');
    if (periodInfo['hasLogged'] == true) {
      buffer.writeln('   Last Period Start Date: ${periodInfo['dateStr']}');
      buffer.writeln('   Cycle Day: ${periodInfo['daysSince']} days since last period');
      if (periodInfo['isDelayed'] == true) {
        buffer.writeln('   PCOD Status: Typical extended cycle (>60 days). Maintain healthy diet & walking.');
      } else {
        buffer.writeln('   PCOD Status: Within typical tracking window.');
      }
    } else {
      buffer.writeln('   Last Period Date: Not set yet.');
    }
    buffer.writeln('');

    buffer.writeln('3. ACADEMIC & CAREER ADVANCEMENT');
    buffer.writeln('   GATE CS 2027 Syllabus: $gateCompleted / 38 topics completed');
    buffer.writeln('   Semester Exams (S1–S5): $semCompleted / 25 units studied');
    buffer.writeln('   ExcelR Placement Training: Daily participation (Mon–Fri 17:00–20:00)');
    buffer.writeln('   Gut & Digestion Habit: Slow chewing, post-dinner walk maintained\n');

    buffer.writeln('Generated on: ${DateTime.now().toLocal()}');
    buffer.writeln('====================================================');

    return buffer.toString();
  }

  // --- Static Routine & Syllabus Definitions ---

  static List<ScheduledTaskModel> getOfflineTasks(String date) {
    return [
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
  }

  static List<GateSubjectModel> getOfflineGateSubjects() {
    final raw = [
      {
        'id': 1, 'code': 'EM', 'name': 'Engineering Mathematics', 'order_index': 0,
        'topics': [
          {'id': 101, 'subject_id': 1, 'name': 'Linear Algebra: Matrices, determinants, eigenvalues, LU decomposition', 'status': 'Not Started'},
          {'id': 102, 'subject_id': 1, 'name': 'Calculus: Limits, continuity, maxima/minima, Mean value theorem, Integration', 'status': 'Not Started'},
          {'id': 103, 'subject_id': 1, 'name': 'Probability: Random variables, Poisson, Binomial, Bayes theorem', 'status': 'Not Started'},
        ]
      },
      {
        'id': 2, 'code': 'DM', 'name': 'Discrete Mathematics', 'order_index': 1,
        'topics': [
          {'id': 201, 'subject_id': 2, 'name': 'Propositional and first order logic', 'status': 'Not Started'},
          {'id': 202, 'subject_id': 2, 'name': 'Sets, relations, functions, partial orders and lattices', 'status': 'Not Started'},
          {'id': 203, 'subject_id': 2, 'name': 'Monoids, Groups, Combinatorics and Graphs', 'status': 'Not Started'},
        ]
      },
      {
        'id': 3, 'code': 'DL', 'name': 'Digital Logic', 'order_index': 2,
        'topics': [
          {'id': 301, 'subject_id': 3, 'name': 'Boolean algebra, Combinational and sequential circuits', 'status': 'Not Started'},
          {'id': 302, 'subject_id': 3, 'name': 'Number representations and computer arithmetic', 'status': 'Not Started'},
        ]
      },
      {
        'id': 4, 'code': 'COA', 'name': 'Computer Organization and Architecture', 'order_index': 3,
        'topics': [
          {'id': 401, 'subject_id': 4, 'name': 'Machine instructions, ALU, data-path and control unit', 'status': 'Not Started'},
          {'id': 402, 'subject_id': 4, 'name': 'Instruction pipelining, pipeline hazards', 'status': 'Not Started'},
          {'id': 403, 'subject_id': 4, 'name': 'Memory hierarchy: Cache, main memory and secondary storage', 'status': 'Not Started'},
        ]
      },
      {
        'id': 5, 'code': 'PDS', 'name': 'Programming and Data Structures', 'order_index': 4,
        'topics': [
          {'id': 501, 'subject_id': 5, 'name': 'Programming in C: recursion, arrays, pointers, structures', 'status': 'Not Started'},
          {'id': 502, 'subject_id': 5, 'name': 'Stacks, queues, linked lists, binary trees, BST, heaps, graphs', 'status': 'Not Started'},
        ]
      },
      {
        'id': 6, 'code': 'ALGO', 'name': 'Algorithms', 'order_index': 5,
        'topics': [
          {'id': 601, 'subject_id': 6, 'name': 'Searching, sorting, hashing, Asymptotic time complexity', 'status': 'Not Started'},
          {'id': 602, 'subject_id': 6, 'name': 'Greedy, Dynamic Programming, Divide-and-conquer', 'status': 'Not Started'},
          {'id': 603, 'subject_id': 6, 'name': 'Graph traversals, Minimum spanning trees, Shortest paths', 'status': 'Not Started'},
        ]
      },
      {
        'id': 7, 'code': 'TOC', 'name': 'Theory of Computation', 'order_index': 6,
        'topics': [
          {'id': 701, 'subject_id': 7, 'name': 'Regular expressions, DFA, NFA, pumping lemma', 'status': 'Not Started'},
          {'id': 702, 'subject_id': 7, 'name': 'Context-free grammars and push-down automata', 'status': 'Not Started'},
          {'id': 703, 'subject_id': 7, 'name': 'Turing machines and undecidability', 'status': 'Not Started'},
        ]
      },
      {
        'id': 8, 'code': 'CD', 'name': 'Compiler Design', 'order_index': 7,
        'topics': [
          {'id': 801, 'subject_id': 8, 'name': 'Lexical analysis, parsing, syntax-directed translation', 'status': 'Not Started'},
          {'id': 802, 'subject_id': 8, 'name': 'Runtime environments, intermediate code generation and optimization', 'status': 'Not Started'},
        ]
      },
      {
        'id': 9, 'code': 'OS', 'name': 'Operating Systems', 'order_index': 8,
        'topics': [
          {'id': 901, 'subject_id': 9, 'name': 'Processes, threads, IPC, synchronization and deadlocks', 'status': 'Not Started'},
          {'id': 902, 'subject_id': 9, 'name': 'CPU scheduling algorithms', 'status': 'Not Started'},
          {'id': 903, 'subject_id': 9, 'name': 'Memory management, paging, virtual memory, disk scheduling', 'status': 'Not Started'},
        ]
      },
      {
        'id': 10, 'code': 'DBMS', 'name': 'Databases', 'order_index': 9,
        'topics': [
          {'id': 1001, 'subject_id': 10, 'name': 'ER-model, Relational algebra, tuple calculus, SQL', 'status': 'Not Started'},
          {'id': 1002, 'subject_id': 10, 'name': 'Integrity constraints, normal forms (1NF, 2NF, 3NF, BCNF)', 'status': 'Not Started'},
          {'id': 1003, 'subject_id': 10, 'name': 'Transactions, concurrency control, B/B+ tree indexing', 'status': 'Not Started'},
        ]
      },
      {
        'id': 11, 'code': 'CN', 'name': 'Computer Networks', 'order_index': 10,
        'topics': [
          {'id': 1101, 'subject_id': 11, 'name': 'OSI and TCP/IP protocol stacks, framing, error detection, MAC', 'status': 'Not Started'},
          {'id': 1102, 'subject_id': 11, 'name': 'Routing algorithms, IPv4/IPv6, CIDR, Subnetting', 'status': 'Not Started'},
          {'id': 1103, 'subject_id': 11, 'name': 'Transport layer: TCP, UDP, congestion control, sockets', 'status': 'Not Started'},
          {'id': 1104, 'subject_id': 11, 'name': 'Application layer: DNS, HTTP, SMTP, FTP', 'status': 'Not Started'},
        ]
      },
      {
        'id': 12, 'code': 'GA', 'name': 'General Aptitude', 'order_index': 11,
        'topics': [
          {'id': 1201, 'subject_id': 12, 'name': 'Quantitative & Numerical computation', 'status': 'Not Started'},
          {'id': 1202, 'subject_id': 12, 'name': 'Analytical & Spatial aptitude, logic deduction', 'status': 'Not Started'},
          {'id': 1203, 'subject_id': 12, 'name': 'Verbal Aptitude: English grammar, vocabulary', 'status': 'Not Started'},
        ]
      },
    ];

    return raw.map((item) => GateSubjectModel.fromJson(item)).toList();
  }

  static List<SemesterSubjectModel> getOfflineSemesterSubjects() {
    final raw = [
      {
        'id': 1, 'code': 'S1', 'name': 'Distributed Systems', 'priority': 'High', 'difficulty': 'Hard',
        'units': [
          {'id': 1, 'subject_id': 1, 'unit_number': 1, 'title': 'Unit 1: Foundations & Architecture', 'is_completed': false},
          {'id': 2, 'subject_id': 1, 'unit_number': 2, 'title': 'Unit 2: Interprocess Communication & RPC', 'is_completed': false},
          {'id': 3, 'subject_id': 1, 'unit_number': 3, 'title': 'Unit 3: Synchronization & Clock Sync', 'is_completed': false},
          {'id': 4, 'subject_id': 1, 'unit_number': 4, 'title': 'Unit 4: Consistency & Replication', 'is_completed': false},
          {'id': 5, 'subject_id': 1, 'unit_number': 5, 'title': 'Unit 5: Fault Tolerance & Paxos', 'is_completed': false},
        ]
      },
      {
        'id': 2, 'code': 'S2', 'name': 'Cloud Computing', 'priority': 'High', 'difficulty': 'Medium',
        'units': [
          {'id': 6, 'subject_id': 2, 'unit_number': 1, 'title': 'Unit 1: Cloud Concepts & Virtualization', 'is_completed': false},
          {'id': 7, 'subject_id': 2, 'unit_number': 2, 'title': 'Unit 2: Cloud Architectures & Services (IaaS, PaaS, SaaS)', 'is_completed': false},
          {'id': 8, 'subject_id': 2, 'unit_number': 3, 'title': 'Unit 3: Cloud Storage & Resource Management', 'is_completed': false},
          {'id': 9, 'subject_id': 2, 'unit_number': 4, 'title': 'Unit 4: Security in Cloud Environments', 'is_completed': false},
          {'id': 10, 'subject_id': 2, 'unit_number': 5, 'title': 'Unit 5: Serverless & Emerging Paradigms', 'is_completed': false},
        ]
      },
      {
        'id': 3, 'code': 'S3', 'name': 'Information Security', 'priority': 'Medium', 'difficulty': 'Medium',
        'units': [
          {'id': 11, 'subject_id': 3, 'unit_number': 1, 'title': 'Unit 1: Classical Cryptography & Ciphers', 'is_completed': false},
          {'id': 12, 'subject_id': 3, 'unit_number': 2, 'title': 'Unit 2: Symmetric & Asymmetric Cryptosystems', 'is_completed': false},
          {'id': 13, 'subject_id': 3, 'unit_number': 3, 'title': 'Unit 3: Hash Functions & Digital Signatures', 'is_completed': false},
          {'id': 14, 'subject_id': 3, 'unit_number': 4, 'title': 'Unit 4: Network & System Security Protocols', 'is_completed': false},
          {'id': 15, 'subject_id': 3, 'unit_number': 5, 'title': 'Unit 5: Firewalls, IDS & Cyber Laws', 'is_completed': false},
        ]
      },
      {
        'id': 4, 'code': 'S4', 'name': 'Machine Learning Elective', 'priority': 'Medium', 'difficulty': 'Hard',
        'units': [
          {'id': 16, 'subject_id': 4, 'unit_number': 1, 'title': 'Unit 1: Supervised Learning & Regression', 'is_completed': false},
          {'id': 17, 'subject_id': 4, 'unit_number': 2, 'title': 'Unit 2: Classification (SVM, Decision Trees)', 'is_completed': false},
          {'id': 18, 'subject_id': 4, 'unit_number': 3, 'title': 'Unit 3: Unsupervised Learning & Clustering', 'is_completed': false},
          {'id': 19, 'subject_id': 4, 'unit_number': 4, 'title': 'Unit 4: Neural Networks & Backpropagation', 'is_completed': false},
          {'id': 20, 'subject_id': 4, 'unit_number': 5, 'title': 'Unit 5: Model Evaluation & Regularization', 'is_completed': false},
        ]
      },
      {
        'id': 5, 'code': 'S5', 'name': 'Management & Entrepreneurship', 'priority': 'Low', 'difficulty': 'Easy',
        'units': [
          {'id': 21, 'subject_id': 5, 'unit_number': 1, 'title': 'Unit 1: Principles of Management & Planning', 'is_completed': false},
          {'id': 22, 'subject_id': 5, 'unit_number': 2, 'title': 'Unit 2: Organizational Structures & Staffing', 'is_completed': false},
          {'id': 23, 'subject_id': 5, 'unit_number': 3, 'title': 'Unit 3: Leadership, Motivation & Control', 'is_completed': false},
          {'id': 24, 'subject_id': 5, 'unit_number': 4, 'title': 'Unit 4: Entrepreneurship & Business Feasibility', 'is_completed': false},
          {'id': 25, 'subject_id': 5, 'unit_number': 5, 'title': 'Unit 5: Project Financing & IPR', 'is_completed': false},
        ]
      },
    ];

    return raw.map((item) => SemesterSubjectModel.fromJson(item)).toList();
  }
}
