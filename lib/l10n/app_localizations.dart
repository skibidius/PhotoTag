import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'PhotoTag'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'GPS camera with location watermarks'**
  String get appTagline;

  /// No description provided for @tabCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get tabCamera;

  /// No description provided for @tabProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get tabProjects;

  /// No description provided for @tabPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get tabPhotos;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @cameraNoCamera.
  ///
  /// In en, this message translates to:
  /// **'No camera is available on this device.'**
  String get cameraNoCamera;

  /// No description provided for @cameraPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required to capture photos.'**
  String get cameraPermissionDenied;

  /// No description provided for @cameraCannotStart.
  ///
  /// In en, this message translates to:
  /// **'Unable to start the camera.'**
  String get cameraCannotStart;

  /// No description provided for @cameraCannotInit.
  ///
  /// In en, this message translates to:
  /// **'Unable to initialize the camera.'**
  String get cameraCannotInit;

  /// No description provided for @cameraTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get cameraTryAgain;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @cameraPhotoSaved.
  ///
  /// In en, this message translates to:
  /// **'Photo saved'**
  String get cameraPhotoSaved;

  /// No description provided for @cameraCaptureFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not capture the photo'**
  String get cameraCaptureFailed;

  /// No description provided for @projectRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a project to start shooting'**
  String get projectRequired;

  /// No description provided for @chooseProject.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get chooseProject;

  /// No description provided for @savingCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Saving 1 photo…} other{Saving {count} photos…}}'**
  String savingCount(int count);

  /// No description provided for @cameraLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location is unavailable'**
  String get cameraLocationUnavailable;

  /// No description provided for @cameraSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch camera'**
  String get cameraSwitch;

  /// No description provided for @cameraFlash.
  ///
  /// In en, this message translates to:
  /// **'Flash'**
  String get cameraFlash;

  /// No description provided for @locationOff.
  ///
  /// In en, this message translates to:
  /// **'Location off'**
  String get locationOff;

  /// No description provided for @locationNoPermission.
  ///
  /// In en, this message translates to:
  /// **'No permission'**
  String get locationNoPermission;

  /// No description provided for @locationLocating.
  ///
  /// In en, this message translates to:
  /// **'Locating…'**
  String get locationLocating;

  /// No description provided for @locationAccuracy.
  ///
  /// In en, this message translates to:
  /// **'±{meters} m'**
  String locationAccuracy(String meters);

  /// No description provided for @project.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get project;

  /// No description provided for @projectNone.
  ///
  /// In en, this message translates to:
  /// **'No project'**
  String get projectNone;

  /// No description provided for @projectNew.
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get projectNew;

  /// No description provided for @projectName.
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get projectName;

  /// No description provided for @projectDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete project?'**
  String get projectDeleteTitle;

  /// No description provided for @projectDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'“{name}” will be removed. The photos keep their location but are no longer grouped.'**
  String projectDeleteBody(String name);

  /// No description provided for @projectsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get projectsEmpty;

  /// No description provided for @projectsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Group photos by site, job or client.'**
  String get projectsEmptyHint;

  /// No description provided for @projectsAllPhotos.
  ///
  /// In en, this message translates to:
  /// **'All photos'**
  String get projectsAllPhotos;

  /// No description provided for @exportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export project'**
  String get exportTitle;

  /// No description provided for @exportOriginal.
  ///
  /// In en, this message translates to:
  /// **'Originals'**
  String get exportOriginal;

  /// No description provided for @exportWatermarked.
  ///
  /// In en, this message translates to:
  /// **'Watermarked'**
  String get exportWatermarked;

  /// No description provided for @exportBoth.
  ///
  /// In en, this message translates to:
  /// **'Watermarked + originals'**
  String get exportBoth;

  /// No description provided for @exportEmpty.
  ///
  /// In en, this message translates to:
  /// **'This project has no photos.'**
  String get exportEmpty;

  /// No description provided for @exportNoOriginals.
  ///
  /// In en, this message translates to:
  /// **'Original copies aren\'t available — enable “Keep original copy” in Settings.'**
  String get exportNoOriginals;

  /// No description provided for @exportPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing archive…'**
  String get exportPreparing;

  /// No description provided for @photosAll.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photosAll;

  /// No description provided for @photosAllCount.
  ///
  /// In en, this message translates to:
  /// **'Photos · {count}'**
  String photosAllCount(int count);

  /// No description provided for @photosEmpty.
  ///
  /// In en, this message translates to:
  /// **'No photos yet'**
  String get photosEmpty;

  /// No description provided for @photosEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Photos you capture appear here.'**
  String get photosEmptyHint;

  /// No description provided for @photosCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo} other{{count} photos}}'**
  String photosCount(int count);

  /// No description provided for @photoDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete photo?'**
  String get photoDeleteTitle;

  /// No description provided for @photoDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This photo and its location data will be removed.'**
  String get photoDeleteBody;

  /// No description provided for @photoShowOnMap.
  ///
  /// In en, this message translates to:
  /// **'Show on map'**
  String get photoShowOnMap;

  /// No description provided for @photoAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy ±{meters} m'**
  String photoAccuracy(String meters);

  /// No description provided for @mapTitle.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get mapTitle;

  /// No description provided for @mapStyle.
  ///
  /// In en, this message translates to:
  /// **'Map style'**
  String get mapStyle;

  /// No description provided for @mapFitAll.
  ///
  /// In en, this message translates to:
  /// **'Show all photos'**
  String get mapFitAll;

  /// No description provided for @mapNoPhotos.
  ///
  /// In en, this message translates to:
  /// **'No photos with location'**
  String get mapNoPhotos;

  /// No description provided for @mapNoPhotosHint.
  ///
  /// In en, this message translates to:
  /// **'Capture photos with GPS enabled to see them on the map.'**
  String get mapNoPhotosHint;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @sectionCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get sectionCoordinates;

  /// No description provided for @sectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Stamp appearance'**
  String get sectionAppearance;

  /// No description provided for @sectionFields.
  ///
  /// In en, this message translates to:
  /// **'Stamp fields'**
  String get sectionFields;

  /// No description provided for @sectionDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get sectionDetails;

  /// No description provided for @sectionCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get sectionCamera;

  /// No description provided for @sectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get sectionAbout;

  /// No description provided for @coordFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get coordFormat;

  /// No description provided for @coordDecimal.
  ///
  /// In en, this message translates to:
  /// **'Decimal degrees'**
  String get coordDecimal;

  /// No description provided for @coordDms.
  ///
  /// In en, this message translates to:
  /// **'Degrees · minutes · seconds'**
  String get coordDms;

  /// No description provided for @coordDdm.
  ///
  /// In en, this message translates to:
  /// **'Degrees · decimal minutes'**
  String get coordDdm;

  /// No description provided for @coordUtm.
  ///
  /// In en, this message translates to:
  /// **'UTM'**
  String get coordUtm;

  /// No description provided for @coordMgrs.
  ///
  /// In en, this message translates to:
  /// **'MGRS'**
  String get coordMgrs;

  /// No description provided for @stampStyle.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get stampStyle;

  /// No description provided for @styleCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get styleCard;

  /// No description provided for @styleMinimal.
  ///
  /// In en, this message translates to:
  /// **'Minimal'**
  String get styleMinimal;

  /// No description provided for @styleOutline.
  ///
  /// In en, this message translates to:
  /// **'Outline'**
  String get styleOutline;

  /// No description provided for @stampPosition.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get stampPosition;

  /// No description provided for @posTopLeft.
  ///
  /// In en, this message translates to:
  /// **'Top left'**
  String get posTopLeft;

  /// No description provided for @posTopCenter.
  ///
  /// In en, this message translates to:
  /// **'Top center'**
  String get posTopCenter;

  /// No description provided for @posTopRight.
  ///
  /// In en, this message translates to:
  /// **'Top right'**
  String get posTopRight;

  /// No description provided for @posBottomLeft.
  ///
  /// In en, this message translates to:
  /// **'Bottom left'**
  String get posBottomLeft;

  /// No description provided for @posBottomCenter.
  ///
  /// In en, this message translates to:
  /// **'Bottom center'**
  String get posBottomCenter;

  /// No description provided for @posBottomRight.
  ///
  /// In en, this message translates to:
  /// **'Bottom right'**
  String get posBottomRight;

  /// No description provided for @stampSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get stampSize;

  /// No description provided for @sizeSmall.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get sizeSmall;

  /// No description provided for @sizeMedium.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get sizeMedium;

  /// No description provided for @sizeLarge.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get sizeLarge;

  /// No description provided for @stampTone.
  ///
  /// In en, this message translates to:
  /// **'Text colour'**
  String get stampTone;

  /// No description provided for @toneLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get toneLight;

  /// No description provided for @toneDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get toneDark;

  /// No description provided for @stampOpacity.
  ///
  /// In en, this message translates to:
  /// **'Background opacity · {percent}%'**
  String stampOpacity(int percent);

  /// No description provided for @fieldDateTime.
  ///
  /// In en, this message translates to:
  /// **'Date & time'**
  String get fieldDateTime;

  /// No description provided for @fieldCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get fieldCoordinates;

  /// No description provided for @fieldBearing.
  ///
  /// In en, this message translates to:
  /// **'Compass bearing'**
  String get fieldBearing;

  /// No description provided for @fieldAltitude.
  ///
  /// In en, this message translates to:
  /// **'Altitude'**
  String get fieldAltitude;

  /// No description provided for @fieldAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get fieldAccuracy;

  /// No description provided for @fieldAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get fieldAddress;

  /// No description provided for @fieldPhotoNumber.
  ///
  /// In en, this message translates to:
  /// **'Photo number'**
  String get fieldPhotoNumber;

  /// No description provided for @detailsNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get detailsNote;

  /// No description provided for @detailsNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Foundation inspection'**
  String get detailsNoteHint;

  /// No description provided for @detailsAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get detailsAuthor;

  /// No description provided for @detailsAuthorHint.
  ///
  /// In en, this message translates to:
  /// **'Your name or company'**
  String get detailsAuthorHint;

  /// No description provided for @detailsCounter.
  ///
  /// In en, this message translates to:
  /// **'Photo counter'**
  String get detailsCounter;

  /// No description provided for @detailsNextNumber.
  ///
  /// In en, this message translates to:
  /// **'Next photo will be № {value}'**
  String detailsNextNumber(String value);

  /// No description provided for @detailsResetCounter.
  ///
  /// In en, this message translates to:
  /// **'Reset counter'**
  String get detailsResetCounter;

  /// No description provided for @cameraGridSetting.
  ///
  /// In en, this message translates to:
  /// **'Rule-of-thirds grid'**
  String get cameraGridSetting;

  /// No description provided for @cameraHud.
  ///
  /// In en, this message translates to:
  /// **'Live stamp preview'**
  String get cameraHud;

  /// No description provided for @cameraMaxResolution.
  ///
  /// In en, this message translates to:
  /// **'Maximum resolution'**
  String get cameraMaxResolution;

  /// No description provided for @cameraMaxResolutionHint.
  ///
  /// In en, this message translates to:
  /// **'Capture at the sensor\'s full resolution'**
  String get cameraMaxResolutionHint;

  /// No description provided for @cameraKeepOriginal.
  ///
  /// In en, this message translates to:
  /// **'Keep original copy'**
  String get cameraKeepOriginal;

  /// No description provided for @cameraKeepOriginalHint.
  ///
  /// In en, this message translates to:
  /// **'Also save the photo without the stamp'**
  String get cameraKeepOriginalHint;

  /// No description provided for @photoQuality.
  ///
  /// In en, this message translates to:
  /// **'Photo quality'**
  String get photoQuality;

  /// No description provided for @qualityMaximum.
  ///
  /// In en, this message translates to:
  /// **'Maximum'**
  String get qualityMaximum;

  /// No description provided for @qualityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get qualityHigh;

  /// No description provided for @qualityBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get qualityBalanced;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageRussian.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get languageRussian;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutVersion;

  /// No description provided for @aboutLicense.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get aboutLicense;

  /// No description provided for @aboutLicenseValue.
  ///
  /// In en, this message translates to:
  /// **'MIT License'**
  String get aboutLicenseValue;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkForUpdates;

  /// No description provided for @checkingUpdates.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get checkingUpdates;

  /// No description provided for @upToDate.
  ///
  /// In en, this message translates to:
  /// **'You\'re up to date'**
  String get upToDate;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is available'**
  String updateAvailable(String version);

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @stampByAuthor.
  ///
  /// In en, this message translates to:
  /// **'by {author}'**
  String stampByAuthor(String author);

  /// No description provided for @stampCounter.
  ///
  /// In en, this message translates to:
  /// **'№ {value}'**
  String stampCounter(String value);
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
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
