import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../app/theme.dart';
import '../core/api.dart';
import '../core/models.dart';
import '../shared/widgets/ui.dart';

Future<LatLng> locate() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw Exception('GPS is off. Turn it on or tap the map to pin manually.');
  }
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw Exception(
        'Location permission denied. Tap the map to choose a location, or enable location in Android settings.');
  }
  final position = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)),
  );
  return LatLng(position.latitude, position.longitude);
}

class RoadMap extends StatefulWidget {
  final List<PotholeReport> reports;
  final LatLng? pin;
  final ValueChanged<LatLng>? onPin;
  final double height;
  const RoadMap(
      {this.reports = const [],
      this.pin,
      this.onPin,
      this.height = 300,
      super.key});
  @override
  State<RoadMap> createState() => _RoadMapState();
}

class _RoadMapState extends State<RoadMap> {
  final controller = MapController();
  bool tileError = false;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void openReport(PotholeReport report) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
          child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heading(sheetContext, report.road),
              gap(10),
              Text('Brgy. ${report.barangay}'),
              gap(12),
              StatusChip(report.status),
              gap(16),
              action('View public report', () {
                Navigator.pop(sheetContext);
                go(context, '/map/reports/${report.id}');
              }),
            ]),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: widget.height,
          child: Stack(children: [
            FlutterMap(
              mapController: controller,
              options: MapOptions(
                initialCenter: widget.pin ?? const LatLng(14.855, 120.815),
                initialZoom: 14,
                onTap: widget.onPin == null
                    ? null
                    : (_, point) => widget.onPin!(point),
                onLongPress: widget.onPin == null
                    ? null
                    : (_, point) => widget.onPin!(point),
              ),
              children: [
                ColorFiltered(
                    colorFilter: Theme.of(context).brightness == Brightness.dark
                        ? const ColorFilter.matrix([
                            -0.72,
                            0,
                            0,
                            0,
                            210,
                            0,
                            -0.72,
                            0,
                            0,
                            214,
                            0,
                            0,
                            -0.72,
                            0,
                            220,
                            0,
                            0,
                            0,
                            1,
                            0
                          ])
                        : const ColorFilter.mode(
                            Colors.transparent, BlendMode.srcOver),
                    child: TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'ph.patag.citizen',
                        errorTileCallback: (tile, error, stack) {
                          if (mounted && !tileError) {
                            setState(() => tileError = true);
                          }
                        })),
                MarkerLayer(markers: [
                  if (widget.pin != null)
                    Marker(
                        point: widget.pin!,
                        width: 44,
                        height: 44,
                        child: const Icon(Icons.location_pin,
                            color: orange, size: 44)),
                  ...widget.reports.map((report) => Marker(
                        point: LatLng(
                            report.coordinates.lat, report.coordinates.lng),
                        width: 44,
                        height: 44,
                        child: IconButton(
                            tooltip: '${report.road}: ${report.status}',
                            icon: Icon(Icons.location_pin,
                                color: report.status == 'Resolved'
                                    ? const Color(0xFF247B50)
                                    : ink,
                                size: 36),
                            onPressed: () => openReport(report)),
                      )),
                ]),
                const RichAttributionWidget(attributions: [
                  TextSourceAttribution('OpenStreetMap contributors')
                ]),
              ],
            ),
            Positioned(
                top: 10,
                right: 10,
                child: Column(children: [
                  FloatingActionButton.small(
                      heroTag: null,
                      tooltip: 'Zoom in',
                      onPressed: () => controller.move(
                          controller.camera.center, controller.camera.zoom + 1),
                      child: const Icon(Icons.add)),
                  gap(4),
                  FloatingActionButton.small(
                      heroTag: null,
                      tooltip: 'Zoom out',
                      onPressed: () => controller.move(
                          controller.camera.center, controller.camera.zoom - 1),
                      child: const Icon(Icons.remove)),
                  gap(4),
                  FloatingActionButton.small(
                      heroTag: null,
                      tooltip: 'Recenter map',
                      onPressed: () => controller.move(
                          widget.pin ?? const LatLng(14.855, 120.815), 14),
                      child: const Icon(Icons.my_location)),
                ])),
            if (tileError)
              Positioned(
                  bottom: 24,
                  left: 8,
                  right: 8,
                  child: ColoredBox(
                      color: Theme.of(context).colorScheme.surface,
                      child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Text(
                              'Map tiles unavailable. Enter coordinates or use the report list.',
                              style: TextStyle(fontSize: 11))))),
          ]),
        ));
  }
}

class PublicMap extends StatefulWidget {
  const PublicMap({super.key});
  @override
  State<PublicMap> createState() => _PublicMapState();
}

class _PublicMapState extends State<PublicMap> {
  String severity = 'All', status = 'All';
  bool list = false;
  LatLng? gps;
  @override
  void initState() {
    super.initState();
    store.refresh().catchError((Object _) {});
  }

  @override
  Widget build(BuildContext context) {
    final reports = store.publicReports
        .where((report) =>
            (severity == 'All' || severity == report.severity) &&
            (status == 'All' || status == report.status))
        .toList();
    return Screen(
      title: 'Community pothole map',
      selected: 1,
      body: ListView(padding: const EdgeInsets.all(20), children: [
        heading(context, 'Know the road ahead.'),
        gap(8),
        Text('Fictional demonstration reports · Malolos, Bulacan',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12)),
        gap(20),
        Wrap(spacing: 12, runSpacing: 12, children: [
          DropdownButton<String>(
              value: severity,
              items: ['All', 'High', 'Medium', 'Low']
                  .map((s) => DropdownMenuItem(
                      value: s, child: Text(s == 'All' ? 'All severities' : s)))
                  .toList(),
              onChanged: (s) => setState(() => severity = s!)),
          DropdownButton<String>(
              value: status,
              items: ['All', ...reportStatuses]
                  .map((s) => DropdownMenuItem(
                      value: s, child: Text(s == 'All' ? 'All statuses' : s)))
                  .toList(),
              onChanged: (s) => setState(() => status = s!)),
          IconButton(
              tooltip: list ? 'Show map' : 'Show list',
              onPressed: () => setState(() => list = !list),
              icon: Icon(list ? Icons.map_outlined : Icons.list)),
        ]),
        gap(12),
        if (!list)
          RoadMap(key: ValueKey(gps), reports: reports, pin: gps, height: 420),
        gap(16),
        const Text('Community reports',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        gap(12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final s in ['All', ...reportStatuses])
            ChoiceChip(
                label: Text(s),
                selected: status == s,
                onSelected: (_) => setState(() => status = s)),
        ]),
        gap(16),
        if (reports.isEmpty)
          const EmptyState('No reports nearby', 'Try a different filter.'),
        if (list) ...reports.map((report) => ReportCard(report, public: true)),
        if (!list) Text('${reports.length} reports · Tap a pin for details.'),
        gap(),
        OutlinedButton.icon(
            icon: const Icon(Icons.my_location),
            label: const Text('Use current GPS location'),
            onPressed: () async {
              try {
                final point = await locate();
                if (mounted) setState(() => gps = point);
              } catch (error) {
                if (context.mounted) message(context, PatagStore.clean(error));
              }
            }),
      ]),
    );
  }
}
