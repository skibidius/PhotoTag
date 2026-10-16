import 'dart:async';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/app_settings.dart';
import '../models/photo_record.dart';
import '../services/image_processor.dart';
import '../services/geocode_service.dart';
import '../services/location_service.dart';
import '../services/photo_store.dart';
import '../services/project_store.dart';
import '../services/settings_controller.dart';
import '../utils/page_route.dart';
import '../widgets/stamp_overlay.dart';
import 'gallery_screen.dart';
import 'settings_screen.dart';

/// Camera startup failures, localised at render time.
enum _CameraError { noCamera, permission, cannotStart, cannotInit }

/// The in-app camera. It captures at the maximum available resolution, renders
/// the stamp from the same widget shown in the preview, and burns it into the
/// full-resolution photo without ever leaving the app.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  static const double _capturePixelRatio = 6.0;
  final GlobalKey _captureKey = GlobalKey();

  CameraController? _controller;
  List<CameraDescription> _cameras = <CameraDescription>[];
  int _cameraIndex = 0;
  bool _initializing = true;
  _CameraError? _error;

  FlashMode _flashMode = FlashMode.off;
  double _zoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _scaleStartZoom = 1.0;

  Offset? _focusPoint;
  bool _focusRingVisible = false;
  Timer? _focusTimer;

  bool _capturing = false;
  StampContext? _captureCtx;
  String? _address;
  DateTime _now = DateTime.now();
  Timer? _clock;

  LocationService get _location => context.read<LocationService>();
  SettingsController get _settings => context.read<SettingsController>();
  PhotoStore get _photos => context.read<PhotoStore>();
  ProjectStore get _projects => context.read<ProjectStore>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _location.addListener(_onLocationChanged);
    _clock = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _now = DateTime.now()),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureLocation());
  }

  Future<void> _ensureLocation() async {
    final bool ok = await _location.start();
    if (!ok && mounted) {
      final AppLocalizations l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.cameraLocationUnavailable),
          action: SnackBarAction(
            label: l10n.enable,
            onPressed: () => _location.openSettings(),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _clock?.cancel();
    _focusTimer?.cancel();
    _location.removeListener(_onLocationChanged);
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  void _onLocationChanged() {
    final LocationFix? fix = _location.fix;
    if (fix == null || !fix.hasLocation) return;
    GeocodeService.reverse(fix.latitude!, fix.longitude!).then((String? a) {
      if (mounted && a != null && a != _address) {
        setState(() => _address = a);
      }
    });
  }

  Future<void> _initCamera() async {
    setState(() {
      _initializing = true;
      _error = null;
    });
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _error = _CameraError.noCamera;
          _initializing = false;
        });
        return;
      }
      final int back = _cameras.indexWhere(
          (CameraDescription c) => c.lensDirection == CameraLensDirection.back);
      _cameraIndex = back >= 0 ? back : 0;
      await _initController(_cameras[_cameraIndex]);
    } on CameraException catch (e) {
      setState(() {
        _error = e.code == 'CameraAccessDenied' ||
                e.code == 'CameraAccessDeniedWithoutPrompt'
            ? _CameraError.permission
            : _CameraError.cannotStart;
        _initializing = false;
      });
    } catch (e) {
      setState(() {
        _error = _CameraError.cannotStart;
        _initializing = false;
      });
    }
  }

  Future<void> _initController(CameraDescription description) async {
    await _controller?.dispose();
    final CameraController controller = CameraController(
      description,
      ResolutionPreset.max,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _controller = controller;
    try {
      await controller.initialize();
      _minZoom = await controller.getMinZoomLevel();
      _maxZoom = await controller.getMaxZoomLevel();
      _zoom = 1.0.clamp(_minZoom, _maxZoom);
      await controller.setZoomLevel(_zoom);
      await controller.setFlashMode(_flashMode);
      if (mounted) setState(() => _initializing = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _CameraError.cannotInit;
          _initializing = false;
        });
      }
    }
  }

  Future<void> _toggleCamera() async {
    HapticFeedback.selectionClick();
    if (_cameras.length < 2) return;
    final CameraLensDirection current = _cameras[_cameraIndex].lensDirection;
    final CameraLensDirection target = current == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    final int idx =
        _cameras.indexWhere((CameraDescription c) => c.lensDirection == target);
    if (idx < 0) return;
    _cameraIndex = idx;
    await _initController(_cameras[_cameraIndex]);
  }

  Future<void> _cycleFlash() async {
    HapticFeedback.selectionClick();
    final FlashMode next;
    switch (_flashMode) {
      case FlashMode.off:
        next = FlashMode.auto;
        break;
      case FlashMode.auto:
        next = FlashMode.always;
        break;
      default:
        next = FlashMode.off;
    }
    _flashMode = next;
    await _controller?.setFlashMode(next);
    if (mounted) setState(() {});
  }

  void _setZoom(double zoom) {
    final double clamped = zoom.clamp(_minZoom, _maxZoom);
    _zoom = clamped;
    _controller?.setZoomLevel(clamped);
    setState(() {});
  }

  void _onScaleStart(ScaleStartDetails details) {
    _scaleStartZoom = _zoom;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount < 2) return;
    _setZoom(_scaleStartZoom * details.scale);
  }

  void _onTapFocus(TapUpDetails details, Size size) {
    final Offset pos = details.localPosition;
    final double nx = (pos.dx / size.width).clamp(0.0, 1.0);
    final double ny = (pos.dy / size.height).clamp(0.0, 1.0);
    _controller?.setFocusPoint(Offset(nx, ny));
    _controller?.setExposurePoint(Offset(nx, ny));
    HapticFeedback.selectionClick();
    setState(() {
      _focusPoint = pos;
      _focusRingVisible = true;
    });
    _focusTimer?.cancel();
    _focusTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _focusRingVisible = false);
    });
  }

  Future<void> _capture() async {
    final CameraController? controller = _controller;
    if (_capturing || controller == null || !controller.value.isInitialized) {
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _capturing = true);

    try {
      // Refresh the fix so the stamp is as accurate as possible.
      await _location.refresh();

      final XFile file = await controller.takePicture();
      final Uint8List photoBytes = await file.readAsBytes();

      final AppSettings settings = _settings.value;
      final LocationFix? fix = _location.fix;
      final StampContext ctx = StampContext(
        timestamp: DateTime.now(),
        latitude: fix?.latitude,
        longitude: fix?.longitude,
        altitude: fix?.altitude,
        accuracy: fix?.accuracy,
        bearing: fix?.heading,
        address: _address,
        note: settings.note,
        project: _projects.active,
        author: settings.author,
        counter: settings.counter,
        coordFormat: settings.coordFormat,
      );

      final Uint8List stampPng = await _renderStampPng(ctx);
      final Uint8List result = await ImageProcessor.compositeJpeg(
        photoBytes: photoBytes,
        stampPng: stampPng,
        position: settings.stampPosition,
      );

      final PhotoRecord record = await _photos.save(
        jpeg: result,
        originalJpeg: settings.saveOriginal ? photoBytes : null,
        takenAt: ctx.timestamp,
        latitude: fix?.latitude,
        longitude: fix?.longitude,
        altitude: fix?.altitude,
        accuracy: fix?.accuracy,
        bearing: fix?.heading,
        address: _address,
        note: settings.note,
        project: _projects.active,
        counter: settings.counter,
        coordText: ctx.coordText,
      );

      // Make the photo visible in the system gallery.
      try {
        if (!await Gal.hasAccess(toAlbum: false)) {
          await Gal.requestAccess(toAlbum: false);
        }
        await Gal.putImage(record.path, album: 'PhotoTag');
      } catch (_) {}

      HapticFeedback.lightImpact();
      if (mounted) {
        final AppLocalizations l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.cameraPhotoSaved),
            action: SnackBarAction(
              label: l10n.view,
              onPressed: () => _openGallery(),
            ),
          ),
        );
      }

      // Advance the automatic photo counter.
      await _settings.update((AppSettings s) => s.copyWith(counter: s.counter + 1));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).cameraCaptureFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
      if (_captureCtx != null && mounted) setState(() => _captureCtx = null);
    }
  }

  Future<Uint8List> _renderStampPng(StampContext ctx) async {
    setState(() => _captureCtx = ctx);
    // Let the off-screen boundary rebuild and paint before capturing it.
    await Future<void>.delayed(const Duration(milliseconds: 80));
    final RenderObject? ro = _captureKey.currentContext?.findRenderObject();
    final RenderRepaintBoundary boundary = ro as RenderRepaintBoundary;
    final ui.Image image =
        await boundary.toImage(pixelRatio: _capturePixelRatio);
    try {
      final ByteData? data =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  void _openGallery() {
    Navigator.of(context).push(sharedAxisRoute(const GalleryScreen()));
  }

  void _openSettings() {
    Navigator.of(context).push(sharedAxisRoute(const SettingsScreen()));
  }

  StampContext _liveContext(AppSettings settings) {
    final LocationFix? fix = _location.fix;
    return StampContext(
      timestamp: _now,
      latitude: fix?.latitude,
      longitude: fix?.longitude,
      altitude: fix?.altitude,
      accuracy: fix?.accuracy,
      bearing: fix?.heading,
      address: _address,
      note: settings.note,
      project: _projects.active,
      author: settings.author,
      counter: settings.counter,
      coordFormat: settings.coordFormat,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppSettings settings = context.watch<SettingsController>().value;
    final LocationService location = context.watch<LocationService>();
    final Color accent = Theme.of(context).colorScheme.primary;
    final StampContext liveCtx = _liveContext(settings);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: <Widget>[
          _buildBody(settings, location, accent, liveCtx),
        ],
      ),
    );
  }

  Widget _buildBody(AppSettings settings, LocationService location,
      Color accent, StampContext liveCtx) {
    if (_error != null) return _buildError(settings, accent);
    if (_initializing) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: <Widget>[
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onTapUp: (TapUpDetails d) =>
              _onTapFocus(d, MediaQuery.sizeOf(context)),
          child: _buildPreview(),
        ),
        // Hidden capture target: renders the stamp at export resolution.
        Positioned(
          left: -100000,
          top: 0,
          child: IgnorePointer(
            child: RepaintBoundary(
              key: _captureKey,
              child: StampOverlay(
                settings: settings,
                data: _captureCtx ?? liveCtx,
                accent: accent,
              ),
            ),
          ),
        ),
        if (settings.showGrid) const _GridOverlay(),
        if (_focusPoint != null)
          Positioned(
            left: _focusPoint!.dx - 38,
            top: _focusPoint!.dy - 38,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _focusRingVisible ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                child: AnimatedScale(
                  scale: _focusRingVisible ? 1.0 : 1.3,
                  duration: const Duration(milliseconds: 220),
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (settings.showHud)
          _StampPreview(settings: settings, data: liveCtx, accent: accent),
        _buildTopBar(settings, location, accent),
        _buildBottomControls(settings, accent),
      ],
    );
  }

  Widget _buildPreview() {
    final CameraController? controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.expand();
    }
    final Size size = MediaQuery.sizeOf(context);
    final Size preview = controller.value.previewSize ?? size;
    final double short = preview.width < preview.height ? preview.width : preview.height;
    final double long = preview.width < preview.height ? preview.height : preview.width;

    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: short,
            height: long,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }

  Widget _buildError(AppSettings settings, Color accent) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String message = switch (_error!) {
      _CameraError.noCamera => l10n.cameraNoCamera,
      _CameraError.permission => l10n.cameraPermissionDenied,
      _CameraError.cannotStart => l10n.cameraCannotStart,
      _CameraError.cannotInit => l10n.cameraCannotInit,
    };
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.no_photography_outlined,
              color: Colors.white54, size: 56),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _initCamera,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.cameraTryAgain),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(
      AppSettings settings, LocationService location, Color accent) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Flexible(child: _ProjectChip(onTap: _openProjectPicker)),
                const Spacer(),
                IconButton(
                  onPressed: () => _settings.update(
                    (AppSettings s) => s.copyWith(showGrid: !s.showGrid),
                  ),
                  icon: Icon(
                    settings.showGrid
                        ? Icons.grid_4x4
                        : Icons.grid_4x4_outlined,
                    color: Colors.white,
                  ),
                  tooltip: l10n.cameraGrid,
                ),
                IconButton(
                  onPressed: _openSettings,
                  icon: const Icon(Icons.settings_outlined, color: Colors.white),
                  tooltip: l10n.cameraSettings,
                ),
              ],
            ),
            const SizedBox(height: 4),
            _LocationPill(location: location, accent: accent),
          ],
        ),
      ),
    );
  }

  Future<void> _openProjectPicker() async {
    final ProjectStore store = _projects;
    final String? selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        final AppLocalizations l10n = AppLocalizations.of(context);
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(
                  l10n.project,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.block_outlined),
                title: Text(l10n.projectNone),
                trailing: store.active == null ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop(''),
              ),
              for (final String p in store.projects)
                ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(p),
                  trailing: store.active == p ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.of(context).pop(p),
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.add),
                title: Text(l10n.projectNew),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _createProject();
                },
              ),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      HapticFeedback.selectionClick();
      await store.setActive(selected.isEmpty ? null : selected);
    }
  }

  Future<void> _createProject() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TextEditingController controller = TextEditingController();
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l10n.projectNew),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n.projectName,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (String v) => Navigator.of(context).pop(v),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(l10n.create),
          ),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      HapticFeedback.selectionClick();
      await _projects.add(name);
    }
  }

  Widget _buildBottomControls(AppSettings settings, Color accent) {
    final List<double> presets = _zoomPresets;
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (presets.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _ZoomPresets(
                    presets: presets,
                    current: _zoom,
                    onSelected: (double z) {
                      HapticFeedback.selectionClick();
                      _setZoom(z);
                    },
                  ),
                ),
              Row(
                children: <Widget>[
                  _ControlButton(
                    icon: _flashIcon(),
                    onTap: _cycleFlash,
                    tooltip: AppLocalizations.of(context).cameraFlash,
                  ),
                  const Spacer(),
                  _ShutterButton(capturing: _capturing, onTap: _capture),
                  const Spacer(),
                  _ControlButton(
                    icon: Icons.cameraswitch_outlined,
                    onTap: _cameras.length > 1 ? _toggleCamera : null,
                    tooltip: AppLocalizations.of(context).cameraSwitch,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The lens / zoom presets offered by the current camera, e.g. 0.5×, 1×, 2×.
  List<double> get _zoomPresets {
    final Set<double> set = <double>{1.0};
    if (_minZoom <= 0.55) set.add(0.5);
    if (_maxZoom >= 2.0) set.add(2.0);
    if (_maxZoom >= 3.0) set.add(3.0);
    final List<double> list = set
        .where((double z) => z >= _minZoom - 0.01 && z <= _maxZoom + 0.01)
        .toList()
      ..sort();
    return list;
  }

  IconData _flashIcon() {
    switch (_flashMode) {
      case FlashMode.off:
        return Icons.flash_off_outlined;
      case FlashMode.auto:
        return Icons.flash_auto_outlined;
      case FlashMode.always:
        return Icons.flash_on_outlined;
      case FlashMode.torch:
        return Icons.highlight_outlined;
    }
  }
}

class _StampPreview extends StatelessWidget {
  const _StampPreview({
    required this.settings,
    required this.data,
    required this.accent,
  });

  final AppSettings settings;
  final StampContext data;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Padding(
        // Keep the preview clear of the top bar and the capture controls.
        padding: const EdgeInsets.fromLTRB(14, 118, 14, 168),
        child: Align(
          alignment: settings.stampPosition.alignment,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.78,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: settings.stampPosition.alignment,
              child: StampOverlay(
                settings: settings,
                data: data,
                accent: accent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GridOverlay extends StatelessWidget {
  const _GridOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _GridPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (int i = 1; i < 3; i++) {
      final double x = size.width * i / 3;
      final double y = size.height * i / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LocationPill extends StatelessWidget {
  const _LocationPill({required this.location, required this.accent});

  final LocationService location;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final LocationFix? fix = location.fix;
    final AppLocalizations l10n = AppLocalizations.of(context);

    String text;
    IconData icon;
    Color color;
    if (!location.serviceEnabled) {
      text = l10n.locationOff;
      icon = Icons.location_off_outlined;
      color = Colors.orangeAccent;
    } else if (!location.permissionGranted) {
      text = l10n.locationNoPermission;
      icon = Icons.location_disabled_outlined;
      color = Colors.orangeAccent;
    } else if (fix == null) {
      text = l10n.locationLocating;
      icon = Icons.my_location_outlined;
      color = Colors.white70;
    } else {
      text = l10n.locationAccuracy(fix.accuracy?.round().toString() ?? '–');
      icon = Icons.gps_fixed;
      color = accent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          if (fix != null && fix.heading != null) ...<Widget>[
            const SizedBox(width: 8),
            Icon(Icons.navigation, size: 14, color: Colors.white70),
            Text(
              '${fix.heading!.round()}°',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProjectChip extends StatelessWidget {
  const _ProjectChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String? active = context.watch<ProjectStore>().active;
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                active == null ? Icons.folder_open_outlined : Icons.folder_outlined,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: Text(
                  active ?? AppLocalizations.of(context).projectNone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({required this.icon, required this.onTap, required this.tooltip});

  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.45),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, color: onTap == null ? Colors.white38 : Colors.white),
          ),
        ),
      ),
    );
  }
}

class _ShutterButton extends StatefulWidget {
  const _ShutterButton({required this.capturing, required this.onTap});

  final bool capturing;
  final VoidCallback onTap;

  @override
  State<_ShutterButton> createState() => _ShutterButtonState();
}

class _ShutterButtonState extends State<_ShutterButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            color: widget.capturing ? Colors.white38 : Colors.white24,
          ),
          child: Center(
            child: widget.capturing
                ? const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  )
                : Container(
                    width: 62,
                    height: 62,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ZoomPresets extends StatelessWidget {
  const _ZoomPresets({
    required this.presets,
    required this.current,
    required this.onSelected,
  });

  final List<double> presets;
  final double current;
  final ValueChanged<double> onSelected;

  static String _label(double z) =>
      z == z.roundToDouble() ? '${z.toInt()}×' : '$z×';

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: presets.map((double preset) {
        final bool selected = (current - preset).abs() < 0.08;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Material(
            color: selected
                ? Colors.white
                : Colors.black.withValues(alpha: 0.45),
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onSelected(preset),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  _label(preset),
                  style: TextStyle(
                    color: selected ? Colors.black : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
