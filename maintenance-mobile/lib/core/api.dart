import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

/// Talks to the shared PATAG API (see docs/api-contract.md). The server is the
/// source of truth: local state only changes after a successful response.
class PatagMaintenanceStore extends ChangeNotifier {
  PatagMaintenanceStore({http.Client? client})
      : client = client ?? http.Client();

  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:4100/api';
    return const String.fromEnvironment(
      'API_URL',
      defaultValue: 'http://10.0.2.2:4100/api',
    );
  }

  /// Replaceable in tests.
  http.Client client;

  /// Called after the server rejects the session (401), e.g. to open the login screen.
  VoidCallback? onSessionExpired;

  String? token;
  User? user;
  Team? team;
  List<PotholeReport> reports = [];
  List<Notice> notifications = [];
  Timer? timer;
  String? networkError;
  bool showUnread = true;

  void setUnreadPreference(bool value) {
    showUnread = value;
    notifyListeners();
  }

  List<PotholeReport> get myAssignments => reports.where((r) {
        if (team != null && r.teamId == team!.id) return true;
        return ['Assigned', 'In Progress', 'Resolved'].contains(r.status);
      }).toList();

  List<PotholeReport> get activeWork =>
      myAssignments.where((r) => r.status == 'In Progress').toList();

  List<PotholeReport> get newAssignments =>
      myAssignments.where((r) => r.status == 'Assigned').toList();

  List<PotholeReport> get submissions => myAssignments
      .where((r) =>
          r.completion != null &&
          r.completion!.state == 'Awaiting Verification')
      .toList();

  List<PotholeReport> get completedHistory =>
      myAssignments.where((r) => r.status == 'Resolved').toList();

  PotholeReport? getReportById(String id) {
    try {
      return reports.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Full URL for a photo path returned by the API (e.g. `/uploads/<uuid>.jpg`).
  static String photoUrl(String path) =>
      '${baseUrl.replaceFirst(RegExp(r'/api$'), '')}/api$path';

  Future<dynamic> call(
    String path, {
    Map<String, dynamic>? body,
    String? method,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    // Photos are sent as base64 (up to ~11 MB), so allow time on mobile data.
    const timeout = Duration(seconds: 20);
    http.Response response;
    try {
      if (method == 'PATCH') {
        response = await client
            .patch(uri, headers: headers, body: jsonEncode(body))
            .timeout(timeout);
      } else if (body == null) {
        response = await client.get(uri, headers: headers).timeout(timeout);
      } else {
        response = await client
            .post(uri, headers: headers, body: jsonEncode(body))
            .timeout(timeout);
      }
    } on TimeoutException {
      throw Exception('Connection timed out. Please retry.');
    } catch (_) {
      throw Exception(
          'Cannot reach the PATAG server. Check your connection and try again.');
    }

    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Unexpected response from the PATAG server.');
    }
    if (response.statusCode >= 400) {
      if (response.statusCode == 401 && token != null) {
        _clearSession();
        onSessionExpired?.call();
      }
      throw Exception(
          (data is Map ? data['error'] : null) ?? 'Request failed.');
    }
    return data;
  }

  Future<void> authenticate(String email, String password) async {
    final data = await call('/auth/login', body: {
      'email': email,
      'password': password,
      'role': 'maintenance',
    });
    await _startSession(data);
  }

  /// Seeded demo crew. Works only when the backend runs with ALLOW_DEMO=true.
  Future<void> demoLogin() async {
    final data = await call('/auth/demo', body: {'role': 'maintenance'});
    await _startSession(data);
  }

  Future<void> _startSession(dynamic data) async {
    if (data['user']?['role'] != 'maintenance') {
      throw Exception('This account does not belong to road maintenance.');
    }
    token = data['token'] as String;
    user = User.fromJson(Map<String, dynamic>.from(data['user']));
    await refresh();
    startPolling();
  }

  void startPolling() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 8), (_) {
      refresh().catchError((Object _) {});
    });
  }

  Future<void> refresh() async {
    if (token == null) return;
    try {
      final data = await call('/bootstrap');
      reports = (data['reports'] as List? ?? [])
          .map((r) => PotholeReport(Map<String, dynamic>.from(r)))
          .toList();
      notifications = (data['notifications'] as List? ?? [])
          .map((n) => Notice.fromJson(Map<String, dynamic>.from(n)))
          .toList();
      user = User.fromJson(Map<String, dynamic>.from(data['user']));
      final teams = (data['teams'] as List? ?? [])
          .map((t) => Team.fromJson(Map<String, dynamic>.from(t)))
          .toList();
      team = teams.where((t) => t.id == user?.teamId).firstOrNull;
      networkError = null;
      notifyListeners();
    } catch (e) {
      networkError = clean(e);
      notifyListeners();
      rethrow;
    }
  }

  /// Sends a workflow action (start, before-photos, progress, complete) and
  /// reloads from the server. Throws the server's message on failure; local
  /// state is left unchanged.
  Future<void> event(
    String reportId,
    String action, {
    Map<String, dynamic>? payload,
  }) async {
    await call(
      '/reports/$reportId/events',
      body: {'action': action, if (payload != null) ...payload},
    );
    await refresh();
  }

  Future<void> markRead(String id) async {
    await call('/notifications/read', body: {'id': id});
    await refresh();
  }

  Future<Map<String, dynamic>> upload(XFile file,
      {String kind = 'after'}) async {
    final bytes = await file.readAsBytes();
    if (bytes.length > 8 * 1024 * 1024) {
      throw Exception('Choose a photo under 8 MB.');
    }
    final name = file.name.toLowerCase();
    final type = name.endsWith('.png')
        ? 'png'
        : name.endsWith('.webp')
            ? 'webp'
            : (name.endsWith('.jpg') || name.endsWith('.jpeg'))
                ? 'jpeg'
                : null;
    if (type == null) {
      throw Exception('Choose a JPEG, PNG or WebP photo.');
    }
    final res = await call('/uploads', body: {
      'data': 'data:image/$type;base64,${base64Encode(bytes)}',
      'name': file.name,
      'kind': kind,
    });
    return Map<String, dynamic>.from(res);
  }

  void _clearSession() {
    token = null;
    user = null;
    team = null;
    reports = [];
    notifications = [];
    timer?.cancel();
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await call('/auth/logout', body: {});
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('patag-maintenance-draft');
    _clearSession();
  }

  static String clean(Object e) => e.toString().replaceFirst('Exception: ', '');

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}

final store = PatagMaintenanceStore();
