import 'dart:async';
import 'package:flutter/material.dart';

import '../../data/storage/settings_storage.dart';
import '../../fengshui/bazhai.dart';
import '../../fengshui/compass_math.dart';
import '../../fengshui/compass_reading_builder.dart';
import 'compass_sensor_service.dart';
import 'compass_status.dart';
import 'luopan_painter.dart';

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
        backgroundColor: Color(0xFFd8d8d8),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final reading = CompassReadingBuilder.build(
      degree: _displayHeading,
      houseGua: _houseGua,
    );

    final hasHeading = _mode == CompassInputMode.manual || _hasSensorData;

    return Scaffold(
      backgroundColor: const Color(0xFFd8d8d8),
      appBar: AppBar(
        title: const Text('测向工具'),
        centerTitle: true,
        backgroundColor: const Color(0xFFc8b898),
        foregroundColor: const Color(0xFF333333),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 罗盘盘面
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: LuopanDial(
                    heading: _displayHeading,
                    houseGua: _houseGua,
                  ),
                ),
              ),
            ),
            // 信息条 + 控制区
            _buildBottomPanel(reading, hasHeading),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel(CompassReading reading, bool hasHeading) {
    return Container(
      color: const Color(0xFFe8e0d0),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSummaryRow(reading),
            const SizedBox(height: 6),
            _buildModeSwitch(),
            const SizedBox(height: 6),
            _buildHouseGuaSelector(),
            const SizedBox(height: 6),
            _buildStatusRow(reading),
            const SizedBox(height: 6),
            _buildCalibrationButtons(),
            if (_mode == CompassInputMode.manual) _buildManualSlider(),
            if (!hasHeading) _buildNoDataWarning(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(CompassReading reading) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${reading.facingDegree.toStringAsFixed(0)}°',
          style:
              const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFf5e7c3),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '向${reading.facingMountain}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFf5e7c3),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '坐${reading.sittingMountain}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          reading.sittingFacingText,
          style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF555555)),
        ),
      ],
    );
  }

  Widget _buildStatusRow(CompassReading reading) {
    final guaColor =
        reading.isAuspicious ? const Color(0xFF4CAF50) : const Color(0xFFEF5350);
    final magColor = _magneticStatus == MagneticStatus.normal
        ? const Color(0xFF4CAF50)
        : const Color(0xFFEF5350);

    return Wrap(
      spacing: 16,
      runSpacing: 2,
      alignment: WrapAlignment.center,
      children: [
        _InlineLabel('宫位', '${reading.facingGua}宫'),
        _InlineLabel('三元龙', reading.sanyuanType),
        _InlineLabel('八宅星', reading.bazhaiStar, valueColor: guaColor),
        _InlineLabel('吉凶', reading.isAuspicious ? '吉' : '凶',
            valueColor: guaColor),
        _InlineLabel('磁场', _magneticStatus.label, valueColor: magColor),
      ],
    );
  }

  Widget _buildModeSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChoiceChip(
          selected: _mode == CompassInputMode.sensor,
          label: const Text('实时罗盘'),
          onSelected: (_) => setState(() => _mode = CompassInputMode.sensor),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          selected: _mode == CompassInputMode.manual,
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
        const Text('宅卦：', style: TextStyle(fontSize: 14, color: Color(0xFF555555))),
        DropdownButton<String>(
          value: _houseGua,
          underline: const SizedBox(),
          items: BazhaiCalculator.guas
              .map((g) => DropdownMenuItem(
                    value: g,
                    child: Text('$g宅', style: const TextStyle(fontSize: 14)),
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
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: _calibrateToZero,
          icon: const Icon(Icons.gps_fixed, size: 16),
          label: const Text('设当前为0°', style: TextStyle(fontSize: 13)),
        ),
        OutlinedButton(
          onPressed: _resetCalibration,
          child: const Text('重置校准', style: TextStyle(fontSize: 13)),
        ),
        OutlinedButton(
          onPressed: _showCalibrationGuide,
          child: const Text('校准说明', style: TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildManualSlider() {
    return Column(
      children: [
        Text('手动角度：${_manualDegree.toStringAsFixed(0)}°',
            style:
                const TextStyle(fontSize: 14, color: Color(0xFF555555))),
        SizedBox(
          height: 30,
          child: Slider(
            min: 0,
            max: 359,
            divisions: 359,
            value: _manualDegree,
            onChanged: (v) => setState(() => _manualDegree = v),
          ),
        ),
      ],
    );
  }

  Widget _buildNoDataWarning() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0x33EF5350),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        '当前设备暂未返回指南针数据，请检查手机是否支持磁力计，或切换到手动测试模式。',
        style: TextStyle(fontSize: 12, color: Color(0xFF333333)),
      ),
    );
  }
}

class _InlineLabel extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InlineLabel(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? const Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }
}
