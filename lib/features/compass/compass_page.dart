import 'dart:async';
import 'package:flutter/material.dart';

import '../../data/storage/settings_storage.dart';
import '../../fengshui/bazhai.dart';
import '../../fengshui/compass_math.dart';
import '../../fengshui/compass_reading_builder.dart';
import 'compass_sensor_service.dart';
import 'compass_status.dart';
import 'luopan_dial.dart';
import 'tilt_service.dart';
import 'bubble_indicator.dart';
import '../../fengshui/bazhai_you_nian_table.dart';

enum CompassInputMode { sensor, manual }

class CompassPage extends StatefulWidget {
  const CompassPage({super.key});

  @override
  State<CompassPage> createState() => _CompassPageState();
}

class _CompassPageState extends State<CompassPage> {
  final _settings = SettingsStorage();
  final _sensor = const CompassSensorService();
  final _tilt = TiltService();

  CompassInputMode _mode = CompassInputMode.manual;

  double _rawHeading = 0;
  double _calibrationOffset = 0;
  double _smoothedHeading = 0;
  bool _hasSensorData = false;
  bool _smoothedInitialized = false;

  double _manualDegree = 161;
  String _houseGua = '乾';

  final List<double> _recentHeadings = [];
  static const int _stabilityWindow = 10;
  MagneticStatus _magneticStatus = MagneticStatus.normal;

  double _tiltH = 0;
  double _tiltV = 0;

