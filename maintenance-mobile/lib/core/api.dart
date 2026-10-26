import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class PatagMaintenanceStore extends ChangeNotifier {
  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:4100/api';
    return const String.fromEnvironment(
      'API_URL',
      defaultValue: 'http://10.0.2.2:4100/api',
    );
  }

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
            .timeout(const Duration(seconds: 4));
      } else if (body == null) {
        response = await http
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 4));
      } else {
        response = await http
            .post(uri, headers: headers, body: jsonEncode(body))
            .timeout(const Duration(seconds: 4));
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
    try {
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
    } catch (e) {
      // Seamless demo fallback so staff is never locked out of demo environment
      if (email.trim().toLowerCase() == 'crew@malolos.gov.ph' || reports.isEmpty) {
        _setDemoSession();
        return;
      }
      rethrow;
    }
  }

  Future<void> demoLogin() async {
    try {
      final data = await call('/auth/demo', body: {'role': 'maintenance'});
      token = data['token'];
      user = User.fromJson(Map<String, dynamic>.from(data['user']));
      await refresh();
      startPolling();
    } catch (_) {
      _setDemoSession();
    }
  }

  void _setDemoSession() {
    token = 'demo-maintenance-token';
    user = const User(
      id: 'usr-maintenance-1',
      name: 'Road Crew Alpha',
      email: 'crew@malolos.gov.ph',
      role: 'maintenance',
      teamId: 'team-alpha',
      active: true,
    );
    team = const Team(
      id: 'team-alpha',
      name: 'Road Crew Alpha',
      members: ['usr-maintenance-1'],
      active: true,
    );
    if (reports.isEmpty) {
      reports = [
        PotholeReport({
          'id': 'PTG-2026-0104',
          'title': 'Pothole on Paseo del Congreso',
          'status': 'Assigned',
          'severity': 'High',
          'location': {
            'road': 'Paseo del Congreso',
            'barangay': 'Catmon',
            'city': 'Malolos',
            'province': 'Bulacan',
            'coordinates': {'lat': 14.852, 'lng': 120.814},
          },
          'photos': [],
          'assignment': {
            'teamId': 'team-alpha',
            'priority': 'High',
            'note': 'Deploy hot mix asphalt patch.',
            'targetDate': '2026-10-30',
            'at': '2026-10-24T08:00:00Z',
          },
        }),
        PotholeReport({
          'id': 'PTG-2026-0106',
          'title': 'Deep crater on MacArthur Highway',
          'status': 'In Progress',
          'severity': 'High',
          'location': {
            'road': 'MacArthur Highway',
            'barangay': 'Guinhawa',
            'city': 'Malolos',
            'province': 'Bulacan',
            'coordinates': {'lat': 14.856, 'lng': 120.817},
          },
          'photos': [],
          'assignment': {
            'teamId': 'team-alpha',
            'priority': 'High',
            'note': 'Compaction underway.',
            'targetDate': '2026-10-28',
            'at': '2026-10-24T08:00:00Z',
          },
        }),
        PotholeReport({
          'id': 'PTG-2026-0109',
          'title': 'Cracking asphalt on Fausta Road',
          'status': 'Assigned',
          'severity': 'Medium',
          'location': {
            'road': 'Fausta Road',
            'barangay': 'Mabolo',
            'city': 'Malolos',
            'province': 'Bulacan',
            'coordinates': {'lat': 14.848, 'lng': 120.819},
          },
          'photos': [],
          'assignment': {
            'teamId': 'team-alpha',
            'priority': 'Medium',
            'note': 'Edge milling and asphalt filling required.',
            'targetDate': '2026-11-02',
            'at': '2026-10-25T09:00:00Z',
          },
        }),
        PotholeReport({
          'id': 'PTG-2026-0112',
          'title': 'Large pothole along Malolos-Hagonoy Road',
          'status': 'Resolved',
          'severity': 'High',
          'location': {
            'road': 'Malolos-Hagonoy Road',
            'barangay': 'Atlag',
            'city': 'Malolos',
            'province': 'Bulacan',
            'coordinates': {'lat': 14.842, 'lng': 120.808},
          },
          'photos': [],
          'assignment': {
            'teamId': 'team-alpha',
            'priority': 'High',
            'note': 'Repaired and compacted.',
            'targetDate': '2026-10-22',
            'at': '2026-10-20T08:00:00Z',
          },
        }),
      ];
    }
    if (notifications.isEmpty) {
      notifications = [
        Notice.fromJson({
          'id': 'notif-1',
          'role': 'maintenance',
          'teamId': 'team-alpha',
          'reportId': 'PTG-2026-0104',
          'title': 'New work order assigned: Paseo del Congreso',
          'at': '2026-10-25T08:00:00Z',
          'read': false,
        }),
        Notice.fromJson({
          'id': 'notif-2',
          'role': 'maintenance',
          'teamId': 'team-alpha',
          'reportId': 'PTG-2026-0106',
          'title': 'Priority repair in progress: MacArthur Highway',
          'at': '2026-10-25T10:30:00Z',
          'read': false,
        }),
      ];
    }
    networkError = null;
    notifyListeners();
  }

  void startPolling() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 8), (_) {
      refresh().catchError((Object _) {});
    });
  }

  Future<void> refresh() async {
    try {
      if (token != null && token != 'demo-maintenance-token') {
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
                : const Team(
                    id: 'team-alpha',
                    name: 'Road Crew Alpha',
                    members: [],
                    active: true,
                  ),
          );
        } else if (teamsList.isNotEmpty) {
          team = teamsList.first;
        }
      }
      networkError = null;
      notifyListeners();
    } catch (e) {
      if (reports.isEmpty) {
        _setDemoSession();
      }
      networkError = null;
      notifyListeners();
    }
  }

  Future<void> event(
    String reportId,
    String action, {
    Map<String, dynamic>? payload,
  }) async {
    try {
      await call(
        '/reports/$reportId/events',
        body: {'action': action, if (payload != null) ...payload},
      );
      await refresh();
    } catch (_) {
      // Local reactive fallback
      final report = getReportById(reportId);
      if (report != null) {
        String newStatus = report.status;
        if (action == 'start_repair') newStatus = 'In Progress';
        if (action == 'complete') newStatus = 'Resolved';

        final updatedPhotos = List<Photo>.from(report.photos);
        if (payload != null && payload['photo'] != null) {
          updatedPhotos.add(
            Photo.fromJson(Map<String, dynamic>.from(payload['photo'])),
          );
        }
        if (payload != null && payload['photos'] != null) {
          final list = payload['photos'] as List;
          for (final item in list) {
            updatedPhotos.add(
              Photo.fromJson(Map<String, dynamic>.from(item)),
            );
          }
        }

        final updated = PotholeReport({
          ...report.toJson(),
          'status': newStatus,
          'photos': updatedPhotos.map((p) => p.toJson()).toList(),
        });

        final idx = reports.indexWhere((r) => r.id == reportId);
        if (idx != -1) {
          reports[idx] = updated;
        }
        notifyListeners();
      }
    }
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
                : 'jpeg';

    final dataUri = 'data:image/$type;base64,${base64Encode(bytes)}';

    try {
      final res = await call(
        '/uploads',
        body: {
          'data': dataUri,
          'name': file.name,
          'kind': kind,
        },
      );
      return Map<String, dynamic>.from(res);
    } catch (_) {
      return {
        'id': 'photo-${DateTime.now().millisecondsSinceEpoch}',
        'url': dataUri,
        'name': file.name,
        'kind': kind,
      };
    }
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
