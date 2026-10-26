import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../app/theme.dart';
import '../core/api.dart';
import '../core/models.dart';
import '../shared/widgets/ui.dart';

class TaskMapScreen extends StatefulWidget {
  final String? initialReportId;
  const TaskMapScreen({super.key, this.initialReportId});

  @override
  State<TaskMapScreen> createState() => _TaskMapScreenState();
}

class _TaskMapScreenState extends State<TaskMapScreen> {
  final MapController _mapController = MapController();
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final allReports = store.myAssignments;

    final filtered = allReports.where((r) {
      if (_filter == 'Assigned') return r.status == 'Assigned';
      if (_filter == 'In Progress') return r.status == 'In Progress';
      if (_filter == 'High') return r.severity == 'High';
      return true;
    }).toList();

    final center = filtered.isNotEmpty && filtered.first.coordinates.isValid
        ? LatLng(filtered.first.coordinates.lat, filtered.first.coordinates.lng)
        : const LatLng(14.855, 120.815);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assigned Task Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => store.refresh(),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 14.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'ph.patag.maintenance',
              ),
              MarkerLayer(
                markers: filtered.map((report) {
                  final c = report.coordinates;
                  final latLng = LatLng(c.lat, c.lng);
                  Color markerColor = crewAmber;
                  if (report.status == 'In Progress') {
                    markerColor = orange;
                  } else if (report.status == 'Resolved') {
                    markerColor = crewGreen;
                  }

                  return Marker(
                    point: latLng,
                    width: 44,
                    height: 44,
                    child: GestureDetector(
                      onTap: () => _showTaskBottomSheet(context, report),
                      child: Container(
                        decoration: BoxDecoration(
                          color: markerColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.handyman_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'In Progress', 'Assigned', 'High'].map((f) {
                  final isSelected = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _filter = f);
                      },
                      selectedColor: orange,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : (dark ? Colors.white70 : ink),
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 24,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: dark ? const Color(0xFF22242A) : Colors.white,
              foregroundColor: orange,
              onPressed: () {
                _mapController.move(center, 14.0);
              },
              child: const Icon(Icons.my_location_rounded),
            ),
          ),
        ],
      ),
    );
  }

  void _showTaskBottomSheet(BuildContext context, PotholeReport report) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatusBadge(report.status),
                SeverityBadge(report.severity),
              ],
            ),
            gap(12),
            Text(
              report.road.isNotEmpty ? report.road : 'Road Work Order',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            gap(4),
            Text(
              'Brgy. ${report.barangay}, ${report.city} · ${report.id}',
              style: const TextStyle(fontSize: 13, color: slate),
            ),
            if (report.description.isNotEmpty) ...[
              gap(8),
              Text(
                report.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ],
            gap(18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Open Task Details'),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pushNamed('/assignments/${report.id}');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
