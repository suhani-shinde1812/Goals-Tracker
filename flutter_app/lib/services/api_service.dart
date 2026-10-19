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
  static bool get isLoggedIn => _token != null;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _userEmail = prefs.getString('user_email');
    _userName = prefs.getString('user_name');
  }

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

  // --- Auth & Account Management ---

  static Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': email, 'password': password},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        await saveAuth(token, email, 'BloomTrack User');
        // Fetch profile
        await fetchUserProfile();
        return true;
      }
    } catch (e) {
      debugPrint('Login error: $e');
    }
    return false;
  }

  static Future<Map<String, dynamic>> register(String fullName, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': fullName,
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final token = data['access_token'];
        await saveAuth(token, email, fullName);
        return {'success': true, 'message': 'Account created successfully!'};
      } else {
        return {'success': false, 'message': data['detail'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
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
    if (_token != null) return;

    // Try auto-login default demo account
    final loggedIn = await login('user@bloomtrack.com', 'SecretPassword123!');
    if (!loggedIn) {
      // If user doesn't exist yet on remote DB, register
      await register('BloomTrack Wellness', 'user@bloomtrack.com', 'SecretPassword123!');
    }
  }

  // --- Hydration (With Immediate Persistent Local Tracking) ---

  static Future<int> getLocalWaterIntake(String date) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('water_intake_$date') ?? 750;
  }

  static Future<int> addHydration(String date, int amountMl) async {
    // 1. Immediately increment local persistent intake
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt('water_intake_$date') ?? 750;
    final updated = current + amountMl;
    await prefs.setInt('water_intake_$date', updated);

    // 2. Also asynchronously sync with remote backend
    try {
      await http.post(
        Uri.parse('$baseUrl/hydration/add'),
        headers: _headers,
        body: jsonEncode({'date': date, 'amount_ml': amountMl}),
      ).timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('addHydration remote sync error: $e');
    }

    return updated;
  }

  // --- Dashboard Summary ---

  static Future<DashboardSummaryModel?> getDashboardSummary(String date) async {
    final localWater = await getLocalWaterIntake(date);

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/dashboard-summary?target_date=$date'),
        headers: _headers,
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final model = DashboardSummaryModel.fromJson(jsonDecode(response.body));
        // Ensure local quick adds take precedence if local is higher
        final effectiveWater = model.waterIntakeTodayMl > localWater ? model.waterIntakeTodayMl : localWater;
        return model.copyWith(
          welcomeMessage: _userName != null ? 'Welcome back, ${_userName!.split(" ")[0]}!' : model.welcomeMessage,
          waterIntakeTodayMl: effectiveWater,
        );
      }
    } catch (e) {
      debugPrint('getDashboardSummary network error: $e');
    }

    // Offline fallback
    final fallback = DashboardSummaryModel.defaultOffline(date);
    return fallback.copyWith(
      welcomeMessage: _userName != null ? 'Welcome back, ${_userName!.split(" ")[0]}!' : fallback.welcomeMessage,
      waterIntakeTodayMl: localWater,
    );
  }

  // --- Tasks ---

  static Future<List<ScheduledTaskModel>> getTasks(String date) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tasks?target_date=$date'),
        headers: _headers,
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.map((item) => ScheduledTaskModel.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('getTasks network error: $e');
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
      debugPrint('toggleTaskCompletion error: $e');
    }
    return null;
  }

  // --- GATE CS 2027 Syllabus & Topics ---

  static Future<List<GateSubjectModel>> getGateSubjects() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/gate/subjects'),
        headers: _headers,
      ).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.map((item) => GateSubjectModel.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('getGateSubjects error: $e');
    }

    return getOfflineGateSubjects();
  }

  static Future<bool> updateGateTopicStatus(int topicId, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/gate/topics/$topicId'),
        headers: _headers,
        body: jsonEncode({'status': status}),
      ).timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('updateGateTopicStatus error: $e');
      return true; // Local optimistic update
    }
  }

  // --- Semester Exams ---

  static Future<List<SemesterSubjectModel>> getSemesterSubjects() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/semester/subjects'),
        headers: _headers,
      ).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.map((item) => SemesterSubjectModel.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('getSemesterSubjects error: $e');
    }

    return getOfflineSemesterSubjects();
  }

  static Future<bool> toggleSemesterUnit(int unitId, bool isCompleted) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/semester/units/$unitId/toggle'),
        headers: _headers,
        body: jsonEncode({'is_completed': isCompleted}),
      ).timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('toggleSemesterUnit error: $e');
      return true;
    }
  }

  static Future<bool> renameSemesterSubject(int subjectId, String newName) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/semester/subjects/$subjectId/rename'),
        headers: _headers,
        body: jsonEncode({'name': newName}),
      ).timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('renameSemesterSubject error: $e');
      return true;
    }
  }

  // --- Offline Fallback Data ---

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
