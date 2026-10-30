import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fil.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fil')
  ];

  /// No description provided for @brandTagline.
  ///
  /// In en, this message translates to:
  /// **'Pa-tag lubak, lubak patag.'**
  String get brandTagline;

  /// No description provided for @brandHomeQuestion.
  ///
  /// In en, this message translates to:
  /// **'May lubak\nsa daan?'**
  String get brandHomeQuestion;

  /// No description provided for @brandReportTitle.
  ///
  /// In en, this message translates to:
  /// **'I-report ang lubak'**
  String get brandReportTitle;

  /// No description provided for @brandWelcomeHeadline.
  ///
  /// In en, this message translates to:
  /// **'Mas maayos na daan, nagsisimula sa’yo.'**
  String get brandWelcomeHeadline;

  /// No description provided for @brandSignInHeading.
  ///
  /// In en, this message translates to:
  /// **'Tuloy po. Welcome back.'**
  String get brandSignInHeading;

  /// No description provided for @brandOnboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'See a pothole? I-tag mo.'**
  String get brandOnboardingTitle;

  /// No description provided for @brandSuccessHeading.
  ///
  /// In en, this message translates to:
  /// **'Na-tag na ang lubak!'**
  String get brandSuccessHeading;

  /// No description provided for @brandAboutHeading.
  ///
  /// In en, this message translates to:
  /// **'I-tag ang lubak. Tungo sa patag.'**
  String get brandAboutHeading;

  /// No description provided for @brandFeedbackThanks.
  ///
  /// In en, this message translates to:
  /// **'Salamat sa feedback!'**
  String get brandFeedbackThanks;

  /// No description provided for @brandDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Ka-PATAG'**
  String get brandDefaultName;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language / Wika'**
  String get languageTitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageTagalog.
  ///
  /// In en, this message translates to:
  /// **'Tagalog'**
  String get languageTagalog;

  /// No description provided for @languageBody.
  ///
  /// In en, this message translates to:
  /// **'Choose the app language.'**
  String get languageBody;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @createAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAnAccount;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @brgy.
  ///
  /// In en, this message translates to:
  /// **'Brgy. {name}'**
  String brgy(String name);

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'{label} is required.'**
  String fieldRequired(String label);

  /// No description provided for @errorSemantics.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorSemantics(String message);

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get navReport;

  /// No description provided for @navMyReports.
  ///
  /// In en, this message translates to:
  /// **'My reports'**
  String get navMyReports;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @reportAPothole.
  ///
  /// In en, this message translates to:
  /// **'Report a pothole'**
  String get reportAPothole;

  /// No description provided for @switchToLight.
  ///
  /// In en, this message translates to:
  /// **'Switch to light mode'**
  String get switchToLight;

  /// No description provided for @switchToDark.
  ///
  /// In en, this message translates to:
  /// **'Switch to dark mode'**
  String get switchToDark;

  /// No description provided for @demoEvidence.
  ///
  /// In en, this message translates to:
  /// **'Illustrated demo evidence'**
  String get demoEvidence;

  /// No description provided for @photoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Photo unavailable. Check your connection.'**
  String get photoUnavailable;

  /// No description provided for @progressTitle.
  ///
  /// In en, this message translates to:
  /// **'Report progress'**
  String get progressTitle;

  /// No description provided for @progressResolved.
  ///
  /// In en, this message translates to:
  /// **'Repair verified. A better road ahead.'**
  String get progressResolved;

  /// No description provided for @progressAwaiting.
  ///
  /// In en, this message translates to:
  /// **'Repair submitted. Awaiting LGU verification.'**
  String get progressAwaiting;

  /// No description provided for @progressFollow.
  ///
  /// In en, this message translates to:
  /// **'Follow your tag, from report to repair.'**
  String get progressFollow;

  /// No description provided for @progressStepReported.
  ///
  /// In en, this message translates to:
  /// **'Reported'**
  String get progressStepReported;

  /// No description provided for @progressStepVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get progressStepVerified;

  /// No description provided for @progressStepRepair.
  ///
  /// In en, this message translates to:
  /// **'Repair'**
  String get progressStepRepair;

  /// No description provided for @progressStepResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get progressStepResolved;

  /// No description provided for @stepPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get stepPhoto;

  /// No description provided for @stepLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get stepLocation;

  /// No description provided for @stepDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get stepDetails;

  /// No description provided for @stepReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get stepReview;

  /// No description provided for @serverWaking.
  ///
  /// In en, this message translates to:
  /// **'Connecting to PATAG… A server that was asleep can take up to a minute.'**
  String get serverWaking;

  /// No description provided for @serverUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the PATAG server. Is the backend running?'**
  String get serverUnreachable;

  /// No description provided for @statusSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get statusSubmitted;

  /// No description provided for @statusUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get statusUnderReview;

  /// No description provided for @statusVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get statusVerified;

  /// No description provided for @statusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get statusAssigned;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// No description provided for @statusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get statusResolved;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @statusDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get statusDuplicate;

  /// No description provided for @statusAwaitingVerification.
  ///
  /// In en, this message translates to:
  /// **'Awaiting LGU verification'**
  String get statusAwaitingVerification;

  /// No description provided for @severityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get severityLow;

  /// No description provided for @severityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get severityMedium;

  /// No description provided for @severityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get severityHigh;

  /// No description provided for @errTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timed out. Your draft is saved. Please retry.'**
  String get errTimeout;

  /// No description provided for @errUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach PATAG. Check the local API and your connection. Your draft is saved.'**
  String get errUnreachable;

  /// No description provided for @errServerDown.
  ///
  /// In en, this message translates to:
  /// **'The PATAG server is unavailable ({status}). Please retry in a moment.'**
  String errServerDown(int status);

  /// No description provided for @errUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Unexpected response from the PATAG server ({status}).'**
  String errUnexpected(int status);

  /// No description provided for @errTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Please try again.'**
  String get errTryAgain;

  /// No description provided for @errCitizenOnly.
  ///
  /// In en, this message translates to:
  /// **'Use a citizen account in this app.'**
  String get errCitizenOnly;

  /// No description provided for @errPhotoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Choose a photo under 8 MB.'**
  String get errPhotoTooLarge;

  /// No description provided for @errPhotoType.
  ///
  /// In en, this message translates to:
  /// **'Choose a JPEG, PNG or WebP photo.'**
  String get errPhotoType;

  /// No description provided for @errPhotoMismatch.
  ///
  /// In en, this message translates to:
  /// **'Image content does not match its type.'**
  String get errPhotoMismatch;

  /// No description provided for @errSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Sign in again.'**
  String get errSessionExpired;

  /// No description provided for @errWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect for this portal.'**
  String get errWrongPassword;

  /// No description provided for @errTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a minute and try again.'**
  String get errTooManyAttempts;

  /// No description provided for @errTooManyLookups.
  ///
  /// In en, this message translates to:
  /// **'Too many address lookups. Wait a minute and try again.'**
  String get errTooManyLookups;

  /// No description provided for @errAccountUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unable to create an account with these details. Try signing in or recovering access.'**
  String get errAccountUnavailable;

  /// No description provided for @errEmailRegistered.
  ///
  /// In en, this message translates to:
  /// **'Email is already registered.'**
  String get errEmailRegistered;

  /// No description provided for @errFeedbackOnce.
  ///
  /// In en, this message translates to:
  /// **'Feedback is available once for resolved reports.'**
  String get errFeedbackOnce;

  /// No description provided for @errReportIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Evidence photo, description, road, barangay, city, province, valid coordinates and severity are required.'**
  String get errReportIncomplete;

  /// No description provided for @errAddressRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your barangay, city or municipality, and province.'**
  String get errAddressRequired;

  /// No description provided for @errGpsOff.
  ///
  /// In en, this message translates to:
  /// **'GPS is off. Turn it on or tap the map to pin manually.'**
  String get errGpsOff;

  /// No description provided for @errLocationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied. Tap the map to choose a location, or enable location in Android settings.'**
  String get errLocationDenied;

  /// No description provided for @mapFullScreen.
  ///
  /// In en, this message translates to:
  /// **'Full screen map'**
  String get mapFullScreen;

  /// No description provided for @mapZoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get mapZoomIn;

  /// No description provided for @mapZoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get mapZoomOut;

  /// No description provided for @mapRecenter.
  ///
  /// In en, this message translates to:
  /// **'Recenter map'**
  String get mapRecenter;

  /// No description provided for @mapTilesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Map tiles unavailable. Enter coordinates or use the report list.'**
  String get mapTilesUnavailable;

  /// No description provided for @mapPinTooltip.
  ///
  /// In en, this message translates to:
  /// **'{road}: {status}'**
  String mapPinTooltip(String road, String status);

  /// No description provided for @viewPublicReport.
  ///
  /// In en, this message translates to:
  /// **'View public report'**
  String get viewPublicReport;

  /// No description provided for @mapSignInToReport.
  ///
  /// In en, this message translates to:
  /// **'Sign in to report this pothole.'**
  String get mapSignInToReport;

  /// No description provided for @mapHintPicking.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to place the pothole pin.'**
  String get mapHintPicking;

  /// No description provided for @mapHintBrowsing.
  ///
  /// In en, this message translates to:
  /// **'Tap a pin for details, or tap the road to report a pothole there.'**
  String get mapHintBrowsing;

  /// No description provided for @mapClose.
  ///
  /// In en, this message translates to:
  /// **'Close full screen map'**
  String get mapClose;

  /// No description provided for @mapPinCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Pin: {lat}, {lng}'**
  String mapPinCoordinates(String lat, String lng);

  /// No description provided for @locating.
  ///
  /// In en, this message translates to:
  /// **'Locating…'**
  String get locating;

  /// No description provided for @myGps.
  ///
  /// In en, this message translates to:
  /// **'My GPS'**
  String get myGps;

  /// No description provided for @useThisLocation.
  ///
  /// In en, this message translates to:
  /// **'Use this location'**
  String get useThisLocation;

  /// No description provided for @reportPotholeHere.
  ///
  /// In en, this message translates to:
  /// **'Report a pothole here'**
  String get reportPotholeHere;

  /// No description provided for @publicMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Community pothole map'**
  String get publicMapTitle;

  /// No description provided for @publicMapHeading.
  ///
  /// In en, this message translates to:
  /// **'Know the road ahead.'**
  String get publicMapHeading;

  /// No description provided for @publicMapDemoNote.
  ///
  /// In en, this message translates to:
  /// **'Fictional demonstration reports · Malolos, Bulacan'**
  String get publicMapDemoNote;

  /// No description provided for @allSeverities.
  ///
  /// In en, this message translates to:
  /// **'All severities'**
  String get allSeverities;

  /// No description provided for @allStatuses.
  ///
  /// In en, this message translates to:
  /// **'All statuses'**
  String get allStatuses;

  /// No description provided for @showMap.
  ///
  /// In en, this message translates to:
  /// **'Show map'**
  String get showMap;

  /// No description provided for @showList.
  ///
  /// In en, this message translates to:
  /// **'Show list'**
  String get showList;

  /// No description provided for @communityReports.
  ///
  /// In en, this message translates to:
  /// **'Community reports'**
  String get communityReports;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @noReportsNearby.
  ///
  /// In en, this message translates to:
  /// **'No reports nearby'**
  String get noReportsNearby;

  /// No description provided for @tryDifferentFilter.
  ///
  /// In en, this message translates to:
  /// **'Try a different filter.'**
  String get tryDifferentFilter;

  /// No description provided for @reportsCountTapPin.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 report · Tap a pin for details.} other{{count} reports · Tap a pin for details.}}'**
  String reportsCountTapPin(int count);

  /// No description provided for @useCurrentGps.
  ///
  /// In en, this message translates to:
  /// **'Use current GPS location'**
  String get useCurrentGps;

  /// No description provided for @wizardPinFromMap.
  ///
  /// In en, this message translates to:
  /// **'Location set from the map. Add a photo, then check the road details.'**
  String get wizardPinFromMap;

  /// No description provided for @wizardPhotoLimit.
  ///
  /// In en, this message translates to:
  /// **'You can attach up to {max} photos.'**
  String wizardPhotoLimit(int max);

  /// No description provided for @wizardPhotoRoom.
  ///
  /// In en, this message translates to:
  /// **'Only {room} more photo(s) could be added (limit {max}).'**
  String wizardPhotoRoom(int room, int max);

  /// No description provided for @wizardNeedPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add at least one evidence photo.'**
  String get wizardNeedPhoto;

  /// No description provided for @wizardInvalidCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Tap the map or enter valid latitude and longitude.'**
  String get wizardInvalidCoordinates;

  /// No description provided for @wizardReviewDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Review possible duplicates before submitting.'**
  String get wizardReviewDuplicates;

  /// No description provided for @wizardHeadingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Show us the road.'**
  String get wizardHeadingPhoto;

  /// No description provided for @wizardHeadingLocation.
  ///
  /// In en, this message translates to:
  /// **'Pin the exact spot.'**
  String get wizardHeadingLocation;

  /// No description provided for @wizardHeadingDetails.
  ///
  /// In en, this message translates to:
  /// **'Tell us what you saw.'**
  String get wizardHeadingDetails;

  /// No description provided for @wizardHeadingReview.
  ///
  /// In en, this message translates to:
  /// **'Ready to tag it?'**
  String get wizardHeadingReview;

  /// No description provided for @wizardIntroPhoto.
  ///
  /// In en, this message translates to:
  /// **'One clear photo helps the LGU inspect your report. Stay in a safe place when taking photos.'**
  String get wizardIntroPhoto;

  /// No description provided for @wizardIntroLocation.
  ///
  /// In en, this message translates to:
  /// **'GPS is optional. Tap the map to select or move your pin.'**
  String get wizardIntroLocation;

  /// No description provided for @wizardIntroDetails.
  ///
  /// In en, this message translates to:
  /// **'Your severity estimate helps with review. The LGU will verify the report.'**
  String get wizardIntroDetails;

  /// No description provided for @wizardIntroReview.
  ///
  /// In en, this message translates to:
  /// **'Check your evidence, location and description before submitting.'**
  String get wizardIntroReview;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @photoRequirements.
  ///
  /// In en, this message translates to:
  /// **'JPEG, PNG or WebP · maximum 8 MB per image'**
  String get photoRequirements;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String removePhoto(String name);

  /// No description provided for @useMyGps.
  ///
  /// In en, this message translates to:
  /// **'Use my GPS location'**
  String get useMyGps;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @roadName.
  ///
  /// In en, this message translates to:
  /// **'Road name'**
  String get roadName;

  /// No description provided for @barangay.
  ///
  /// In en, this message translates to:
  /// **'Barangay'**
  String get barangay;

  /// No description provided for @municipalityCity.
  ///
  /// In en, this message translates to:
  /// **'Municipality / City'**
  String get municipalityCity;

  /// No description provided for @province.
  ///
  /// In en, this message translates to:
  /// **'Province'**
  String get province;

  /// No description provided for @nearbyLandmark.
  ///
  /// In en, this message translates to:
  /// **'Nearby landmark'**
  String get nearbyLandmark;

  /// No description provided for @reportTitleField.
  ///
  /// In en, this message translates to:
  /// **'Short report title'**
  String get reportTitleField;

  /// No description provided for @describeDamage.
  ///
  /// In en, this message translates to:
  /// **'Describe the road damage'**
  String get describeDamage;

  /// No description provided for @observedHazards.
  ///
  /// In en, this message translates to:
  /// **'Observed hazards'**
  String get observedHazards;

  /// No description provided for @reportedSeverity.
  ///
  /// In en, this message translates to:
  /// **'Reported severity'**
  String get reportedSeverity;

  /// No description provided for @severityLowHint.
  ///
  /// In en, this message translates to:
  /// **'Minor surface damage'**
  String get severityLowHint;

  /// No description provided for @severityMediumHint.
  ///
  /// In en, this message translates to:
  /// **'Needs care when passing'**
  String get severityMediumHint;

  /// No description provided for @severityHighHint.
  ///
  /// In en, this message translates to:
  /// **'Deep damage or immediate road hazard'**
  String get severityHighHint;

  /// No description provided for @reviewAddress.
  ///
  /// In en, this message translates to:
  /// **'{road}, Brgy. {barangay}'**
  String reviewAddress(String road, String barangay);

  /// No description provided for @hazardsLine.
  ///
  /// In en, this message translates to:
  /// **'Hazards: {text}'**
  String hazardsLine(String text);

  /// No description provided for @possibleDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Possible duplicate reports'**
  String get possibleDuplicates;

  /// No description provided for @possibleDuplicatesHint.
  ///
  /// In en, this message translates to:
  /// **'These nearby reports may describe the same damage. You can inspect them before continuing.'**
  String get possibleDuplicatesHint;

  /// No description provided for @duplicateDistance.
  ///
  /// In en, this message translates to:
  /// **'{distance} m away · {road}'**
  String duplicateDistance(String distance, String road);

  /// No description provided for @duplicatesAcknowledge.
  ///
  /// In en, this message translates to:
  /// **'I checked these reports and still want to submit.'**
  String get duplicatesAcknowledge;

  /// No description provided for @wizardStartsSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Your report starts as Submitted. The LGU reviews the evidence before verification.'**
  String get wizardStartsSubmitted;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait…'**
  String get pleaseWait;

  /// No description provided for @submitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get submitReport;

  /// No description provided for @findingAddress.
  ///
  /// In en, this message translates to:
  /// **'Finding address…'**
  String get findingAddress;

  /// No description provided for @addressFilledFromMap.
  ///
  /// In en, this message translates to:
  /// **'Filled from the map — please check it.'**
  String get addressFilledFromMap;

  /// No description provided for @addressNotFound.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t find the address — please type it.'**
  String get addressNotFound;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @onboardingTitlePin.
  ///
  /// In en, this message translates to:
  /// **'Pin it. Help us find it.'**
  String get onboardingTitlePin;

  /// No description provided for @onboardingTitleFollow.
  ///
  /// In en, this message translates to:
  /// **'Follow every road forward.'**
  String get onboardingTitleFollow;

  /// No description provided for @onboardingBodyPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a clear photo and tell your LGU about the damaged road.'**
  String get onboardingBodyPhoto;

  /// No description provided for @onboardingBodyPin.
  ///
  /// In en, this message translates to:
  /// **'Use GPS or tap the map. Accurate locations help the right crew reach the site.'**
  String get onboardingBodyPin;

  /// No description provided for @onboardingBodyFollow.
  ///
  /// In en, this message translates to:
  /// **'Track review, assignment and repair updates. Share feedback after LGU verification.'**
  String get onboardingBodyFollow;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Report road damage. Follow the progress. Help your community move safely.'**
  String get welcomeBody;

  /// No description provided for @explorePublicMap.
  ///
  /// In en, this message translates to:
  /// **'Explore the public map'**
  String get explorePublicMap;

  /// No description provided for @academicNote.
  ///
  /// In en, this message translates to:
  /// **'Academic demonstration · IT 305\nNo official LGU records or partnerships.'**
  String get academicNote;

  /// No description provided for @privacyRequired.
  ///
  /// In en, this message translates to:
  /// **'Please acknowledge the privacy information.'**
  String get privacyRequired;

  /// No description provided for @recoverAccount.
  ///
  /// In en, this message translates to:
  /// **'Recover account'**
  String get recoverAccount;

  /// No description provided for @recoveryHeading.
  ///
  /// In en, this message translates to:
  /// **'Let’s get you back.'**
  String get recoveryHeading;

  /// No description provided for @registerHeading.
  ///
  /// In en, this message translates to:
  /// **'Join the road forward.'**
  String get registerHeading;

  /// No description provided for @devAuthNote.
  ///
  /// In en, this message translates to:
  /// **'Development authentication · local demo API'**
  String get devAuthNote;

  /// No description provided for @signupStep.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total} · {name}'**
  String signupStep(int step, int total, String name);

  /// No description provided for @signupStepAbout.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get signupStepAbout;

  /// No description provided for @signupStepAddress.
  ///
  /// In en, this message translates to:
  /// **'Your address'**
  String get signupStepAddress;

  /// No description provided for @signupStepSecure.
  ///
  /// In en, this message translates to:
  /// **'Secure your account'**
  String get signupStepSecure;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddress;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get invalidEmail;

  /// No description provided for @addressPrivateNote.
  ///
  /// In en, this message translates to:
  /// **'Your address stays on your private account. You will pin the pothole separately when reporting.'**
  String get addressPrivateNote;

  /// No description provided for @streetOptional.
  ///
  /// In en, this message translates to:
  /// **'Street / house number (optional)'**
  String get streetOptional;

  /// No description provided for @enterBarangay.
  ///
  /// In en, this message translates to:
  /// **'Enter your barangay.'**
  String get enterBarangay;

  /// No description provided for @cityMunicipality.
  ///
  /// In en, this message translates to:
  /// **'City / municipality'**
  String get cityMunicipality;

  /// No description provided for @enterCity.
  ///
  /// In en, this message translates to:
  /// **'Enter your city or municipality.'**
  String get enterCity;

  /// No description provided for @enterProvince.
  ///
  /// In en, this message translates to:
  /// **'Enter your province.'**
  String get enterProvince;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @passwordRule.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters with uppercase, lowercase, number, and special character.'**
  String get passwordRule;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get enterPassword;

  /// No description provided for @passwordRequirements.
  ///
  /// In en, this message translates to:
  /// **'Requires at least 8 characters including uppercase, lowercase, number, and special character.'**
  String get passwordRequirements;

  /// No description provided for @privacyAcknowledge.
  ///
  /// In en, this message translates to:
  /// **'I understand this academic demo stores test account data locally. I will not use personal information.'**
  String get privacyAcknowledge;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connecting;

  /// No description provided for @requestRecovery.
  ///
  /// In en, this message translates to:
  /// **'Request recovery'**
  String get requestRecovery;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAccount;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @exploreDemoNote.
  ///
  /// In en, this message translates to:
  /// **'Explore the demo without a password.'**
  String get exploreDemoNote;

  /// No description provided for @continueAsDemo.
  ///
  /// In en, this message translates to:
  /// **'Continue as demo citizen'**
  String get continueAsDemo;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @helloName.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}.'**
  String helloName(String name);

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A little tag. A better road.'**
  String get homeSubtitle;

  /// No description provided for @homeCallToAction.
  ///
  /// In en, this message translates to:
  /// **'I-tag mo na. Help your community move safely.'**
  String get homeCallToAction;

  /// No description provided for @aroundYou.
  ///
  /// In en, this message translates to:
  /// **'Around you'**
  String get aroundYou;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @yourImpact.
  ///
  /// In en, this message translates to:
  /// **'Your impact'**
  String get yourImpact;

  /// No description provided for @viewReports.
  ///
  /// In en, this message translates to:
  /// **'View reports'**
  String get viewReports;

  /// No description provided for @totalReports.
  ///
  /// In en, this message translates to:
  /// **'Total reports'**
  String get totalReports;

  /// No description provided for @everyTagCounts.
  ///
  /// In en, this message translates to:
  /// **'Every tag counts.'**
  String get everyTagCounts;

  /// No description provided for @metricUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get metricUnderReview;

  /// No description provided for @metricInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get metricInProgress;

  /// No description provided for @metricResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get metricResolved;

  /// No description provided for @latestReport.
  ///
  /// In en, this message translates to:
  /// **'Latest report'**
  String get latestReport;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @firstTagTitle.
  ///
  /// In en, this message translates to:
  /// **'Your first tag starts here.'**
  String get firstTagTitle;

  /// No description provided for @firstTagBody.
  ///
  /// In en, this message translates to:
  /// **'Send a clear photo and a location.'**
  String get firstTagBody;

  /// No description provided for @clearerPictureTitle.
  ///
  /// In en, this message translates to:
  /// **'A clearer picture helps.'**
  String get clearerPictureTitle;

  /// No description provided for @clearerPictureBody.
  ///
  /// In en, this message translates to:
  /// **'Stay safe, add a landmark and check your map pin.'**
  String get clearerPictureBody;

  /// No description provided for @readGuide.
  ///
  /// In en, this message translates to:
  /// **'Read the reporting guide'**
  String get readGuide;

  /// No description provided for @demoReportsNote.
  ///
  /// In en, this message translates to:
  /// **'Fictional demonstration reports · IT 305'**
  String get demoReportsNote;

  /// No description provided for @yourProfile.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get yourProfile;

  /// No description provided for @myReportsHeading.
  ///
  /// In en, this message translates to:
  /// **'Your tags. Their progress.'**
  String get myReportsHeading;

  /// No description provided for @searchReports.
  ///
  /// In en, this message translates to:
  /// **'Search road or reference'**
  String get searchReports;

  /// No description provided for @newestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get newestFirst;

  /// No description provided for @oldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get oldestFirst;

  /// No description provided for @noReportsFound.
  ///
  /// In en, this message translates to:
  /// **'No reports found'**
  String get noReportsFound;

  /// No description provided for @noReportsFoundBody.
  ///
  /// In en, this message translates to:
  /// **'Try another search or start a new report.'**
  String get noReportsFoundBody;

  /// No description provided for @reportDetails.
  ///
  /// In en, this message translates to:
  /// **'Report details'**
  String get reportDetails;

  /// No description provided for @reportNotFound.
  ///
  /// In en, this message translates to:
  /// **'Report not found'**
  String get reportNotFound;

  /// No description provided for @reportNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'Refresh your reports, or check the public map.'**
  String get reportNotFoundBody;

  /// No description provided for @detailsAddress.
  ///
  /// In en, this message translates to:
  /// **'Brgy. {barangay}, {city}, {province}'**
  String detailsAddress(String barangay, String city, String province);

  /// No description provided for @roadToResolution.
  ///
  /// In en, this message translates to:
  /// **'The road to resolution'**
  String get roadToResolution;

  /// No description provided for @repairDocumentation.
  ///
  /// In en, this message translates to:
  /// **'Repair documentation'**
  String get repairDocumentation;

  /// No description provided for @shareRepairFeedback.
  ///
  /// In en, this message translates to:
  /// **'Share repair feedback'**
  String get shareRepairFeedback;

  /// No description provided for @feedbackRecorded.
  ///
  /// In en, this message translates to:
  /// **'Salamat! Your feedback is recorded.'**
  String get feedbackRecorded;

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted'**
  String get reportSubmitted;

  /// No description provided for @reportSubmittedBody.
  ///
  /// In en, this message translates to:
  /// **'Your report has been submitted for review. The LGU will check the evidence and location.'**
  String get reportSubmittedBody;

  /// No description provided for @viewReport.
  ///
  /// In en, this message translates to:
  /// **'View report'**
  String get viewReport;

  /// No description provided for @returnHome.
  ///
  /// In en, this message translates to:
  /// **'Return home'**
  String get returnHome;

  /// No description provided for @readAll.
  ///
  /// In en, this message translates to:
  /// **'Read all'**
  String get readAll;

  /// No description provided for @allQuiet.
  ///
  /// In en, this message translates to:
  /// **'All quiet for now'**
  String get allQuiet;

  /// No description provided for @allQuietBody.
  ///
  /// In en, this message translates to:
  /// **'Report progress updates will appear here.'**
  String get allQuietBody;

  /// No description provided for @notificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{reportId} · {date}'**
  String notificationSubtitle(String reportId, String date);

  /// No description provided for @repairFeedback.
  ///
  /// In en, this message translates to:
  /// **'Repair feedback'**
  String get repairFeedback;

  /// No description provided for @repairNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Repair not yet verified'**
  String get repairNotVerified;

  /// No description provided for @repairNotVerifiedBody.
  ///
  /// In en, this message translates to:
  /// **'Feedback opens after the LGU verifies the completed repair.'**
  String get repairNotVerifiedBody;

  /// No description provided for @howWasRepair.
  ///
  /// In en, this message translates to:
  /// **'How was the repair?'**
  String get howWasRepair;

  /// No description provided for @feedbackSaved.
  ///
  /// In en, this message translates to:
  /// **'Your feedback has been recorded.'**
  String get feedbackSaved;

  /// No description provided for @feedbackAlready.
  ///
  /// In en, this message translates to:
  /// **'You already shared feedback for this repair.'**
  String get feedbackAlready;

  /// No description provided for @starsTooltip.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 star} other{{count} stars}}'**
  String starsTooltip(int count);

  /// No description provided for @yourRepairFeedback.
  ///
  /// In en, this message translates to:
  /// **'Your repair feedback'**
  String get yourRepairFeedback;

  /// No description provided for @submitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get submitting;

  /// No description provided for @submitFeedback.
  ///
  /// In en, this message translates to:
  /// **'Submit feedback'**
  String get submitFeedback;

  /// No description provided for @feedbackIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Choose a rating and add feedback.'**
  String get feedbackIncomplete;

  /// No description provided for @defaultCitizenName.
  ///
  /// In en, this message translates to:
  /// **'Citizen'**
  String get defaultCitizenName;

  /// No description provided for @profileAddress.
  ///
  /// In en, this message translates to:
  /// **'Address · {address}'**
  String profileAddress(String address);

  /// No description provided for @communityReportsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 community report} other{{count} community reports}}'**
  String communityReportsCount(int count);

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @reportingGuide.
  ///
  /// In en, this message translates to:
  /// **'Reporting guide'**
  String get reportingGuide;

  /// No description provided for @aboutPatag.
  ///
  /// In en, this message translates to:
  /// **'About PATAG'**
  String get aboutPatag;

  /// No description provided for @emailChangeNote.
  ///
  /// In en, this message translates to:
  /// **'Email changes require verified account recovery.'**
  String get emailChangeNote;

  /// No description provided for @privateAddressNote.
  ///
  /// In en, this message translates to:
  /// **'Private address · separate from each road report'**
  String get privateAddressNote;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get saveProfile;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved.'**
  String get profileSaved;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @appearanceBody.
  ///
  /// In en, this message translates to:
  /// **'Use light, dark, or your device setting.'**
  String get appearanceBody;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @showUnread.
  ///
  /// In en, this message translates to:
  /// **'Show unread notification indicators'**
  String get showUnread;

  /// No description provided for @showUnreadBody.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device. Update history remains available.'**
  String get showUnreadBody;

  /// No description provided for @permissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera & location permissions'**
  String get permissionsTitle;

  /// No description provided for @permissionsBody.
  ///
  /// In en, this message translates to:
  /// **'Permissions are requested when needed. If denied, choose a gallery photo or manually tap the map. You can manage access in Android Settings → Apps → PATAG.'**
  String get permissionsBody;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @privacyBody.
  ///
  /// In en, this message translates to:
  /// **'Public reports omit your identity. This academic demo stores test records on a local API. Use fictional account information.'**
  String get privacyBody;

  /// No description provided for @mapboxNotice.
  ///
  /// In en, this message translates to:
  /// **'When you place a pin, its coordinates are sent to Mapbox through PATAG\'s server to look up the address.'**
  String get mapboxNotice;

  /// No description provided for @guideHeading.
  ///
  /// In en, this message translates to:
  /// **'A good report goes further.'**
  String get guideHeading;

  /// No description provided for @aboutMeaning.
  ///
  /// In en, this message translates to:
  /// **'PATAG means a level or smooth surface. Read as “pa-tag”, it also means calling attention to a problem.'**
  String get aboutMeaning;

  /// No description provided for @aboutMission.
  ///
  /// In en, this message translates to:
  /// **'Our mission is to empower communities to report road problems, connect citizens with local authorities, and turn reports into action.'**
  String get aboutMission;

  /// No description provided for @aboutAcademic.
  ///
  /// In en, this message translates to:
  /// **'An academic final project for IT 305 – Advanced Web Development, Bulacan State University. This demonstration does not represent official LGU records or partnerships.'**
  String get aboutAcademic;

  /// No description provided for @guidePhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'1. Photograph safely'**
  String get guidePhotoTitle;

  /// No description provided for @guidePhotoBody.
  ///
  /// In en, this message translates to:
  /// **'Take clear photos of the damaged surface. Do not stand in traffic. Upload JPEG, PNG or WebP images under 8 MB.'**
  String get guidePhotoBody;

  /// No description provided for @guideLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'2. Set the location'**
  String get guideLocationTitle;

  /// No description provided for @guideLocationBody.
  ///
  /// In en, this message translates to:
  /// **'Use GPS when permission is granted. If GPS is off, denied or inaccurate, tap the map to pin manually or enter coordinates. Add road, barangay, city and province.'**
  String get guideLocationBody;

  /// No description provided for @guideDescribeTitle.
  ///
  /// In en, this message translates to:
  /// **'3. Describe the damage'**
  String get guideDescribeTitle;

  /// No description provided for @guideDescribeBody.
  ///
  /// In en, this message translates to:
  /// **'Explain the pothole and hazards. Your severity estimate is reviewed by the LGU.'**
  String get guideDescribeBody;

  /// No description provided for @guideDuplicatesTitle.
  ///
  /// In en, this message translates to:
  /// **'4. Check for duplicates'**
  String get guideDuplicatesTitle;

  /// No description provided for @guideDuplicatesBody.
  ///
  /// In en, this message translates to:
  /// **'Nearby reports on the same road may refer to the same damage. Inspect suggestions before submitting. The system never silently merges your report.'**
  String get guideDuplicatesBody;

  /// No description provided for @guideProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'5. Follow the progress'**
  String get guideProgressTitle;

  /// No description provided for @guideProgressBody.
  ///
  /// In en, this message translates to:
  /// **'Submitted → Under Review → Verified → Assigned → In Progress → Resolved. Only an LGU-verified repair is Resolved.'**
  String get guideProgressBody;

  /// No description provided for @guideOutcomesTitle.
  ///
  /// In en, this message translates to:
  /// **'Other outcomes'**
  String get guideOutcomesTitle;

  /// No description provided for @guideOutcomesBody.
  ///
  /// In en, this message translates to:
  /// **'Rejected reports include a reason. Duplicate means the LGU confirmed an existing case. Reports may be forwarded to the responsible agency.'**
  String get guideOutcomesBody;

  /// No description provided for @guideFeedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'6. Share feedback'**
  String get guideFeedbackTitle;

  /// No description provided for @guideFeedbackBody.
  ///
  /// In en, this message translates to:
  /// **'Once the repair is resolved, open your report and submit a rating and feedback.'**
  String get guideFeedbackBody;

  /// No description provided for @guideConnectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection & drafts'**
  String get guideConnectionTitle;

  /// No description provided for @guideConnectionBody.
  ///
  /// In en, this message translates to:
  /// **'Your reporting draft is saved on this device. Submission needs internet access to the configured API. There is no automatic offline synchronization.'**
  String get guideConnectionBody;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFound;

  /// No description provided for @pageNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'Use the navigation to continue.'**
  String get pageNotFoundBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fil'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fil':
      return AppLocalizationsFil();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
