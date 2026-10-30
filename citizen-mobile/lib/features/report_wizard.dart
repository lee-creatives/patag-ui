import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api.dart';
import '../core/models.dart';
import '../l10n/l10n.dart';
import '../shared/widgets/ui.dart';
import 'address_autofill.dart';
import 'report_map.dart';

class ReportWizard extends StatefulWidget {
  /// Location chosen on the full-screen map; replaces any saved draft location.
  final LatLng? initialPin;
  const ReportWizard({this.initialPin, super.key});
  @override
  State<ReportWizard> createState() => _ReportWizardState();
}

class _ReportWizardState extends State<ReportWizard> {
  final key = GlobalKey<FormState>();
  final road = TextEditingController(),
      barangay = TextEditingController(),
      city = TextEditingController(text: 'Malolos'),
      province = TextEditingController(text: 'Bulacan'),
      landmark = TextEditingController(),
      description = TextEditingController(),
      hazards = TextEditingController(),
      title = TextEditingController(),
      lat = TextEditingController(),
      lng = TextEditingController();
  late final AddressAutofill autofill = AddressAutofill(
    road: road,
    barangay: barangay,
    city: city,
    province: province,
    lookup: (lat, lng) => store.reverseGeocode(lat, lng, language),
    onFilled: save,
  );
  int step = 0;
  String severity = 'Medium';

  /// An error to show above the form: a localized message from [errorText],
  /// or a function of the current strings.
  Object? error;
  bool busy = false, acknowledged = false;
  LatLng? pin;
  List<Map<String, dynamic>> photos = [];
  List<dynamic> duplicates = [];

  /// Language for the address lookup: the app language when known.
  String get language =>
      mounted && Localizations.maybeLocaleOf(context)?.languageCode == 'fil'
          ? 'fil'
          : 'en';

  Map<String, dynamic> get draft => {
        'title': title.text,
        'description': description.text,
        'hazards': hazards.text,
        'severity': severity,
        'photos': photos,
        'location': {
          'road': road.text,
          'barangay': barangay.text,
          'city': city.text,
          'province': province.text,
          'landmark': landmark.text,
          'coordinates': {
            'lat': double.tryParse(lat.text),
            'lng': double.tryParse(lng.text),
          },
        },
      };

  List<TextEditingController> get controllers => [
        road,
        barangay,
        city,
        province,
        landmark,
        description,
        hazards,
        title,
        lat,
        lng,
      ];

  @override
  void initState() {
    super.initState();
    autofill.addListener(_autofillChanged);
    load();
    for (final c in controllers) {
      c.addListener(save);
    }
  }

  void _autofillChanged() {
    if (mounted) setState(() {});
  }

  Future<void> load() async {
    await loadDraft();
    final start = widget.initialPin;
    if (start != null && mounted) {
      setPin(start);
      message(context, l10n(context).wizardPinFromMap);
    }
  }

