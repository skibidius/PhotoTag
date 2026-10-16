import 'package:geocoding/geocoding.dart';

/// Reverse-geocodes coordinates into a readable address, with a small cache so
/// the same area is only looked up once.
class GeocodeService {
  GeocodeService._();

  static final Geocoding _geocoding = Geocoding();
  static final Map<String, String?> _cache = <String, String?>{};

  static Future<String?> reverse(double latitude, double longitude) async {
    final String key =
        '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';
    if (_cache.containsKey(key)) return _cache[key];

    String? result;
    try {
      final List<Placemark> placemarks =
          await _geocoding.placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final Placemark p = placemarks.first;
        final List<String?> parts = <String?>[
          p.street ?? p.thoroughfare,
          p.subLocality,
          p.locality,
          p.administrativeArea,
          p.country,
        ];
        final List<String> cleaned = parts
            .where((String? s) => s != null && s.trim().isNotEmpty)
            .map((String? s) => s!.trim())
            .toList();

        // Drop exact duplicates that are common with shorter addresses.
        final List<String> deduped = <String>[];
        for (final String part in cleaned) {
          if (!deduped.contains(part)) deduped.add(part);
        }
        result = deduped.join(', ');
      }
    } catch (_) {
      result = null;
    }

    _cache[key] = result;
    return result;
  }
}
