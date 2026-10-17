// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PhotoTag';

  @override
  String get appTagline => 'GPS camera with location watermarks';

  @override
  String get tabCamera => 'Camera';

  @override
  String get tabProjects => 'Projects';

  @override
  String get tabPhotos => 'Photos';

  @override
  String get cancel => 'Cancel';

  @override
  String get create => 'Create';

  @override
  String get delete => 'Delete';

  @override
  String get enable => 'Enable';

  @override
  String get view => 'View';

  @override
  String get share => 'Share';

  @override
  String get cameraNoCamera => 'No camera is available on this device.';

  @override
  String get cameraPermissionDenied =>
      'Camera permission is required to capture photos.';

  @override
  String get cameraCannotStart => 'Unable to start the camera.';

  @override
  String get cameraCannotInit => 'Unable to initialize the camera.';

  @override
  String get cameraTryAgain => 'Try again';

  @override
  String get cameraPhotoSaved => 'Photo saved';

  @override
  String get cameraCaptureFailed => 'Could not capture the photo';

  @override
  String savingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Saving $count photos…',
      one: 'Saving 1 photo…',
    );
    return '$_temp0';
  }

  @override
  String get cameraLocationUnavailable => 'Location is unavailable';

  @override
  String get permissionsNeeded =>
      'Camera and location permissions are required';

  @override
  String get cameraGrid => 'Grid';

  @override
  String get cameraSettings => 'Settings';

  @override
  String get cameraSwitch => 'Switch camera';

  @override
  String get cameraFlash => 'Flash';

  @override
  String get locationOff => 'Location off';

  @override
  String get locationNoPermission => 'No permission';

  @override
  String get locationLocating => 'Locating…';

  @override
  String locationAccuracy(String meters) {
    return '±$meters m';
  }

  @override
  String get project => 'Project';

  @override
  String get projectNone => 'No project';

  @override
  String get projectNew => 'New project';

  @override
  String get projectName => 'Project name';

  @override
  String get projectDeleteTitle => 'Delete project?';

  @override
  String projectDeleteBody(String name) {
    return '“$name” will be removed. The photos keep their location but are no longer grouped.';
  }

  @override
  String get projectsEmpty => 'No projects yet';

  @override
  String get projectsEmptyHint => 'Group photos by site, job or client.';

  @override
  String get projectsAllPhotos => 'All photos';

  @override
  String get exportTitle => 'Export project';

  @override
  String get exportOriginal => 'Originals';

  @override
  String get exportWatermarked => 'Watermarked';

  @override
  String get exportBoth => 'Watermarked + originals';

  @override
  String get exportEmpty => 'This project has no photos.';

  @override
  String get exportNoOriginals =>
      'Original copies aren\'t available — enable “Keep original copy” in Settings.';

  @override
  String get exportPreparing => 'Preparing archive…';

  @override
  String get photosAll => 'Photos';

  @override
  String photosAllCount(int count) {
    return 'Photos · $count';
  }

  @override
  String get photosEmpty => 'No photos yet';

  @override
  String get photosEmptyHint => 'Photos you capture appear here.';

  @override
  String photosCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return '$_temp0';
  }

  @override
  String get photoDeleteTitle => 'Delete photo?';

  @override
  String get photoDeleteBody =>
      'This photo and its location data will be removed.';

  @override
  String get photoShowOnMap => 'Show on map';

  @override
  String photoAccuracy(String meters) {
    return 'Accuracy ±$meters m';
  }

  @override
  String get mapTitle => 'Location';

  @override
  String get mapAttribution => 'OpenStreetMap contributors';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionCoordinates => 'Coordinates';

  @override
  String get sectionAppearance => 'Stamp appearance';

  @override
  String get sectionFields => 'Stamp fields';

  @override
  String get sectionDetails => 'Details';

  @override
  String get sectionCamera => 'Camera';

  @override
  String get sectionAbout => 'About';

  @override
  String get coordFormat => 'Format';

  @override
  String get coordDecimal => 'Decimal degrees';

  @override
  String get coordDms => 'Degrees · minutes · seconds';

  @override
  String get coordDdm => 'Degrees · decimal minutes';

  @override
  String get coordUtm => 'UTM';

  @override
  String get coordMgrs => 'MGRS';

  @override
  String get stampStyle => 'Style';

  @override
  String get styleCard => 'Card';

  @override
  String get styleMinimal => 'Minimal';

  @override
  String get styleOutline => 'Outline';

  @override
  String get stampPosition => 'Position';

  @override
  String get posTopLeft => 'Top left';

  @override
  String get posTopCenter => 'Top center';

  @override
  String get posTopRight => 'Top right';

  @override
  String get posBottomLeft => 'Bottom left';

  @override
  String get posBottomCenter => 'Bottom center';

  @override
  String get posBottomRight => 'Bottom right';

  @override
  String get stampSize => 'Size';

  @override
  String get sizeSmall => 'S';

  @override
  String get sizeMedium => 'M';

  @override
  String get sizeLarge => 'L';

  @override
  String get stampTone => 'Text colour';

  @override
  String get toneLight => 'Light';

  @override
  String get toneDark => 'Dark';

  @override
  String stampOpacity(int percent) {
    return 'Background opacity · $percent%';
  }

  @override
  String get fieldDateTime => 'Date & time';

  @override
  String get fieldCoordinates => 'Coordinates';

  @override
  String get fieldBearing => 'Compass bearing';

  @override
  String get fieldAltitude => 'Altitude';

  @override
  String get fieldAccuracy => 'Accuracy';

  @override
  String get fieldAddress => 'Address';

  @override
  String get fieldPhotoNumber => 'Photo number';

  @override
  String get detailsNote => 'Note';

  @override
  String get detailsNoteHint => 'e.g. Foundation inspection';

  @override
  String get detailsAuthor => 'Author';

  @override
  String get detailsAuthorHint => 'Your name or company';

  @override
  String get detailsCounter => 'Photo counter';

  @override
  String detailsNextNumber(String value) {
    return 'Next photo will be № $value';
  }

  @override
  String get detailsResetCounter => 'Reset counter';

  @override
  String get cameraGridSetting => 'Rule-of-thirds grid';

  @override
  String get cameraHud => 'Live stamp preview';

  @override
  String get cameraMaxResolution => 'Maximum resolution';

  @override
  String get cameraMaxResolutionHint =>
      'Capture at the sensor\'s full resolution';

  @override
  String get cameraKeepOriginal => 'Keep original copy';

  @override
  String get cameraKeepOriginalHint => 'Also save the photo without the stamp';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageRussian => 'Русский';

  @override
  String get about => 'About';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutLicense => 'License';

  @override
  String get aboutLicenseValue => 'MIT License';

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String get checkingUpdates => 'Checking…';

  @override
  String get upToDate => 'You\'re up to date';

  @override
  String updateAvailable(String version) {
    return 'Version $version is available';
  }

  @override
  String get update => 'Update';

  @override
  String stampByAuthor(String author) {
    return 'by $author';
  }

  @override
  String stampCounter(String value) {
    return '№ $value';
  }
}
