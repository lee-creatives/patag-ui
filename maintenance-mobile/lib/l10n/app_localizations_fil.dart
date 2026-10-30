// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Filipino Pilipino (`fil`).
class AppLocalizationsFil extends AppLocalizations {
  AppLocalizationsFil([String locale = 'fil']) : super(locale);

  @override
  String get appTitle => 'PATAG Maintenance';

  @override
  String get devicePreviewLabel =>
      'PATAG Crew Mobile · Portrait na View ng Phone';

  @override
  String get languageSettingTitle => 'Wika / Language';

  @override
  String get languageSettingSubtitle => 'Piliin ang wika ng app.';

  @override
  String get languageTagalog => 'Tagalog';

  @override
  String get languageEnglish => 'English';

  @override
  String get themeSwitchToLight => 'Lumipat sa light mode';

  @override
  String get themeSwitchToDark => 'Lumipat sa dark mode';

  @override
  String get retry => 'Subukan ulit';

  @override
  String get refresh => 'I-refresh';

  @override
  String get brandEveryPothole => 'Bawat lubak, may agarang aksyon.';

  @override
  String get brandFastRepair => 'Mabilis na kumpuni, ligtas na biyahe.';

  @override
  String get brandWorkOrdersReady => 'Handa na ang mga work order.';

  @override
  String get splashTagline => 'Operasyon sa Pagkukumpuni ng Kalsada';

  @override
  String get welcomeBody =>
      'Tingnan ang mga naka-assign na work order, i-document ang repair mismo sa site, at i-upload ang ebidensya diretso sa LGU portal.';

  @override
  String get welcomeSignIn => 'Mag-sign in sa Workspace';

  @override
  String welcomeContinueAs(String team) {
    return 'Magpatuloy bilang $team';
  }

  @override
  String get welcomeFooter =>
      'Akademikong demo · IT 305\nOperasyon sa Pagkukumpuni ng Kalsada ng Lungsod ng Malolos.';

  @override
  String get loginHeroTitle => 'Dito nagsisimula ang mas ligtas na kalsada.';

  @override
  String get loginHeroSubtitle =>
      'Malinaw na ulat. Bantay sa progreso. Tapos ang repair.';

  @override
  String get loginBadge => 'ACCOUNT NG MAINTENANCE';

  @override
  String get loginWelcome => 'Maligayang pagbabalik';

  @override
  String get loginIntro =>
      'Mag-sign in para makita ang mga assignment at ma-update ang mga repair sa kalsada.';

  @override
  String get loginHeading => 'Mag-log in';

  @override
  String get loginEmail => 'Email address';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginShowPassword => 'Ipakita ang password';

  @override
  String get loginHidePassword => 'Itago ang password';

  @override
  String get loginSigningIn => 'Nagsa-sign in…';

  @override
  String get loginAccountAssigned => 'Account na bigay ng LGU Admin';

  @override
  String get loginForgotPassword => 'Nakalimutan ang password?';

  @override
  String get loginForgotPasswordHelp =>
      'Ang LGU Admin ang nagbibigay at namamahala ng mga maintenance account. Kausapin ang inyong supervisor para ma-reset ang login ninyo.';

  @override
  String get loginDemoTitle => 'Subukan ang demo (kunwaring data)';

  @override
  String get loginDemoBody =>
      'Hiwalay na test access para sa nakahandang crew account.';

  @override
  String get loginDemoOpening => 'Binubuksan…';

  @override
  String get loginDemoButton => 'Buksan ang maintenance demo';

  @override
  String get navHome => 'Home';

  @override
  String get navTasks => 'Mga Task';

  @override
  String get navRepair => 'Repair';

  @override
  String get navMap => 'Mapa';

  @override
  String get navProfile => 'Profile';

  @override
  String get statusSubmitted => 'Naisumite';

  @override
  String get statusUnderReview => 'Sinusuri';

  @override
  String get statusVerified => 'Na-verify';

  @override
  String get statusAssigned => 'Naka-assign';

  @override
  String get statusInProgress => 'Ginagawa';

  @override
  String get statusResolved => 'Naayos na';

  @override
  String get statusRejected => 'Hindi tinanggap';

