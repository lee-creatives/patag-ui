const reportStatuses = [
  'Submitted',
  'Under Review',
  'Verified',
  'Assigned',
  'In Progress',
  'Resolved',
  'Rejected',
  'Duplicate'
];

class Coordinates {
  final double lat, lng;
  const Coordinates(this.lat, this.lng);

  factory Coordinates.fromJson(Map<String, dynamic> json) => Coordinates(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};
  bool get isValid =>
      lat.isFinite && lng.isFinite && lat.abs() <= 90 && lng.abs() <= 180;
}

class Photo {
  final String id, url, name, kind;
  final bool demo;

  const Photo({
    required this.id,
    required this.url,
    required this.name,
    required this.kind,
    this.demo = false,
  });

  factory Photo.fromJson(Map<String, dynamic> json) => Photo(
        id: json['id'] as String? ?? '',
        url: json['url'] as String? ?? '',
        name: json['name'] as String? ?? '',
        kind: json['kind'] as String? ?? 'before',
        demo: json['demo'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'name': name,
        'kind': kind,
        'demo': demo,
      };
}

class Assignment {
  final String teamId;
  final String priority;
  final String note;
  final String? targetDate;
  final String at;

  const Assignment({
    required this.teamId,
    required this.priority,
    required this.note,
    this.targetDate,
    required this.at,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) => Assignment(
        teamId: json['teamId'] as String? ?? '',
        priority: json['priority'] as String? ?? 'Medium',
        note: json['note'] as String? ?? '',
        targetDate: json['targetDate'] as String?,
        at: json['at'] as String? ?? '',
      );
}

class ProgressUpdate {
  final String at;
  final String note;
  final String phase;
  final List<Photo> photos;

  const ProgressUpdate({
    required this.at,
    required this.note,
    required this.phase,
    required this.photos,
  });

  factory ProgressUpdate.fromJson(Map<String, dynamic> json) => ProgressUpdate(
        at: json['at'] as String? ?? '',
        note: json['note'] as String? ?? '',
        phase: json['phase'] as String? ?? 'Inspection',
        photos: (json['photos'] as List<dynamic>? ?? [])
            .map((p) => Photo.fromJson(Map<String, dynamic>.from(p)))
            .toList(),
      );
}

class Completion {
  final String state;
  final String note;
  final List<Photo> photos;
  final String at;

  const Completion({
    required this.state,
    required this.note,
    required this.photos,
    required this.at,
  });

  factory Completion.fromJson(Map<String, dynamic> json) => Completion(
        state: json['state'] as String? ?? 'Awaiting Verification',
        note: json['note'] as String? ?? '',
        photos: (json['photos'] as List<dynamic>? ?? [])
            .map((p) => Photo.fromJson(Map<String, dynamic>.from(p)))
            .toList(),
        at: json['at'] as String? ?? '',
      );
}

class PotholeReport {
  final Map<String, dynamic> json;
  PotholeReport(this.json);

  String get id => json['id'] as String? ?? '';
  String get title => json['title'] as String? ?? '';
  String get description => json['description'] as String? ?? '';
  String get hazards => json['hazards'] as String? ?? '';
  String get severity => json['severity'] as String? ?? 'Medium';
  String get status => json['status'] as String? ?? 'Submitted';
  String get createdAt => json['createdAt'] as String? ?? '';
  String get updatedAt => json['updatedAt'] as String? ?? '';
  String? get teamId => json['teamId'] as String?;

  String get road => json['location']?['road'] as String? ?? '';
  String get barangay => json['location']?['barangay'] as String? ?? '';
  String get city => json['location']?['city'] as String? ?? '';
  String get province => json['location']?['province'] as String? ?? '';
  String get landmark => json['location']?['landmark'] as String? ?? '';

  Coordinates get coordinates => Coordinates.fromJson(
        Map<String, dynamic>.from(
            json['location']?['coordinates'] ?? {'lat': 14.85, 'lng': 120.81}),
      );

  List<Photo> get photos => (json['photos'] as List<dynamic>? ?? [])
      .map((p) => Photo.fromJson(Map<String, dynamic>.from(p)))
      .toList();

  Assignment? get assignment => json['assignment'] != null
      ? Assignment.fromJson(Map<String, dynamic>.from(json['assignment']))
      : null;

  List<ProgressUpdate> get updates => (json['updates'] as List<dynamic>? ?? [])
      .map((u) => ProgressUpdate.fromJson(Map<String, dynamic>.from(u)))
      .toList();

  Completion? get completion => json['completion'] != null
      ? Completion.fromJson(Map<String, dynamic>.from(json['completion']))
      : null;

  List<dynamic> get history => json['history'] as List<dynamic>? ?? [];

  bool get isAssigned => status == 'Assigned';
  bool get isInProgress => status == 'In Progress';
  bool get isAwaitingVerification =>
      status == 'In Progress' &&
      completion != null &&
      completion!.state == 'Awaiting Verification';
  bool get isResolved => status == 'Resolved';
}

class Team {
  final String id, name;
  final List<String> members;
  final bool active;

  const Team({
    required this.id,
    required this.name,
    required this.members,
    required this.active,
  });

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        members: (json['members'] as List<dynamic>? ?? [])
            .map((m) => m.toString())
            .toList(),
        active: json['active'] as bool? ?? true,
      );
}

class User {
  final String id, name, email, role;
  final String? teamId;
  final bool active;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.teamId,
    required this.active,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: json['role'] as String? ?? 'maintenance',
        teamId: json['teamId'] as String?,
        active: json['active'] as bool? ?? true,
      );
}

class Notice {
  final String id, reportId, title, at;
  final bool read;

  const Notice({
    required this.id,
    required this.reportId,
    required this.title,
    required this.read,
    required this.at,
  });

  factory Notice.fromJson(Map<String, dynamic> json) => Notice(
        id: json['id'] as String? ?? '',
        reportId: json['reportId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        read: json['read'] as bool? ?? false,
        at: json['at'] as String? ?? '',
      );
}
