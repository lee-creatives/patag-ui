import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api.dart';
import '../core/models.dart';
import '../shared/widgets/ui.dart';
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
  int step = 0;
  String severity = 'Medium', error = '';
  bool busy = false, acknowledged = false;
  LatLng? pin;
  List<Map<String, dynamic>> photos = [];
  List<dynamic> duplicates = [];
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
  @override
  void initState() {
    super.initState();
    load();
    for (final c in [
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
    ]) {
      c.addListener(save);
    }
  }

  Future<void> load() async {
    await loadDraft();
    final start = widget.initialPin;
    if (start != null && mounted) {
      setPin(start);
      message(context,
          'Location set from the map. Add a photo, then check the road details.');
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
      if (double.tryParse(lat.text) != null &&
          double.tryParse(lng.text) != null) {
        pin = LatLng(double.parse(lat.text), double.parse(lng.text));
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('patag-draft', jsonEncode(draft));
  }

  @override
  void dispose() {
    for (final c in [
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
    ]) {
      c.removeListener(save);
      c.dispose();
    }
    super.dispose();
  }

  Future<void> pick(bool camera) async {
    setState(() => busy = true);
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
      for (final file in files) {
        final photo = await store.upload(file);
        photos.add(photo);
      }
      await save();
    } catch (e) {
      error = PatagStore.clean(e);
    }
    if (mounted) setState(() => busy = false);
  }

  void setPin(LatLng p) {
    pin = p;
    lat.text = p.latitude.toStringAsFixed(6);
    lng.text = p.longitude.toStringAsFixed(6);
    setState(() {});
  }

  Future<void> next() async {
    setState(() => error = '');
    if (step == 0 && photos.isEmpty) {
      setState(() => error = 'Add at least one evidence photo.');
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
          () => error = 'Tap the map or enter valid latitude and longitude.',
        );
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
            error = PatagStore.clean(e);
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
      setState(() => error = 'Review possible duplicates before submitting.');
      return;
    }
    setState(() => busy = true);
    try {
      final r = await store.call('/reports', body: draft);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('patag-draft');
      await store.refresh();
      if (mounted) {
        Navigator.of(context)
            .pushReplacementNamed('/report/success/${r['id']}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = PatagStore.clean(e);
          busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Screen(
        title: 'I-report ang lubak',
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
                        'Show us the road.',
                        'Pin the exact spot.',
                        'Tell us what you saw.',
                        'Ready to tag it?',
                      ][step],
                    ),
                    gap(10),
                    Text(
                      [
                        'One clear photo helps the LGU inspect your report. Stay in a safe place when taking photos.',
                        'GPS is optional. Tap the map to select or move your pin.',
                        'Your severity estimate helps with review. The LGU will verify the report.',
                        'Check your evidence, location and description before submitting.',
                      ][step],
                      style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    gap(20),
                    if (error.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          error,
                          style: const TextStyle(color: Color(0xFF8C3212)),
                          semanticsLabel: 'Error: $error',
                        ),
                      ),
                    if (step == 0) ...[
                      action(
                        'Take a photo',
                        busy ? null : () => pick(true),
                        icon: Icons.camera_alt_outlined,
                      ),
                      gap(12),
                      OutlinedButton.icon(
                        onPressed: busy ? null : () => pick(false),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Choose from gallery'),
                      ),
                      gap(12),
                      Text(
                        'JPEG, PNG or WebP · maximum 8 MB per image',
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12),
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
                              label: Text('Remove ${p['name']}'),
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
                                  error = PatagStore.clean(e);
                                }
                                if (mounted) setState(() => busy = false);
                              },
                        icon: const Icon(Icons.my_location),
                        label: const Text('Use my GPS location'),
                      ),
                      gap(),
                      RoadMap(pin: pin, onPin: setPin, height: 270),
                      gap(),
                      Row(
                        children: [
                          Expanded(
                            child: field(
                              'Latitude',
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
                              'Longitude',
                              lng,
                              keyboard: const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      field('Road name', road),
                      field('Barangay', barangay),
                      field('Municipality / City', city),
                      field('Province', province),
                      field('Nearby landmark', landmark, required: false),
                    ],
                    if (step == 2) ...[
                      field('Short report title', title, required: false),
                      field('Describe the road damage', description, lines: 4),
                      field('Observed hazards', hazards,
                          lines: 2, required: false),
                      const Text(
                        'Reported severity',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      gap(8),
                      ...['Low', 'Medium', 'High'].map(
                        (s) => RadioListTile<String>(
                          title: Text(s),
                          subtitle: Text(
                            s == 'Low'
                                ? 'Minor surface damage'
                                : s == 'Medium'
                                    ? 'Needs care when passing'
                                    : 'Deep damage or immediate road hazard',
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
                        '${road.text}, Brgy. ${barangay.text}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text('${city.text}, ${province.text}'),
                      Text(
                        '${lat.text}, ${lng.text}',
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12),
                      ),
                      gap(),
                      if (pin != null)
                        RoadMap(pin: pin, height: 180, expandable: false),
                      gap(),
                      StatusChip(severity),
                      gap(),
                      Text(description.text),
                      if (hazards.text.isNotEmpty)
                        Text('Hazards: ${hazards.text}'),
                      if (duplicates.isNotEmpty) ...[
                        gap(),
                        const Text(
                          'Possible duplicate reports',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'These nearby reports may describe the same damage. You can inspect them before continuing.',
                        ),
                        ...duplicates.map(
                          (d) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(d['report']['id']),
                            subtitle: Text(
                              '${d['distance']} m away · ${d['report']['location']['road']}',
                            ),
                            trailing: const Icon(Icons.open_in_new),
                            onTap: () => go(
                                context, '/map/reports/${d['report']['id']}'),
                          ),
                        ),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'I checked these reports and still want to submit.',
                          ),
                          value: acknowledged,
                          onChanged: (v) =>
                              setState(() => acknowledged = v ?? false),
                        ),
                      ],
                      gap(),
                      Text(
                        'Your report starts as Submitted. The LGU reviews the evidence before verification.',
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12),
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
                        child: const Text('Back'),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: action(
                        busy
                            ? 'Please wait…'
                            : step == 3
                                ? 'Submit report'
                                : 'Next',
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
