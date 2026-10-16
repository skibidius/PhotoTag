import '../utils/coords.dart';

/// Metadata describing a single captured photo, persisted alongside the image
/// so the gallery can display and export it later.
class PhotoRecord {
  const PhotoRecord({
    required this.id,
    required this.path,
    required this.thumbPath,
    this.originalPath,
    required this.takenAt,
    this.latitude,
    this.longitude,
    this.altitude,
    this.accuracy,
    this.bearing,
    this.address,
    this.note,
    this.project,
    required this.counter,
    required this.coordText,
  });

  final String id;
  final String path;
  final String thumbPath;
  final String? originalPath;
  final DateTime takenAt;
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final double? accuracy;
  final double? bearing;
  final String? address;
  final String? note;
  final String? project;
  final int counter;
  final String coordText;

  bool get hasLocation => latitude != null && longitude != null;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'path': path,
        'thumbPath': thumbPath,
        'originalPath': originalPath,
        'takenAt': takenAt.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'accuracy': accuracy,
        'bearing': bearing,
        'address': address,
        'note': note,
        'project': project,
        'counter': counter,
        'coordText': coordText,
      };

  factory PhotoRecord.fromJson(Map<String, dynamic> json) => PhotoRecord(
        id: json['id'] as String,
        path: json['path'] as String,
        thumbPath: json['thumbPath'] as String,
        originalPath: json['originalPath'] as String?,
        takenAt: DateTime.parse(json['takenAt'] as String),
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        altitude: (json['altitude'] as num?)?.toDouble(),
        accuracy: (json['accuracy'] as num?)?.toDouble(),
        bearing: (json['bearing'] as num?)?.toDouble(),
        address: json['address'] as String?,
        note: json['note'] as String?,
        project: json['project'] as String?,
        counter: json['counter'] as int? ?? 0,
        coordText: json['coordText'] as String? ?? '',
      );
}

/// The live data needed to render a stamp, decoupled from the GPS sensor so the
/// same widget drives both the camera preview and the exported image.
class StampContext {
  const StampContext({
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.altitude,
    this.accuracy,
    this.bearing,
    this.address,
    this.note,
    this.project,
    this.author,
    this.counter,
    this.coordFormat = CoordFormat.decimal,
  });

  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final double? accuracy;
  final double? bearing;
  final String? address;
  final String? note;
  final String? project;
  final String? author;
  final int? counter;
  final CoordFormat coordFormat;

  bool get hasLocation => latitude != null && longitude != null;

  String get coordText =>
      hasLocation ? Coords.format(coordFormat, latitude!, longitude!) : '';
}