  Future<void> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('patag-draft');
    if (raw == null) return;
    try {
      final d = jsonDecode(raw);
      title.text = d['title'] ?? '';
      description.text = d['description'] ?? '';
      hazards.text = d['hazards'] ?? '';
      severity = d['severity'] ?? 'Medium';
      photos = (d['photos'] as List)
          .map((p) => Map<String, dynamic>.from(p))
          .toList();
      final loc = d['location'];
      road.text = loc['road'] ?? '';
      barangay.text = loc['barangay'] ?? '';
      city.text = loc['city'] ?? 'Malolos';
      province.text = loc['province'] ?? 'Bulacan';
      landmark.text = loc['landmark'] ?? '';
      lat.text = loc['coordinates']['lat']?.toString() ?? '';
      lng.text = loc['coordinates']['lng']?.toString() ?? '';
      final filled = d['autofilled'];
      if (filled is List) autofill.restore(filled.whereType<String>());
      if (double.tryParse(lat.text) != null &&
          double.tryParse(lng.text) != null) {
        pin = LatLng(double.parse(lat.text), double.parse(lng.text));
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('patag-draft',
        jsonEncode({...draft, 'autofilled': autofill.autoFilled.toList()}));
  }

  @override
  void dispose() {
    autofill.removeListener(_autofillChanged);
    autofill.dispose();
    for (final c in controllers) {
      c.removeListener(save);
      c.dispose();
    }
    super.dispose();
  }

  static const maxPhotos = 10;

  Future<void> pick(bool camera) async {
    if (photos.length >= maxPhotos) {
      setState(
          () => error = (AppLocalizations l) => l.wizardPhotoLimit(maxPhotos));
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final picker = ImagePicker();
      final files = camera
          ? [
              await picker.pickImage(
                source: ImageSource.camera,
                imageQuality: 85,
              ),
            ].whereType<XFile>().toList()
          : await picker.pickMultiImage(imageQuality: 85);
      final room = maxPhotos - photos.length;
      for (final file in files.take(room)) {
        final photo = await store.upload(file);
        photos.add(photo);
      }
      if (files.length > room) {
        error = (AppLocalizations l) => l.wizardPhotoRoom(room, maxPhotos);
      }
      await save();
    } catch (e) {
      error = e;
    }
    if (mounted) setState(() => busy = false);
  }

  void setPin(LatLng p) {
    pin = p;
    lat.text = p.latitude.toStringAsFixed(6);
    lng.text = p.longitude.toStringAsFixed(6);
    autofill.pinMoved(p.latitude, p.longitude);
    setState(() {});
  }

  String? errorMessage(AppLocalizations l) {
    final e = error;
    if (e == null) return null;
    if (e is String Function(AppLocalizations)) return e(l);
    return describeError(l, e);
  }

  Future<void> next() async {
    setState(() => error = null);
    if (step == 0 && photos.isEmpty) {
      setState(() => error = (AppLocalizations l) => l.wizardNeedPhoto);
      return;
    }
    if (!key.currentState!.validate()) return;
    if (step == 1) {
      final c = Coordinates(
        double.tryParse(lat.text) ?? double.nan,
        double.tryParse(lng.text) ?? double.nan,
      );
      if (!c.isValid) {
        setState(
            () => error = (AppLocalizations l) => l.wizardInvalidCoordinates);
        return;
      }
      pin = LatLng(c.lat, c.lng);
    }
    if (step == 2) {
      setState(() => busy = true);
      try {
        duplicates = await store.call('/duplicates', body: draft);
        acknowledged = duplicates.isEmpty;
      } catch (e) {
        if (mounted) {
          setState(() {
            error = e;
            busy = false;
          });
        }
        return;
      }
      if (mounted) setState(() => busy = false);
    }
    if (step < 3) {
      setState(() => step++);
      return;
    }
    if (!acknowledged) {
      setState(() => error = (AppLocalizations l) => l.wizardReviewDuplicates);
      return;
    }
    setState(() => busy = true);
    try {
      final r = await store.call('/reports', body: draft);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('patag-draft');
      // The report exists now; a failed reload must not look like a failed submit.
      unawaited(store.refresh().catchError((Object _) {}));
      if (mounted) {
        Navigator.of(context)
            .pushReplacementNamed('/report/success/${r['id']}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e;
          busy = false;
        });
      }
    }
  }

