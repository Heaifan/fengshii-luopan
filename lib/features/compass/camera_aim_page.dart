import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/compass_record.dart';
import '../../data/models/measure_type.dart';
import '../../data/models/measurement_project.dart';
import '../../data/storage/settings_storage.dart';
import '../../fengshui/bazhai_base_resolver.dart';
import '../../fengshui/bazhai_you_nian_table.dart';
import '../../fengshui/compass_math.dart';
import '../../fengshui/compass_reading_builder.dart';
import '../../fengshui/direction_sector.dart';
import '../../fengshui/measure_hints.dart';
import '../projects/new_measurement_project_page.dart';
import '../projects/widgets/measure_point_form_sheet.dart';
import '../projects/widgets/project_picker_sheet.dart';
import 'compass_sensor_service.dart';
import 'services/photo_watermark_service.dart';

class CameraAimPage extends StatefulWidget {
  final MeasurementProject? project;

  const CameraAimPage({super.key, this.project});

  @override
  State<CameraAimPage> createState() => _CameraAimPageState();
}

class _CameraAimPageState extends State<CameraAimPage>
    with WidgetsBindingObserver {
  final _sensor = const CompassSensorService();
  final _storage = SettingsStorage();

  List<CameraDescription> _backCameras = [];
  int _cameraIndex = 0;
  CameraController? _cameraController;
  bool _cameraInitialized = false;
  String? _cameraError;
  double _currentZoom = 1.0;

  // Heading
  double _heading = 0;
  StreamSubscription<CompassSensorReading>? _headingSub;

  // Tilt
  double _pitch = 0;
  double _roll = 0;

  // UI state
  bool _capturing = false;
  bool _saving = false;
  String? _tempPhotoPath;
  String _selectedType = 'entranceDoor';

  // Project / Bazhai state
  MeasurementProject? _project;
  List<CompassRecord> _projectRecords = [];
  bool _bazhaiResolved = false;
  String _bazhaiBaseGua = '';
  bool _projectChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initProject();
    _initHeading();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _headingSub?.cancel();
    _cameraController?.dispose();
    // Cleanup temp photo if any
    _cleanupTemp();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    }
  }

  // ============================================================
  // Project check
  // ============================================================

  Future<void> _initProject() async {
    if (widget.project != null) {
      _project = widget.project;
      await _loadProjectRecords();
      if (mounted) setState(() => _projectChecked = true);
      await _initCamera();
      return;
    }

    final project = await _ensureProjectForCamera();

    if (project == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    _project = project;
    await _loadProjectRecords();

    if (!mounted) return;
    setState(() => _projectChecked = true);
    await _initCamera();
  }

  /// Let user pick an existing project or create a new one.
  Future<MeasurementProject?> _ensureProjectForCamera() async {
    final projects = await _storage.loadProjects();

    if (!mounted) return null;

    // No projects at all → force create
    if (projects.isEmpty) {
      return _createProjectForCamera();
    }

    // Have projects → show picker
    return showModalBottomSheet<MeasurementProject>(
      context: context,
      builder: (ctx) => ProjectPickerSheet(
        projects: projects,
        onCreateProject: _createProjectForCamera,
      ),
    );
  }

  Future<MeasurementProject?> _createProjectForCamera() async {
    return Navigator.push<MeasurementProject>(
      context,
      MaterialPageRoute(
        builder: (_) => const NewMeasurementProjectPage(
          returnProject: true,
        ),
      ),
    );
  }

  Future<void> _loadProjectRecords() async {
    if (_project == null) return;
    final records = await _storage.loadRecordsByProject(_project!.id);
    _projectRecords = records;
    _updateBazhaiStatus();
  }

  void _updateBazhaiStatus() {
    if (_project == null) {
      _bazhaiResolved = false;
      _bazhaiBaseGua = '';
      return;
    }
    final base = BaZhaiBaseResolver.resolveBasePalace(
      project: _project!,
      records: _projectRecords,
    );
    _bazhaiResolved = base != null;
    _bazhaiBaseGua = base ?? '乾';
  }

  // ============================================================
  // Camera
  // ============================================================

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _cameraError = '未检测到相机');
        return;
      }
      // Collect back cameras (use index 0 = main)
      _backCameras = cameras
          .where((c) => c.lensDirection == CameraLensDirection.back)
          .toList();
      if (_backCameras.isEmpty) {
        _backCameras = [cameras.first];
      }
      _cameraIndex = 0;
      await _initCameraController(_backCameras[_cameraIndex]);
    } catch (e) {
      if (!mounted) return;
      setState(() => _cameraError = '相机初始化失败：$e');
    }
  }

  Future<void> _initCameraController(CameraDescription camera) async {
    final controller = CameraController(camera, ResolutionPreset.medium);
    _cameraController = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() => _cameraInitialized = true);

      // Auto-set to ultra-wide if supported
      try {
        final minZoom = await controller.getMinZoomLevel();
        if (minZoom < 0.8) {
          await controller.setZoomLevel(minZoom);
          _currentZoom = minZoom;
        }
      } catch (_) {
        // Zoom API not available on this device — stay at default 1x
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _cameraError = '相机初始化失败：$e');
    }
  }

  void _switchCamera() {
    if (_backCameras.length < 2) return;
    final newIdx = (_cameraIndex + 1) % _backCameras.length;
    _cameraController?.dispose();
    _cameraInitialized = false;
    setState(() => _cameraIndex = newIdx);
    _initCameraController(_backCameras[newIdx]);
  }

  // ============================================================
  // Heading
  // ============================================================

  void _initHeading() {
    _headingSub = _sensor.readingStream.listen((reading) {
      if (!mounted || reading.heading == null) return;
      setState(() {
        _heading = reading.heading!;
      });
    });
  }

  CompassReading _buildReading({String? houseGua}) {
    final gua = houseGua ?? _bazhaiBaseGua;
    return CompassReadingBuilder.build(
      degree: _heading,
      houseGua: gua,
    );
  }

  String _directionText() {
    return '${compassDirectionName(_heading)}${_heading.toStringAsFixed(0)}°';
  }

  // ============================================================
  // Capture → 伏位 (first) → Watermark → Save
  // ============================================================

  /// Check if this project still needs its first definition (伏位).
  bool get _needsBasePalace {
    return _project != null &&
        BaZhaiBaseResolver.needsBasePalace(_project!, _projectRecords);
  }

  Future<void> _onCapture() async {
    if (_capturing || _cameraController == null || _project == null) return;
    setState(() => _capturing = true);

    try {
      // Check if first capture — must define 伏位 first
      if (_needsBasePalace) {
        await _setBasePalaceAndCapture();
        if (!mounted) return;
        setState(() => _capturing = false);
        return;
      }

      // Normal capture: take photo → save form
      await _normalCapture();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('拍照失败：$e')),
      );
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  /// First capture: set 伏位 from heading, save project, save photo.
  Future<void> _setBasePalaceAndCapture() async {
    // 1. Set 伏位 from current heading
    final gua = BaZhaiBaseResolver.guaFromHeading(_heading);
    final now = DateTime.now();
    final updatedProject = MeasurementProject(
      id: _project!.id,
      name: _project!.name,
      type: _project!.type,
      location: _project!.location,
      note: _project!.note,
      createdAt: _project!.createdAt,
      updatedAt: now,
      baZhaiMode: 'wholeHouse',
      basePalace: gua,
    );
    await _storage.updateProject(updatedProject);
    _project = updatedProject;
    _bazhaiResolved = true;
    _bazhaiBaseGua = gua;

    // 2. Show 伏位 confirmation
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('伏位已定：${gua}宫（${_directionText()}）'),
        backgroundColor: const Color(0xFF1E8E3E),
        duration: const Duration(seconds: 2),
      ),
    );

    // 3. Also capture and save the photo as a normal point
    await _normalCapture();
  }

  /// Normal capture: take photo → watermark → save form.
  Future<void> _normalCapture() async {
    // 1. Take photo → save as temp file
    final XFile? photo;
    try {
      photo = await _cameraController!.takePicture();
    } catch (e) {
      if (!mounted) return;
      final proceed = await _showPhotoFailedDialog();
      if (proceed == true) {
        await _saveWithoutPhoto();
      }
      return;
    }

    // 2. Save to temp
    final tempDir = await getApplicationDocumentsDirectory();
    final tempFile = '${tempDir.path}/temp_capture_${DateTime.now().millisecondsSinceEpoch}.jpg';
    _tempPhotoPath = tempFile;
    await File(photo.path).copy(tempFile);

    // 3. Open save form
    if (!mounted) return;
    await _openSaveForm(tempFile);
  }

  Future<void> _openSaveForm(String tempPath) async {
    final now = DateTime.now();
    final reading = _buildReading();
    final dirText = _directionText();
    final sectorKey = DirectionSector.sector8FromHeading(_heading);
    final palaceLabel = DirectionSector.sectorGuaPalaceLabel(sectorKey);

    // Build bazhai text — handle pending
    String bazhaiDisplay;
    if (_bazhaiResolved) {
      final meta = bazhaiStarMetaMap[reading.bazhaiStar];
      bazhaiDisplay =
          '${reading.bazhaiStar}${meta?.element ?? ''}（${reading.bazhaiRank}）';
    } else {
      bazhaiDisplay = '待定（请先保存入户门）';
    }

    setState(() => _saving = true);

    final result = await showMeasurePointFormSheet(
      context: context,
      initialRecord: CompassRecord.create(
        name: '',
        heading: _heading,
        directionText: dirText,
        sittingFacingText: reading.sittingFacingText,
        sittingMountain: reading.sittingMountain,
        facingMountain: reading.facingMountain,
        palace: '$palaceLabel',
        mountainText: reading.fullSanyuanText,
        bazhaiText: bazhaiDisplay,
        statusText: '相机测向',
        horizontalAngle: _roll,
        verticalAngle: _pitch,
        houseGua: _bazhaiBaseGua,
        projectId: _project!.id,
        measureType: _selectedType,
        savedFromCamera: false,
      ),
      houseGua: _bazhaiBaseGua,
    );

    if (result == null || !mounted) {
      // User cancelled — cleanup temp
      _cleanupTemp();
      setState(() => _saving = false);
      return;
    }

    // User confirmed — generate watermarked photo
    String? finalPhotoPath;
    try {
      final meta = bazhaiStarMetaMap[reading.bazhaiStar];
      final bazhaiText = _bazhaiResolved
          ? '${reading.bazhaiStar}${meta?.element ?? ''}（${reading.bazhaiRank}）'
          : '待定';

      finalPhotoPath = await PhotoWatermarkService.addWatermark(
        sourcePath: tempPath,
        headingText: dirText,
        palaceText: '${reading.facingGua}宫',
        sittingFacingText: reading.sittingFacingText,
        facingMountainText: reading.facingMountain,
        sittingMountainText: reading.sittingMountain,
        projectName: _project?.name ?? '',
        pointLabel: MeasureTypes.label(result.measureType),
        pointName: result.measureName,
        bazhaiText: bazhaiText,
        takenAt: now,
        magneticField: null,
        pitch: _pitch,
        roll: _roll,
        deleteSource: true,
      );
    } catch (_) {}
    _tempPhotoPath = null; // temp handled by watermark service

    // Save the record
    final record = CompassRecord.create(
      name: result.measureName.isEmpty
          ? '${MeasureTypes.label(result.measureType)}测点'
          : result.measureName,
      heading: _heading,
      directionText: dirText,
      sittingFacingText: reading.sittingFacingText,
      sittingMountain: reading.sittingMountain,
      facingMountain: reading.facingMountain,
      palace: '${reading.facingGua}宫',
      mountainText: reading.fullSanyuanText,
      bazhaiText: bazhaiDisplay,
      statusText: '相机测向',
      horizontalAngle: _roll,
      verticalAngle: _pitch,
      houseGua: _bazhaiBaseGua,
      projectId: _project!.id,
      measureType: result.measureType,
      measureName: result.measureName,
      spaceName: result.spaceName,
      note: result.note,
      photoPath: finalPhotoPath,
      photoTakenAt: now,
      savedPitch: _pitch,
      savedRoll: _roll,
      savedFromCamera: finalPhotoPath != null,
    );
    await _storage.addRecord(record);

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '测点已保存${finalPhotoPath != null ? '（含带水印照片）' : '（照片保存失败）'}',
        ),
      ),
    );
    Navigator.pop(context, record);
  }

  Future<void> _saveWithoutPhoto() async {
    final reading = _buildReading();
    final dirText = _directionText();
    final bazhaiDisplay = _bazhaiResolved
        ? '${reading.bazhaiStar}${bazhaiStarMetaMap[reading.bazhaiStar]?.element ?? ''}（${reading.bazhaiRank}）'
        : '待定';

    final result = await showMeasurePointFormSheet(
      context: context,
      initialRecord: CompassRecord.create(
        name: '',
        heading: _heading,
        directionText: dirText,
        sittingFacingText: reading.sittingFacingText,
        sittingMountain: reading.sittingMountain,
        facingMountain: reading.facingMountain,
        palace: '${reading.facingGua}宫',
        mountainText: reading.fullSanyuanText,
        bazhaiText: bazhaiDisplay,
        statusText: '相机测向',
        horizontalAngle: _roll,
        verticalAngle: _pitch,
        houseGua: _bazhaiBaseGua,
        projectId: _project!.id,
        measureType: _selectedType,
        savedFromCamera: false,
      ),
      houseGua: _bazhaiBaseGua,
    );

    if (result == null || !mounted) return;

    final record = CompassRecord.create(
      name: result.measureName.isEmpty
          ? '${MeasureTypes.label(result.measureType)}测点'
          : result.measureName,
      heading: _heading,
      directionText: dirText,
      sittingFacingText: reading.sittingFacingText,
      sittingMountain: reading.sittingMountain,
      facingMountain: reading.facingMountain,
      palace: '${reading.facingGua}宫',
      mountainText: reading.fullSanyuanText,
      bazhaiText: bazhaiDisplay,
      statusText: '相机测向',
      horizontalAngle: _roll,
      verticalAngle: _pitch,
      houseGua: _bazhaiBaseGua,
      projectId: _project!.id,
      measureType: result.measureType,
      measureName: result.measureName,
      spaceName: result.spaceName,
      note: result.note,
      savedFromCamera: false,
    );
    await _storage.addRecord(record);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('测点已保存（无照片）')),
    );
    Navigator.pop(context, record);
  }

  void _cleanupTemp() {
    if (_tempPhotoPath != null) {
      try { File(_tempPhotoPath!).delete(); } catch (_) {}
      _tempPhotoPath = null;
    }
  }

  Future<bool?> _showPhotoFailedDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('拍照失败'),
        content: const Text('照片保存失败，是否仅保存测点？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('仅保存测点'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Bazhai display
  // ============================================================

  String _bazhaiDisplayText() {
    if (!_bazhaiResolved) return '八宅：待定';
    final reading = _buildReading();
    final meta = bazhaiStarMetaMap[reading.bazhaiStar];
    return '八宅：${reading.bazhaiStar}${meta?.element ?? ''}（${reading.bazhaiRank}）';
  }

  Color? _bazhaiColor() {
    if (!_bazhaiResolved) return const Color(0xFFFFD54F);
    final reading = _buildReading();
    final meta = bazhaiStarMetaMap[reading.bazhaiStar];
    return meta?.isGood == true
        ? const Color(0xFF66BB6A)
        : const Color(0xFFEF5350);
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (!_projectChecked) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_cameraInitialized && _cameraController != null)
            SizedBox.expand(
              child: CameraPreview(_cameraController!),
            )
          else if (_cameraError != null)
            _buildError()
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          if (_cameraInitialized || _cameraError != null)
            ..._buildOverlays(),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam_off, color: Colors.white70, size: 48),
          const SizedBox(height: 12),
          Text(
            _cameraError!,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('返回'),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    const types = ['entranceDoor', 'roomDoor', 'balcony', 'window', 'bed'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: types.map((t) {
          final selected = t == _selectedType;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => setState(() => _selectedType = t),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.black38,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? Colors.white : Colors.white24,
                    width: selected ? 1.5 : 0.5,
                  ),
                ),
                child: Text(
                  MeasureTypes.label(t),
                  style: TextStyle(
                    color: selected ? Colors.black87 : Colors.white70,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Widget> _buildOverlays() {
    final reading = _buildReading();
    final dirText = _directionText();
    final sectorKey = DirectionSector.sector8FromHeading(_heading);
    final palaceLabel = DirectionSector.sectorGuaPalaceLabel(sectorKey);
    final dirLabel = DirectionSector.shortSector8Label(sectorKey);
    final sitingText = reading.sittingFacingText;
    final bazhaiDisplay = _bazhaiDisplayText();
    final bazhaiColor = _bazhaiColor();

    return [
      // Top bar
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              // Lens switch button
              if (_backCameras.length > 1)
                IconButton(
                  icon: const Icon(Icons.flip_camera_android,
                      color: Colors.white),
                  onPressed: _switchCamera,
                  tooltip: '切换镜头',
                ),
              const SizedBox(width: 4),
              // 定伏位 badge or project name
              if (_needsBasePalace)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '定伏位',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _project?.name ?? '相机测向',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),

      // Crosshair (center)
      CustomPaint(
        size: Size.infinite,
        painter: _CrosshairPainter(pitch: _pitch, roll: _roll),
      ),

      // Heading info + type selector (upper area)
      Positioned(
        left: 0,
        right: 0,
        top: MediaQuery.of(context).size.height * 0.14,
        child: IgnorePointer(
          child: Column(
            children: [
              // Measurement principle
              Text(
                MeasureHints.principle,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                ),
              ),
              const SizedBox(height: 8),
              // Big heading
              Text(
                dirText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                ),
              ),
              const SizedBox(height: 4),
              // Palace + sitting
              Text(
                '$palaceLabel（$dirLabel）｜$sitingText',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                ),
              ),
              const SizedBox(height: 2),
              // Bazhai
              Text(
                bazhaiDisplay,
                style: TextStyle(
                  color: bazhaiColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
                ),
              ),
              const SizedBox(height: 10),
              // Context label + hint
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      '当前：${MeasureHints.shortContext(_selectedType)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      MeasureHints.hintFor(_selectedType),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // Type selector (above capture button)
      Positioned(
        left: 0,
        right: 0,
        bottom: MediaQuery.of(context).size.height * 0.16,
        child: _buildTypeSelector(),
      ),

      // Capture button (bottom)
      Positioned(
        left: 0,
        right: 0,
        bottom: MediaQuery.of(context).size.height * 0.08,
        child: Center(
          child: _saving
              ? const CircularProgressIndicator(color: Colors.white)
              : GestureDetector(
                  onTap: _capturing ? null : _onCapture,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white70, width: 4),
                    ),
                    child: Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Center(
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.black26,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.black87,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),

      // Bottom hint
      Positioned(
        left: 0,
        right: 0,
        bottom: MediaQuery.of(context).size.height * 0.03,
        child: IgnorePointer(
          child: Center(
            child: Text(
              _capturing
                  ? '处理中…'
                  : _needsBasePalace
                      ? '首次拍照自动定为伏位'
                      : '将十字线对准目标中心',
              style: TextStyle(
                color: _needsBasePalace
                    ? const Color(0xFFFFD54F)
                    : Colors.white60,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    ];
  }
}

// ============================================================
// Crosshair Painter
// ============================================================

class _CrosshairPainter extends CustomPainter {
  final double pitch;
  final double roll;

  const _CrosshairPainter({required this.pitch, required this.roll});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final len = math.min(size.width, size.height) * 0.15;
    final gap = 12.0;

    final tiltQuality = (pitch.abs() + roll.abs()) / 2;
    final color = tiltQuality < 15
        ? Colors.white
        : tiltQuality < 30
            ? Colors.yellowAccent
            : Colors.redAccent;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final shadowPaint = Paint()
      ..color = Colors.black38
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    void draw(Offset from, Offset to) {
      canvas.drawLine(from, to, shadowPaint);
      canvas.drawLine(from, to, paint);
    }

    draw(Offset(center.dx, center.dy - gap),
        Offset(center.dx, center.dy - len));
    draw(Offset(center.dx, center.dy + gap),
        Offset(center.dx, center.dy + len));
    draw(Offset(center.dx - gap, center.dy),
        Offset(center.dx - len, center.dy));
    draw(Offset(center.dx + gap, center.dy),
        Offset(center.dx + len, center.dy));

    canvas.drawCircle(center, 3.0, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_CrosshairPainter old) =>
      old.pitch != pitch || old.roll != roll;
}
