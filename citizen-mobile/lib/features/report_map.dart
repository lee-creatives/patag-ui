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

  /// Fixed height; null fills the parent (full-screen map).
  final double? height;

  /// Shows the full-screen button.
  final bool expandable;
  const RoadMap(
      {this.reports = const [],
      this.pin,
      this.onPin,
      this.height = 300,
      this.expandable = true,
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

  @override
  void didUpdateWidget(RoadMap old) {
    super.didUpdateWidget(old);
    // Bring a pin set elsewhere (GPS, full-screen picker) into view.
    final pin = widget.pin;
    if (pin != null && pin != old.pin) {
      try {
        if (!controller.camera.visibleBounds.contains(pin)) {
          controller.move(pin, controller.camera.zoom);
        }
      } catch (_) {}
    }
  }

  /// Opens this map full screen. When the map picks a location, the chosen
  /// point is handed back through [RoadMap.onPin].
  Future<void> expand() async {
    final picking = widget.onPin != null;
    final picked = await Navigator.of(context).push<LatLng>(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => FullMapScreen(
            reports: widget.reports, initialPin: widget.pin, picking: picking)));
    if (picked != null && picking) widget.onPin!(picked);
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
        borderRadius: BorderRadius.circular(widget.height == null ? 0 : 18),
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
                  if (widget.expandable) ...[
                    FloatingActionButton.small(
                        heroTag: null,
                        tooltip: 'Full screen map',
                        onPressed: expand,
                        child: const Icon(Icons.fullscreen)),
                    gap(4),
                  ],
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

/// Edge-to-edge map. In [picking] mode it returns the chosen point with
/// "Use this location"; otherwise the citizen can drop a pin and start a
/// report there.
class FullMapScreen extends StatefulWidget {
  final List<PotholeReport> reports;
  final LatLng? initialPin;
  final bool picking;
  const FullMapScreen(
      {this.reports = const [],
      this.initialPin,
      this.picking = false,
      super.key});
  @override
  State<FullMapScreen> createState() => _FullMapScreenState();
}

class _FullMapScreenState extends State<FullMapScreen> {
  LatLng? pin;
  bool locating = false;

  @override
  void initState() {
    super.initState();
    pin = widget.initialPin;
  }

  Future<void> useGps() async {
    setState(() => locating = true);
    try {
      final point = await locate();
      if (mounted) setState(() => pin = point);
    } catch (e) {
      if (mounted) message(context, PatagStore.clean(e));
    }
    if (mounted) setState(() => locating = false);
  }

  void reportHere() {
    final point = pin!;
    if (store.token == null) {
      // Kept until sign-in finishes, then the report form opens with it.
      store.pendingReportPin = point;
      message(context, 'Sign in to report this pothole.');
      Navigator.of(context).pushNamed('/login').then((_) {
        // Backed out without signing in: don't open a report form later.
        if (store.token == null) store.pendingReportPin = null;
      });
      return;
    }
    Navigator.of(context).pushNamed('/report/new', arguments: point);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hint = widget.picking
        ? 'Tap the map to place the pothole pin.'
        : 'Tap a pin for details, or tap the road to report a pothole there.';
    return Scaffold(
      body: SizedBox.expand(
          child: Stack(children: [
        Positioned.fill(
            child: RoadMap(
                reports: widget.reports,
                pin: pin,
                onPin: (point) => setState(() => pin = point),
                height: null,
                expandable: false)),
        Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
                child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 64, 0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FloatingActionButton.small(
                heroTag: null,
                tooltip: 'Close full screen map',
                onPressed: () => Navigator.of(context).pop(),
                child: const Icon(Icons.close)),
            const SizedBox(width: 8),
            Flexible(
                child: Material(
              color: theme.colorScheme.surface.withValues(alpha: .94),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Text(hint, style: const TextStyle(fontSize: 13))),
            )),
          ]),
        ))),
        Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
                child: Padding(
              padding: const EdgeInsets.all(16),
              child: Material(
                elevation: 6,
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    if (pin != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                            'Pin: ${pin!.latitude.toStringAsFixed(5)}, ${pin!.longitude.toStringAsFixed(5)}',
                            style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant)),
                      ),
                    Row(children: [
                      Expanded(
                          child: OutlinedButton.icon(
                              onPressed: locating ? null : useGps,
                              icon: const Icon(Icons.my_location),
                              label: Text(locating ? 'Locating…' : 'My GPS'))),
                      const SizedBox(width: 10),
                      Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                              onPressed: pin == null
                                  ? null
                                  : widget.picking
                                      ? () => Navigator.of(context).pop(pin)
                                      : reportHere,
                              icon: Icon(widget.picking
                                  ? Icons.check
                                  : Icons.add_location_alt_outlined),
                              label: Text(widget.picking
                                  ? 'Use this location'
                                  : 'Report a pothole here'))),
                    ]),
                  ]),
                ),
              ),
            ))),
      ])),
    );
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