  /// "Finding address…", "Filled from the map…" or "Couldn't find…" under
  /// the address fields. Never blocks the form.
  Widget autofillNote(AppLocalizations l) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final style = TextStyle(color: muted, fontSize: 12);
    switch (autofill.state) {
      case AutofillState.finding:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(children: [
            SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: muted)),
            const SizedBox(width: 8),
            Expanded(child: Text(l.findingAddress, style: style)),
          ]),
        );
      case AutofillState.filled:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(children: [
            Icon(Icons.auto_fix_high_outlined, size: 16, color: muted),
            const SizedBox(width: 8),
            Expanded(child: Text(l.addressFilledFromMap, style: style)),
          ]),
        );
      case AutofillState.notFound:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(l.addressNotFound, style: style),
        );
      case AutofillState.idle:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = l10n(context);
    final errorText = errorMessage(l);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Screen(
      title: l.brandReportTitle,
      body: Form(
        key: key,
        child: Column(
          children: [
            WizardSteps(step),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  heading(
                    context,
                    [
                      l.wizardHeadingPhoto,
                      l.wizardHeadingLocation,
                      l.wizardHeadingDetails,
                      l.wizardHeadingReview,
                    ][step],
                  ),
                  gap(10),
                  Text(
                    [
                      l.wizardIntroPhoto,
                      l.wizardIntroLocation,
                      l.wizardIntroDetails,
                      l.wizardIntroReview,
                    ][step],
                    style: TextStyle(color: muted),
                  ),
                  gap(20),
                  if (errorText != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        errorText,
                        style: const TextStyle(color: Color(0xFF8C3212)),
                        semanticsLabel: l.errorSemantics(errorText),
                      ),
                    ),
                  if (step == 0) ...[
                    action(
                      l.takePhoto,
                      busy ? null : () => pick(true),
                      icon: Icons.camera_alt_outlined,
                    ),
                    gap(12),
                    OutlinedButton.icon(
                      onPressed: busy ? null : () => pick(false),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(l.chooseFromGallery),
                    ),
                    gap(12),
                    Text(
                      l.photoRequirements,
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                    gap(16),
                    ...photos.map(
                      (p) => Column(
                        children: [
                          Evidence(p),
                          TextButton.icon(
                            onPressed: () => setState(() {
                              photos.remove(p);
                              save();
                            }),
                            icon: const Icon(Icons.close),
                            label: Text(l.removePhoto('${p['name']}')),
                          ),
                        ],
                      ),
                    ),
                    if (busy) const LinearProgressIndicator(),
                  ],
                  if (step == 1) ...[
                    OutlinedButton.icon(
                      onPressed: busy
                          ? null
                          : () async {
                              setState(() => busy = true);
                              try {
                                setPin(await locate());
                              } catch (e) {
                                error = e;
                              }
                              if (mounted) setState(() => busy = false);
                            },
                      icon: const Icon(Icons.my_location),
                      label: Text(l.useMyGps),
                    ),
                    gap(),
                    RoadMap(pin: pin, onPin: setPin, height: 270),
                    gap(),
                    Row(
                      children: [
                        Expanded(
                          child: field(
                            l.latitude,
                            lat,
                            keyboard: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: field(
                            l.longitude,
                            lng,
                            keyboard: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    field(l.roadName, road, maxLength: 120),
                    field(l.barangay, barangay, maxLength: 120),
                    field(l.municipalityCity, city, maxLength: 120),
                    field(l.province, province, maxLength: 120),
                    autofillNote(l),
                    field(l.nearbyLandmark, landmark,
                        required: false, maxLength: 200),
                  ],
                  if (step == 2) ...[
                    field(l.reportTitleField, title,
                        required: false, maxLength: 120),
                    field(l.describeDamage, description,
                        lines: 4, maxLength: 2000),
                    field(l.observedHazards, hazards,
                        lines: 2, required: false),
                    Text(
                      l.reportedSeverity,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    gap(8),
                    ...['Low', 'Medium', 'High'].map(
                      (s) => RadioListTile<String>(
                        title: Text(apiValueLabel(l, s)),
                        subtitle: Text(
                          s == 'Low'
                              ? l.severityLowHint
                              : s == 'Medium'
                                  ? l.severityMediumHint
                                  : l.severityHighHint,
                        ),
                        value: s,
                        groupValue: severity,
                        onChanged: (v) => setState(() {
                          severity = v!;
                          save();
                        }),
                      ),
                    ),
                  ],
                  if (step == 3) ...[
                    ...photos.map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Evidence(p),
                      ),
                    ),
                    gap(),
                    Text(
                      l.reviewAddress(road.text, barangay.text),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text('${city.text}, ${province.text}'),
                    Text(
                      '${lat.text}, ${lng.text}',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                    gap(),
                    if (pin != null)
                      RoadMap(pin: pin, height: 180, expandable: false),
                    gap(),
                    StatusChip(severity),
                    gap(),
                    Text(description.text),
                    if (hazards.text.isNotEmpty)
                      Text(l.hazardsLine(hazards.text)),
                    if (duplicates.isNotEmpty) ...[
                      gap(),
                      Text(
                        l.possibleDuplicates,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(l.possibleDuplicatesHint),
                      ...duplicates.map(
                        (d) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(d['report']['id']),
                          subtitle: Text(
                            l.duplicateDistance('${d['distance']}',
                                '${d['report']['location']['road']}'),
                          ),
                          trailing: const Icon(Icons.open_in_new),
                          onTap: () =>
                              go(context, '/map/reports/${d['report']['id']}'),
                        ),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l.duplicatesAcknowledge),
                        value: acknowledged,
                        onChanged: (v) =>
                            setState(() => acknowledged = v ?? false),
                      ),
                    ],
                    gap(),
                    Text(
                      l.wizardStartsSubmitted,
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              color: Theme.of(context).colorScheme.surface,
              child: Row(
                children: [
                  if (step > 0) ...[
                    OutlinedButton(
                      onPressed: busy ? null : () => setState(() => step--),
                      child: Text(l.back),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: action(
                      busy
                          ? l.pleaseWait
                          : step == 3
                              ? l.submitReport
                              : l.next,
                      busy ? null : next,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
