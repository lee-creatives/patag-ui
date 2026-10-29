import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PatagStore extends ChangeNotifier {
  static const baseUrl = String.fromEnvironment('API_URL',
      defaultValue: 'http://10.0.2.2:4100/api');
  String? token;
  Map<String, dynamic>? user;
  List<PotholeReport> reports = [], publicReports = [];
  List<dynamic> notifications = [];
  Timer? timer;
  String? networkError;
  bool showUnread = true;

  /// Replaceable in tests.
  http.Client client = http.Client();

  /// Called after the server rejects the session (401), e.g. to open sign-in.
  VoidCallback? onSessionExpired;

  /// Result of the last GET /health; null while reachable or not yet checked.
  String? serverProblem;
  bool checkingServer = false;
  int _serverCheck = 0;

  /// Checks that the backend answers. Waits up to 60 s so a hosted server
  /// that went to sleep has time to wake up. Only the newest check may
  /// update the result when several screens check at once.
  Future<bool> checkServer() async {
    final check = ++_serverCheck;
    checkingServer = true;
    serverProblem = null;
    notifyListeners();
    var ok = false;
    try {
      final response = await client
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 60));
      ok = response.statusCode == 200;
    } catch (_) {
      ok = false;
    }
    if (check == _serverCheck) {
      checkingServer = false;
      serverProblem =
          ok ? null : "Can't reach the PATAG server. Is the backend running?";
      notifyListeners();
    }
    return ok;
  }

  /// A spot chosen on the full-screen map before signing in; the report form
  /// opens with it once the citizen is signed in.
  LatLng? pendingReportPin;
  LatLng? takePendingReportPin() {
    final pin = pendingReportPin;
    pendingReportPin = null;
    return pin;
  }

  void setUnreadPreference(bool value) {
    showUnread = value;
    notifyListeners();
  }

  Future<dynamic> call(String path,
      {Map<String, dynamic>? body, String? method}) async {
    final uri = Uri.parse('$baseUrl$path');
    final sentWith = token;
    final headers = {
      'Content-Type': 'application/json',
      if (sentWith != null) 'Authorization': 'Bearer $sentWith'
    };
    http.Response response;
    try {
      response = await (method == 'PATCH'
              ? client.patch(uri, headers: headers, body: jsonEncode(body))
              : body == null
                  ? client.get(uri, headers: headers)
                  : client.post(uri, headers: headers, body: jsonEncode(body)))
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw Exception('Connection timed out. Your draft is saved. Please retry.');
    } catch (_) {
      throw Exception(
          'Cannot reach PATAG. Check the local API and your connection. Your draft is saved.');
    }
    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {
      // e.g. an HTML 502 page while a hosted server is starting.
      throw Exception(response.statusCode >= 500
          ? 'The PATAG server is unavailable (${response.statusCode}). Please retry in a moment.'
          : 'Unexpected response from the PATAG server (${response.statusCode}).');
    }
    if (response.statusCode >= 400) {
      // Only expire the session this request was made with (not a newer login).
      if (response.statusCode == 401 && sentWith != null && sentWith == token) {
        await _clearSession();
        onSessionExpired?.call();
      }
      throw Exception(
          (data is Map ? data['error'] : null) ?? 'Please try again.');
    }
    return data;
  }

  Future<void> authenticate(String path, Map<String, dynamic> body) async {
    final data = await call(path, body: body);
    if (data['user']['role'] != 'citizen') {
      throw Exception('Use a citizen account in this app.');
    }
    token = data['token'];
    user = Map<String, dynamic>.from(data['user']);
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 8), (_) {
      refresh().catchError((Object _) {});
    });
    // Signed in either way: a failed first load is shown as networkError and
    // retried by polling, instead of reporting the sign-in itself as failed.
    await refresh().catchError((Object _) {});
  }

  bool _refreshing = false;
  Future<void> refresh() async {
    if (_refreshing) return; // a slow poll is still running
    _refreshing = true;
    final sessionToken = token;
    try {
      Map<String, dynamic>? data;
      if (sessionToken != null) {
        data = Map<String, dynamic>.from(await call('/bootstrap'));
      }
      final public = (await call('/public/reports') as List)
          .map((r) => PotholeReport(Map<String, dynamic>.from(r)))
          .toList();
      // Signed out or switched accounts while waiting: drop the old answer.
      if (token != sessionToken) return;
      if (data != null) {
        reports = (data['reports'] as List)
            .map((r) => PotholeReport(Map<String, dynamic>.from(r)))
            .toList();
        notifications = data['notifications'];
        user = Map<String, dynamic>.from(data['user']);
      }
      publicReports = public;
      networkError = null;
      notifyListeners();
    } catch (e) {
      if (token == sessionToken) {
        networkError = clean(e);
        notifyListeners();
      }
      rethrow;
    } finally {
      _refreshing = false;
    }
  }

  Future<Map<String, dynamic>> upload(XFile file) async {
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
    return Map<String, dynamic>.from(await call('/uploads', body: {
      'data': 'data:image/$type;base64,${base64Encode(bytes)}',
      'name': file.name,
      'kind': 'before'
    }));
  }

  String photoUrl(String path) =>
      '${baseUrl.replaceFirst(RegExp(r'/api$'), '')}/api$path';

  /// Forgets everything tied to the signed-in account, including the report
  /// draft (its photos belong to this account) and any pending map pin.
  Future<void> _clearSession() async {
    token = null;
    user = null;
    reports = [];
    notifications = [];
    pendingReportPin = null;
    timer?.cancel();
    notifyListeners();
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove('patag-draft');
    } catch (_) {}
  }

  Future<void> logout() async {
    try {
      await call('/auth/logout', body: {});
    } catch (_) {}
    await _clearSession();
  }

  static String clean(Object e) => e.toString().replaceFirst('Exception: ', '');
  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}

final store = PatagStore();
