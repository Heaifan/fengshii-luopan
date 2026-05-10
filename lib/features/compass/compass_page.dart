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

class CompassPage extends StatefulWidget {
  const CompassPage({super.key});

  @override
  State<CompassPage> createState() => _CompassPageState();
}

class _CompassPageState extends State<CompassPage> {
  final _settings = SettingsStorage();
  final _sensor = const CompassSensorService();
  final _tilt = TiltService();

  double _rawHeading = 0;
  double _calibrationOffset = 0;
  double _smoothedHeading = 0;
  bool _smoothedInitialized = false;

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
          _magneticStatus =
              HeadingStabilityAnalyzer.analyze(_recentHeadings.toList());
        });
      },
      onError: (_) {},
    );
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

  double get _displayHeading =>
      applyCalibration(_smoothedHeading, _calibrationOffset);

  void _calibrateToZero() {
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

  // ======== HOUSE GUA PICKER ========

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

  // ======== BUILD ========

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
            _buildTopPanel(reading, discRotationDeg),
            _buildShoulderBubbles(),
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
            _buildBottomPanel(reading),
          ],
        ),
      ),
    );
  }

  // ======== TOP PANEL ========

  Widget _buildTopPanel(CompassReading reading, double discRotationDeg) {
    // Bazhai star with element
    final starMeta = bazhaiStarMetaMap[reading.bazhaiStar];
    final starElement = starMeta?.element ?? '';
    final bazhaiText = '${reading.bazhaiStar}$starElement（${reading.bazhaiRank}）';

    // Combined status
    final hStatus = tiltStatus(_tiltH);
    final vStatus = tiltStatus(_tiltV);
    final tiltBothGood = hStatus == TiltStatus.good && vStatus == TiltStatus.good;
    final tiltAnyBad = hStatus == TiltStatus.bad || vStatus == TiltStatus.bad;
    String statusText;
    Color statusColor;
    if (_magneticStatus == MagneticStatus.normal) {
      if (tiltBothGood) {
        statusText = '磁场正常｜校准良好';
        statusColor = const Color(0xFF4CAF50);
      } else if (tiltAnyBad) {
        statusText = '磁场正常｜姿态偏差大';
        statusColor = const Color(0xFFEF5350);
      } else {
        statusText = '磁场正常｜轻微偏移';
        statusColor = const Color(0xFFFFC107);
      }
    } else {
      statusText = '${_magneticStatus.label}｜姿态偏差大';
      statusColor = const Color(0xFFEF5350);
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8EED8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFB99A61), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: compass reading
          Text(
            '${compassDirectionName(reading.facingDegree)}${reading.facingDegree.toStringAsFixed(0)}°',
            style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2A2118)),
          ),
          // Row 2: sitting-facing
          Text(
            reading.sittingFacingText,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5A4724)),
          ),
          const SizedBox(height: 4),
          // Row 3: table header (centered, fixed width)
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SizedBox(width: 52, child: _TableHeader('宫位')),
                SizedBox(width: 74, child: _TableHeader('向山')),
                SizedBox(width: 130, child: _TableHeader('八宅')),
              ],
            ),
          ),
          const SizedBox(height: 2),
          // Row 4: table values (centered, fixed width)
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                    width: 52,
                    child: _TableCell('${reading.facingGua}宫')),
                SizedBox(
                    width: 74,
                    child: _TableCell(reading.fullSanyuanText,
                        color: const Color(0xFF2A2118))),
                SizedBox(
                    width: 130,
                    child: _TableCell(bazhaiText,
                        color: reading.isAuspicious
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFC43C32))),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Row 5: status
          Text(statusText,
              style: TextStyle(fontSize: 12, color: statusColor)),
          // Debug
          if (_showDebug) ...[
            const Divider(height: 8),
            Text(
              'raw:${_rawHeading.toStringAsFixed(1)}° '
              'disp:${_displayHeading.toStringAsFixed(1)}° '
              'discRot:${discRotationDeg.toStringAsFixed(1)}° '
              'gua:$_houseGua '
              'offset:${_calibrationOffset.toStringAsFixed(0)}°',
              style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF888888),
                  fontFamily: 'monospace'),
            ),
          ],
        ],
      ),
    );
  }

  // ======== SHOULDER BUBBLES ========

  Widget _buildShoulderBubbles() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: horizontal level indicator
          MiniBubbleIndicator(label: '水平', angle: _tiltH),
          // Right: vertical tilt indicator
          VerticalMiniBubble(label: '俯仰', angle: _tiltV),
        ],
      ),
    );
  }

  // ======== BOTTOM PANEL ========

  Widget _buildBottomPanel(CompassReading reading) {
    final group = getHouseGroup(_houseGua);
    return Container(
      color: const Color(0xFFe8e0d0),
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('宅卦选择',
              style: TextStyle(fontSize: 11, color: Color(0xFF9A8A6A))),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _showHouseGuaPicker,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0E8D5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFB99A61)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$_houseGua宅',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2A2118))),
                      const SizedBox(width: 4),
                      Text(group,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF7A6040))),
                      const Icon(Icons.arrow_drop_down,
                          color: Color(0xFF7A6040), size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Calibration buttons
          Wrap(
            spacing: 6,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: _calibrateToZero,
                icon: const Icon(Icons.gps_fixed, size: 14),
                label:
                    const Text('设当前为0°', style: TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF5A4724),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
              ),
              OutlinedButton(
                onPressed: _resetCalibration,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF5A4724),
                  side: const BorderSide(color: Color(0xFFB99A61)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                child:
                    const Text('重置校准', style: TextStyle(fontSize: 12)),
              ),
              OutlinedButton(
                onPressed: _showCalibrationGuide,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF5A4724),
                  side: const BorderSide(color: Color(0xFFB99A61)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                child:
                    const Text('校准说明', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '校准偏移：${_calibrationOffset.toStringAsFixed(0)}°',
            style:
                const TextStyle(fontSize: 11, color: Color(0xFF9A8A6A)),
          ),
        ],
      ),
    );
  }
}

// ======== Tiny table widgets ========

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11, color: Color(0xFF9A8A6A)));
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final Color? color;
  const _TableCell(this.text, {this.color});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color ?? const Color(0xFF2A2118)));
  }
}