  @override
  String get statusDuplicate => 'Doble';

  @override
  String get statusAwaitingVerification => 'Hinihintay ang Verification';

  @override
  String get statusAdditionalWorkRequested =>
      'May Hiniling na Dagdag na Trabaho';

  @override
  String get severityLow => 'Mababa';

  @override
  String get severityMedium => 'Katamtaman';

  @override
  String get severityHigh => 'Mataas';

  @override
  String get filterAll => 'Lahat';

  @override
  String get notificationsTooltip => 'Mga abiso';

  @override
  String get profileTooltip => 'Ang profile mo';

  @override
  String dashboardGreeting(String name) {
    return 'Kumusta, $name!';
  }

  @override
  String get greetingFallbackName => 'Crew';

  @override
  String dashboardReadyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count work order ang naghihintay ng aksyon.',
      one: '1 work order ang naghihintay ng aksyon.',
    );
    return '$_temp0';
  }

  @override
  String get dashboardReviewNext => 'Tingnan ang susunod na work order';

  @override
  String get dashboardActiveWorkOrders => 'Mga Aktibong Work Order';

  @override
  String get viewAll => 'Tingnan lahat';

  @override
  String get dashboardEmptyTitle => 'Wala munang trabaho';

  @override
  String get dashboardEmptyBody =>
      'Walang naka-pending na repair na naka-assign sa team ninyo.';

  @override
  String get safetyTitle => 'Safety Protocol sa Site';

  @override
  String get safetyBody =>
      'Maglagay ng safety cone 15m bago ang site, magsuot ng high-vis vest, at kumuha ng before at after na photo.';

  @override
  String get assignmentsTitle => 'Mga Assignment Ko';

  @override
  String get assignmentsSearchHint => 'Hanapin ang kalsada, barangay, o ID…';

  @override
  String get assignmentsEmptyTitle => 'Walang tugmang work order';

  @override
  String get assignmentsEmptyBody =>
      'Subukan ang ibang filter o tingnan kung may bagong naka-assign na task.';

  @override
  String get inProgressTitle => 'Mga Repair na Ginagawa';

  @override
  String get inProgressEmptyTitle => 'Walang repair na ginagawa';

  @override
  String inProgressEmptyBody(String action) {
    return 'Pumili ng naka-assign na task sa Work Orders at pindutin ang \"$action\" para magsimula.';
  }

  @override
  String get taskCardSite => 'Site';

  @override
  String get taskCardFallbackTitle => 'Work Order sa Sirang Kalsada';

  @override
  String get taskFallbackTitle => 'Work Order sa Kalsada';

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
  String get taskDetailsTitle => 'Detalye ng Task';

  @override
  String get taskNotFoundTitle => 'Hindi makita ang task';

  @override
  String get taskNotFoundBody => 'Hindi ma-load ang task na ito.';

  @override
  String get beforePhotosHeading => 'Mga Photo Bago ang Repair (Inspeksyon)';

  @override
  String get afterPhotosHeading => 'Mga Photo Pagkatapos ng Repair';

  @override
  String get assignmentDetails => 'Detalye ng Assignment';

  @override
  String lguNote(String note) {
    return 'Bilin ng LGU: $note';
  }

  @override
  String targetCompletion(String date) {
    return 'Target na matapos: $date';
  }

  @override
  String coordinatesLine(String lat, String lng) {
    return 'Coordinates: $lat, $lng';
  }

  @override
  String get beforeInspectionTitle => 'Inspeksyon Bago ang Repair';

  @override
  String get beforeInspectionBody =>
      'Kunan ng photo ang sirang kalsada bago simulan ang repair.';

  @override
  String get addBeforePhoto => 'Magdagdag ng Before Photo';

  @override
  String get updating => 'Ina-update…';

  @override
  String get startRepair => 'Simulan ang Inspeksyon / Repair';

  @override
  String get awaitingVerificationInfo =>
      'Naipasa na ang repair. Hinihintay pa ang LGU na i-verify ang ebidensya bago ma-resolve ang task.';

  @override
  String get moreWorkRequested =>
      'Humiling ang LGU ng dagdag na trabaho sa repair na ito.';

  @override
  String moreWorkRequestedNote(String note) {
    return 'May dagdag na trabahong hiniling ang LGU: $note';
  }

  @override
  String get afterEvidenceTitle => 'Ebidensya ng Natapos na Repair';

  @override
  String get afterEvidenceBody =>
      'Magdagdag ng photo ng na-patch na kalsada bago ipasa ang completion report.';

  @override
  String get addAfterPhoto => 'Magdagdag ng After Photo';

  @override
  String get documentAndSubmit => 'I-document at Ipasa ang Natapos na Repair';

  @override
  String get resolvedInfo => 'Na-verify at naayos na ang repair ayon sa LGU.';

  @override
  String repairStarted(String status) {
    return 'Nasimulan na ang repair! $status na ang task.';
  }

  @override
  String errorWithMessage(String message) {
    return 'May error: $message';
  }

  @override
  String get beforePhotoUploaded => 'Na-upload na ang before photo.';

  @override
  String get afterPhotoUploaded => 'Na-upload na ang after photo.';

  @override
  String uploadFailed(String message) {
    return 'Hindi na-upload: $message';
  }

  @override
  String get progressTitle => 'PROGRESO NG TASK';

  @override
  String get progressAssignedToCrew => 'Naka-assign sa Crew';

  @override
  String get progressAwaitingVerification =>
      'Hinihintay ang Verification ng LGU';

  @override
  String get progressMoreWork => 'May Dagdag na Trabaho';

  @override
  String get progressRepairInProgress => 'Ginagawa ang Repair';

  @override
  String get progressCompleted => 'Tapos at Na-verify';

  @override
  String progressSummary(int percent, String step) {
    return '$percent% · $step';
  }

  @override
  String progressStep(int number, String label) {
    return '$number. $label';
  }

  @override
  String get documentRepairTitle => 'I-document ang Repair';

  @override
  String get uploadAfterEvidence =>
      'I-upload ang Ebidensya ng Natapos na Repair';

  @override
  String get uploadAfterEvidenceBody =>
      'Maglagay ng malinaw na photo ng na-patch at siniksik na kalsada.';

  @override
  String get takeAfterPhoto => 'Kumuha / Pumili ng After Photo';

  @override
  String get workNotesHeading => 'Ginawang Trabaho / Mga Tala sa Progreso';

  @override
  String get workNotesHint =>
      'Ilarawan ang materyales na ginamit, compaction, curing time…';

  @override
  String get defaultWorkNote =>
      'Siniksik ang base, nilagyan ng crack seal, at tinapalan ng hot asphalt hanggang pantay sa kalsada.';

  @override
  String get submitting => 'Ipinapasa…';

  @override
  String get submitForVerification => 'Ipasa para ma-verify';

  @override
  String photoUploadFailed(String message) {
    return 'Hindi na-upload ang photo: $message';
  }

  @override
  String get completionRequirements =>
      'Maglagay ng kahit isang after photo at ilarawan ang ginawang trabaho.';

  @override
  String submissionFailed(String message) {
    return 'Hindi naipasa: $message';
  }

  @override
  String get successTitle =>
      'Naipasa na ang trabaho.\nIsang hakbang na lang, patag na.';

  @override
  String successBody(String reportId) {
    return '$reportId · Susuriin ng LGU engineering office ang ebidensya ninyo bago isara ang task.';
  }

  @override
  String get returnToOverview => 'Bumalik sa Overview';

  @override
  String get notificationsTitle => 'Mga Abiso';

  @override
  String get markAllRead => 'Markahan lahat';

  @override
  String get notificationsEmptyTitle => 'Wala nang bago';

  @override
  String get notificationsEmptyBody =>
      'Walang bagong abiso para sa crew ninyo.';

  @override
  String notificationSubtitle(String reportId, String date) {
    return '$reportId · $date';
  }

  @override
  String get profileTitle => 'Profile at Settings';

  @override
  String get profileFallbackName => 'Tauhan ng Maintenance';

  @override
  String get themeMode => 'Tema';

  @override
  String get themeDark => 'Madilim';

  @override
  String get themeLight => 'Maliwanag';

  @override
  String get unreadIndicators => 'Marka ng Hindi pa Nabasa';

  @override
  String get aboutTitle => 'Tungkol sa PATAG Maintenance';

  @override
  String get aboutSubtitle => 'IT 305 · Bulacan State University';

  @override
  String get signOut => 'Mag-sign out sa Workspace';

  @override
  String get mapTitle => 'Mapa ng mga Naka-assign na Task';

  @override
  String get mapRecenter => 'Igitna ang mapa';

  @override
  String get openTaskDetails => 'Buksan ang Detalye ng Task';

  @override
  String fieldRequired(String label) {
    return 'Kailangan ang $label.';
  }

  @override
  String get photoBefore => 'Photo bago ang repair';

  @override
  String get photoAfter => 'Photo pagkatapos ng repair';

  @override
  String get photoPlaceholder => 'Walang makitang photo';

  @override
  String get serverConnecting =>
      'Kumokonekta sa PATAG… Kung naka-sleep ang server, puwedeng umabot ng isang minuto.';

  @override
  String get errorServerDown =>
      'Hindi maabot ang PATAG server. Tumatakbo ba ang backend?';

  @override
  String get errorTimeout => 'Nag-time out ang koneksyon. Subukan ulit.';

  @override
  String get errorUnreachable =>
      'Hindi maabot ang PATAG server. I-check ang koneksyon mo at subukan ulit.';

  @override
  String errorServerUnavailable(int code) {
    return 'Hindi available ang PATAG server ($code). Subukan ulit maya-maya.';
  }

  @override
  String errorUnexpectedResponse(int code) {
    return 'Hindi inaasahang sagot mula sa PATAG server ($code).';
  }

  @override
  String get errorRequestFailed => 'Hindi natuloy ang request.';

  @override
  String get errorNotMaintenance =>
      'Hindi pang-road maintenance ang account na ito.';

  @override
  String get errorPhotoTooLarge => 'Pumili ng photo na mas maliit sa 8 MB.';

  @override
  String get errorPhotoType => 'Pumili ng JPEG, PNG o WebP na photo.';

  @override
  String get errorPhotoMismatch =>
      'Hindi tugma ang laman ng image sa uri nito.';

  @override
  String get errorSessionExpired =>
      'Nag-expire na ang session. Mag-sign in ulit.';

  @override
  String get errorBadCredentials =>
      'Mali ang email o password para sa portal na ito.';

  @override
  String get errorTooManyAttempts =>
      'Masyadong maraming subok. Maghintay ng isang minuto at subukan ulit.';

  @override
  String get errorActionNotAllowed =>
      'Hindi puwede ang aksyong ito sa kasalukuyang status ng report.';

  @override
  String get errorRepairEvidenceRequired =>
      'Kailangan ang tala ng repair at mga after photo.';

  @override
  String get errorBeforePhotosRequired =>
      'Mag-upload ng mga photo bago ang repair.';

  @override
  String get errorProgressNoteRequired => 'Maglagay ng tala sa progreso.';

  @override
  String get errorUploadPhotoFirst =>
      'I-upload muna ang photo bago ito ilakip.';

  @override
  String get errorUploadRealPhotos =>
      'Mag-upload muna ng totoong photo ng repair.';

  @override
  String get errorReportNotFound => 'Hindi makita ang report.';

  @override
  String get errorPhotoNotFound => 'Hindi makita ang photo.';

  @override
  String get errorOtherTeam =>
      'Ang report na ito ay para sa ibang account o team.';

  @override
  String get errorDemoUnavailable => 'Hindi available ang demo account.';

  @override
  String get errorCheckAction =>
      'I-check ang detalye ng aksyon at subukan ulit.';

  @override
  String get errorMaintenanceOnly =>
      'Ang maintenance ay puwedeng magsimula ng trabaho, mag-update ng progreso, o magpasa ng ebidensya; ang LGU ang magve-verify bago ma-resolve.';

  @override
  String get errorServerGeneric =>
      'Hindi natapos ng PATAG ang request na ito. Subukan ulit.';

  @override
  String get errorInvalidRequest => 'Hindi valid ang request.';
}
