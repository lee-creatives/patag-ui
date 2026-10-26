import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class PatagMaintenanceStore extends ChangeNotifier {
  static const baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:4100/api',
  );

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
      .where((r) => r.completion != null && r.completion!.state == 'Awaiting Verification')
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
    http.Response response;
    try {
      if (method == 'PATCH') {
        response = await http
            .patch(uri, headers: headers, body: jsonEncode(body))
            .timeout(const Duration(seconds: 20));
      } else if (body == null) {
        response =
            await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
      } else {
        response = await http
            .post(uri, headers: headers, body: jsonEncode(body))
            .timeout(const Duration(seconds: 20));
      }
    } on TimeoutException {
      throw Exception('Connection timed out. Please retry.');
    } catch (_) {
      throw Exception('Cannot reach PATAG server. Check API connection.');
    }

    final data = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      if (response.statusCode == 401) {
        token = null;
        user = null;
        team = null;
        reports = [];
        notifications = [];
        timer?.cancel();
        notifyListeners();
      }
      throw Exception(data['error'] ?? 'Request failed.');
    }
    return data;
  }

  Future<void> authenticate(String email, String password) async {
    final data = await call('/auth/login', body: {
      'email': email,
      'password': password,
      'role': 'maintenance',
    });
    if (data['user']['role'] != 'maintenance') {
      throw Exception('This account does not belong to road maintenance.');
    }
    token = data['token'];
    user = User.fromJson(Map<String, dynamic>.from(data['user']));
    await refresh();
    startPolling();
  }

  Future<void> demoLogin() async {
    final data = await call('/auth/demo', body: {'role': 'maintenance'});
    token = data['token'];
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
    try {
      if (token != null) {
        final data = await call('/bootstrap');
        reports = (data['reports'] as List? ?? [])
            .map((r) => PotholeReport(Map<String, dynamic>.from(r)))
            .toList();
        notifications = (data['notifications'] as List? ?? [])
            .map((n) => Notice.fromJson(Map<String, dynamic>.from(n)))
            .toList();
        user = User.fromJson(Map<String, dynamic>.from(data['user']));

        final teamsList = (data['teams'] as List? ?? [])
            .map((t) => Team.fromJson(Map<String, dynamic>.from(t)))
            .toList();
        if (user?.teamId != null) {
          team = teamsList.firstWhere(
            (t) => t.id == user!.teamId,
            orElse: () => teamsList.isNotEmpty
                ? teamsList.first
                : const Team(id: 'team-1', name: 'Road Crew Alpha', members: [], active: true),
          );
        } else if (teamsList.isNotEmpty) {
          team = teamsList.first;
        }
      }
      networkError = null;
      notifyListeners();
    } catch (e) {
      networkError = clean(e);
      notifyListeners();
      rethrow;
    }
  }

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

  Future<Map<String, dynamic>> upload(XFile file, {String kind = 'after'}) async {
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
    final res = await call(
      '/uploads',
      body: {
        'data': 'data:image/$type;base64,${base64Encode(bytes)}',
        'name': file.name,
        'kind': kind,
      },
    );
    return Map<String, dynamic>.from(res);
  }

  Future<void> logout() async {
    try {
      await call('/auth/logout', body: {});
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('patag-maintenance-draft');
    token = null;
    user = null;
    team = null;
    reports = [];
    notifications = [];
    timer?.cancel();
    notifyListeners();
  }

  static String clean(Object e) => e.toString().replaceFirst('Exception: ', '');
}

final store = PatagMaintenanceStore();
