import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';

/// English strings, used where no [BuildContext] is available (for example
/// [PatagException.toString]) and as the fallback when a widget is shown
/// without the localization delegates.
final AppLocalizations englishL10n = lookupAppLocalizations(const Locale('en'));

enum PatagErrorKind {
  timeout,
  unreachable,
  serverDown,
  unexpectedResponse,
  server,
  citizenOnly,
  photoTooLarge,
  photoType,
  gpsOff,
  locationDenied,
}

/// An error the citizen sees. The text is chosen at display time with
/// [describeError], so it follows the current app language.
class PatagException implements Exception {
  final PatagErrorKind kind;

  /// The server's own (English) message for [PatagErrorKind.server].
  final String? serverMessage;

  /// HTTP status for [PatagErrorKind.serverDown] and
  /// [PatagErrorKind.unexpectedResponse].
  final int? status;

  const PatagException(this.kind, {this.serverMessage, this.status});

  /// English text, kept for logs and callers that only need a string.
  @override
  String toString() => kind == PatagErrorKind.server
      ? (serverMessage ?? englishL10n.errTryAgain)
      : describeError(englishL10n, this);
}

/// The text to show for [error] in the language of [l].
String describeError(AppLocalizations l, Object error) {
  if (error is PatagException) {
    switch (error.kind) {
      case PatagErrorKind.timeout:
        return l.errTimeout;
      case PatagErrorKind.unreachable:
        return l.errUnreachable;
      case PatagErrorKind.serverDown:
        return l.errServerDown(error.status ?? 500);
      case PatagErrorKind.unexpectedResponse:
        return l.errUnexpected(error.status ?? 0);
      case PatagErrorKind.citizenOnly:
        return l.errCitizenOnly;
      case PatagErrorKind.photoTooLarge:
        return l.errPhotoTooLarge;
      case PatagErrorKind.photoType:
        return l.errPhotoType;
      case PatagErrorKind.gpsOff:
        return l.errGpsOff;
      case PatagErrorKind.locationDenied:
        return l.errLocationDenied;
      case PatagErrorKind.server:
        return translateServerMessage(l, error.serverMessage ?? '');
    }
  }
  return translateServerMessage(
      l, error.toString().replaceFirst('Exception: ', ''));
}

/// The backend answers in English. Common messages are translated; anything
/// else is shown as the server wrote it.
String translateServerMessage(AppLocalizations l, String message) {
  final text = message.trim();
  if (text.isEmpty) return l.errTryAgain;
  final known = <String, String Function()>{
    'Session expired. Sign in again.': () => l.errSessionExpired,
    'Email or password is incorrect for this portal.': () => l.errWrongPassword,
    'Please try again.': () => l.errTryAgain,
    'Use a citizen account in this app.': () => l.errCitizenOnly,
    'Choose a photo under 8 MB.': () => l.errPhotoTooLarge,
    'Invalid image or file exceeds 8 MB.': () => l.errPhotoTooLarge,
    'Choose a JPEG, PNG or WebP photo.': () => l.errPhotoType,
    'Choose a PNG, JPEG or WebP image.': () => l.errPhotoType,
    'Image content does not match its type.': () => l.errPhotoMismatch,
    'Unable to create an account with these details. Try signing in or recovering access.':
        () => l.errAccountUnavailable,
    'Email is already registered.': () => l.errEmailRegistered,
    'Enter a valid email address.': () => l.invalidEmail,
    'Enter a valid email.': () => l.invalidEmail,
    'Choose a rating and add feedback.': () => l.feedbackIncomplete,
    'Feedback is available once for resolved reports.': () => l.errFeedbackOnce,
    'Report not found.': () => l.reportNotFound,
    'Evidence photo, description, road, barangay, city, province, valid coordinates and severity are required.':
        () => l.errReportIncomplete,
    'Enter your barangay, city or municipality, and province.': () =>
        l.errAddressRequired,
    'Password must be at least 8 characters and include lowercase, uppercase, number, and special character.':
        () => l.passwordRule,
    'Email changes require verified account recovery.': () => l.emailChangeNote,
    "Can't reach the PATAG server. Is the backend running?": () =>
        l.serverUnreachable,
  };
  final exact = known[text];
  if (exact != null) return exact();
  final lower = text.toLowerCase();
  if (lower.startsWith('too many address lookups')) return l.errTooManyLookups;
  if (lower.startsWith('too many')) return l.errTooManyAttempts;
  if (lower.contains('session expired')) return l.errSessionExpired;
  if (lower.contains('too large') || lower.contains('exceeds 8 mb')) {
    return l.errPhotoTooLarge;
  }
  return text;
}
