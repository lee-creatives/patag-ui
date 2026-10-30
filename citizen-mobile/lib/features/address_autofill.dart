import 'dart:async';

import 'package:flutter/widgets.dart';

/// Looks up road, barangay, city and province for a point. Unknown parts are
/// empty strings; a failed lookup may throw or return all parts empty.
typedef AddressLookup = Future<Map<String, String>> Function(
    double lat, double lng);

enum AutofillState { idle, finding, filled, notFound }

/// Fills the report's address fields from the map pin.
///
/// - Lookups wait [delay] after the last pin move, so dragging or tapping
///   around sends one request.
/// - Only fields that are empty, still hold their untouched default, or were
///   filled by an earlier lookup are written. Text the citizen typed or
///   edited is never overwritten.
/// - A response for an older pin is ignored.
class AddressAutofill extends ChangeNotifier {
  static const parts = ['road', 'barangay', 'city', 'province'];

  final Map<String, TextEditingController> fields;
  final Map<String, String> defaults;
  final AddressLookup lookup;
  final Duration delay;

  /// Called after fields were filled (e.g. to save the draft).
  final VoidCallback? onFilled;

  AddressAutofill({
    required TextEditingController road,
    required TextEditingController barangay,
    required TextEditingController city,
    required TextEditingController province,
    required this.lookup,
    this.defaults = const {'city': 'Malolos', 'province': 'Bulacan'},
    this.delay = const Duration(milliseconds: 600),
    this.onFilled,
  }) : fields = {
          'road': road,
          'barangay': barangay,
          'city': city,
          'province': province,
        } {
    for (final entry in fields.entries) {
      _seen[entry.key] = entry.value.text;
      void listener() => _onEdited(entry.key);
      _listeners[entry.key] = listener;
      entry.value.addListener(listener);
    }
  }

  final Set<String> _autoFilled = {}, _userOwned = {};
  final Map<String, String> _seen = {};
  final Map<String, VoidCallback> _listeners = {};
  Timer? _timer;
  int _sequence = 0;
  bool _writing = false, _disposed = false;

  AutofillState state = AutofillState.idle;

  /// Fields whose current text came from a lookup.
  Set<String> get autoFilled => Set.unmodifiable(_autoFilled);

  /// Fields the citizen typed or edited.
  Set<String> get userOwned => Set.unmodifiable(_userOwned);

  bool get finding => state == AutofillState.finding;

  /// Restores which fields were auto-filled (from a saved draft). Call after
  /// the draft text has been put into the controllers.
  void restore(Iterable<String> autoFilledParts) {
    for (final part in autoFilledParts) {
      final controller = fields[part];
      if (controller == null || controller.text.isEmpty) continue;
      _userOwned.remove(part);
      _autoFilled.add(part);
    }
  }

  /// Whether a lookup may write [part].
  bool canFill(String part) {
    final text = fields[part]!.text;
    if (_userOwned.contains(part)) return false;
    return text.trim().isEmpty ||
        _autoFilled.contains(part) ||
        text == defaults[part];
  }

  void _onEdited(String part) {
    final text = fields[part]!.text;
    // Listeners also fire for cursor and selection changes.
    if (text == _seen[part]) return;
    _seen[part] = text;
    if (_writing) return;
    _autoFilled.remove(part);
    if (text.trim().isEmpty || text == defaults[part]) {
      _userOwned.remove(part);
    } else {
      _userOwned.add(part);
    }
  }

  /// Schedules a lookup for a new pin. Earlier pending or running lookups
  /// are superseded.
  void pinMoved(double lat, double lng) {
    if (_disposed) return;
    _timer?.cancel();
    final sequence = ++_sequence;
    state = AutofillState.finding;
    notifyListeners();
    _timer = Timer(delay, () => _run(sequence, lat, lng));
  }

  Future<void> _run(int sequence, double lat, double lng) async {
    Map<String, String> result;
    try {
      result = await lookup(lat, lng);
    } catch (_) {
      result = const {};
    }
    if (_disposed || sequence != _sequence) return;
    var filledAny = false, foundAny = false;
    _writing = true;
    try {
      for (final part in parts) {
        final value = (result[part] ?? '').trim();
        if (value.isEmpty) continue;
        foundAny = true;
        if (!canFill(part)) continue;
        final controller = fields[part]!;
        if (controller.text != value) controller.text = value;
        _seen[part] = controller.text;
        _autoFilled.add(part);
        filledAny = true;
      }
    } finally {
      _writing = false;
    }
    state = !foundAny
        ? AutofillState.notFound
        : _autoFilled.isNotEmpty
            ? AutofillState.filled
            : AutofillState.idle;
    notifyListeners();
    if (filledAny) onFilled?.call();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    for (final entry in _listeners.entries) {
      fields[entry.key]!.removeListener(entry.value);
    }
    super.dispose();
  }
}
