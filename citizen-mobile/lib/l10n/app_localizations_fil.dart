// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Filipino Pilipino (`fil`).
class AppLocalizationsFil extends AppLocalizations {
  AppLocalizationsFil([String locale = 'fil']) : super(locale);

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
  String get languageBody => 'Piliin ang wika ng app.';

  @override
  String get retry => 'Subukan ulit';

  @override
  String get back => 'Bumalik';

  @override
  String get next => 'Susunod';

  @override
  String get cancel => 'Kanselahin';

  @override
  String get signIn => 'Mag-sign in';

  @override
  String get signOut => 'Mag-sign out';

  @override
  String get createAnAccount => 'Gumawa ng account';

  @override
  String get createAccount => 'Gumawa ng account';

  @override
  String get continueLabel => 'Ituloy';

  @override
  String brgy(String name) {
    return 'Brgy. $name';
  }

  @override
  String fieldRequired(String label) {
    return 'Kailangan ito: $label';
  }

  @override
  String errorSemantics(String message) {
    return 'Error: $message';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navMap => 'Mapa';

  @override
  String get navReport => 'I-report';

  @override
  String get navMyReports => 'Mga report ko';

  @override
  String get navProfile => 'Profile';

  @override
  String get reportAPothole => 'Mag-report ng lubak';

  @override
  String get switchToLight => 'Gawing light mode';

  @override
  String get switchToDark => 'Gawing dark mode';

  @override
  String get demoEvidence => 'Halimbawang larawan para sa demo';

  @override
  String get photoUnavailable =>
      'Hindi ma-load ang photo. I-check ang internet mo.';

  @override
  String get progressTitle => 'Progreso ng report';

  @override
  String get progressResolved =>
      'Kumpirmado nang naayos. Mas maayos na ang daan.';

  @override
  String get progressAwaiting =>
      'Tapos na ang pag-aayos. Hinihintay ang kumpirmasyon ng LGU.';

  @override
  String get progressFollow =>
      'Subaybayan ang tag mo, mula report hanggang maayos.';

  @override
  String get progressStepReported => 'Na-report';

  @override
  String get progressStepVerified => 'Na-verify';

  @override
  String get progressStepRepair => 'Inaayos';

  @override
  String get progressStepResolved => 'Naayos na';

  @override
  String get stepPhoto => 'Photo';

  @override
  String get stepLocation => 'Lokasyon';

  @override
  String get stepDetails => 'Detalye';

  @override
  String get stepReview => 'I-check';

  @override
  String get serverWaking =>
      'Kumokonekta sa PATAG… Kung natutulog ang server, puwedeng umabot nang isang minuto.';

  @override
  String get serverUnreachable =>
      'Hindi maabot ang PATAG server. Tumatakbo ba ang backend?';

  @override
  String get statusSubmitted => 'Naisumite';

  @override
  String get statusUnderReview => 'Sinusuri';

  @override
  String get statusVerified => 'Na-verify';

  @override
  String get statusAssigned => 'Na-assign na';

  @override
  String get statusInProgress => 'Inaayos na';

  @override
  String get statusResolved => 'Naayos na';

  @override
  String get statusRejected => 'Hindi tinanggap';

  @override
  String get statusDuplicate => 'Doble';

  @override
  String get statusAwaitingVerification => 'Hinihintay ang kumpirmasyon ng LGU';

  @override
  String get severityLow => 'Mababa';

  @override
  String get severityMedium => 'Katamtaman';

  @override
  String get severityHigh => 'Mataas';

  @override
  String get errTimeout =>
      'Natagalan ang koneksyon. Naka-save ang draft mo. Subukan ulit.';

  @override
  String get errUnreachable =>
      'Hindi makakonekta sa PATAG. I-check ang local API at ang internet mo. Naka-save ang draft mo.';

  @override
  String errServerDown(int status) {
    return 'Hindi available ang PATAG server ($status). Subukan ulit maya-maya.';
  }

  @override
  String errUnexpected(int status) {
    return 'Hindi inaasahang sagot mula sa PATAG server ($status).';
  }

  @override
  String get errTryAgain => 'Pakisubukan ulit.';

  @override
  String get errCitizenOnly => 'Citizen account ang gamitin sa app na ito.';

  @override
  String get errPhotoTooLarge => 'Pumili ng photo na mas maliit sa 8 MB.';

  @override
  String get errPhotoType => 'Pumili ng JPEG, PNG o WebP na photo.';

  @override
  String get errPhotoMismatch =>
      'Hindi tugma ang laman ng photo sa uri ng file nito.';

  @override
  String get errSessionExpired =>
      'Nag-expire na ang session. Mag-sign in ulit.';

  @override
  String get errWrongPassword =>
      'Mali ang email o password para sa portal na ito.';

  @override
  String get errTooManyAttempts =>
      'Sobrang dami ng subok. Maghintay ng isang minuto bago ulitin.';

  @override
  String get errTooManyLookups =>
      'Sobrang daming paghahanap ng address. Maghintay ng isang minuto bago ulitin.';

  @override
  String get errAccountUnavailable =>
      'Hindi makagawa ng account gamit ang mga detalyeng ito. Subukang mag-sign in o i-recover ang account mo.';

  @override
  String get errEmailRegistered => 'Naka-register na ang email na ito.';

  @override
  String get errFeedbackOnce =>
      'Isang beses lang puwedeng mag-feedback, at para lang sa mga naayos nang report.';

  @override
  String get errReportIncomplete =>
      'Kailangan ang photo, paglalarawan, kalsada, barangay, lungsod, probinsya, tamang coordinates at tindi ng sira.';

  @override
  String get errAddressRequired =>
      'Ilagay ang barangay, lungsod o bayan, at probinsya mo.';

  @override
  String get errGpsOff =>
      'Naka-off ang GPS. I-on ito o i-tap ang mapa para mag-pin nang mano-mano.';

  @override
  String get errLocationDenied =>
      'Hindi pinayagan ang location. I-tap ang mapa para pumili ng lugar, o i-on ang location sa Android settings.';

  @override
  String get mapFullScreen => 'Full screen na mapa';

  @override
  String get mapZoomIn => 'I-zoom in';

  @override
  String get mapZoomOut => 'I-zoom out';

  @override
  String get mapRecenter => 'Ibalik sa gitna ang mapa';

  @override
  String get mapTilesUnavailable =>
      'Hindi ma-load ang mapa. Ilagay ang coordinates o gamitin ang listahan ng report.';

  @override
  String mapPinTooltip(String road, String status) {
    return '$road: $status';
  }

  @override
  String get viewPublicReport => 'Tingnan ang public report';

  @override
  String get mapSignInToReport => 'Mag-sign in para i-report ang lubak na ito.';

  @override
  String get mapHintPicking => 'I-tap ang mapa para ilagay ang pin ng lubak.';

  @override
  String get mapHintBrowsing =>
      'I-tap ang pin para sa detalye, o i-tap ang kalsada para mag-report ng lubak doon.';

  @override
  String get mapClose => 'Isara ang full screen na mapa';

  @override
  String mapPinCoordinates(String lat, String lng) {
    return 'Pin: $lat, $lng';
  }

  @override
  String get locating => 'Hinahanap…';

  @override
  String get myGps => 'GPS ko';

  @override
  String get useThisLocation => 'Gamitin ang lugar na ito';

  @override
  String get reportPotholeHere => 'Mag-report ng lubak dito';

  @override
  String get publicMapTitle => 'Mapa ng lubak sa komunidad';

  @override
  String get publicMapHeading => 'Alamin ang daraanan mo.';

  @override
  String get publicMapDemoNote =>
      'Mga gawa-gawang report para sa demo · Malolos, Bulacan';

  @override
  String get allSeverities => 'Lahat ng tindi';

  @override
  String get allStatuses => 'Lahat ng status';

  @override
  String get showMap => 'Ipakita ang mapa';

  @override
  String get showList => 'Ipakita ang listahan';

  @override
  String get communityReports => 'Mga report ng komunidad';

  @override
  String get filterAll => 'Lahat';

  @override
  String get noReportsNearby => 'Walang report sa malapit';

  @override
  String get tryDifferentFilter => 'Subukan ang ibang filter.';

  @override
  String reportsCountTapPin(int count) {
    return '$count report · I-tap ang pin para sa detalye.';
  }

  @override
  String get useCurrentGps => 'Gamitin ang kasalukuyang GPS location';

  @override
  String get wizardPinFromMap =>
      'Naka-set na ang lokasyon mula sa mapa. Magdagdag ng photo, tapos i-check ang detalye ng kalsada.';

  @override
  String wizardPhotoLimit(int max) {
    return 'Hanggang $max photo lang ang puwedeng ilakip.';
  }

  @override
  String wizardPhotoRoom(int room, int max) {
    return '$room pang photo lang ang naidagdag (hanggang $max lang).';
  }

  @override
  String get wizardNeedPhoto =>
      'Magdagdag ng kahit isang photo bilang ebidensya.';

  @override
  String get wizardInvalidCoordinates =>
      'I-tap ang mapa o maglagay ng tamang latitude at longitude.';

  @override
  String get wizardReviewDuplicates =>
      'Tingnan muna ang mga posibleng kaparehong report bago ipasa.';

  @override
  String get wizardHeadingPhoto => 'Ipakita ang kalsada.';

  @override
  String get wizardHeadingLocation => 'I-pin ang eksaktong lugar.';

  @override
  String get wizardHeadingDetails => 'Ikuwento ang nakita mo.';

  @override
  String get wizardHeadingReview => 'Handa nang i-tag?';

  @override
  String get wizardIntroPhoto =>
      'Malaking tulong sa LGU ang isang malinaw na photo. Pumuwesto sa ligtas na lugar habang kumukuha.';

  @override
  String get wizardIntroLocation =>
      'Hindi required ang GPS. I-tap ang mapa para pumili o ilipat ang pin.';

  @override
  String get wizardIntroDetails =>
      'Nakakatulong sa pagsusuri ang tantiya mo kung gaano kalala ang sira. Ang LGU ang magve-verify ng report.';

  @override
  String get wizardIntroReview =>
      'I-check ang photo, lokasyon at paglalarawan bago ipasa.';

  @override
  String get takePhoto => 'Kumuha ng photo';

  @override
  String get chooseFromGallery => 'Pumili sa gallery';

  @override
  String get photoRequirements =>
      'JPEG, PNG o WebP · hanggang 8 MB bawat photo';

  @override
  String removePhoto(String name) {
    return 'Alisin ang $name';
  }

  @override
  String get useMyGps => 'Gamitin ang GPS location ko';

  @override
  String get latitude => 'Latitude';

  @override
  String get longitude => 'Longitude';

  @override
  String get roadName => 'Pangalan ng kalsada';

  @override
  String get barangay => 'Barangay';

  @override
  String get municipalityCity => 'Bayan / Lungsod';

  @override
  String get province => 'Probinsya';

  @override
  String get nearbyLandmark => 'Palatandaan sa malapit';

  @override
  String get reportTitleField => 'Maikling pamagat ng report';

  @override
  String get describeDamage => 'Ilarawan ang sira sa kalsada';

  @override
  String get observedHazards => 'Mga panganib na napansin';

  @override
  String get reportedSeverity => 'Gaano kalala ang sira';

  @override
  String get severityLowHint => 'Maliit na sira sa ibabaw';

  @override
  String get severityMediumHint => 'Kailangang mag-ingat pagdaan';

  @override
  String get severityHighHint => 'Malalim na sira o delikado na sa daan';

  @override
  String reviewAddress(String road, String barangay) {
    return '$road, Brgy. $barangay';
  }

  @override
  String hazardsLine(String text) {
    return 'Mga panganib: $text';
  }

  @override
  String get possibleDuplicates => 'Mga posibleng kaparehong report';

  @override
  String get possibleDuplicatesHint =>
      'Baka iisang sira lang ang tinutukoy ng mga report na ito sa malapit. Puwede mo muna silang tingnan bago magpatuloy.';

  @override
  String duplicateDistance(String distance, String road) {
    return '$distance m ang layo · $road';
  }

  @override
  String get duplicatesAcknowledge =>
      'Natingnan ko na ang mga report na ito at gusto ko pa ring ipasa.';

  @override
  String get wizardStartsSubmitted =>
      'Magsisimula ang report mo bilang Naisumite. Susuriin muna ng LGU ang ebidensya bago i-verify.';

  @override
  String get pleaseWait => 'Sandali lang…';

  @override
  String get submitReport => 'Ipasa ang report';

  @override
  String get findingAddress => 'Hinahanap ang address…';

  @override
  String get addressFilledFromMap => 'Kinuha sa mapa — pakitingnan kung tama.';

  @override
  String get addressNotFound =>
      'Hindi mahanap ang address — pakisulat na lang.';

  @override
  String get skip => 'Skip';

  @override
  String get onboardingTitlePin => 'I-pin mo. Para madali naming mahanap.';

  @override
  String get onboardingTitleFollow => 'Subaybayan hanggang maayos.';

  @override
  String get onboardingBodyPhoto =>
      'Kumuha ng malinaw na photo at ipaalam sa LGU ang sirang kalsada.';

  @override
  String get onboardingBodyPin =>
      'Gamitin ang GPS o i-tap ang mapa. Kapag eksakto ang lokasyon, mas madaling makarating ang tamang crew.';

  @override
  String get onboardingBodyFollow =>
      'Subaybayan ang pagsusuri, pag-assign at pag-aayos. Magbigay ng feedback kapag na-verify na ng LGU.';

  @override
  String get getStarted => 'Simulan na';

  @override
  String get welcomeBody =>
      'I-report ang sirang kalsada. Subaybayan ang progreso. Tulungan ang komunidad na makabiyahe nang ligtas.';

  @override
  String get explorePublicMap => 'Tingnan ang public map';

  @override
  String get academicNote =>
      'Pang-akademikong demo · IT 305\nWalang opisyal na record o partnership sa LGU.';

  @override
  String get privacyRequired =>
      'Pakikumpirma na nabasa mo ang impormasyon tungkol sa privacy.';

  @override
  String get recoverAccount => 'I-recover ang account';

  @override
  String get recoveryHeading => 'Ibalik natin ang access mo.';

  @override
  String get registerHeading => 'Samahan kami sa pag-ayos ng daan.';

  @override
  String get devAuthNote => 'Development sign-in · local demo API';

  @override
  String signupStep(int step, int total, String name) {
    return 'Hakbang $step sa $total · $name';
  }

  @override
  String get signupStepAbout => 'Tungkol sa iyo';

  @override
  String get signupStepAddress => 'Address mo';

  @override
  String get signupStepSecure => 'I-secure ang account mo';

  @override
  String get fullName => 'Buong pangalan';

  @override
  String get emailAddress => 'Email address';

  @override
  String get invalidEmail => 'Maglagay ng tamang email address.';

  @override
  String get addressPrivateNote =>
      'Sa private account mo lang makikita ang address mo. Hiwalay mong ipi-pin ang lubak kapag nagre-report.';

  @override
  String get streetOptional => 'Kalye / numero ng bahay (opsyonal)';

  @override
  String get enterBarangay => 'Ilagay ang barangay mo.';

  @override
  String get cityMunicipality => 'Lungsod / bayan';

  @override
  String get enterCity => 'Ilagay ang lungsod o bayan mo.';

  @override
  String get enterProvince => 'Ilagay ang probinsya mo.';

  @override
  String get password => 'Password';

  @override
  String get showPassword => 'Ipakita ang password';

  @override
  String get hidePassword => 'Itago ang password';

  @override
  String get passwordRule =>
      'Gumamit ng kahit 8 character na may malaking titik, maliit na titik, numero, at special character.';

  @override
  String get enterPassword => 'Ilagay ang password mo.';

  @override
  String get passwordRequirements =>
      'Kailangan ng kahit 8 character, kasama ang malaking titik, maliit na titik, numero, at special character.';

  @override
  String get privacyAcknowledge =>
      'Naiintindihan kong sa local lang sine-save ng academic demo na ito ang test account data. Hindi ako gagamit ng totoong personal na impormasyon.';

  @override
  String get connecting => 'Kumokonekta…';

  @override
  String get requestRecovery => 'Humiling ng recovery';

  @override
  String get alreadyHaveAccount => 'May account ka na? Mag-sign in';

  @override
  String get forgotPassword => 'Nakalimutan ang password?';

  @override
  String get exploreDemoNote => 'Subukan ang demo kahit walang password.';

  @override
  String get continueAsDemo => 'Ituloy bilang demo citizen';

  @override
  String get notifications => 'Mga notification';

  @override
  String helloName(String name) {
    return 'Kumusta, $name!';
  }

  @override
  String get homeSubtitle => 'Konting tag, mas maayos na daan.';

  @override
  String get homeCallToAction =>
      'I-tag mo na. Tulungan ang komunidad na makabiyahe nang ligtas.';

  @override
  String get aroundYou => 'Sa paligid mo';

  @override
  String get explore => 'Tingnan';

  @override
  String get yourImpact => 'Ang naiambag mo';

  @override
  String get viewReports => 'Tingnan ang mga report';

  @override
  String get totalReports => 'Kabuuang report';

  @override
  String get everyTagCounts => 'Mahalaga ang bawat tag.';

  @override
  String get metricUnderReview => 'Sinusuri';

  @override
  String get metricInProgress => 'Inaayos';

  @override
  String get metricResolved => 'Naayos na';

  @override
  String get latestReport => 'Pinakabagong report';

  @override
  String get viewAll => 'Tingnan lahat';

  @override
  String get firstTagTitle => 'Dito magsisimula ang una mong tag.';

  @override
  String get firstTagBody => 'Magpadala ng malinaw na photo at lokasyon.';

  @override
  String get clearerPictureTitle =>
      'Mas malinaw na photo, mas malaking tulong.';

  @override
  String get clearerPictureBody =>
      'Mag-ingat, maglagay ng palatandaan at i-check ang pin sa mapa.';

  @override
  String get readGuide => 'Basahin ang gabay sa pag-report';

  @override
  String get demoReportsNote => 'Mga gawa-gawang report para sa demo · IT 305';

  @override
  String get yourProfile => 'Profile mo';

  @override
  String get myReportsHeading => 'Ang mga tag mo at ang progreso nila.';

  @override
  String get searchReports => 'Hanapin ang kalsada o reference';

  @override
  String get newestFirst => 'Pinakabago muna';

  @override
  String get oldestFirst => 'Pinakaluma muna';

  @override
  String get noReportsFound => 'Walang nahanap na report';

  @override
  String get noReportsFoundBody =>
      'Subukan ang ibang hanap o gumawa ng bagong report.';

  @override
  String get reportDetails => 'Detalye ng report';

  @override
  String get reportNotFound => 'Hindi mahanap ang report';

  @override
  String get reportNotFoundBody =>
      'I-refresh ang mga report mo, o tingnan ang public map.';

  @override
  String detailsAddress(String barangay, String city, String province) {
    return 'Brgy. $barangay, $city, $province';
  }

  @override
  String get roadToResolution => 'Mula report hanggang maayos';

  @override
  String get repairDocumentation => 'Dokumentasyon ng pag-aayos';

  @override
  String get shareRepairFeedback => 'Magbigay ng feedback sa pag-aayos';

  @override
  String get feedbackRecorded => 'Salamat! Naitala na ang feedback mo.';

  @override
  String get reportSubmitted => 'Naipasa ang report';

  @override
  String get reportSubmittedBody =>
      'Naipasa na ang report mo para sa pagsusuri. Titingnan ng LGU ang ebidensya at lokasyon.';

  @override
  String get viewReport => 'Tingnan ang report';

  @override
  String get returnHome => 'Bumalik sa Home';

  @override
  String get readAll => 'Basahin lahat';

  @override
  String get allQuiet => 'Wala pang bago';

  @override
  String get allQuietBody => 'Dito lalabas ang mga update sa mga report mo.';

  @override
  String notificationSubtitle(String reportId, String date) {
    return '$reportId · $date';
  }

  @override
  String get repairFeedback => 'Feedback sa pag-aayos';

  @override
  String get repairNotVerified => 'Hindi pa na-verify ang pag-aayos';

  @override
  String get repairNotVerifiedBody =>
      'Puwede nang mag-feedback kapag na-verify na ng LGU na tapos na ang pag-aayos.';

  @override
  String get howWasRepair => 'Kumusta ang pagkakaayos?';

  @override
  String get feedbackSaved => 'Naitala na ang feedback mo.';

  @override
  String get feedbackAlready =>
      'Nakapagbigay ka na ng feedback para sa pag-aayos na ito.';

  @override
  String starsTooltip(int count) {
    return '$count bituin';
  }

  @override
  String get yourRepairFeedback => 'Feedback mo sa pag-aayos';

  @override
  String get submitting => 'Ipinapasa…';

  @override
  String get submitFeedback => 'Ipasa ang feedback';

  @override
  String get feedbackIncomplete => 'Pumili ng rating at magsulat ng feedback.';

  @override
  String get defaultCitizenName => 'Mamamayan';

  @override
  String profileAddress(String address) {
    return 'Address · $address';
  }

  @override
  String communityReportsCount(int count) {
    return '$count report sa komunidad';
  }

  @override
  String get editProfile => 'I-edit ang profile';

  @override
  String get settings => 'Settings';

  @override
  String get reportingGuide => 'Gabay sa pag-report';

  @override
  String get aboutPatag => 'Tungkol sa PATAG';

  @override
  String get emailChangeNote =>
      'Para mapalitan ang email, kailangan ng verified na account recovery.';

  @override
  String get privateAddressNote =>
      'Private na address · hiwalay sa bawat report sa kalsada';

  @override
  String get saveProfile => 'I-save ang profile';

  @override
  String get profileSaved => 'Na-save ang profile.';

  @override
  String get appearance => 'Itsura';

  @override
  String get appearanceBody => 'Light, dark, o sundin ang setting ng device.';

  @override
  String get themeSystem => 'Device';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get showUnread =>
      'Ipakita ang tanda ng hindi pa nababasang notification';

  @override
  String get showUnreadBody =>
      'Naka-save sa device na ito. Makikita mo pa rin ang history ng mga update.';

  @override
  String get permissionsTitle => 'Pahintulot sa camera at location';

  @override
  String get permissionsBody =>
      'Hihingi lang ng pahintulot kapag kailangan. Kung hindi pinayagan, pumili ng photo sa gallery o i-tap ang mapa. Mababago mo ito sa Android Settings → Apps → PATAG.';

  @override
  String get privacy => 'Privacy';

  @override
  String get privacyBody =>
      'Hindi ipinapakita sa public report kung sino ka. Sa local API sine-save ng academic demo na ito ang mga test record. Gumamit ng gawa-gawang impormasyon sa account.';

  @override
  String get mapboxNotice =>
      'Kapag naglagay ka ng pin, ipinapadala ang coordinates nito sa Mapbox sa pamamagitan ng server ng PATAG para mahanap ang address.';

  @override
  String get guideHeading => 'Mas malayo ang mararating ng maayos na report.';

  @override
  String get aboutMeaning =>
      'Ang PATAG ay nangangahulugang pantay o makinis na ibabaw. Kapag binasa bilang “pa-tag”, ibig sabihin din nito ay pagtawag-pansin sa isang problema.';

  @override
  String get aboutMission =>
      'Layunin naming tulungan ang mga komunidad na i-report ang problema sa kalsada, ikonekta ang mamamayan sa lokal na pamahalaan, at gawing aksyon ang mga report.';

  @override
  String get aboutAcademic =>
      'Isang final project para sa IT 305 – Advanced Web Development, Bulacan State University. Hindi kumakatawan ang demo na ito sa opisyal na record o partnership ng anumang LGU.';

  @override
  String get guidePhotoTitle => '1. Kumuha ng photo nang ligtas';

  @override
  String get guidePhotoBody =>
      'Kumuha ng malinaw na photo ng sirang bahagi. Huwag tumayo sa gitna ng trapiko. Mag-upload ng JPEG, PNG o WebP na mas maliit sa 8 MB.';

  @override
  String get guideLocationTitle => '2. I-set ang lokasyon';

  @override
  String get guideLocationBody =>
      'Gamitin ang GPS kung pinayagan. Kung naka-off, hindi pinayagan o hindi eksakto ang GPS, i-tap ang mapa para mag-pin nang mano-mano o ilagay ang coordinates. Ilagay ang kalsada, barangay, lungsod at probinsya.';

  @override
  String get guideDescribeTitle => '3. Ilarawan ang sira';

  @override
  String get guideDescribeBody =>
      'Ipaliwanag ang lubak at mga panganib. Susuriin ng LGU ang tantiya mo kung gaano kalala ang sira.';

  @override
  String get guideDuplicatesTitle => '4. Tingnan kung may kapareho';

  @override
  String get guideDuplicatesBody =>
      'Baka iisang sira lang ang tinutukoy ng mga report sa parehong kalsada. Tingnan ang mga mungkahi bago ipasa. Hindi kailanman pagsasamahin ng system ang report mo nang hindi mo alam.';

  @override
  String get guideProgressTitle => '5. Subaybayan ang progreso';

  @override
  String get guideProgressBody =>
      'Naisumite → Sinusuri → Na-verify → Na-assign na → Inaayos na → Naayos na. Magiging Naayos na lang ito kapag na-verify ng LGU ang pag-aayos.';

  @override
  String get guideOutcomesTitle => 'Iba pang posibleng resulta';

  @override
  String get guideOutcomesBody =>
      'May kasamang dahilan ang report na Hindi tinanggap. Ang Doble ay ibig sabihing kinumpirma ng LGU na may naunang report na. Puwedeng ipasa ang report sa ahensyang may sakop.';

  @override
  String get guideFeedbackTitle => '6. Magbigay ng feedback';

  @override
  String get guideFeedbackBody =>
      'Kapag naayos na, buksan ang report mo at magbigay ng rating at feedback.';

  @override
  String get guideConnectionTitle => 'Koneksyon at draft';

  @override
  String get guideConnectionBody =>
      'Naka-save sa device na ito ang draft ng report mo. Kailangan ng internet para maipasa ito sa naka-configure na API. Walang awtomatikong offline sync.';

  @override
  String get pageNotFound => 'Hindi mahanap ang page';

  @override
  String get pageNotFoundBody => 'Gamitin ang navigation para magpatuloy.';
}
