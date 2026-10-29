import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'models.dart';
import 'package:shared_preferences/shared_preferences.dart';
class PatagStore extends ChangeNotifier {
  static const baseUrl = String.fromEnvironment('API_URL');
  String? token;
  Map<String, dynamic>? user;
  List<PotholeReport> reports = [], publicReports = [];
  List<dynamic> notifications = [];
  Timer? timer;
  String? networkError;
  bool showUnread = true;
  void setUnreadPreference(bool value) {
    showUnread=value;
    notifyListeners();
  }
  Future<dynamic> call(String path, {
    Map<String, dynamic>? body, String? method
  }
  ) async {
    if (baseUrl.isEmpty) throw Exception('Configure API_URL for the shared PostgreSQL mobile API.');
    final uri = Uri.parse('$baseUrl$path');
    final headers = {
      'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token'
    }
    ;
    http.Response response;
    try {
      response = await (method == 'PATCH' ? http.patch(uri, headers: headers, body: jsonEncode(body)) : body == null ? http.get(uri,
      headers: headers) : http.post(uri, headers: headers, body: jsonEncode(body))).timeout(const Duration(seconds: 20));
    }
    on TimeoutException {
      throw Exception('Connection timed out. Your draft is saved. Please retry.');
    }
    catch (_) {
      throw Exception('Cannot reach PATAG. Check the local API and your connection. Your draft is saved.');
    }
    final data = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      if (response.statusCode == 401) {
        token = null;
        user=null; reports=[]; notifications=[];
        timer?.cancel();
        notifyListeners();
      }
      throw Exception(data['error'] ?? 'Please try again.');
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
    await refresh();
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 8), (_) {
      refresh().catchError((Object _) {
      }
      );
    }
    );
  }
  Future<void> refresh() async {
    try {
      if (token != null) {
        final data = await call('/bootstrap');
        reports = (data['reports'] as List).map((r) => PotholeReport(Map<String,dynamic>.from(r))).toList();
        notifications = data['notifications'];
        user=Map<String,dynamic>.from(data['user']);
      }
      publicReports = (await call('/public/reports') as List).map((r) => PotholeReport(Map<String,dynamic>.from(r))).toList();
      networkError = null;
      notifyListeners();
    }
    catch (e) {
      networkError = clean(e);
      notifyListeners();
      rethrow;
    }
  }
  Future<Map<String,dynamic>> upload(XFile file) async {
    final bytes=await file.readAsBytes();
    if(bytes.length > 8*1024*1024) {
      throw Exception('Choose a photo under 8 MB.');
    }
    final name=file.name.toLowerCase();
    final type=name.endsWith('.png')?'png':name.endsWith('.webp')?'webp':(name.endsWith('.jpg')||name.endsWith('.jpeg'))?'jpeg':null;
    if(type==null) {
      throw Exception('Choose a JPEG, PNG or WebP photo.');
    }
    return Map<String,dynamic>.from(await call('/uploads',body:{
      'data':'data:image/$type;base64,${base64Encode(bytes)}','name':file.name,'kind':'before'
    }
    ));
  }
  String photoUrl(String path) => '${baseUrl.replaceFirst(RegExp(r'/api$'), '')}/api$path';
  Future<void> logout() async {
    try {
      await call('/auth/logout',body:{
      }
      );
    }
    catch (_) {
    }
    final preferences=await SharedPreferences.getInstance();
    await preferences.remove('patag-draft');
    token=null;
    user=null;
    reports=[];
    notifications=[];
    timer?.cancel();
    notifyListeners();
  }
  static String clean(Object e)=>e.toString().replaceFirst('Exception: ', '');
  @override void dispose(){
    timer?.cancel();
    super.dispose();
  }
}
final store=PatagStore();
