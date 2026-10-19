import 'package:flutter/widgets.dart';

import '../utils/coords.dart';

/// Visual treatment of the stamp burned onto each photo.
enum StampStyle { card, minimal, outline }

/// Where on the photo the stamp sits.
enum StampPosition {
  topLeft,
  topCenter,
  topRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

/// Relative size of the stamp text.
enum StampSize { small, medium, large }

/// Whether the stamp is rendered with light or dark text.
enum StampTone { light, dark }

/// The app's interface language.
enum AppLanguage { system, english, russian }

/// Capture quality preset. Higher presets use the sensor's full resolution and
/// a richer JPEG encode.
enum PhotoQuality { maximum, high, balanced }

/// Captures every user-controllable aspect of the app. Instances are immutable
/// and copied through [copyWith]; persistence is handled by the settings
/// controller.
class AppSettings {
  const AppSettings({
    this.coordFormat = CoordFormat.decimal,
    this.stampStyle = StampStyle.card,
    this.stampPosition = StampPosition.bottomLeft,
    this.stampSize = StampSize.medium,
    this.stampTone = StampTone.light,
    this.opacity = 0.82,
    this.showDate = true,
    this.showTime = true,
    this.showCoordinates = true,
    this.showBearing = true,
    this.showAltitude = true,
    this.showAccuracy = true,
    this.showAddress = true,
    this.showNote = false,
    this.showCounter = true,
    this.showAuthor = false,
    this.note = '',
    this.author = '',
    this.projectCounters = const <String, int>{},
    this.showGrid = false,
    this.showHud = true,
    this.saveOriginal = true,
    this.language = AppLanguage.system,
    this.photoQuality = PhotoQuality.maximum,
    this.basemap = 'yandex-map',
  });

  final CoordFormat coordFormat;
  final StampStyle stampStyle;
  final StampPosition stampPosition;
  final StampSize stampSize;
  final StampTone stampTone;
  final double opacity;

  final bool showDate;
  final bool showTime;
  final bool showCoordinates;
  final bool showBearing;
  final bool showAltitude;
  final bool showAccuracy;
  final bool showAddress;
  final bool showNote;
  final bool showCounter;
  final bool showAuthor;

  final String note;
  final String author;
  /// Next photo number for each project (the empty key is "no project").
  final Map<String, int> projectCounters;

  /// The next photo number for [project] (null means no active project).
  int counterFor(String? project) => projectCounters[project ?? ''] ?? 1;

  /// Returns a copy with the next number for [project] set to [value].
  AppSettings withCounter(String? project, int value) => copyWith(
        projectCounters: <String, int>{
          ...projectCounters,
          project ?? '': value,
        },
      );

  /// Advances the counter for [project] by one.
  AppSettings advanceCounter(String? project) =>
      withCounter(project, counterFor(project) + 1);

  final bool showGrid;
  final bool showHud;
  final bool saveOriginal;
  final AppLanguage language;
  final PhotoQuality photoQuality;

  /// Key of the last basemap chosen on the map screen.
  final String basemap;

