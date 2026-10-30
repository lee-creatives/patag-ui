import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../core/errors.dart';
import 'app_localizations.dart';

export '../core/errors.dart' show englishL10n, describeError;
export 'app_localizations.dart';

/// The strings for the current app language. Falls back to English when a
/// widget is shown without the localization delegates (e.g. in small tests).
AppLocalizations l10n(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations) ??
    englishL10n;

extension L10nContext on BuildContext {
  /// Shorthand for [l10n].
  AppLocalizations get l => l10n(this);
}

/// Error text for [error] (an exception or a server message) in the current
/// app language.
String errorText(BuildContext context, Object error) =>
    describeError(l10n(context), error);

/// Display text for an English API value (report status or severity). The
/// API values themselves always stay English.
String apiValueLabel(AppLocalizations l, String value) => switch (value) {
      'Submitted' => l.statusSubmitted,
      'Under Review' => l.statusUnderReview,
      'Verified' => l.statusVerified,
      'Assigned' => l.statusAssigned,
      'In Progress' => l.statusInProgress,
      'Resolved' => l.statusResolved,
      'Rejected' => l.statusRejected,
      'Duplicate' => l.statusDuplicate,
      'Awaiting Verification' => l.statusAwaitingVerification,
      'Low' => l.severityLow,
      'Medium' => l.severityMedium,
      'High' => l.severityHigh,
      _ => value,
    };

/// A date such as "Oct 30, 2026" in the current app language. Falls back to
/// the first ten characters of an ISO string it cannot read.
String formatDate(BuildContext context, Object? value) {
  final raw = value?.toString() ?? '';
  final date = DateTime.tryParse(raw);
  if (date == null) return raw.length >= 10 ? raw.substring(0, 10) : raw;
  final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
  try {
    return DateFormat.yMMMd(locale).format(date.toLocal());
  } catch (_) {
    return DateFormat.yMMMd('en').format(date.toLocal());
  }
}
