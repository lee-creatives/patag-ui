import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import '../app/locale.dart';
import 'app_localizations.dart';

export '../core/errors.dart' show errorText, translateServerMessage;
export 'app_localizations.dart';

extension AppLocalizationsContext on BuildContext {
  /// Strings for the current language. Falls back to the chosen app language
  /// when a widget is shown outside a localized app (e.g. a bare test).
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ??
      lookupAppLocalizations(localeController.locale);
}

/// Display text for a report status or completion state. The API values
/// themselves (e.g. 'In Progress', 'Awaiting Verification') never change.
String statusLabel(AppLocalizations l, String status) => switch (status) {
      'Submitted' => l.statusSubmitted,
      'Under Review' => l.statusUnderReview,
      'Verified' => l.statusVerified,
      'Assigned' => l.statusAssigned,
      'In Progress' => l.statusInProgress,
      'Resolved' => l.statusResolved,
      'Rejected' => l.statusRejected,
      'Duplicate' => l.statusDuplicate,
      'Awaiting Verification' => l.statusAwaitingVerification,
      'Additional Work Requested' => l.statusAdditionalWorkRequested,
      _ => status,
    };

/// Display text for a severity or priority value (Low / Medium / High).
String severityLabel(AppLocalizations l, String severity) =>
    switch (severity.toLowerCase()) {
      'low' => l.severityLow,
      'medium' => l.severityMedium,
      'high' => l.severityHigh,
      _ => severity,
    };

/// A date from the API (ISO 8601 or yyyy-MM-dd) in the app language, e.g.
/// "Oct 30, 2026" / "Okt 30, 2026". Unparseable values are shown unchanged.
String formatDate(AppLocalizations l, String value, {bool withTime = false}) {
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  try {
    final format = withTime
        ? DateFormat.yMMMd(l.localeName).add_jm()
        : DateFormat.yMMMd(l.localeName);
    return format.format(date.isUtc ? date.toLocal() : date);
  } catch (_) {
    // Date symbols are loaded by the localization delegates; without them
    // (a bare widget test) keep the raw value.
    return value;
  }
}