  AppSettings copyWith({
    CoordFormat? coordFormat,
    StampStyle? stampStyle,
    StampPosition? stampPosition,
    StampSize? stampSize,
    StampTone? stampTone,
    double? opacity,
    bool? showDate,
    bool? showTime,
    bool? showCoordinates,
    bool? showBearing,
    bool? showAltitude,
    bool? showAccuracy,
    bool? showAddress,
    bool? showNote,
    bool? showCounter,
    bool? showAuthor,
    String? note,
    String? author,
    Map<String, int>? projectCounters,
    bool? showGrid,
    bool? showHud,
    bool? saveOriginal,
    AppLanguage? language,
    PhotoQuality? photoQuality,
    String? basemap,
  }) {
    return AppSettings(
      coordFormat: coordFormat ?? this.coordFormat,
      stampStyle: stampStyle ?? this.stampStyle,
      stampPosition: stampPosition ?? this.stampPosition,
      stampSize: stampSize ?? this.stampSize,
      stampTone: stampTone ?? this.stampTone,
      opacity: opacity ?? this.opacity,
      showDate: showDate ?? this.showDate,
      showTime: showTime ?? this.showTime,
      showCoordinates: showCoordinates ?? this.showCoordinates,
      showBearing: showBearing ?? this.showBearing,
      showAltitude: showAltitude ?? this.showAltitude,
      showAccuracy: showAccuracy ?? this.showAccuracy,
      showAddress: showAddress ?? this.showAddress,
      showNote: showNote ?? this.showNote,
      showCounter: showCounter ?? this.showCounter,
      showAuthor: showAuthor ?? this.showAuthor,
      note: note ?? this.note,
      author: author ?? this.author,
      projectCounters: projectCounters ?? this.projectCounters,
      showGrid: showGrid ?? this.showGrid,
      showHud: showHud ?? this.showHud,
      saveOriginal: saveOriginal ?? this.saveOriginal,
      language: language ?? this.language,
      photoQuality: photoQuality ?? this.photoQuality,
      basemap: basemap ?? this.basemap,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'coordFormat': coordFormat.name,
        'stampStyle': stampStyle.name,
        'stampPosition': stampPosition.name,
        'stampSize': stampSize.name,
        'stampTone': stampTone.name,
        'opacity': opacity,
        'showDate': showDate,
        'showTime': showTime,
        'showCoordinates': showCoordinates,
        'showBearing': showBearing,
        'showAltitude': showAltitude,
        'showAccuracy': showAccuracy,
        'showAddress': showAddress,
        'showNote': showNote,
        'showCounter': showCounter,
        'showAuthor': showAuthor,
        'note': note,
        'author': author,
        'counter': counterFor(null),
        'projectCounters': projectCounters,
        'showGrid': showGrid,
        'showHud': showHud,
        'saveOriginal': saveOriginal,
        'language': language.name,
        'photoQuality': photoQuality.name,
        'basemap': basemap,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    T enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
      for (final T value in values) {
        if (value.name == name) return value;
      }
      return fallback;
    }

    return AppSettings(
      coordFormat: enumByName(CoordFormat.values, json['coordFormat'] as String?, CoordFormat.decimal),
      stampStyle: enumByName(StampStyle.values, json['stampStyle'] as String?, StampStyle.card),
      stampPosition: enumByName(StampPosition.values, json['stampPosition'] as String?, StampPosition.bottomLeft),
      stampSize: enumByName(StampSize.values, json['stampSize'] as String?, StampSize.medium),
      stampTone: enumByName(StampTone.values, json['stampTone'] as String?, StampTone.light),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 0.82,
      showDate: json['showDate'] as bool? ?? true,
      showTime: json['showTime'] as bool? ?? true,
      showCoordinates: json['showCoordinates'] as bool? ?? true,
      showBearing: json['showBearing'] as bool? ?? true,
      showAltitude: json['showAltitude'] as bool? ?? true,
      showAccuracy: json['showAccuracy'] as bool? ?? true,
      showAddress: json['showAddress'] as bool? ?? true,
      showNote: json['showNote'] as bool? ?? false,
      showCounter: json['showCounter'] as bool? ?? true,
      showAuthor: json['showAuthor'] as bool? ?? false,
      note: json['note'] as String? ?? '',
      author: json['author'] as String? ?? '',
      projectCounters: () {
        final Object? raw = json['projectCounters'];
        if (raw is Map) {
          return raw.map<String, int>(
            (Object? key, Object? value) =>
                MapEntry<String, int>(key.toString(), (value as num).toInt()),
          );
        }
        // Migrate the pre-per-project global counter.
        return <String, int>{'': json['counter'] as int? ?? 1};
      }(),
      showGrid: json['showGrid'] as bool? ?? false,
      showHud: json['showHud'] as bool? ?? true,
      saveOriginal: json['saveOriginal'] as bool? ?? true,
      language: enumByName(AppLanguage.values, json['language'] as String?, AppLanguage.system),
      photoQuality: enumByName(PhotoQuality.values, json['photoQuality'] as String?, PhotoQuality.maximum),
      basemap: json['basemap'] as String? ?? 'yandex-map',
    );
  }
}

extension StampPositionX on StampPosition {
  Alignment get alignment {
    switch (this) {
      case StampPosition.topLeft:
        return Alignment.topLeft;
      case StampPosition.topCenter:
        return Alignment.topCenter;
      case StampPosition.topRight:
        return Alignment.topRight;
      case StampPosition.bottomLeft:
        return Alignment.bottomLeft;
      case StampPosition.bottomCenter:
        return Alignment.bottomCenter;
      case StampPosition.bottomRight:
        return Alignment.bottomRight;
    }
  }
}

extension PhotoQualityX on PhotoQuality {
  /// JPEG quality used when re-encoding the stamped photo.
  int get jpegQuality {
    switch (this) {
      case PhotoQuality.maximum:
        return 100;
      case PhotoQuality.high:
        return 95;
      case PhotoQuality.balanced:
        return 90;
    }
  }
}