  StreamSubscription<double?>? _headingSub;
  StreamSubscription<TiltData>? _tiltSub;
  bool _settingsLoaded = false;
  bool _showDebug = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _startSensor();
    _startTilt();
  }

  @override
  void dispose() {
    _headingSub?.cancel();
    _tiltSub?.cancel();
    super.dispose();
  }

  void _startTilt() {
    _tiltSub = _tilt.tiltStream.listen((data) {
      if (!mounted) return;
      setState(() {
        _tiltH = data.horizontalAngle;
        _tiltV = data.verticalAngle;
      });
    });
  }

  Future<void> _loadSettings() async {
    final gua = await _settings.loadHouseGua();
    final offset = await _settings.loadCalibrationOffset();
    setState(() {
      _houseGua = gua;
      _calibrationOffset = offset;
      _settingsLoaded = true;
    });
  }

  void _startSensor() {
    _headingSub = _sensor.headingStream.listen(
      (heading) {
        if (heading == null) return;
        if (!mounted) return;

        final raw = normalizeDegree(heading);

        if (!_smoothedInitialized) {
          _smoothedHeading = raw;
          _smoothedInitialized = true;
        } else {
          _smoothedHeading =
              smoothDegree(previous: _smoothedHeading, current: raw);
        }

        _recentHeadings.add(raw);
        if (_recentHeadings.length > _stabilityWindow) {
          _recentHeadings.removeAt(0);
        }

        setState(() {
          _rawHeading = raw;
          _hasSensorData = true;
          _magneticStatus =
              HeadingStabilityAnalyzer.analyze(_recentHeadings.toList());
        });
      },
      onError: (_) {},
    );
  }

  double get _displayHeading {
    if (_mode == CompassInputMode.manual) return _manualDegree;
    return applyCalibration(_smoothedHeading, _calibrationOffset);
  }

  void _calibrateToZero() {
    if (_mode == CompassInputMode.manual) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请切换到实时罗盘后设置当前为 0°')),
      );
      return;
    }
    final source = _rawHeading;
    setState(() => _calibrationOffset = source);
    _settings.saveCalibrationOffset(source);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              '已将当前方向设为 0°，偏移 ${source.toStringAsFixed(0)}°')),
    );
  }

  void _resetCalibration() {
    setState(() => _calibrationOffset = 0);
    _settings.saveCalibrationOffset(0);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已重置校准，恢复真实罗盘角度')),
    );
  }

  Future<void> _onHouseGuaChanged(String gua) async {
    setState(() => _houseGua = gua);
    await _settings.saveHouseGua(gua);
  }

  void _showCalibrationGuide() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('罗盘校准建议'),
        content: const Text(
          '1. 远离电梯、配电箱、冰箱、电脑、音箱、车库、金属门框。\n'
          '2. 摘掉磁吸手机壳或 MagSafe 配件。\n'
          '3. 将手机缓慢做 8 字形晃动数次。\n'
          '4. 测量时尽量保持手机水平。\n'
          '5. 若仍然不稳定，可切换到手动测试模式，或用已知方向进行偏移校准。\n\n'
          '注意：\n'
          'App 内的"设当前为0°"只是角度偏移校正，不能消除真实磁场干扰。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_settingsLoaded) {
      return const Scaffold(
        backgroundColor: Color(0xFFD8D6CF),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final reading = CompassReadingBuilder.build(
      degree: _displayHeading,
      houseGua: _houseGua,
    );

    final hasHeading = _mode == CompassInputMode.manual || _hasSensorData;
    final discRotationDeg = luopanVisualOffset - _displayHeading;

    return Scaffold(
      backgroundColor: const Color(0xFFD8D6CF),
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: () => setState(() => _showDebug = !_showDebug),
          child: const Text('风水荷盘'),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFc8b898),
        foregroundColor: const Color(0xFF333333),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ---- Top reading panel ----
            _buildTopPanel(reading, discRotationDeg),
            // ---- Triangle (part of overlay, spacer only) ----
            const SizedBox(height: 4),
            // ---- Luopan disc ----
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: LuopanDial(
                      heading: _displayHeading,
                      houseGua: _houseGua,
                    ),
                  ),
                ),
              ),
            ),
            // ---- Tilt calibration ----
            _buildTiltSection(),
            // ---- Bottom controls ----
            _buildBottomPanel(reading, hasHeading),
          ],
        ),
      ),
    );
  }

  // ======== TOP PANEL ========

  Widget _buildTopPanel(CompassReading reading, double discRotationDeg) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8EED8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFB99A61), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: compass-style main reading
          Text(
            '${compassDirectionName(reading.facingDegree)} ${reading.facingDegree.toStringAsFixed(0)}°',
            style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2A2118)),
          ),
          const SizedBox(height: 4),
          // Row 2: sitting-facing
          Text(
            reading.sittingFacingText,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5A4724)),
          ),
          const SizedBox(height: 6),
          // Row 3: merged rule summary
          Text(
            '${reading.facingGua}宫 · ${reading.fullSanyuanText} · ${reading.bazhaiStar}（${reading.bazhaiRank}）',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: reading.isAuspicious
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFC43C32)),
          ),
          const SizedBox(height: 4),
          // Row 4: status
          Text(
            _calibrationOffset != 0
                ? '${_magneticStatus.label} · 偏移 ${_calibrationOffset.toStringAsFixed(0)}°'
                : _magneticStatus.label,
            style: TextStyle(
                fontSize: 13,
                color: _magneticStatus == MagneticStatus.normal
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFC43C32)),
          ),
          // Debug row
          if (_showDebug) ...[
            const Divider(height: 10),
            Text(
              'raw:${_rawHeading.toStringAsFixed(1)}° '
              'disp:${_displayHeading.toStringAsFixed(1)}° '
              'discRot:${discRotationDeg.toStringAsFixed(1)}° '
              'mode:${_mode.name} gua:$_houseGua '
              'offset:${_calibrationOffset.toStringAsFixed(1)}°',
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF888888),
                  fontFamily: 'monospace'),
            ),
          ],
        ],
      ),
    );
  }

  // ======== BOTTOM PANEL ========

  // ======== TILT SECTION ========

  String get _combinedCalibrationLabel {
    final hStatus = tiltStatus(_tiltH);
    final vStatus = tiltStatus(_tiltV);
    if (hStatus == TiltStatus.good && vStatus == TiltStatus.good) {
      return '校准良好';
    }
    if (hStatus == TiltStatus.bad || vStatus == TiltStatus.bad) {
      return '姿态偏差较大，读数可能不准';
    }
    return '轻微偏移，建议微调';
  }

  Color get _combinedCalibrationColor {
    final hStatus = tiltStatus(_tiltH);
    final vStatus = tiltStatus(_tiltV);
    if (hStatus == TiltStatus.good && vStatus == TiltStatus.good) {
      return const Color(0xFF4CAF50);
    }
    if (hStatus == TiltStatus.bad || vStatus == TiltStatus.bad) {
      return const Color(0xFFEF5350);
    }
    return const Color(0xFFFFC107);
  }

  Widget _buildTiltSection() {
    final statusColor = _combinedCalibrationColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0E8D5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD8C8A0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('校准状态：',
                  style: TextStyle(fontSize: 12, color: Color(0xFF7A6040))),
              Text(_combinedCalibrationLabel,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor)),
            ],
          ),
          const SizedBox(height: 4),
          BubbleIndicator(label: '水平', angle: _tiltH),
          const SizedBox(height: 2),
          BubbleIndicator(label: '垂直', angle: _tiltV),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(CompassReading reading, bool hasHeading) {
    return Container(
      color: const Color(0xFFe8e0d0),
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeSwitch(),
          const SizedBox(height: 4),
          _buildHouseGuaSelector(),
          const SizedBox(height: 4),
          _buildCalibrationButtons(),
          const SizedBox(height: 4),
          Text(
            '校准偏移：${_calibrationOffset.toStringAsFixed(0)}°',
            style: const TextStyle(
                fontSize: 11, color: Color(0xFF9A8A6A)),
          ),
          if (_mode == CompassInputMode.manual) _buildManualSlider(),
        ],
      ),
    );
  }

  Widget _buildModeSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChoiceChip(
          selected: _mode == CompassInputMode.sensor,
          selectedColor: const Color(0xFF5A4724),
          backgroundColor: const Color(0xFFF0E8D5),
          side: BorderSide(
              color: _mode == CompassInputMode.sensor
                  ? const Color(0xFF5A4724)
                  : const Color(0xFFB99A61)),
          labelStyle: TextStyle(
              color:
                  _mode == CompassInputMode.sensor ? Colors.white : const Color(0xFF5A4724),
              fontSize: 13),
          label: const Text('实时罗盘'),
          onSelected: (_) => setState(() => _mode = CompassInputMode.sensor),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          selected: _mode == CompassInputMode.manual,
          selectedColor: const Color(0xFF5A4724),
          backgroundColor: const Color(0xFFF0E8D5),
          side: BorderSide(
              color: _mode == CompassInputMode.manual
                  ? const Color(0xFF5A4724)
                  : const Color(0xFFB99A61)),
          labelStyle: TextStyle(
              color:
                  _mode == CompassInputMode.manual ? Colors.white : const Color(0xFF5A4724),
              fontSize: 13),
          label: const Text('手动测试'),
          onSelected: (_) => setState(() => _mode = CompassInputMode.manual),
        ),
      ],
    );
  }

  void _showHouseGuaPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.58,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF7EEDB),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Color(0xFFB99A61),
                      borderRadius:
                          BorderRadius.all(Radius.circular(999)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('选择宅卦',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2A2118))),
                  const SizedBox(height: 8),
                  const Divider(
                      height: 1, color: Color(0xFFB99A61)),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      children: BazhaiCalculator.guas.map((g) {
                        final selected = g == _houseGua;
                        final group = getHouseGroup(g);
                        return ListTile(
                          dense: true,
                          visualDensity:
                              const VisualDensity(vertical: -1),
                          tileColor: selected
                              ? const Color(0xFFE9D8AE)
                              : null,
                          title: Text(
                            '$g宅',
                            style: TextStyle(
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: const Color(0xFF2A2118),
                            ),
                          ),
                          subtitle: Text(
                            group,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF7A6040)),
                          ),
                          trailing: selected
                              ? const Icon(Icons.check,
                                  color: Color(0xFF5A4724),
                                  size: 20)
                              : null,
                          onTap: () {
                            _onHouseGuaChanged(g);
                            Navigator.pop(ctx);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHouseGuaSelector() {
    final group = getHouseGroup(_houseGua);
    return GestureDetector(
      onTap: _showHouseGuaPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF0E8D5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFB99A61)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_houseGua宅',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2A2118)),
            ),
            const SizedBox(width: 6),
            Text(
              group,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF7A6040)),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down,
                color: Color(0xFF7A6040), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildCalibrationButtons() {
    final btnStyle = OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF5A4724),
      side: const BorderSide(color: Color(0xFFB99A61)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    );

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: [
        FilledButton.icon(
          onPressed: _calibrateToZero,
          icon: const Icon(Icons.gps_fixed, size: 14),
          label: const Text('设当前为0°', style: TextStyle(fontSize: 12)),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF5A4724),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          ),
        ),
        OutlinedButton(
          onPressed: _resetCalibration,
          style: btnStyle,
          child: const Text('重置校准', style: TextStyle(fontSize: 12)),
        ),
        OutlinedButton(
          onPressed: _showCalibrationGuide,
          style: btnStyle,
          child: const Text('校准说明', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildManualSlider() {
    return Column(
      children: [
        Text(
          '手动角度：${_manualDegree.toStringAsFixed(0)}°',
          style: const TextStyle(fontSize: 12, color: Color(0xFF7A6040)),
        ),
        SizedBox(
          height: 28,
          child: Slider(
            min: 0,
            max: 359,
            divisions: 359,
            value: _manualDegree,
            activeColor: const Color(0xFF5A4724),
            onChanged: (v) => setState(() => _manualDegree = v),
          ),
        ),
      ],
    );
  }
}

// ======== tiny widgets ========

