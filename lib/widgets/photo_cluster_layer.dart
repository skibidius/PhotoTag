import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/photo_record.dart';
import 'direction_marker.dart';

/// Renders photo markers, merging nearby ones into numbered clusters.
///
/// Clustering is done in screen space at the current zoom: photos whose
/// projected centres are within [clusterRadius] logical pixels share one
/// bubble. Zooming in splits the clusters naturally, and the selected photo is
/// always drawn on its own so its direction cone stays visible.
class PhotoClusterLayer extends StatelessWidget {
  const PhotoClusterLayer({
    super.key,
    required this.records,
    required this.selected,
    required this.onPhotoTap,
    required this.onClusterTap,
    this.clusterRadius = 64,
  });

  final List<PhotoRecord> records;
  final PhotoRecord? selected;
  final ValueChanged<PhotoRecord> onPhotoTap;
  final ValueChanged<List<PhotoRecord>> onClusterTap;
  final double clusterRadius;

  @override
  Widget build(BuildContext context) {
    final MapCamera camera = MapCamera.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;

    final List<PhotoRecord> unselected = records
        .where((PhotoRecord record) => record != selected)
        .toList(growable: false);
    final List<_Cluster> clusters = _clusterise(unselected, camera);

    final List<Marker> markers = <Marker>[
      for (final _Cluster cluster in clusters)
        if (cluster.records.length == 1)
          _photoMarker(cluster.records.single, scheme, selected: false)
        else
          _clusterMarker(cluster, camera, scheme),
      if (selected != null) _photoMarker(selected!, scheme, selected: true),
    ];

    return MarkerLayer(markers: markers);
  }

  Marker _photoMarker(
    PhotoRecord record,
    ColorScheme scheme, {
    required bool selected,
  }) {
    return Marker(
      point: LatLng(record.latitude!, record.longitude!),
      width: selected ? 72 : 60,
      height: selected ? 72 : 60,
      alignment: Alignment.center,
      child: DirectionMarker(
        bearing: record.bearing,
        color: scheme.primary,
        iconColor: scheme.onPrimary,
        selected: selected,
        onTap: () => onPhotoTap(record),
      ),
    );
  }

  Marker _clusterMarker(
    _Cluster cluster,
    MapCamera camera,
    ColorScheme scheme,
  ) {
    final int count = cluster.records.length;
    return Marker(
      point: camera.unprojectAtZoom(cluster.centroid),
      width: 58,
      height: 58,
      alignment: Alignment.center,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onClusterTap(cluster.records),
        child: Container(
          decoration: BoxDecoration(
            color: scheme.primary,
            shape: BoxShape.circle,
            border: Border.all(color: scheme.surface, width: 3),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            count > 99 ? '99+' : '$count',
            style: TextStyle(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w700,
              fontSize: count > 99 ? 12 : 15,
            ),
          ),
        ),
      ),
    );
  }

  List<_Cluster> _clusterise(List<PhotoRecord> items, MapCamera camera) {
    final List<_Cluster> clusters = <_Cluster>[];
    final Map<(int, int), Set<_Cluster>> grid =
        <(int, int), Set<_Cluster>>{};

    (int, int) cellOf(Offset point) => (
          (point.dx / clusterRadius).floor(),
          (point.dy / clusterRadius).floor(),
        );

    for (final PhotoRecord record in items) {
      final Offset point = camera.projectAtZoom(
        LatLng(record.latitude!, record.longitude!),
      );
      final (int cx, int cy) = cellOf(point);

      _Cluster? target;
      outer:
      for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
          final Set<_Cluster>? bucket = grid[(cx + dx, cy + dy)];
          if (bucket == null) continue;
          for (final _Cluster cluster in bucket) {
            if ((cluster.centroid - point).distance <= clusterRadius) {
              target = cluster;
              break outer;
            }
          }
        }
      }

      if (target == null) {
        final _Cluster cluster = _Cluster(record, point);
        clusters.add(cluster);
        grid.putIfAbsent((cx, cy), () => <_Cluster>{}).add(cluster);
      } else {
        final (int, int) oldCell = cellOf(target.centroid);
        target.add(record, point);
        final (int, int) newCell = cellOf(target.centroid);
        if (oldCell != newCell) {
          grid[oldCell]?.remove(target);
          grid.putIfAbsent(newCell, () => <_Cluster>{}).add(target);
        }
      }
    }
    return clusters;
  }
}

class _Cluster {
  _Cluster(PhotoRecord record, Offset point)
      : records = <PhotoRecord>[record],
        _sum = point;

  final List<PhotoRecord> records;
  Offset _sum;

  Offset get centroid => _sum / records.length.toDouble();

  void add(PhotoRecord record, Offset point) {
    records.add(record);
    _sum += point;
  }
}
