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
import '../../fengshui/bazhai_you_nian_table.dart';
import '../../fengshui/compass_math.dart';
import '../../fengshui/compass_reading_builder.dart';
import '../../fengshui/direction_sector.dart';
import '../projects/widgets/measure_point_form_sheet.dart';
import 'compass_sensor_service.dart';

/// Snapshot of all measure data at capture moment.
class MeasureSnapshot {
  final double heading;
  final String directionText;
  final String sittingFacingText;
  final String palaceText;
  final String facingMountain;
  final String sittingMountain;
  final String bazhaiText;
  final String statusText;
  final String mountainText;
  final String houseGua;
  final double? pitch;
  final double? roll;
  final DateTime takenAt;

  const MeasureSnapshot({
    required this.heading,
    required this.directionText,
    required this.sittingFacingText,
    required this.palaceText,
    required this.facingMountain,
    required this.sittingMountain,
    required this.bazhaiText,
    required this.statusText,
    required this.mountainText,
    required this.houseGua,
    this.pitch,
    this.roll,
    required this.takenAt,
  });
}

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

  CameraController? _cameraController;
  bool _cameraInitialized = false;
  String? _cameraError;

  // Heading
  double _heading = 0;
  StreamSubscription<CompassSensorReading>? _headingSub;

  // Tilt
  double _pitch = 0;
  double _roll = 0;

  // UI state
  bool _capturing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _initHeading();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _headingSub?.cancel();
    _cameraController?.dispose();
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

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _cameraError = '未检测到相机');
        return;
      }
      // Prefer back camera
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(back, ResolutionPreset.medium);
      _cameraController = controller;
      await controller.initialize();
      if (!mounted) return;
      setState(() => _cameraInitialized = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _cameraError = '相机初始化失败：$e');
    }
  }

  void _initHeading() {
    _headingSub = _sensor.readingStream.listen((reading) {
      if (!mounted || reading.heading == null) return;
      setState(() {
        _heading = reading.heading!;
      });
    });
  }

  // ---- Build reading from current heading ----
  CompassReading _buildReading({String houseGua = '乾'}) {
    return CompassReadingBuilder.build(
      degree: _heading,
      houseGua: houseGua,
    );
  }

  String _directionText() {
    return '${compassDirectionName(_heading)}${_heading.toStringAsFixed(0)}°';
  }

  // ---- Capture ----
  Future<void> _onCapture() async {
    if (_capturing || _cameraController == null) return;
    setState(() => _capturing = true);

    try {
      // 1. Take photo
      final XFile? photo;
      try {
        photo = await _cameraController!.takePicture();
      } catch (e) {
        // Photo failed — ask user if they want to save without photo
        if (!mounted) return;
        final proceed = await _showPhotoFailedDialog();
        if (proceed != true) {
          setState(() => _capturing = false);
          return;
        }
        await _openSaveSheet(null);
        setState(() => _capturing = false);
        return;
      }

      // 2. Save photo to app private dir
      final now = DateTime.now();
      final photoDir = await getApplicationDocumentsDirectory();
      final photoSubDir = Directory('${photoDir.path}/project_photos');
      if (!await photoSubDir.exists()) {
        await photoSubDir.create(recursive: true);
      }
      final photoPath =
          '${photoSubDir.path}/capture_${now.millisecondsSinceEpoch}.jpg';
      await File(photo.path).copy(photoPath);

      // 3. Open save sheet
      if (!mounted) return;
      await _openSaveSheet(photoPath);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('拍照失败：$e')),
      );
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _openSaveSheet(String? photoPath) async {
    final now = DateTime.now();
    final reading = _buildReading();
    final meta = bazhaiStarMetaMap[reading.bazhaiStar];
    final bazhaiText =
        '${reading.bazhaiStar}${meta?.element ?? ''}（${reading.bazhaiRank}）';
    final dirText = _directionText();

    setState(() => _saving = true);

    // Open the existing measure point form sheet
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
        bazhaiText: bazhaiText,
        statusText: '相机测向',
        horizontalAngle: _roll,
        verticalAngle: _pitch,
        houseGua: reading.houseGua,
        projectId: widget.project?.id,
        photoPath: photoPath,
        photoTakenAt: now,
        savedPitch: _pitch,
        savedRoll: _roll,
        savedFromCamera: photoPath != null,
      ),
      houseGua: reading.houseGua,
    );

    if (result == null || !mounted) {
      setState(() => _saving = false);
      return;
    }

    // Save the new record
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
      bazhaiText: bazhaiText,
      statusText: '相机测向',
      horizontalAngle: _roll,
      verticalAngle: _pitch,
      houseGua: reading.houseGua,
      projectId: widget.project?.id,
      measureType: result.measureType,
      measureName: result.measureName,
      spaceName: result.spaceName,
      note: result.note,
      photoPath: photoPath,
      photoTakenAt: now,
      savedPitch: _pitch,
      savedRoll: _roll,
      savedFromCamera: photoPath != null,
    );
    await _storage.addRecord(record);

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('测点已保存${photoPath != null ? '（含现场照片）' : ''}')),
    );
    Navigator.pop(context, record);
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
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
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

          // Crosshair + overlays
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

  List<Widget> _buildOverlays() {
    final reading = _buildReading();
    final dirText = _directionText();
    final sectorKey = DirectionSector.sector8FromHeading(_heading);
    final palaceLabel = DirectionSector.sectorGuaPalaceLabel(sectorKey);
    final dirLabel = DirectionSector.shortSector8Label(sectorKey);
    final meta = bazhaiStarMetaMap[reading.bazhaiStar];
    final bazhaiText =
        '${reading.bazhaiStar}${meta?.element ?? ''}（${reading.bazhaiRank}）';
    final sitingText = reading.sittingFacingText;

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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '相机测向',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),

      // Crosshair (center)
      CustomPaint(
        size: Size.infinite,
        painter: _CrosshairPainter(
          pitch: _pitch,
          roll: _roll,
        ),
      ),

      // Heading info (center-top area)
      Positioned(
        left: 0,
        right: 0,
        top: MediaQuery.of(context).size.height * 0.22,
        child: IgnorePointer(
          child: Column(
            children: [
              // Big heading
              Text(
                dirText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(color: Colors.black54, blurRadius: 8),
                  ],
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
                  shadows: [
                    Shadow(color: Colors.black54, blurRadius: 6),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              // Bazhai
              Text(
                bazhaiText,
                style: TextStyle(
                  color: meta?.isGood == true
                      ? const Color(0xFF66BB6A)
                      : const Color(0xFFEF5350),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  shadows: const [
                    Shadow(color: Colors.black54, blurRadius: 6),
                  ],
                ),
              ),
            ],
          ),
        ),
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
                              color: _capturing
                                  ? Colors.grey
                                  : Colors.white,
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
              _capturing ? '处理中…' : '将十字线对准目标中心',
              style: const TextStyle(
                color: Colors.white60,
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

    // Color based on tilt
    final tiltQuality = (pitch.abs() + roll.abs()) / 2;
    Color color;
    if (tiltQuality < 15) {
      color = Colors.white;
    } else if (tiltQuality < 30) {
      color = Colors.yellowAccent;
    } else {
      color = Colors.redAccent;
    }

    final paint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final shadowPaint = Paint()
      ..color = Colors.black38
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    void drawLine(Offset from, Offset to) {
      canvas.drawLine(from, to, shadowPaint);
      canvas.drawLine(from, to, paint);
    }

    // Vertical line (top)
    drawLine(
      Offset(center.dx, center.dy - gap),
      Offset(center.dx, center.dy - len),
    );
    // Vertical line (bottom)
    drawLine(
      Offset(center.dx, center.dy + gap),
      Offset(center.dx, center.dy + len),
    );
    // Horizontal line (left)
    drawLine(
      Offset(center.dx - gap, center.dy),
      Offset(center.dx - len, center.dy),
    );
    // Horizontal line (right)
    drawLine(
      Offset(center.dx + gap, center.dy),
      Offset(center.dx + len, center.dy),
    );

    // Center dot
    canvas.drawCircle(
      center,
      3.0,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_CrosshairPainter old) =>
      old.pitch != pitch || old.roll != roll;
}
