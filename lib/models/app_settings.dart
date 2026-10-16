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
    this.counter = 1,
    this.showGrid = false,
    this.showHud = true,
    this.saveOriginal = false,
    this.highResolution = true,
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
  final int counter;

  final bool showGrid;
  final bool showHud;
  final bool saveOriginal;
  final bool highResolution;

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
    int? counter,
    bool? showGrid,
    bool? showHud,
    bool? saveOriginal,
    bool? highResolution,
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
      counter: counter ?? this.counter,
      showGrid: showGrid ?? this.showGrid,
      showHud: showHud ?? this.showHud,
      saveOriginal: saveOriginal ?? this.saveOriginal,
      highResolution: highResolution ?? this.highResolution,
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
        'counter': counter,
        'showGrid': showGrid,
        'showHud': showHud,
        'saveOriginal': saveOriginal,
        'highResolution': highResolution,
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
      counter: json['counter'] as int? ?? 1,
      showGrid: json['showGrid'] as bool? ?? false,
      showHud: json['showHud'] as bool? ?? true,
      saveOriginal: json['saveOriginal'] as bool? ?? false,
      highResolution: json['highResolution'] as bool? ?? true,
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

  String get label {
    switch (this) {
      case StampPosition.topLeft:
        return 'Top left';
      case StampPosition.topCenter:
        return 'Top center';
      case StampPosition.topRight:
        return 'Top right';
      case StampPosition.bottomLeft:
        return 'Bottom left';
      case StampPosition.bottomCenter:
        return 'Bottom center';
      case StampPosition.bottomRight:
        return 'Bottom right';
    }
  }
}

extension StampStyleX on StampStyle {
  String get label {
    switch (this) {
      case StampStyle.card:
        return 'Card';
      case StampStyle.minimal:
        return 'Minimal';
      case StampStyle.outline:
        return 'Outline';
    }
  }
}

extension StampSizeX on StampSize {
  String get label {
    switch (this) {
      case StampSize.small:
        return 'Small';
      case StampSize.medium:
        return 'Medium';
      case StampSize.large:
        return 'Large';
    }
  }
}

extension StampToneX on StampTone {
  String get label {
    switch (this) {
      case StampTone.light:
        return 'Light';
      case StampTone.dark:
        return 'Dark';
    }
  }
}
