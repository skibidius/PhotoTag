import 'dart:async';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/app_settings.dart';
import '../models/photo_record.dart';
import '../services/capture_queue.dart';
import '../services/geocode_service.dart';
import '../services/location_service.dart';
import '../services/project_store.dart';
import '../services/settings_controller.dart';
import '../utils/page_route.dart';
import '../utils/route_observer.dart';
import '../widgets/stamp_overlay.dart';
import 'settings_screen.dart';

/// Camera startup failures, localised at render time.
enum _CameraError { noCamera, permission, cannotStart, cannotInit }

/// The in-app camera. It captures at the maximum available resolution, renders
/// the stamp from the same widget shown in the preview, and burns it into the
/// full-resolution photo without ever leaving the app.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key, this.active = true});

  /// Whether the camera tab is currently selected. When false the preview is
  /// paused to keep the rest of the app smooth.
  final bool active;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver, RouteAware {
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

  bool _routeVisible = true;
  bool _previewPaused = false;

  bool _capturing = false;
  StampContext? _captureCtx;
  String? _address;
  DateTime _now = DateTime.now();
  Timer? _clock;

  LocationService get _location => context.read<LocationService>();
  SettingsController get _settings => context.read<SettingsController>();
  ProjectStore get _projects => context.read<ProjectStore>();
  CaptureQueue get _queue => context.read<CaptureQueue>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _location.addListener(_onLocationChanged);
    _clock = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _now = DateTime.now()),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  /// Starts the camera and location. Both plugins ask for their own
  /// permission the first time they are initialised.
  Future<void> _bootstrap() async {
    await _initCamera();
    await _ensureLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    if (route is PageRoute) routeObserver.subscribe(this, route);
  }

  @override
  void didUpdateWidget(CameraScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) _syncPreview();
  }

  @override
  void didPushNext() {
    _routeVisible = false;
    _syncPreview();
  }

  @override
  void didPopNext() {
    _routeVisible = true;
    _syncPreview();
  }

  /// Pauses the preview whenever the camera is off-screen (another tab or a
  /// route on top), which keeps scrolling elsewhere at a smooth frame rate.
  void _syncPreview() {
    final CameraController? controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final bool shouldRun = widget.active && _routeVisible;
    if (shouldRun && _previewPaused) {
      controller.resumePreview();
      _previewPaused = false;
    } else if (!shouldRun && !_previewPaused) {
      controller.pausePreview();
      _previewPaused = true;
    }
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
    routeObserver.unsubscribe(this);
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
      _resolutionFor(_settings.value.photoQuality),
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
      _previewPaused = false;
      if (mounted) {
        setState(() => _initializing = false);
        _syncPreview();
      }
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

    // A photo must belong to a project.
    if (_projects.active == null) {
      HapticFeedback.selectionClick();
      final AppLocalizations l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.projectRequired),
          action: SnackBarAction(
            label: l10n.chooseProject,
            onPressed: _openProjectPicker,
          ),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _capturing = true);

    try {
      // Capture immediately — don't block on a fresh GPS fix; the location
      // stream already keeps the latest position warm.
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

      // Queue the heavy work (watermarking + encoding) so the shutter stays
      // instant and the user can keep shooting.
      _queue.enqueue(CaptureTask(
        photoBytes: photoBytes,
        stampPng: stampPng,
        position: settings.stampPosition,
        timestamp: ctx.timestamp,
        counter: settings.counter,
        coordText: ctx.coordText,
        saveOriginal: settings.saveOriginal,
        jpegQuality: settings.photoQuality.jpegQuality,
        latitude: fix?.latitude,
        longitude: fix?.longitude,
        altitude: fix?.altitude,
        bearing: fix?.heading,
        accuracy: fix?.accuracy,
        address: _address,
        note: settings.note,
        project: _projects.active,
      ));

      HapticFeedback.lightImpact();
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
    final String? activeProject = context.watch<ProjectStore>().active;
    final Color accent = Theme.of(context).colorScheme.primary;
    final StampContext liveCtx = _liveContext(settings);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: <Widget>[
          _buildBody(settings, location, accent, liveCtx,
              hasProject: activeProject != null),
        ],
      ),
    );
  }

  Widget _buildBody(AppSettings settings, LocationService location,
      Color accent, StampContext liveCtx, {required bool hasProject}) {
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
        // The full-frame preview with the grid, focus ring and live stamp
        // aligned to the photo frame (not the screen).
        _buildPreview(settings, liveCtx, accent),
        _buildTopBar(settings, location, accent),
        _buildSideControls(settings, accent),
        if (!hasProject)
          Positioned(
            left: 24,
            right: 24,
            bottom: 200,
            child: _NoProjectPrompt(onTap: _openProjectPicker),
          ),
        _buildBottomControls(settings, accent, hasProject: hasProject),
      ],
    );
  }

  Widget _buildPreview(
      AppSettings settings, StampContext liveCtx, Color accent) {
    final CameraController? controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.expand();
    }
    // Portrait aspect of the sensor, so the full frame is shown letterboxed
    // instead of cropped by a cover fit.
    final double previewAspect = 1 / controller.value.aspectRatio;

    return Center(
      child: AspectRatio(
        aspectRatio: previewAspect,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              onTapUp: (TapUpDetails d) =>
                  _onTapFocus(d, constraints.biggest),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  CameraPreview(controller),
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
                                border: Border.all(
                                    color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (settings.showHud)
                    _StampPreview(
                        settings: settings, data: liveCtx, accent: accent),
                ],
              ),
            );
          },
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
          if (_error == _CameraError.permission) ...<Widget>[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _location.openAppSettings(),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: Text(l10n.openSettings),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopBar(
      AppSettings settings, LocationService location, Color accent) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: <Widget>[
              Flexible(child: _ProjectChip(onTap: _openProjectPicker)),
              const Spacer(),
              _LocationPill(location: location, accent: accent),
            ],
          ),
        ),
      ),
    );
  }

  /// Grid and settings live in a vertical rail on the right edge.
  Widget _buildSideControls(AppSettings settings, Color accent) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _ControlButton(
              icon: settings.showGrid
                  ? Icons.grid_4x4
                  : Icons.grid_4x4_outlined,
              onTap: () => _settings.update(
                (AppSettings s) => s.copyWith(showGrid: !s.showGrid),
              ),
              tooltip: l10n.cameraGrid,
            ),
            const SizedBox(height: 12),
            _ControlButton(
              icon: Icons.settings_outlined,
              onTap: _openSettings,
              tooltip: l10n.cameraSettings,
            ),
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

  Widget _buildBottomControls(AppSettings settings, Color accent,
      {required bool hasProject}) {
    final List<double> presets = _zoomPresets;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const _QueueIndicator(),
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
                  _ShutterButton(
                    capturing: _capturing,
                    enabled: hasProject,
                    onTap: _capture,
                  ),
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

  ResolutionPreset _resolutionFor(PhotoQuality quality) {
    switch (quality) {
      case PhotoQuality.maximum:
        return ResolutionPreset.max;
      case PhotoQuality.high:
        return ResolutionPreset.veryHigh;
      case PhotoQuality.balanced:
        return ResolutionPreset.high;
    }
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
      child: Align(
        alignment: settings.stampPosition.alignment,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.8,
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

class _QueueIndicator extends StatelessWidget {
  const _QueueIndicator();

  @override
  Widget build(BuildContext context) {
    final CaptureQueue queue = context.watch<CaptureQueue>();
    final int count = queue.pendingCount;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: count == 0
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.savingCount(count),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _NoProjectPrompt extends StatelessWidget {
  const _NoProjectPrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.create_new_folder_outlined,
              color: Colors.white70, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.projectRequired,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: Text(l10n.chooseProject),
          ),
        ],
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
  const _ShutterButton({
    required this.capturing,
    required this.enabled,
    required this.onTap,
  });

  final bool capturing;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_ShutterButton> createState() => _ShutterButtonState();
}

class _ShutterButtonState extends State<_ShutterButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.enabled;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: enabled ? Colors.white : Colors.white54, width: 4),
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
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: enabled ? Colors.white : Colors.white54,
                      ),
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
