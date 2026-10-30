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
    Locale('fil'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'PATAG Maintenance'**
  String get appTitle;

  /// No description provided for @devicePreviewLabel.
  ///
  /// In en, this message translates to:
  /// **'PATAG Crew Mobile · Portrait Phone View'**
  String get devicePreviewLabel;

  /// Always bilingual: same text in every language.
  ///
  /// In en, this message translates to:
  /// **'Wika / Language'**
  String get languageSettingTitle;

  /// No description provided for @languageSettingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the language of the app.'**
  String get languageSettingSubtitle;

  /// No description provided for @languageTagalog.
  ///
  /// In en, this message translates to:
  /// **'Tagalog'**
  String get languageTagalog;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @themeSwitchToLight.
  ///
  /// In en, this message translates to:
  /// **'Switch to light mode'**
  String get themeSwitchToLight;

  /// No description provided for @themeSwitchToDark.
  ///
  /// In en, this message translates to:
  /// **'Switch to dark mode'**
  String get themeSwitchToDark;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Brand Taglish line. Keep identical in every language.
  ///
  /// In en, this message translates to:
  /// **'Bawat lubak, may agarang aksyon.'**
  String get brandEveryPothole;

  /// Brand Taglish line. Keep identical in every language.
  ///
  /// In en, this message translates to:
  /// **'Mabilis na kumpuni, ligtas na biyahe.'**
  String get brandFastRepair;

  /// Brand Taglish line. Keep identical in every language.
  ///
  /// In en, this message translates to:
  /// **'Handa na ang mga work order.'**
  String get brandWorkOrdersReady;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Road Maintenance Operations'**
  String get splashTagline;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Access assigned work orders, document road repairs on site, and upload evidence directly to the LGU portal.'**
  String get welcomeBody;

  /// No description provided for @welcomeSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Workspace'**
  String get welcomeSignIn;

  /// No description provided for @welcomeContinueAs.
  ///
  /// In en, this message translates to:
  /// **'Continue as {team}'**
  String welcomeContinueAs(String team);

  /// No description provided for @welcomeFooter.
  ///
  /// In en, this message translates to:
  /// **'Academic demonstration · IT 305\nCity of Malolos Road Maintenance Operations.'**
  String get welcomeFooter;

  /// No description provided for @loginHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Safer roads start here.'**
  String get loginHeroTitle;

  /// No description provided for @loginHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Report clearly. Track progress. See the repair through.'**
  String get loginHeroSubtitle;

  /// No description provided for @loginBadge.
  ///
  /// In en, this message translates to:
  /// **'MAINTENANCE ACCOUNT'**
  String get loginBadge;

  /// No description provided for @loginWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginWelcome;

  /// No description provided for @loginIntro.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view assignments and update road repairs.'**
  String get loginIntro;

  /// No description provided for @loginHeading.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get loginHeading;

  /// No description provided for @loginEmail.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get loginEmail;

  /// No description provided for @loginPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPassword;

  /// No description provided for @loginShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get loginShowPassword;

  /// No description provided for @loginHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get loginHidePassword;

  /// No description provided for @loginSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get loginSigningIn;

  /// No description provided for @loginAccountAssigned.
  ///
  /// In en, this message translates to:
  /// **'Account assigned by LGU Admin'**
  String get loginAccountAssigned;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get loginForgotPassword;

  /// No description provided for @loginForgotPasswordHelp.
  ///
  /// In en, this message translates to:
  /// **'Maintenance accounts are assigned and managed by the LGU Admin. Contact your supervisor to reset credentials.'**
  String get loginForgotPasswordHelp;

  /// No description provided for @loginDemoTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore fictional demo data'**
  String get loginDemoTitle;

  /// No description provided for @loginDemoBody.
  ///
  /// In en, this message translates to:
  /// **'Separate test access for the seeded crew account.'**
  String get loginDemoBody;

  /// No description provided for @loginDemoOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening…'**
  String get loginDemoOpening;

  /// No description provided for @loginDemoButton.
  ///
  /// In en, this message translates to:
  /// **'Open maintenance demo'**
  String get loginDemoButton;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get navTasks;

  /// No description provided for @navRepair.
  ///
  /// In en, this message translates to:
  /// **'Repair'**
  String get navRepair;

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

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
  /// **'Awaiting Verification'**
  String get statusAwaitingVerification;

  /// No description provided for @statusAdditionalWorkRequested.
  ///
  /// In en, this message translates to:
  /// **'Additional Work Requested'**
  String get statusAdditionalWorkRequested;

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

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @notificationsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTooltip;

  /// No description provided for @profileTooltip.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get profileTooltip;

  /// No description provided for @dashboardGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}.'**
  String dashboardGreeting(String name);

  /// No description provided for @greetingFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Crew'**
  String get greetingFallbackName;

  /// No description provided for @dashboardReadyCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 work order ready for action.} other{{count} work orders ready for action.}}'**
  String dashboardReadyCount(int count);

  /// No description provided for @dashboardReviewNext.
  ///
  /// In en, this message translates to:
  /// **'Review next work order'**
  String get dashboardReviewNext;

  /// No description provided for @dashboardActiveWorkOrders.
  ///
  /// In en, this message translates to:
  /// **'Active Work Orders'**
  String get dashboardActiveWorkOrders;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @dashboardEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'All clear for now'**
  String get dashboardEmptyTitle;

  /// No description provided for @dashboardEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'No pending road repairs assigned to your team.'**
  String get dashboardEmptyBody;

  /// No description provided for @safetyTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety Protocol On Site'**
  String get safetyTitle;

  /// No description provided for @safetyBody.
  ///
  /// In en, this message translates to:
  /// **'Deploy safety cones 15m ahead, wear high-vis vests, and log before & after photos.'**
  String get safetyBody;

  /// No description provided for @assignmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Assignments'**
  String get assignmentsTitle;

  /// No description provided for @assignmentsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search road, barangay, or ID…'**
  String get assignmentsSearchHint;

  /// No description provided for @assignmentsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching work orders'**
  String get assignmentsEmptyTitle;

  /// No description provided for @assignmentsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Try another filter or check for newly assigned tasks.'**
  String get assignmentsEmptyBody;

  /// No description provided for @inProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Repairs In Progress'**
  String get inProgressTitle;

  /// No description provided for @inProgressEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No repairs in progress'**
  String get inProgressEmptyTitle;

  /// No description provided for @inProgressEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Select an assigned task from Work Orders and tap \"{action}\" to begin work.'**
  String inProgressEmptyBody(String action);

  /// No description provided for @taskCardSite.
  ///
  /// In en, this message translates to:
  /// **'Site'**
  String get taskCardSite;

  /// No description provided for @taskCardFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Road Damage Work Order'**
  String get taskCardFallbackTitle;

  /// No description provided for @taskFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Road Work Order'**
  String get taskFallbackTitle;

  /// No description provided for @barangayShort.
  ///
  /// In en, this message translates to:
  /// **'Brgy. {barangay}'**
  String barangayShort(String barangay);

  /// No description provided for @taskLocation.
  ///
  /// In en, this message translates to:
  /// **'Brgy. {barangay}, {city}, {province}'**
  String taskLocation(String barangay, String city, String province);

  /// No description provided for @mapTaskLocation.
  ///
  /// In en, this message translates to:
  /// **'Brgy. {barangay}, {city} · {reportId}'**
  String mapTaskLocation(String barangay, String city, String reportId);

  /// No description provided for @taskDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Task Details'**
  String get taskDetailsTitle;

  /// No description provided for @taskNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Task not found'**
  String get taskNotFoundTitle;

  /// No description provided for @taskNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'This task could not be loaded.'**
  String get taskNotFoundBody;

  /// No description provided for @beforePhotosHeading.
  ///
  /// In en, this message translates to:
  /// **'Before-Repair Inspection Photos'**
  String get beforePhotosHeading;

  /// No description provided for @afterPhotosHeading.
  ///
  /// In en, this message translates to:
  /// **'After-Repair Completion Photos'**
  String get afterPhotosHeading;

  /// No description provided for @assignmentDetails.
  ///
  /// In en, this message translates to:
  /// **'Assignment Details'**
  String get assignmentDetails;

  /// No description provided for @lguNote.
  ///
  /// In en, this message translates to:
  /// **'LGU Note: {note}'**
  String lguNote(String note);

  /// No description provided for @targetCompletion.
  ///
  /// In en, this message translates to:
  /// **'Target Completion: {date}'**
  String targetCompletion(String date);

  /// No description provided for @coordinatesLine.
  ///
  /// In en, this message translates to:
  /// **'Coordinates: {lat}, {lng}'**
  String coordinatesLine(String lat, String lng);

  /// No description provided for @beforeInspectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Before-Repair Inspection'**
  String get beforeInspectionTitle;

  /// No description provided for @beforeInspectionBody.
  ///
  /// In en, this message translates to:
  /// **'Record a photo of the damaged road before repair work starts.'**
  String get beforeInspectionBody;

  /// No description provided for @addBeforePhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Before Photo'**
  String get addBeforePhoto;

  /// No description provided for @updating.
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get updating;

  /// No description provided for @startRepair.
  ///
  /// In en, this message translates to:
  /// **'Start Inspection / Repair'**
  String get startRepair;

  /// No description provided for @awaitingVerificationInfo.
  ///
  /// In en, this message translates to:
  /// **'Repair submitted. Waiting for the LGU to verify your evidence before the task is resolved.'**
  String get awaitingVerificationInfo;

  /// No description provided for @moreWorkRequested.
  ///
  /// In en, this message translates to:
  /// **'The LGU requested more work on this repair.'**
  String get moreWorkRequested;

  /// No description provided for @moreWorkRequestedNote.
  ///
  /// In en, this message translates to:
  /// **'More work requested by the LGU: {note}'**
  String moreWorkRequestedNote(String note);

  /// No description provided for @afterEvidenceTitle.
  ///
  /// In en, this message translates to:
  /// **'After-Repair Completion Evidence'**
  String get afterEvidenceTitle;

  /// No description provided for @afterEvidenceBody.
  ///
  /// In en, this message translates to:
  /// **'Add photos of the patched road surface before submitting the completion report.'**
  String get afterEvidenceBody;

  /// No description provided for @addAfterPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add After Photo'**
  String get addAfterPhoto;

  /// No description provided for @documentAndSubmit.
  ///
  /// In en, this message translates to:
  /// **'Document & Submit Completion'**
  String get documentAndSubmit;

  /// No description provided for @resolvedInfo.
  ///
  /// In en, this message translates to:
  /// **'Repair verified and resolved by LGU.'**
  String get resolvedInfo;

  /// No description provided for @repairStarted.
  ///
  /// In en, this message translates to:
  /// **'Repair started! Task is now {status}.'**
  String repairStarted(String status);

  /// No description provided for @errorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorWithMessage(String message);

  /// No description provided for @beforePhotoUploaded.
  ///
  /// In en, this message translates to:
  /// **'Before-repair photo uploaded.'**
  String get beforePhotoUploaded;

  /// No description provided for @afterPhotoUploaded.
  ///
  /// In en, this message translates to:
  /// **'After-repair photo uploaded.'**
  String get afterPhotoUploaded;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {message}'**
  String uploadFailed(String message);

  /// No description provided for @progressTitle.
  ///
  /// In en, this message translates to:
  /// **'TASK PROGRESS'**
  String get progressTitle;

  /// No description provided for @progressAssignedToCrew.
  ///
  /// In en, this message translates to:
  /// **'Assigned to Crew'**
  String get progressAssignedToCrew;

  /// No description provided for @progressAwaitingVerification.
  ///
  /// In en, this message translates to:
  /// **'Awaiting LGU Verification'**
  String get progressAwaitingVerification;

  /// No description provided for @progressMoreWork.
  ///
  /// In en, this message translates to:
  /// **'More Work Requested'**
  String get progressMoreWork;

  /// No description provided for @progressRepairInProgress.
  ///
  /// In en, this message translates to:
  /// **'Repair In Progress'**
  String get progressRepairInProgress;

  /// No description provided for @progressCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed & Verified'**
  String get progressCompleted;

  /// No description provided for @progressSummary.
  ///
  /// In en, this message translates to:
  /// **'{percent}% · {step}'**
  String progressSummary(int percent, String step);

  /// No description provided for @progressStep.
  ///
  /// In en, this message translates to:
  /// **'{number}. {label}'**
  String progressStep(int number, String label);

  /// No description provided for @documentRepairTitle.
  ///
  /// In en, this message translates to:
  /// **'Document Repair'**
  String get documentRepairTitle;

  /// No description provided for @uploadAfterEvidence.
  ///
  /// In en, this message translates to:
  /// **'Upload After-Repair Evidence'**
  String get uploadAfterEvidence;

  /// No description provided for @uploadAfterEvidenceBody.
  ///
  /// In en, this message translates to:
  /// **'Provide clear photos of the patched and compacted road surface.'**
  String get uploadAfterEvidenceBody;

  /// No description provided for @takeAfterPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take / Select After Photo'**
  String get takeAfterPhoto;

  /// No description provided for @workNotesHeading.
  ///
  /// In en, this message translates to:
  /// **'Work Performed / Progress Notes'**
  String get workNotesHeading;

  /// No description provided for @workNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Describe materials used, compaction, curing time…'**
  String get workNotesHint;

  /// No description provided for @defaultWorkNote.
  ///
  /// In en, this message translates to:
  /// **'Base compacted, crack seal applied, and hot asphalt patched to grade.'**
  String get defaultWorkNote;

  /// No description provided for @submitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get submitting;

  /// No description provided for @submitForVerification.
  ///
  /// In en, this message translates to:
  /// **'Submit for Verification'**
  String get submitForVerification;

  /// No description provided for @photoUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Photo upload failed: {message}'**
  String photoUploadFailed(String message);

  /// No description provided for @completionRequirements.
  ///
  /// In en, this message translates to:
  /// **'Add at least one after photo and describe the work.'**
  String get completionRequirements;

  /// No description provided for @submissionFailed.
  ///
  /// In en, this message translates to:
  /// **'Submission failed: {message}'**
  String submissionFailed(String message);

  /// No description provided for @successTitle.
  ///
  /// In en, this message translates to:
  /// **'Work submitted.\nOne step closer to patag.'**
  String get successTitle;

  /// No description provided for @successBody.
  ///
  /// In en, this message translates to:
  /// **'{reportId} · The LGU engineering office will review your evidence before closing the task.'**
  String successBody(String reportId);

  /// No description provided for @returnToOverview.
  ///
  /// In en, this message translates to:
  /// **'Return to Overview'**
  String get returnToOverview;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'No new notifications for your crew.'**
  String get notificationsEmptyBody;

  /// No description provided for @notificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{reportId} · {date}'**
  String notificationSubtitle(String reportId, String date);

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile & Settings'**
  String get profileTitle;

  /// No description provided for @profileFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Personnel'**
  String get profileFallbackName;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeMode;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @unreadIndicators.
  ///
  /// In en, this message translates to:
  /// **'Unread Indicators'**
  String get unreadIndicators;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About PATAG Maintenance'**
  String get aboutTitle;

  /// No description provided for @aboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'IT 305 · Bulacan State University'**
  String get aboutSubtitle;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out of Workspace'**
  String get signOut;

  /// No description provided for @mapTitle.
  ///
  /// In en, this message translates to:
  /// **'Assigned Task Map'**
  String get mapTitle;

  /// No description provided for @mapRecenter.
  ///
  /// In en, this message translates to:
  /// **'Center map'**
  String get mapRecenter;

  /// No description provided for @openTaskDetails.
  ///
  /// In en, this message translates to:
  /// **'Open Task Details'**
  String get openTaskDetails;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'{label} is required.'**
  String fieldRequired(String label);

  /// No description provided for @photoBefore.
  ///
  /// In en, this message translates to:
  /// **'Before-repair photo'**
  String get photoBefore;

  /// No description provided for @photoAfter.
  ///
  /// In en, this message translates to:
  /// **'After-repair photo'**
  String get photoAfter;

  /// No description provided for @photoPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Photo not available'**
  String get photoPlaceholder;

  /// No description provided for @serverConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to PATAG… A server that was asleep can take up to a minute.'**
  String get serverConnecting;

  /// No description provided for @errorServerDown.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the PATAG server. Is the backend running?'**
  String get errorServerDown;

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timed out. Please retry.'**
  String get errorTimeout;

  /// No description provided for @errorUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the PATAG server. Check your connection and try again.'**
  String get errorUnreachable;

  /// No description provided for @errorServerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The PATAG server is unavailable ({code}). Please retry in a moment.'**
  String errorServerUnavailable(int code);

  /// No description provided for @errorUnexpectedResponse.
  ///
  /// In en, this message translates to:
  /// **'Unexpected response from the PATAG server ({code}).'**
  String errorUnexpectedResponse(int code);

  /// No description provided for @errorRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Request failed.'**
  String get errorRequestFailed;

  /// No description provided for @errorNotMaintenance.
  ///
  /// In en, this message translates to:
  /// **'This account does not belong to road maintenance.'**
  String get errorNotMaintenance;

  /// No description provided for @errorPhotoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Choose a photo under 8 MB.'**
  String get errorPhotoTooLarge;

  /// No description provided for @errorPhotoType.
  ///
  /// In en, this message translates to:
  /// **'Choose a JPEG, PNG or WebP photo.'**
  String get errorPhotoType;

  /// No description provided for @errorPhotoMismatch.
  ///
  /// In en, this message translates to:
  /// **'Image content does not match its type.'**
  String get errorPhotoMismatch;

  /// No description provided for @errorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Sign in again.'**
  String get errorSessionExpired;

  /// No description provided for @errorBadCredentials.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect for this portal.'**
  String get errorBadCredentials;

  /// No description provided for @errorTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a minute and try again.'**
  String get errorTooManyAttempts;

  /// No description provided for @errorActionNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This action is not allowed from the current report status.'**
  String get errorActionNotAllowed;

  /// No description provided for @errorRepairEvidenceRequired.
  ///
  /// In en, this message translates to:
  /// **'Repair notes and after photos are required.'**
  String get errorRepairEvidenceRequired;

  /// No description provided for @errorBeforePhotosRequired.
  ///
  /// In en, this message translates to:
  /// **'Upload before-repair photos.'**
  String get errorBeforePhotosRequired;

  /// No description provided for @errorProgressNoteRequired.
  ///
  /// In en, this message translates to:
  /// **'Add a progress note.'**
  String get errorProgressNoteRequired;

  /// No description provided for @errorUploadPhotoFirst.
  ///
  /// In en, this message translates to:
  /// **'Upload the photo first, then attach it.'**
  String get errorUploadPhotoFirst;

  /// No description provided for @errorUploadRealPhotos.
  ///
  /// In en, this message translates to:
  /// **'Upload real repair photos first.'**
  String get errorUploadRealPhotos;

  /// No description provided for @errorReportNotFound.
  ///
  /// In en, this message translates to:
  /// **'Report not found.'**
  String get errorReportNotFound;

  /// No description provided for @errorPhotoNotFound.
  ///
  /// In en, this message translates to:
  /// **'Photo not found.'**
  String get errorPhotoNotFound;

  /// No description provided for @errorOtherTeam.
  ///
  /// In en, this message translates to:
  /// **'This report belongs to another account or team.'**
  String get errorOtherTeam;

  /// No description provided for @errorDemoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Demo role unavailable.'**
  String get errorDemoUnavailable;

  /// No description provided for @errorCheckAction.
  ///
  /// In en, this message translates to:
  /// **'Check the action details and try again.'**
  String get errorCheckAction;

  /// No description provided for @errorMaintenanceOnly.
  ///
  /// In en, this message translates to:
  /// **'Maintenance can start work, update progress or submit evidence; LGU verification is required for resolution.'**
  String get errorMaintenanceOnly;

  /// No description provided for @errorServerGeneric.
  ///
  /// In en, this message translates to:
  /// **'PATAG could not complete this request. Please try again.'**
  String get errorServerGeneric;

  /// No description provided for @errorInvalidRequest.
  ///
  /// In en, this message translates to:
  /// **'Invalid request.'**
  String get errorInvalidRequest;
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
