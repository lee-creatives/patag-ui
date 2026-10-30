// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get brandTagline => 'Pa-tag lubak, lubak patag.';

  @override
  String get brandHomeQuestion => 'May lubak\nsa daan?';

  @override
  String get brandReportTitle => 'I-report ang lubak';

  @override
  String get brandWelcomeHeadline => 'Mas maayos na daan, nagsisimula sa’yo.';

  @override
  String get brandSignInHeading => 'Tuloy po. Welcome back.';

  @override
  String get brandOnboardingTitle => 'See a pothole? I-tag mo.';

  @override
  String get brandSuccessHeading => 'Na-tag na ang lubak!';

  @override
  String get brandAboutHeading => 'I-tag ang lubak. Tungo sa patag.';

  @override
  String get brandFeedbackThanks => 'Salamat sa feedback!';

  @override
  String get brandDefaultName => 'Ka-PATAG';

  @override
  String get languageTitle => 'Language / Wika';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTagalog => 'Tagalog';

  @override
  String get languageBody => 'Choose the app language.';

  @override
  String get retry => 'Retry';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get cancel => 'Cancel';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get createAnAccount => 'Create an account';

  @override
  String get createAccount => 'Create account';

  @override
  String get continueLabel => 'Continue';

  @override
  String brgy(String name) {
    return 'Brgy. $name';
  }

  @override
  String fieldRequired(String label) {
    return '$label is required.';
  }

  @override
  String errorSemantics(String message) {
    return 'Error: $message';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navMap => 'Map';

  @override
  String get navReport => 'Report';

  @override
  String get navMyReports => 'My reports';

  @override
  String get navProfile => 'Profile';

  @override
  String get reportAPothole => 'Report a pothole';

  @override
  String get switchToLight => 'Switch to light mode';

  @override
  String get switchToDark => 'Switch to dark mode';

  @override
  String get demoEvidence => 'Illustrated demo evidence';

  @override
  String get photoUnavailable => 'Photo unavailable. Check your connection.';

  @override
  String get progressTitle => 'Report progress';

  @override
  String get progressResolved => 'Repair verified. A better road ahead.';

  @override
  String get progressAwaiting => 'Repair submitted. Awaiting LGU verification.';

  @override
  String get progressFollow => 'Follow your tag, from report to repair.';

  @override
  String get progressStepReported => 'Reported';

  @override
  String get progressStepVerified => 'Verified';

  @override
  String get progressStepRepair => 'Repair';

  @override
  String get progressStepResolved => 'Resolved';

  @override
  String get stepPhoto => 'Photo';

  @override
  String get stepLocation => 'Location';

  @override
  String get stepDetails => 'Details';

  @override
  String get stepReview => 'Review';

  @override
  String get serverWaking =>
      'Connecting to PATAG… A server that was asleep can take up to a minute.';

  @override
  String get serverUnreachable =>
      'Can\'t reach the PATAG server. Is the backend running?';

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
  String get statusAwaitingVerification => 'Awaiting LGU verification';

  @override
  String get severityLow => 'Low';

  @override
  String get severityMedium => 'Medium';

  @override
  String get severityHigh => 'High';

  @override
  String get errTimeout =>
      'Connection timed out. Your draft is saved. Please retry.';

  @override
  String get errUnreachable =>
      'Cannot reach PATAG. Check the local API and your connection. Your draft is saved.';

  @override
  String errServerDown(int status) {
    return 'The PATAG server is unavailable ($status). Please retry in a moment.';
  }

  @override
  String errUnexpected(int status) {
    return 'Unexpected response from the PATAG server ($status).';
  }

  @override
  String get errTryAgain => 'Please try again.';

  @override
  String get errCitizenOnly => 'Use a citizen account in this app.';

  @override
  String get errPhotoTooLarge => 'Choose a photo under 8 MB.';

  @override
  String get errPhotoType => 'Choose a JPEG, PNG or WebP photo.';

  @override
  String get errPhotoMismatch => 'Image content does not match its type.';

  @override
  String get errSessionExpired => 'Session expired. Sign in again.';

  @override
  String get errWrongPassword =>
      'Email or password is incorrect for this portal.';

  @override
  String get errTooManyAttempts =>
      'Too many attempts. Wait a minute and try again.';

  @override
  String get errTooManyLookups =>
      'Too many address lookups. Wait a minute and try again.';

  @override
  String get errAccountUnavailable =>
      'Unable to create an account with these details. Try signing in or recovering access.';

  @override
  String get errEmailRegistered => 'Email is already registered.';

  @override
  String get errFeedbackOnce =>
      'Feedback is available once for resolved reports.';

  @override
  String get errReportIncomplete =>
      'Evidence photo, description, road, barangay, city, province, valid coordinates and severity are required.';

  @override
  String get errAddressRequired =>
      'Enter your barangay, city or municipality, and province.';

  @override
  String get errGpsOff =>
      'GPS is off. Turn it on or tap the map to pin manually.';

  @override
  String get errLocationDenied =>
      'Location permission denied. Tap the map to choose a location, or enable location in Android settings.';

  @override
  String get mapFullScreen => 'Full screen map';

  @override
  String get mapZoomIn => 'Zoom in';

  @override
  String get mapZoomOut => 'Zoom out';

  @override
  String get mapRecenter => 'Recenter map';

  @override
  String get mapTilesUnavailable =>
      'Map tiles unavailable. Enter coordinates or use the report list.';

  @override
  String mapPinTooltip(String road, String status) {
    return '$road: $status';
  }

  @override
  String get viewPublicReport => 'View public report';

  @override
  String get mapSignInToReport => 'Sign in to report this pothole.';

  @override
  String get mapHintPicking => 'Tap the map to place the pothole pin.';

  @override
  String get mapHintBrowsing =>
      'Tap a pin for details, or tap the road to report a pothole there.';

  @override
  String get mapClose => 'Close full screen map';

  @override
  String mapPinCoordinates(String lat, String lng) {
    return 'Pin: $lat, $lng';
  }

  @override
  String get locating => 'Locating…';

  @override
  String get myGps => 'My GPS';

  @override
  String get useThisLocation => 'Use this location';

  @override
  String get reportPotholeHere => 'Report a pothole here';

  @override
  String get publicMapTitle => 'Community pothole map';

  @override
  String get publicMapHeading => 'Know the road ahead.';

  @override
  String get publicMapDemoNote =>
      'Fictional demonstration reports · Malolos, Bulacan';

  @override
  String get allSeverities => 'All severities';

  @override
  String get allStatuses => 'All statuses';

  @override
  String get showMap => 'Show map';

  @override
  String get showList => 'Show list';

  @override
  String get communityReports => 'Community reports';

  @override
  String get filterAll => 'All';

  @override
  String get noReportsNearby => 'No reports nearby';

  @override
  String get tryDifferentFilter => 'Try a different filter.';

  @override
  String reportsCountTapPin(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reports · Tap a pin for details.',
      one: '1 report · Tap a pin for details.',
    );
    return '$_temp0';
  }

  @override
  String get useCurrentGps => 'Use current GPS location';

  @override
  String get wizardPinFromMap =>
      'Location set from the map. Add a photo, then check the road details.';

  @override
  String wizardPhotoLimit(int max) {
    return 'You can attach up to $max photos.';
  }

  @override
  String wizardPhotoRoom(int room, int max) {
    return 'Only $room more photo(s) could be added (limit $max).';
  }

  @override
  String get wizardNeedPhoto => 'Add at least one evidence photo.';

  @override
  String get wizardInvalidCoordinates =>
      'Tap the map or enter valid latitude and longitude.';

  @override
  String get wizardReviewDuplicates =>
      'Review possible duplicates before submitting.';

  @override
  String get wizardHeadingPhoto => 'Show us the road.';

  @override
  String get wizardHeadingLocation => 'Pin the exact spot.';

  @override
  String get wizardHeadingDetails => 'Tell us what you saw.';

  @override
  String get wizardHeadingReview => 'Ready to tag it?';

  @override
  String get wizardIntroPhoto =>
      'One clear photo helps the LGU inspect your report. Stay in a safe place when taking photos.';

  @override
  String get wizardIntroLocation =>
      'GPS is optional. Tap the map to select or move your pin.';

  @override
  String get wizardIntroDetails =>
      'Your severity estimate helps with review. The LGU will verify the report.';

  @override
  String get wizardIntroReview =>
      'Check your evidence, location and description before submitting.';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get photoRequirements => 'JPEG, PNG or WebP · maximum 8 MB per image';

  @override
  String removePhoto(String name) {
    return 'Remove $name';
  }

  @override
  String get useMyGps => 'Use my GPS location';

  @override
  String get latitude => 'Latitude';

  @override
  String get longitude => 'Longitude';

  @override
  String get roadName => 'Road name';

  @override
  String get barangay => 'Barangay';

  @override
  String get municipalityCity => 'Municipality / City';

  @override
  String get province => 'Province';

  @override
  String get nearbyLandmark => 'Nearby landmark';

  @override
  String get reportTitleField => 'Short report title';

  @override
  String get describeDamage => 'Describe the road damage';

  @override
  String get observedHazards => 'Observed hazards';

  @override
  String get reportedSeverity => 'Reported severity';

  @override
  String get severityLowHint => 'Minor surface damage';

  @override
  String get severityMediumHint => 'Needs care when passing';

  @override
  String get severityHighHint => 'Deep damage or immediate road hazard';

  @override
  String reviewAddress(String road, String barangay) {
    return '$road, Brgy. $barangay';
  }

  @override
  String hazardsLine(String text) {
    return 'Hazards: $text';
  }

  @override
  String get possibleDuplicates => 'Possible duplicate reports';

  @override
  String get possibleDuplicatesHint =>
      'These nearby reports may describe the same damage. You can inspect them before continuing.';

  @override
  String duplicateDistance(String distance, String road) {
    return '$distance m away · $road';
  }

  @override
  String get duplicatesAcknowledge =>
      'I checked these reports and still want to submit.';

  @override
  String get wizardStartsSubmitted =>
      'Your report starts as Submitted. The LGU reviews the evidence before verification.';

  @override
  String get pleaseWait => 'Please wait…';

  @override
  String get submitReport => 'Submit report';

  @override
  String get findingAddress => 'Finding address…';

  @override
  String get addressFilledFromMap => 'Filled from the map — please check it.';

  @override
  String get addressNotFound => 'Couldn\'t find the address — please type it.';

  @override
  String get skip => 'Skip';

  @override
  String get onboardingTitlePin => 'Pin it. Help us find it.';

  @override
  String get onboardingTitleFollow => 'Follow every road forward.';

  @override
  String get onboardingBodyPhoto =>
      'Take a clear photo and tell your LGU about the damaged road.';

  @override
  String get onboardingBodyPin =>
      'Use GPS or tap the map. Accurate locations help the right crew reach the site.';

  @override
  String get onboardingBodyFollow =>
      'Track review, assignment and repair updates. Share feedback after LGU verification.';

  @override
  String get getStarted => 'Get started';

  @override
  String get welcomeBody =>
      'Report road damage. Follow the progress. Help your community move safely.';

  @override
  String get explorePublicMap => 'Explore the public map';

  @override
  String get academicNote =>
      'Academic demonstration · IT 305\nNo official LGU records or partnerships.';

  @override
  String get privacyRequired => 'Please acknowledge the privacy information.';

  @override
  String get recoverAccount => 'Recover account';

  @override
  String get recoveryHeading => 'Let’s get you back.';

  @override
  String get registerHeading => 'Join the road forward.';

  @override
  String get devAuthNote => 'Development authentication · local demo API';

  @override
  String signupStep(int step, int total, String name) {
    return 'Step $step of $total · $name';
  }

  @override
  String get signupStepAbout => 'About you';

  @override
  String get signupStepAddress => 'Your address';

  @override
  String get signupStepSecure => 'Secure your account';

  @override
  String get fullName => 'Full name';

  @override
  String get emailAddress => 'Email address';

  @override
  String get invalidEmail => 'Enter a valid email address.';

  @override
  String get addressPrivateNote =>
      'Your address stays on your private account. You will pin the pothole separately when reporting.';

  @override
  String get streetOptional => 'Street / house number (optional)';

  @override
  String get enterBarangay => 'Enter your barangay.';

  @override
  String get cityMunicipality => 'City / municipality';

  @override
  String get enterCity => 'Enter your city or municipality.';

  @override
  String get enterProvince => 'Enter your province.';

  @override
  String get password => 'Password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get passwordRule =>
      'Use at least 8 characters with uppercase, lowercase, number, and special character.';

  @override
  String get enterPassword => 'Enter your password.';

  @override
  String get passwordRequirements =>
      'Requires at least 8 characters including uppercase, lowercase, number, and special character.';

  @override
  String get privacyAcknowledge =>
      'I understand this academic demo stores test account data locally. I will not use personal information.';

  @override
  String get connecting => 'Connecting…';

  @override
  String get requestRecovery => 'Request recovery';

  @override
  String get alreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get exploreDemoNote => 'Explore the demo without a password.';

  @override
  String get continueAsDemo => 'Continue as demo citizen';

  @override
  String get notifications => 'Notifications';

  @override
  String helloName(String name) {
    return 'Hello, $name.';
  }

  @override
  String get homeSubtitle => 'A little tag. A better road.';

  @override
  String get homeCallToAction =>
      'I-tag mo na. Help your community move safely.';

  @override
  String get aroundYou => 'Around you';

  @override
  String get explore => 'Explore';

  @override
  String get yourImpact => 'Your impact';

  @override
  String get viewReports => 'View reports';

  @override
  String get totalReports => 'Total reports';

  @override
  String get everyTagCounts => 'Every tag counts.';

  @override
  String get metricUnderReview => 'Under review';

  @override
  String get metricInProgress => 'In progress';

  @override
  String get metricResolved => 'Resolved';

  @override
  String get latestReport => 'Latest report';

  @override
  String get viewAll => 'View all';

  @override
  String get firstTagTitle => 'Your first tag starts here.';

  @override
  String get firstTagBody => 'Send a clear photo and a location.';

  @override
  String get clearerPictureTitle => 'A clearer picture helps.';

  @override
  String get clearerPictureBody =>
      'Stay safe, add a landmark and check your map pin.';

  @override
  String get readGuide => 'Read the reporting guide';

  @override
  String get demoReportsNote => 'Fictional demonstration reports · IT 305';

  @override
  String get yourProfile => 'Your profile';

  @override
  String get myReportsHeading => 'Your tags. Their progress.';

  @override
  String get searchReports => 'Search road or reference';

  @override
  String get newestFirst => 'Newest first';

  @override
  String get oldestFirst => 'Oldest first';

  @override
  String get noReportsFound => 'No reports found';

  @override
  String get noReportsFoundBody => 'Try another search or start a new report.';

  @override
  String get reportDetails => 'Report details';

  @override
  String get reportNotFound => 'Report not found';

  @override
  String get reportNotFoundBody =>
      'Refresh your reports, or check the public map.';

  @override
  String detailsAddress(String barangay, String city, String province) {
    return 'Brgy. $barangay, $city, $province';
  }

  @override
  String get roadToResolution => 'The road to resolution';

  @override
  String get repairDocumentation => 'Repair documentation';

  @override
  String get shareRepairFeedback => 'Share repair feedback';

  @override
  String get feedbackRecorded => 'Salamat! Your feedback is recorded.';

  @override
  String get reportSubmitted => 'Report submitted';

  @override
  String get reportSubmittedBody =>
      'Your report has been submitted for review. The LGU will check the evidence and location.';

  @override
  String get viewReport => 'View report';

  @override
  String get returnHome => 'Return home';

  @override
  String get readAll => 'Read all';

  @override
  String get allQuiet => 'All quiet for now';

  @override
  String get allQuietBody => 'Report progress updates will appear here.';

  @override
  String notificationSubtitle(String reportId, String date) {
    return '$reportId · $date';
  }

  @override
  String get repairFeedback => 'Repair feedback';

  @override
  String get repairNotVerified => 'Repair not yet verified';

  @override
  String get repairNotVerifiedBody =>
      'Feedback opens after the LGU verifies the completed repair.';

  @override
  String get howWasRepair => 'How was the repair?';

  @override
  String get feedbackSaved => 'Your feedback has been recorded.';

  @override
  String get feedbackAlready => 'You already shared feedback for this repair.';

  @override
  String starsTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stars',
      one: '1 star',
    );
    return '$_temp0';
  }

  @override
  String get yourRepairFeedback => 'Your repair feedback';

  @override
  String get submitting => 'Submitting…';

  @override
  String get submitFeedback => 'Submit feedback';

  @override
  String get feedbackIncomplete => 'Choose a rating and add feedback.';

  @override
  String get defaultCitizenName => 'Citizen';

  @override
  String profileAddress(String address) {
    return 'Address · $address';
  }

  @override
  String communityReportsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count community reports',
      one: '1 community report',
    );
    return '$_temp0';
  }

  @override
  String get editProfile => 'Edit profile';

  @override
  String get settings => 'Settings';

  @override
  String get reportingGuide => 'Reporting guide';

  @override
  String get aboutPatag => 'About PATAG';

  @override
  String get emailChangeNote =>
      'Email changes require verified account recovery.';

  @override
  String get privateAddressNote =>
      'Private address · separate from each road report';

  @override
  String get saveProfile => 'Save profile';

  @override
  String get profileSaved => 'Profile saved.';

  @override
  String get appearance => 'Appearance';

  @override
  String get appearanceBody => 'Use light, dark, or your device setting.';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get showUnread => 'Show unread notification indicators';

  @override
  String get showUnreadBody =>
      'Saved on this device. Update history remains available.';

  @override
  String get permissionsTitle => 'Camera & location permissions';

  @override
  String get permissionsBody =>
      'Permissions are requested when needed. If denied, choose a gallery photo or manually tap the map. You can manage access in Android Settings → Apps → PATAG.';

  @override
  String get privacy => 'Privacy';

  @override
  String get privacyBody =>
      'Public reports omit your identity. This academic demo stores test records on a local API. Use fictional account information.';

  @override
  String get mapboxNotice =>
      'When you place a pin, its coordinates are sent to Mapbox through PATAG\'s server to look up the address.';

  @override
  String get guideHeading => 'A good report goes further.';

  @override
  String get aboutMeaning =>
      'PATAG means a level or smooth surface. Read as “pa-tag”, it also means calling attention to a problem.';

  @override
  String get aboutMission =>
      'Our mission is to empower communities to report road problems, connect citizens with local authorities, and turn reports into action.';

  @override
  String get aboutAcademic =>
      'An academic final project for IT 305 – Advanced Web Development, Bulacan State University. This demonstration does not represent official LGU records or partnerships.';

  @override
  String get guidePhotoTitle => '1. Photograph safely';

  @override
  String get guidePhotoBody =>
      'Take clear photos of the damaged surface. Do not stand in traffic. Upload JPEG, PNG or WebP images under 8 MB.';

  @override
  String get guideLocationTitle => '2. Set the location';

  @override
  String get guideLocationBody =>
      'Use GPS when permission is granted. If GPS is off, denied or inaccurate, tap the map to pin manually or enter coordinates. Add road, barangay, city and province.';

  @override
  String get guideDescribeTitle => '3. Describe the damage';

  @override
  String get guideDescribeBody =>
      'Explain the pothole and hazards. Your severity estimate is reviewed by the LGU.';

  @override
  String get guideDuplicatesTitle => '4. Check for duplicates';

  @override
  String get guideDuplicatesBody =>
      'Nearby reports on the same road may refer to the same damage. Inspect suggestions before submitting. The system never silently merges your report.';

  @override
  String get guideProgressTitle => '5. Follow the progress';

  @override
  String get guideProgressBody =>
      'Submitted → Under Review → Verified → Assigned → In Progress → Resolved. Only an LGU-verified repair is Resolved.';

  @override
  String get guideOutcomesTitle => 'Other outcomes';

  @override
  String get guideOutcomesBody =>
      'Rejected reports include a reason. Duplicate means the LGU confirmed an existing case. Reports may be forwarded to the responsible agency.';

  @override
  String get guideFeedbackTitle => '6. Share feedback';

  @override
  String get guideFeedbackBody =>
      'Once the repair is resolved, open your report and submit a rating and feedback.';

  @override
  String get guideConnectionTitle => 'Connection & drafts';

  @override
  String get guideConnectionBody =>
      'Your reporting draft is saved on this device. Submission needs internet access to the configured API. There is no automatic offline synchronization.';

  @override
  String get pageNotFound => 'Page not found';

  @override
  String get pageNotFoundBody => 'Use the navigation to continue.';
}
