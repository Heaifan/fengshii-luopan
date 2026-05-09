import 'dart:async';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/storage/settings_storage.dart';
import '../../fengshui/bazhai.dart';
import '../../fengshui/compass_math.dart';
import '../../fengshui/compass_reading_builder.dart';
import 'compass_sensor_service.dart';
import 'compass_status.dart';

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
          'App 内的"以当前方向为0°校准"只是角度偏移校正，不能消除真实磁场干扰。',
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final reading = CompassReadingBuilder.build(
      degree: _displayHeading,
      houseGua: _houseGua,
    );

    final hasHeading =
        _mode == CompassInputMode.manual || _hasSensorData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('测向工具'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHeadingSummary(reading),
              const SizedBox(height: 20),
              _buildStatusSection(reading),
              const SizedBox(height: 16),
              _buildModeSwitch(),
              const SizedBox(height: 12),
              _buildHouseGuaSelector(),
              const SizedBox(height: 12),
              _buildCalibrationButtons(),
              const SizedBox(height: 16),
              if (_mode == CompassInputMode.manual) _buildManualSlider(),
              if (!hasHeading) _buildNoDataWarning(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeadingSummary(CompassReading reading) {
    return Column(
      children: [
        Text(
          '${reading.facingDegree.toStringAsFixed(0)}°',
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _DirectionBadge(
                label: '向', mountain: reading.facingMountain,
                degree: reading.facingDegree),
            const SizedBox(width: 24),
            _DirectionBadge(
                label: '坐', mountain: reading.sittingMountain,
                degree: reading.sittingDegree),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          reading.sittingFacingText,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildStatusSection(CompassReading reading) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _StatusRow(label: '宫位', value: '${reading.facingGua}宫'),
          _StatusRow(label: '三元龙', value: reading.sanyuanType),
          _StatusRow(
            label: '八宅星',
            value: reading.bazhaiStar,
            valueColor: reading.isAuspicious
                ? AppTheme.auspiciousColor
                : AppTheme.inauspiciousColor,
          ),
          _StatusRow(
            label: '吉凶',
            value: reading.isAuspicious ? '吉' : '凶',
            valueColor: reading.isAuspicious
                ? AppTheme.auspiciousColor
                : AppTheme.inauspiciousColor,
          ),
          const Divider(height: 20),
          _StatusRow(
            label: '磁场',
            value: _magneticStatus.label,
            valueColor: _magneticStatus == MagneticStatus.normal
                ? AppTheme.auspiciousColor
                : AppTheme.inauspiciousColor,
          ),
          _StatusRow(label: '水平', value: '未检测'),
          if (_magneticStatus != MagneticStatus.normal &&
              _magneticStatus != MagneticStatus.unavailable)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _magneticStatus.suggestion,
                style: TextStyle(
                    color: AppTheme.inauspiciousColor, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModeSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ModeButton(
          label: '实时罗盘',
          icon: Icons.explore,
          isSelected: _mode == CompassInputMode.sensor,
          onTap: () => setState(() => _mode = CompassInputMode.sensor),
        ),
        const SizedBox(width: 12),
        _ModeButton(
          label: '手动测试',
          icon: Icons.tune,
          isSelected: _mode == CompassInputMode.manual,
          onTap: () => setState(() => _mode = CompassInputMode.manual),
        ),
      ],
    );
  }

  Widget _buildHouseGuaSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('宅卦：', style: TextStyle(fontSize: 16)),
        DropdownButton<String>(
          value: _houseGua,
          underline: const SizedBox(),
          items: BazhaiCalculator.guas
              .map((g) => DropdownMenuItem(
                    value: g,
                    child: Text('$g宅', style: const TextStyle(fontSize: 16)),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: _calibrateToZero,
          icon: const Icon(Icons.gps_fixed, size: 18),
          label: const Text('当前方向为0°'),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: _resetCalibration,
          child: const Text('重置校准'),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: _showCalibrationGuide,
          child: const Text('校准说明'),
        ),
      ],
    );
  }

  Widget _buildManualSlider() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Text('手动角度：${_manualDegree.toStringAsFixed(0)}°',
            style: const TextStyle(fontSize: 18)),
        Slider(
          min: 0,
          max: 359,
          divisions: 359,
          value: _manualDegree,
          onChanged: (v) => setState(() => _manualDegree = v),
        ),
      ],
    );
  }

  Widget _buildNoDataWarning() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.inauspiciousColor.withAlpha(40),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        '当前设备暂未返回指南针数据，请检查手机是否支持磁力计，或切换到手动测试模式。',
        style: TextStyle(fontSize: 13),
      ),
    );
  }
}

class _DirectionBadge extends StatelessWidget {
  final String label;
  final String mountain;
  final double degree;

  const _DirectionBadge({
    required this.label,
    required this.mountain,
    required this.degree,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.highlightColor.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            '$label：$mountain',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            '${degree.toStringAsFixed(0)}°',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatusRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
              width: 70,
              child: Text(label, style: const TextStyle(fontSize: 15))),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (_) => onTap(),
    );
  }
}
