import 'package:flutter/widgets.dart';
import '../l10n/app_localizations.dart';

/// What went wrong, independent of the display language. The text is chosen
/// when the error is shown, so switching language also changes visible errors.
enum PatagErrorKind {
  serverDown,
  timeout,
  unreachable,
  serverUnavailable,
  unexpectedResponse,
  requestFailed,
  notMaintenance,
  photoTooLarge,
  photoType,

  /// A message sent by the backend (always English).
  server,
}

class PatagException implements Exception {
  const PatagException(this.kind, {this.statusCode, this.serverMessage});

  final PatagErrorKind kind;
  final int? statusCode;
  final String? serverMessage;

  String message(AppLocalizations l) => switch (kind) {
        PatagErrorKind.serverDown => l.errorServerDown,
        PatagErrorKind.timeout => l.errorTimeout,
        PatagErrorKind.unreachable => l.errorUnreachable,
        PatagErrorKind.serverUnavailable =>
          l.errorServerUnavailable(statusCode ?? 0),
        PatagErrorKind.unexpectedResponse =>
          l.errorUnexpectedResponse(statusCode ?? 0),
        PatagErrorKind.requestFailed => l.errorRequestFailed,
        PatagErrorKind.notMaintenance => l.errorNotMaintenance,
        PatagErrorKind.photoTooLarge => l.errorPhotoTooLarge,
        PatagErrorKind.photoType => l.errorPhotoType,
        PatagErrorKind.server => translateServerMessage(l, serverMessage ?? ''),
      };

  /// English text, so logs and `PatagMaintenanceStore.clean` keep working.
  /// Server messages are passed through exactly as received.
  @override
  String toString() =>
      'Exception: ${kind == PatagErrorKind.server ? serverMessage : message(_english)}';
}

final _english = lookupAppLocalizations(const Locale('en'));

/// Messages the backend sends in other words than the app's English text.
final Map<String, String Function(AppLocalizations)> _serverAliases = {
  'Choose a PNG, JPEG or WebP image.': (l) => l.errorPhotoType,
  'Photo must be under 8 MB.': (l) => l.errorPhotoTooLarge,
  'Invalid image or file exceeds 8 MB.': (l) => l.errorPhotoTooLarge,
};

/// Every translated message that the backend sends with the same English text.
final List<String Function(AppLocalizations)> _serverMessages = [
  (l) => l.errorSessionExpired,
  (l) => l.errorBadCredentials,
  (l) => l.errorTooManyAttempts,
  (l) => l.errorPhotoType,
  (l) => l.errorPhotoTooLarge,
  (l) => l.errorPhotoMismatch,
  (l) => l.errorActionNotAllowed,
  (l) => l.errorRepairEvidenceRequired,
  (l) => l.errorBeforePhotosRequired,
  (l) => l.errorProgressNoteRequired,
  (l) => l.errorUploadPhotoFirst,
  (l) => l.errorUploadRealPhotos,
  (l) => l.errorReportNotFound,
  (l) => l.errorPhotoNotFound,
  (l) => l.errorOtherTeam,
  (l) => l.errorDemoUnavailable,
  (l) => l.errorCheckAction,
  (l) => l.errorMaintenanceOnly,
  (l) => l.errorServerGeneric,
  (l) => l.errorInvalidRequest,
  (l) => l.errorRequestFailed,
  (l) => l.errorNotMaintenance,
];

/// Translates a known English backend message; unknown ones are shown as sent.
String translateServerMessage(AppLocalizations l, String message) {
  final text = message.trim();
  final alias = _serverAliases[text];
  if (alias != null) return alias(l);
  for (final pick in _serverMessages) {
    if (pick(_english) == text) return pick(l);
  }
  return text;
}

/// Display text for anything caught from the store or the platform.
String errorText(AppLocalizations l, Object error) {
  if (error is PatagException) return error.message(l);
  return translateServerMessage(
      l, error.toString().replaceFirst('Exception: ', ''));
}
