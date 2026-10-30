// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PATAG Maintenance';

  @override
  String get devicePreviewLabel => 'PATAG Crew Mobile · Portrait Phone View';

  @override
  String get languageSettingTitle => 'Wika / Language';

  @override
  String get languageSettingSubtitle => 'Choose the language of the app.';

  @override
  String get languageTagalog => 'Tagalog';

  @override
  String get languageEnglish => 'English';

  @override
  String get themeSwitchToLight => 'Switch to light mode';

  @override
  String get themeSwitchToDark => 'Switch to dark mode';

  @override
  String get retry => 'Retry';

  @override
  String get refresh => 'Refresh';

  @override
  String get brandEveryPothole => 'Bawat lubak, may agarang aksyon.';

  @override
  String get brandFastRepair => 'Mabilis na kumpuni, ligtas na biyahe.';

  @override
  String get brandWorkOrdersReady => 'Handa na ang mga work order.';

  @override
  String get splashTagline => 'Road Maintenance Operations';

  @override
  String get welcomeBody =>
      'Access assigned work orders, document road repairs on site, and upload evidence directly to the LGU portal.';

  @override
  String get welcomeSignIn => 'Sign in to Workspace';

  @override
  String welcomeContinueAs(String team) {
    return 'Continue as $team';
  }

  @override
  String get welcomeFooter =>
      'Academic demonstration · IT 305\nCity of Malolos Road Maintenance Operations.';

  @override
  String get loginHeroTitle => 'Safer roads start here.';

  @override
  String get loginHeroSubtitle =>
      'Report clearly. Track progress. See the repair through.';

  @override
  String get loginBadge => 'MAINTENANCE ACCOUNT';

  @override
  String get loginWelcome => 'Welcome back';

  @override
  String get loginIntro =>
      'Sign in to view assignments and update road repairs.';

  @override
  String get loginHeading => 'Log in';

  @override
  String get loginEmail => 'Email address';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginShowPassword => 'Show password';

  @override
  String get loginHidePassword => 'Hide password';

  @override
  String get loginSigningIn => 'Signing in…';

  @override
  String get loginAccountAssigned => 'Account assigned by LGU Admin';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginForgotPasswordHelp =>
      'Maintenance accounts are assigned and managed by the LGU Admin. Contact your supervisor to reset credentials.';

  @override
  String get loginDemoTitle => 'Explore fictional demo data';

  @override
  String get loginDemoBody =>
      'Separate test access for the seeded crew account.';

  @override
  String get loginDemoOpening => 'Opening…';

  @override
  String get loginDemoButton => 'Open maintenance demo';

  @override
  String get navHome => 'Home';

  @override
  String get navTasks => 'Tasks';

  @override
  String get navRepair => 'Repair';

  @override
  String get navMap => 'Map';

  @override
  String get navProfile => 'Profile';

  @override
  String get statusSubmitted => 'Submitted';

  @override
  String get statusUnderReview => 'Under Review';

  @override
  String get statusVerified => 'Verified';

  @override
  String get statusAssigned => 'Assigned';

  @override
  String get statusInProgress => 'In Progress';

  @override
  String get statusResolved => 'Resolved';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusDuplicate => 'Duplicate';

  @override
  String get statusAwaitingVerification => 'Awaiting Verification';

  @override
  String get statusAdditionalWorkRequested => 'Additional Work Requested';

  @override
  String get severityLow => 'Low';

  @override
  String get severityMedium => 'Medium';

  @override
  String get severityHigh => 'High';

  @override
  String get filterAll => 'All';

  @override
  String get notificationsTooltip => 'Notifications';

  @override
  String get profileTooltip => 'Your profile';

  @override
  String dashboardGreeting(String name) {
    return 'Hello, $name.';
  }

  @override
  String get greetingFallbackName => 'Crew';

  @override
  String dashboardReadyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count work orders ready for action.',
      one: '1 work order ready for action.',
    );
    return '$_temp0';
  }

  @override
  String get dashboardReviewNext => 'Review next work order';

  @override
  String get dashboardActiveWorkOrders => 'Active Work Orders';

  @override
  String get viewAll => 'View all';

  @override
  String get dashboardEmptyTitle => 'All clear for now';

  @override
  String get dashboardEmptyBody =>
      'No pending road repairs assigned to your team.';

  @override
  String get safetyTitle => 'Safety Protocol On Site';

  @override
  String get safetyBody =>
      'Deploy safety cones 15m ahead, wear high-vis vests, and log before & after photos.';

  @override
  String get assignmentsTitle => 'My Assignments';

  @override
  String get assignmentsSearchHint => 'Search road, barangay, or ID…';

  @override
  String get assignmentsEmptyTitle => 'No matching work orders';

  @override
  String get assignmentsEmptyBody =>
      'Try another filter or check for newly assigned tasks.';

  @override
  String get inProgressTitle => 'Repairs In Progress';

  @override
  String get inProgressEmptyTitle => 'No repairs in progress';

  @override
  String inProgressEmptyBody(String action) {
    return 'Select an assigned task from Work Orders and tap \"$action\" to begin work.';
  }

  @override
  String get taskCardSite => 'Site';

  @override
  String get taskCardFallbackTitle => 'Road Damage Work Order';

  @override
  String get taskFallbackTitle => 'Road Work Order';

  @override
  String barangayShort(String barangay) {
    return 'Brgy. $barangay';
  }

  @override
  String taskLocation(String barangay, String city, String province) {
    return 'Brgy. $barangay, $city, $province';
  }

  @override
  String mapTaskLocation(String barangay, String city, String reportId) {
    return 'Brgy. $barangay, $city · $reportId';
  }

  @override
  String get taskDetailsTitle => 'Task Details';

  @override
  String get taskNotFoundTitle => 'Task not found';

  @override
  String get taskNotFoundBody => 'This task could not be loaded.';

  @override
  String get beforePhotosHeading => 'Before-Repair Inspection Photos';

  @override
  String get afterPhotosHeading => 'After-Repair Completion Photos';

  @override
  String get assignmentDetails => 'Assignment Details';

  @override
  String lguNote(String note) {
    return 'LGU Note: $note';
  }

  @override
  String targetCompletion(String date) {
    return 'Target Completion: $date';
  }

  @override
  String coordinatesLine(String lat, String lng) {
    return 'Coordinates: $lat, $lng';
  }

  @override
  String get beforeInspectionTitle => 'Before-Repair Inspection';

  @override
  String get beforeInspectionBody =>
      'Record a photo of the damaged road before repair work starts.';

  @override
  String get addBeforePhoto => 'Add Before Photo';

  @override
  String get updating => 'Updating…';

  @override
  String get startRepair => 'Start Inspection / Repair';

  @override
  String get awaitingVerificationInfo =>
      'Repair submitted. Waiting for the LGU to verify your evidence before the task is resolved.';

  @override
  String get moreWorkRequested => 'The LGU requested more work on this repair.';

  @override
  String moreWorkRequestedNote(String note) {
    return 'More work requested by the LGU: $note';
  }

  @override
  String get afterEvidenceTitle => 'After-Repair Completion Evidence';

  @override
  String get afterEvidenceBody =>
      'Add photos of the patched road surface before submitting the completion report.';

  @override
  String get addAfterPhoto => 'Add After Photo';

  @override
  String get documentAndSubmit => 'Document & Submit Completion';

  @override
  String get resolvedInfo => 'Repair verified and resolved by LGU.';

  @override
  String repairStarted(String status) {
    return 'Repair started! Task is now $status.';
  }

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get beforePhotoUploaded => 'Before-repair photo uploaded.';

  @override
  String get afterPhotoUploaded => 'After-repair photo uploaded.';

  @override
  String uploadFailed(String message) {
    return 'Upload failed: $message';
  }

  @override
  String get progressTitle => 'TASK PROGRESS';

  @override
  String get progressAssignedToCrew => 'Assigned to Crew';

  @override
  String get progressAwaitingVerification => 'Awaiting LGU Verification';

  @override
  String get progressMoreWork => 'More Work Requested';

  @override
  String get progressRepairInProgress => 'Repair In Progress';

  @override
  String get progressCompleted => 'Completed & Verified';

  @override
  String progressSummary(int percent, String step) {
    return '$percent% · $step';
  }

  @override
  String progressStep(int number, String label) {
    return '$number. $label';
  }

  @override
  String get documentRepairTitle => 'Document Repair';

  @override
  String get uploadAfterEvidence => 'Upload After-Repair Evidence';

  @override
  String get uploadAfterEvidenceBody =>
      'Provide clear photos of the patched and compacted road surface.';

  @override
  String get takeAfterPhoto => 'Take / Select After Photo';

  @override
  String get workNotesHeading => 'Work Performed / Progress Notes';

  @override
  String get workNotesHint =>
      'Describe materials used, compaction, curing time…';

  @override
  String get defaultWorkNote =>
      'Base compacted, crack seal applied, and hot asphalt patched to grade.';

  @override
  String get submitting => 'Submitting…';

  @override
  String get submitForVerification => 'Submit for Verification';

  @override
  String photoUploadFailed(String message) {
    return 'Photo upload failed: $message';
  }

  @override
  String get completionRequirements =>
      'Add at least one after photo and describe the work.';

  @override
  String submissionFailed(String message) {
    return 'Submission failed: $message';
  }

  @override
  String get successTitle => 'Work submitted.\nOne step closer to patag.';

  @override
  String successBody(String reportId) {
    return '$reportId · The LGU engineering office will review your evidence before closing the task.';
  }

  @override
  String get returnToOverview => 'Return to Overview';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get notificationsEmptyTitle => 'All caught up';

  @override
  String get notificationsEmptyBody => 'No new notifications for your crew.';

  @override
  String notificationSubtitle(String reportId, String date) {
    return '$reportId · $date';
  }

  @override
  String get profileTitle => 'Profile & Settings';

  @override
  String get profileFallbackName => 'Maintenance Personnel';

  @override
  String get themeMode => 'Theme Mode';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get unreadIndicators => 'Unread Indicators';

  @override
  String get aboutTitle => 'About PATAG Maintenance';

  @override
  String get aboutSubtitle => 'IT 305 · Bulacan State University';

  @override
  String get signOut => 'Sign out of Workspace';

  @override
  String get mapTitle => 'Assigned Task Map';

  @override
  String get mapRecenter => 'Center map';

  @override
  String get openTaskDetails => 'Open Task Details';

  @override
  String fieldRequired(String label) {
    return '$label is required.';
  }

  @override
  String get photoBefore => 'Before-repair photo';

  @override
  String get photoAfter => 'After-repair photo';

  @override
  String get photoPlaceholder => 'Photo not available';

  @override
  String get serverConnecting =>
      'Connecting to PATAG… A server that was asleep can take up to a minute.';

  @override
  String get errorServerDown =>
      'Can\'t reach the PATAG server. Is the backend running?';

  @override
  String get errorTimeout => 'Connection timed out. Please retry.';

  @override
  String get errorUnreachable =>
      'Cannot reach the PATAG server. Check your connection and try again.';

  @override
  String errorServerUnavailable(int code) {
    return 'The PATAG server is unavailable ($code). Please retry in a moment.';
  }

  @override
  String errorUnexpectedResponse(int code) {
    return 'Unexpected response from the PATAG server ($code).';
  }

  @override
  String get errorRequestFailed => 'Request failed.';

  @override
  String get errorNotMaintenance =>
      'This account does not belong to road maintenance.';

  @override
  String get errorPhotoTooLarge => 'Choose a photo under 8 MB.';

  @override
  String get errorPhotoType => 'Choose a JPEG, PNG or WebP photo.';

  @override
  String get errorPhotoMismatch => 'Image content does not match its type.';

  @override
  String get errorSessionExpired => 'Session expired. Sign in again.';

  @override
  String get errorBadCredentials =>
      'Email or password is incorrect for this portal.';

  @override
  String get errorTooManyAttempts =>
      'Too many attempts. Wait a minute and try again.';

  @override
  String get errorActionNotAllowed =>
      'This action is not allowed from the current report status.';

  @override
  String get errorRepairEvidenceRequired =>
      'Repair notes and after photos are required.';

  @override
  String get errorBeforePhotosRequired => 'Upload before-repair photos.';

  @override
  String get errorProgressNoteRequired => 'Add a progress note.';

  @override
  String get errorUploadPhotoFirst => 'Upload the photo first, then attach it.';

  @override
  String get errorUploadRealPhotos => 'Upload real repair photos first.';

  @override
  String get errorReportNotFound => 'Report not found.';

  @override
  String get errorPhotoNotFound => 'Photo not found.';

  @override
  String get errorOtherTeam =>
      'This report belongs to another account or team.';

  @override
  String get errorDemoUnavailable => 'Demo role unavailable.';

  @override
  String get errorCheckAction => 'Check the action details and try again.';

  @override
  String get errorMaintenanceOnly =>
      'Maintenance can start work, update progress or submit evidence; LGU verification is required for resolution.';

  @override
  String get errorServerGeneric =>
      'PATAG could not complete this request. Please try again.';

  @override
  String get errorInvalidRequest => 'Invalid request.';
}
