import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../utils/yandex_crs.dart';

/// A raster tile basemap the map can render.
///
/// The list mirrors the working sources from the PhotoMap project. Yandex
/// layers use [YandexCrs] (EPSG:3395), the rest use Web Mercator.
@immutable
class BasemapDef {
  const BasemapDef({
    required this.key,
    required this.nameRu,
    required this.nameEn,
    required this.groupRu,
    required this.groupEn,
    required this.urlTemplate,
    required this.maxZoom,
    required this.attribution,
    required this.icon,
    this.overlayUrlTemplate,
    this.subdomains = const <String>[],
    this.crs = const Epsg3857(),
    this.localizedLanguage = false,
  });

  final String key;
  final String nameRu;
  final String nameEn;
  final String groupRu;
  final String groupEn;
  final String urlTemplate;
  final String? overlayUrlTemplate;
  final List<String> subdomains;
  final int maxZoom;
  final String attribution;
  final IconData icon;
  final Crs crs;

  /// Whether `{lang}` in the URLs should be replaced with the UI language.
  final bool localizedLanguage;

  String name(String locale) =>
      locale.toLowerCase().startsWith('ru') ? nameRu : nameEn;

  String group(String locale) =>
      locale.toLowerCase().startsWith('ru') ? groupRu : groupEn;

  String url(String locale) => _localize(urlTemplate, locale);

  String? overlayUrl(String locale) => overlayUrlTemplate == null
      ? null
      : _localize(overlayUrlTemplate!, locale);

  String _localize(String template, String locale) {
    if (!localizedLanguage) return template;
    final String lang = locale.toLowerCase().startsWith('ru')
        ? 'ru_RU'
        : 'en_US';
    return template.replaceAll('{lang}', lang);
  }
}

const String kDefaultBasemapKey = 'yandex-map';

/// All basemaps, grouped in the picker by [BasemapDef.group].
const List<BasemapDef> kBasemaps = <BasemapDef>[
  BasemapDef(
    key: 'osm',
    nameRu: 'OpenStreetMap',
    nameEn: 'OpenStreetMap',
    groupRu: 'Открытые',
    groupEn: 'Open',
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    maxZoom: 19,
    attribution: '© OpenStreetMap contributors',
    icon: Icons.public,
  ),
  BasemapDef(
    key: 'otopo',
    nameRu: 'OpenTopoMap',
    nameEn: 'OpenTopoMap',
    groupRu: 'Открытые',
    groupEn: 'Open',
    urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
    subdomains: <String>['a', 'b', 'c'],
    maxZoom: 17,
    attribution: '© OpenStreetMap contributors, © OpenTopoMap (CC-BY-SA)',
    icon: Icons.terrain,
  ),
  BasemapDef(
    key: 'yandex-map',
    nameRu: 'Яндекс — схема',
    nameEn: 'Yandex — map',
    groupRu: 'Яндекс',
    groupEn: 'Yandex',
    urlTemplate:
        'https://core-renderer-tiles.maps.yandex.net/tiles?l=map&x={x}&y={y}&z={z}&scale=1&lang={lang}',
    maxZoom: 19,
    attribution: '© Яндекс',
    icon: Icons.map_outlined,
    crs: YandexCrs(),
    localizedLanguage: true,
  ),
  BasemapDef(
    key: 'yandex-sat',
    nameRu: 'Яндекс — спутник',
    nameEn: 'Yandex — satellite',
    groupRu: 'Яндекс',
    groupEn: 'Yandex',
    urlTemplate:
        'https://core-sat.maps.yandex.net/tiles?l=sat&x={x}&y={y}&z={z}&scale=1',
    maxZoom: 19,
    attribution: '© Яндекс',
    icon: Icons.satellite_alt_outlined,
    crs: YandexCrs(),
  ),
  BasemapDef(
    key: 'yandex-hybrid',
    nameRu: 'Яндекс — гибрид',
    nameEn: 'Yandex — hybrid',
    groupRu: 'Яндекс',
    groupEn: 'Yandex',
    urlTemplate:
        'https://core-sat.maps.yandex.net/tiles?l=sat&x={x}&y={y}&z={z}&scale=1',
    overlayUrlTemplate:
        'https://core-renderer-tiles.maps.yandex.net/tiles?l=skl&x={x}&y={y}&z={z}&scale=1&lang={lang}',
    maxZoom: 19,
    attribution: '© Яндекс',
    icon: Icons.layers_outlined,
    crs: YandexCrs(),
    localizedLanguage: true,
  ),
  BasemapDef(
    key: 'google-map',
    nameRu: 'Google — схема',
    nameEn: 'Google — map',
    groupRu: 'Google',
    groupEn: 'Google',
    urlTemplate: 'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
    subdomains: <String>['0', '1', '2', '3'],
    maxZoom: 20,
    attribution: '© Google',
    icon: Icons.map,
  ),
  BasemapDef(
    key: 'google-sat',
    nameRu: 'Google — спутник',
    nameEn: 'Google — satellite',
    groupRu: 'Google',
    groupEn: 'Google',
    urlTemplate: 'https://mt{s}.google.com/vt/lyrs=s&x={x}&y={y}&z={z}',
    subdomains: <String>['0', '1', '2', '3'],
    maxZoom: 20,
    attribution: '© Google',
    icon: Icons.satellite_alt,
  ),
  BasemapDef(
    key: 'google-hybrid',
    nameRu: 'Google — гибрид',
    nameEn: 'Google — hybrid',
    groupRu: 'Google',
    groupEn: 'Google',
    urlTemplate: 'https://mt{s}.google.com/vt/lyrs=y&x={x}&y={y}&z={z}',
    subdomains: <String>['0', '1', '2', '3'],
    maxZoom: 20,
    attribution: '© Google',
    icon: Icons.layers,
  ),
];

BasemapDef basemapByKey(String? key) {
  for (final BasemapDef basemap in kBasemaps) {
    if (basemap.key == key) return basemap;
  }
  return basemapByKeyOrNull(kDefaultBasemapKey)!;
}

BasemapDef? basemapByKeyOrNull(String key) {
  for (final BasemapDef basemap in kBasemaps) {
    if (basemap.key == key) return basemap;
  }
  return null;
}

/// Tile layers for [basemap], including the optional labels overlay used by
/// hybrid styles.
List<Widget> basemapTileLayers(BasemapDef basemap, String locale) {
  final String? overlay = basemap.overlayUrl(locale);
  return <Widget>[
    TileLayer(
      key: ValueKey<String>('basemap_${basemap.key}'),
      urlTemplate: basemap.url(locale),
      subdomains: basemap.subdomains,
      maxNativeZoom: basemap.maxZoom,
      userAgentPackageName: 'com.phototag',
    ),
    if (overlay != null)
      TileLayer(
        key: ValueKey<String>('basemap_${basemap.key}_labels'),
        urlTemplate: overlay,
        subdomains: basemap.subdomains,
        maxNativeZoom: basemap.maxZoom,
        userAgentPackageName: 'com.phototag',
      ),
  ];
}
