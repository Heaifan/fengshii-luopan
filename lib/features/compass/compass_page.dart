import 'dart:async';
import 'package:flutter/material.dart';

import '../../data/storage/settings_storage.dart';
import '../../fengshui/bazhai.dart';
import '../../fengshui/compass_math.dart';
import '../../fengshui/compass_reading_builder.dart';
import 'compass_sensor_service.dart';
import 'compass_status.dart';
import 'luopan_dial.dart';

enum CompassInputMode { sensor, manual }

class CompassPage extends StatefulWidget {
  const CompassPage({super.key});

  @override
  State<CompassPage> createState() => _CompassPageState();
}

class _CompassPageState extends State<CompassPage> {
  final _settings = SettingsStorage();
  final _sensor = const CompassSensorService();

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

  StreamSubscription<double?>? _headingSub;
  bool _settingsLoaded = false;
  bool _showDebug = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _startSensor();
  }

  @override
  void dispose() {
    _headingSub?.cancel();
    super.dispose();
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
    final source =
        _mode == CompassInputMode.manual ? _manualDegree : _smoothedHeading;
    return applyCalibration(source, _calibrationOffset);
  }

  void _calibrateToZero() {
    final source =
        _mode == CompassInputMode.manual ? _manualDegree : _rawHeading;
    setState(() => _calibrationOffset = source);
    _settings.saveCalibrationOffset(source);
  }

  void _resetCalibration() {
    setState(() => _calibrationOffset = 0);
    _settings.saveCalibrationOffset(0);
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
          child: const Text('测向工具'),
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
            // ---- Bottom controls ----
            _buildBottomPanel(reading, hasHeading),
          ],
        ),
      ),
    );
  }

  // ======== TOP PANEL ========

  Widget _buildTopPanel(CompassReading reading, double discRotationDeg) {
    final guaColor =
        reading.isAuspicious ? const Color(0xFF2E7D32) : const Color(0xFFC43C32);
    final magColor = _magneticStatus == MagneticStatus.normal
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC43C32);

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
          // Row 1: degree + facing/sitting
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${reading.facingDegree.toStringAsFixed(0)}°',
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2A2118)),
              ),
              const SizedBox(width: 16),
              _Tag(
                  '向${reading.facingMountain}',
                  const Color(0xFFF5E7C3),
                  const Color(0xFF2A2118)),
              const SizedBox(width: 6),
              _Tag(
                  '坐${reading.sittingMountain}',
                  const Color(0xFFF5E7C3),
                  const Color(0xFF2A2118)),
            ],
          ),
          const SizedBox(height: 4),
          // Row 1.5: compass direction description
          Text(
            '${compassDirectionName(reading.facingDegree)} ${reading.facingDegree.toStringAsFixed(0)}°',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF5A4724)),
          ),
          const SizedBox(height: 2),
          // Row 2: sitting-facing text
          Text(
            reading.sittingFacingText,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5A4724)),
          ),
          const SizedBox(height: 6),
          // Row 3: gua, bazhai, magnetic
          Wrap(
            spacing: 14,
            runSpacing: 2,
            alignment: WrapAlignment.center,
            children: [
              _InfoChip('宫位', '${reading.facingGua}宫'),
              _InfoChip('三元龙', reading.sanyuanType),
              _InfoChip('八宅星', reading.bazhaiStar, valueColor: guaColor),
              _InfoChip('吉凶', reading.isAuspicious ? '吉' : '凶',
                  valueColor: guaColor),
              _InfoChip('磁场', _magneticStatus.label, valueColor: magColor),
            ],
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

  Widget _buildHouseGuaSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('宅卦：',
            style:
                TextStyle(fontSize: 13, color: Color(0xFF7A6040))),
        DropdownButton<String>(
          value: _houseGua,
          underline: const SizedBox(),
          style: const TextStyle(fontSize: 13, color: Color(0xFF2A2118)),
          items: BazhaiCalculator.guas
              .map((g) => DropdownMenuItem(
                    value: g,
                    child: Text('$g宅'),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) _onHouseGuaChanged(v);
          },
        ),
      ],
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

class _Tag extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const _Tag(this.text, this.bg, this.fg);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoChip(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: [
        TextSpan(
            text: '$label ',
            style:
                const TextStyle(fontSize: 12, color: Color(0xFF9A8A6A))),
        TextSpan(
            text: value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF2A2118))),
      ]),
    );
  }
}
