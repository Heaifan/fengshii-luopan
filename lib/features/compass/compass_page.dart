import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/compass_record.dart';
import '../../data/models/measure_type.dart';
import '../../data/models/measurement_project.dart';
import '../../data/storage/settings_storage.dart';
import '../../fengshui/bazhai.dart';
import '../../fengshui/compass_math.dart';
import '../../fengshui/compass_reading_builder.dart';
import 'compass_sensor_service.dart';
import 'compass_status.dart';
import 'luopan_dial.dart';
import 'tilt_service.dart';
import 'bubble_indicator.dart';
import 'l_type_level_indicator.dart';
import '../../app/theme.dart';
import '../../fengshui/bazhai_you_nian_table.dart';
import '../records/compass_records_page.dart';
import '../projects/measurement_project_detail_page.dart';
import '../projects/measurement_projects_page.dart';
import '../projects/new_measurement_project_page.dart';

class CompassPage extends StatefulWidget {
  final MeasurementProject? activeProject;

  const CompassPage({super.key, this.activeProject});

  bool get isProjectMode => activeProject != null;

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

  StreamSubscription<CompassSensorReading>? _headingSub;
  StreamSubscription<TiltData>? _tiltSub;
  bool _settingsLoaded = false;
  bool _showDebug = false;

  // ---- Lock state ----
  bool _isLocked = false;
  CompassReading? _lockedReading;
  double? _lockedHeading;
  DateTime? _lockedAt;

  double? _lockedTiltH;
  double? _lockedTiltV;
  String? _lockedStatusText;
  Color? _lockedStatusColor;

  int _savedPointCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _startSensor();
    _startTilt();
    _loadProjectPointCount();
  }

  Future<void> _loadProjectPointCount() async {
    final project = widget.activeProject;
    if (project == null) return;
    final points = await _settings.loadRecordsByProject(project.id);
    if (!mounted) return;
    setState(() => _savedPointCount = points.length);
  }

  @override
  void dispose() {
    _headingSub?.cancel();
    _tiltSub?.cancel();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final gua = await _settings.loadHouseGua();

    // V0.4.1.3：废弃旧的"设当前为0°"方向偏移，避免真实方位被错误扣减。
    await _settings.saveCalibrationOffset(0);

    setState(() {
      _houseGua = gua;
      _calibrationOffset = 0;
      _settingsLoaded = true;
    });
  }

  void _startSensor() {
    _headingSub = _sensor.readingStream.listen(
      (event) {
        final heading = event.heading;
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

  double get _displayHeading => normalizeDegree(_smoothedHeading);

  // ---- Lock / unlock ----

  void _lockCompass(CompassReading reading, String statusText,
      Color statusColor) {
    setState(() {
      _isLocked = true;
      _lockedReading = reading;
      _lockedHeading = _displayHeading;
      _lockedAt = DateTime.now();
      _lockedTiltH = _tiltH;
      _lockedTiltV = _tiltV;
      _lockedStatusText = statusText;
      _lockedStatusColor = statusColor;
    });
  }

  void _unlockCompass() {
    setState(() {
      _isLocked = false;
      _lockedReading = null;
      _lockedHeading = null;
      _lockedAt = null;
      _lockedTiltH = null;
      _lockedTiltV = null;
      _lockedStatusText = null;
      _lockedStatusColor = null;
    });
  }

  void _refreshHeading() {
    setState(() {
      _smoothedInitialized = false;
      _recentHeadings.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已重新读取当前罗盘方向')),
    );
  }

  void _resetCalibration() {
    setState(() => _calibrationOffset = 0);
    _settings.saveCalibrationOffset(0);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已重置，恢复真实罗盘角度')),
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
          '5. 若系统指南针与本 App 差异较大，请以系统指南针为准重新校验环境。\n\n'
          '注意：\n'
          '本 App 显示真实罗盘方向，不再使用"设当前为0°"修正真实方位。',
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

  // ======== SAVE SHEET ========

  void _showSaveSheet(CompassReading reading, String statusText) {
    final nameCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final starMeta = bazhaiStarMetaMap[reading.bazhaiStar];
    final starElement = starMeta?.element ?? '';
    final bazhaiText =
        '${reading.bazhaiStar}$starElement（${reading.bazhaiRank}）';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.72,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF7EEDB),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Form(
                key: formKey,
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
                    const Text('保存罗盘',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2A2118))),
                    const SizedBox(height: 8),
                    const Divider(
                        height: 1, color: Color(0xFFB99A61)),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        children: [
                          // ---- Name ----
                          const Text('记录名称 *',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textLabel)),
                          const SizedBox(height: 2),
                          TextFormField(
                            controller: nameCtrl,
                            autofocus: true,
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                            decoration: const InputDecoration(
                              hintText: '例如：A小区 3栋 1201',
                              hintStyle: TextStyle(
                                  color: AppTheme.textHint,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500),
                              filled: true,
                              fillColor: Color(0xFFFFF8ED),
                              border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color(0xFFB99A61))),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? '请输入记录名称'
                                    : null,
                          ),
                          const SizedBox(height: 8),
                          // ---- Location ----
                          const Text('地点（可选）',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textLabel)),
                          const SizedBox(height: 2),
                          TextField(
                            controller: locationCtrl,
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                            decoration: const InputDecoration(
                              hintText: '例如：XX小区、办公室、店铺',
                              hintStyle: TextStyle(
                                  color: AppTheme.textHint,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500),
                              filled: true,
                              fillColor: Color(0xFFFFF8ED),
                              border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color(0xFFB99A61))),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // ---- Note ----
                          const Text('备注（可选）',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textLabel)),
                          const SizedBox(height: 2),
                          TextField(
                            controller: noteCtrl,
                            maxLines: 2,
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                            decoration: const InputDecoration(
                              hintText:
                                  '例如：站在客厅中心，手机朝向阳台测量',
                              hintStyle: TextStyle(
                                  color: AppTheme.textHint,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500),
                              filled: true,
                              fillColor: Color(0xFFFFF8ED),
                              border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color(0xFFB99A61))),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // ---- Measurement summary ----
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8ED),
                              borderRadius:
                                  BorderRadius.circular(8),
                              border: Border.all(
                                  color:
                                      const Color(0xFFB99A61)),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text('测量信息',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight:
                                            FontWeight.bold,
                                        color:
                                            AppTheme.textTitle)),
                                const SizedBox(height: 4),
                                _summaryRow(
                                    '方向',
                                    '${compassDirectionName(reading.facingDegree)}${reading.facingDegree.toStringAsFixed(0)}°'),
                                _summaryRow('坐向',
                                    reading.sittingFacingText),
                                _summaryRow(
                                    '宫位／向山',
                                    '${reading.facingGua}宫｜${reading.fullSanyuanText}'),
                                _summaryRow(
                                    '八宅', bazhaiText),
                                _summaryRow('状态',
                                    statusText),
                                _summaryRow(
                                    '时间',
                                    DateFormat(
                                            'yyyy-MM-dd HH:mm')
                                        .format(DateTime.now())),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // ---- Buttons ----
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx),
                                  style:
                                      OutlinedButton.styleFrom(
                                    foregroundColor:
                                        const Color(
                                            0xFF5A4724),
                                    side: const BorderSide(
                                        color: Color(
                                            0xFFB99A61)),
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                            vertical: 12),
                                  ),
                                  child: const Text('取消'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: FilledButton(
                                  onPressed: () async {
                                    if (!formKey.currentState!
                                        .validate()) return;

                                    final record =
                                        CompassRecord.create(
                                      name:
                                          nameCtrl.text.trim(),
                                      location: locationCtrl
                                              .text
                                              .trim()
                                              .isEmpty
                                          ? null
                                          : locationCtrl.text
                                              .trim(),
                                      note: noteCtrl
                                              .text
                                              .trim()
                                              .isEmpty
                                          ? null
                                          : noteCtrl.text
                                              .trim(),
                                      heading:
                                          reading.facingDegree,
                                      directionText:
                                          '${compassDirectionName(reading.facingDegree)}${reading.facingDegree.toStringAsFixed(0)}°',
                                      sittingFacingText: reading
                                          .sittingFacingText,
                                      sittingMountain:
                                          reading.sittingMountain,
                                      facingMountain:
                                          reading.facingMountain,
                                      palace:
                                          '${reading.facingGua}宫',
                                      mountainText:
                                          reading.fullSanyuanText,
                                      bazhaiText: bazhaiText,
                                      statusText:
                                          statusText,
                                      horizontalAngle:
                                          _lockedTiltH ?? 0,
                                      verticalAngle:
                                          _lockedTiltV ?? 0,
                                      houseGua: _houseGua,
                                    );

                                    try {
                                      await _settings
                                          .addRecord(record);
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(
                                              context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                              '已保存罗盘记录'),
                                          action: SnackBarAction(
                                            label: '查看',
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const CompassRecordsPage(),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    } catch (_) {
                                      ScaffoldMessenger.of(
                                              context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                '保存失败，请重试')),
                                      );
                                    }
                                  },
                                  style:
                                      FilledButton.styleFrom(
                                    backgroundColor:
                                        const Color(
                                            0xFF5A4724),
                                    foregroundColor:
                                        Colors.white,
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                            vertical: 12),
                                  ),
                                  child: const Text('保存',
                                      style: TextStyle(
                                          fontSize: 15)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ======== SAVE POINT SHEET (project mode) ========

  void _showSavePointSheet(CompassReading reading, String statusText) {
    final measureNameCtrl = TextEditingController();
    final spaceNameCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String measureType = MeasureTypes.other;

    final starMeta = bazhaiStarMetaMap[reading.bazhaiStar];
    final starElement = starMeta?.element ?? '';
    final bazhaiText =
        '${reading.bazhaiStar}$starElement（${reading.bazhaiRank}）';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: FractionallySizedBox(
                heightFactor: 0.76,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7EEDB),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Form(
                    key: formKey,
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
                        const Text('保存测点',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2A2118))),
                        Text(widget.activeProject!.name,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF9A8A6A))),
                        const SizedBox(height: 8),
                        const Divider(
                            height: 1, color: Color(0xFFB99A61)),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            children: [
                              // ---- Measure type chips ----
                              const Text('测点类型',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textLabel)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children:
                                    MeasureTypes.all.map((t) {
                                  final selected = t == measureType;
                                  return ChoiceChip(
                                    label: Text(
                                        MeasureTypes.label(t),
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: selected
                                                ? Colors.white
                                                : AppTheme
                                                    .textPrimary)),
                                    selected: selected,
                                    selectedColor:
                                        const Color(0xFF5A4724),
                                    backgroundColor:
                                        const Color(0xFFF0E8D5),
                                    side: BorderSide(
                                        color: selected
                                            ? const Color(
                                                0xFF5A4724)
                                            : AppTheme
                                                .cardBorder),
                                    onSelected: (_) =>
                                        setSheetState(() =>
                                            measureType = t),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 10),

                              // ---- Measure name ----
                              const Text('测点名称（可选）',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textLabel)),
                              const SizedBox(height: 2),
                              TextField(
                                controller: measureNameCtrl,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600),
                                decoration: const InputDecoration(
                                  hintText:
                                      '例如：入户门、客厅阳台、主卧床头',
                                  hintStyle: TextStyle(
                                      color: AppTheme.textHint,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500),
                                  filled: true,
                                  fillColor: Color(0xFFFFF8ED),
                                  border: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color:
                                              Color(0xFFB99A61))),
                                  contentPadding:
                                      EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // ---- Space name ----
                              const Text('空间 / 位置（可选）',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textLabel)),
                              const SizedBox(height: 2),
                              TextField(
                                controller: spaceNameCtrl,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600),
                                decoration: const InputDecoration(
                                  hintText:
                                      '例如：客厅、主卧、厨房',
                                  hintStyle: TextStyle(
                                      color: AppTheme.textHint,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500),
                                  filled: true,
                                  fillColor: Color(0xFFFFF8ED),
                                  border: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color:
                                              Color(0xFFB99A61))),
                                  contentPadding:
                                      EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // ---- Note ----
                              const Text('备注（可选）',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textLabel)),
                              const SizedBox(height: 2),
                              TextField(
                                controller: noteCtrl,
                                maxLines: 2,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600),
                                decoration: const InputDecoration(
                                  hintText:
                                      '例如：站在客厅中心，手机朝向阳台测量',
                                  hintStyle: TextStyle(
                                      color: AppTheme.textHint,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500),
                                  filled: true,
                                  fillColor: Color(0xFFFFF8ED),
                                  border: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color:
                                              Color(0xFFB99A61))),
                                  contentPadding:
                                      EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // ---- Summary ----
                              Container(
                                padding:
                                    const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFFFF8ED),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                  border: Border.all(
                                      color: const Color(
                                          0xFFB99A61)),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text('测量信息',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight:
                                                FontWeight.bold,
                                            color: AppTheme
                                                .textTitle)),
                                    const SizedBox(height: 4),
                                    _summaryRow(
                                        '方向',
                                        '${compassDirectionName(reading.facingDegree)}${reading.facingDegree.toStringAsFixed(0)}°'),
                                    _summaryRow('坐向',
                                        reading.sittingFacingText),
                                    _summaryRow(
                                        '八宅', bazhaiText),
                                    _summaryRow('状态',
                                        statusText),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // ---- Buttons ----
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx),
                                      style: OutlinedButton
                                          .styleFrom(
                                        foregroundColor:
                                            const Color(
                                                0xFF5A4724),
                                        side: const BorderSide(
                                            color: Color(
                                                0xFFB99A61)),
                                        padding: const EdgeInsets
                                            .symmetric(
                                            vertical: 12),
                                      ),
                                      child: const Text(
                                          '取消'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: FilledButton(
                                      onPressed: () async {
                                        final record =
                                            CompassRecord
                                                .create(
                                          name: measureNameCtrl
                                                  .text
                                                  .trim()
                                                  .isEmpty
                                              ? '${MeasureTypes.label(measureType)}测点'
                                              : measureNameCtrl
                                                  .text
                                                  .trim(),
                                          projectId: widget
                                              .activeProject!
                                              .id,
                                          measureType:
                                              measureType,
                                          measureName:
                                              measureNameCtrl
                                                      .text
                                                      .trim()
                                                      .isEmpty
                                                  ? null
                                                  : measureNameCtrl
                                                      .text
                                                      .trim(),
                                          spaceName: spaceNameCtrl
                                                  .text
                                                  .trim()
                                                  .isEmpty
                                              ? null
                                              : spaceNameCtrl
                                                  .text
                                                  .trim(),
                                          note: noteCtrl
                                                  .text
                                                  .trim()
                                                  .isEmpty
                                              ? null
                                              : noteCtrl
                                                  .text
                                                  .trim(),
                                          heading: reading
                                              .facingDegree,
                                          directionText:
                                              '${compassDirectionName(reading.facingDegree)}${reading.facingDegree.toStringAsFixed(0)}°',
                                          sittingFacingText: reading
                                              .sittingFacingText,
                                          sittingMountain: reading
                                              .sittingMountain,
                                          facingMountain: reading
                                              .facingMountain,
                                          palace:
                                              '${reading.facingGua}宫',
                                          mountainText: reading
                                              .fullSanyuanText,
                                          bazhaiText:
                                              bazhaiText,
                                          statusText:
                                              statusText,
                                          horizontalAngle:
                                              _lockedTiltH ?? 0,
                                          verticalAngle:
                                              _lockedTiltV ?? 0,
                                          houseGua:
                                              _houseGua,
                                        );

                                        try {
                                          await _settings
                                              .addRecord(
                                                  record);
                                          setState(() =>
                                              _savedPointCount++);
                                          _unlockCompass();
                                          Navigator.pop(ctx);
                                          ScaffoldMessenger
                                                  .of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  '已保存测点：${MeasureTypes.label(measureType)} · ${record.name}'),
                                            ),
                                          );
                                        } catch (_) {
                                          ScaffoldMessenger
                                                  .of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    '保存失败，请重试')),
                                          );
                                        }
                                      },
                                      style: FilledButton
                                          .styleFrom(
                                        backgroundColor:
                                            const Color(
                                                0xFF5A4724),
                                        foregroundColor:
                                            Colors.white,
                                        padding: const EdgeInsets
                                            .symmetric(
                                            vertical: 12),
                                      ),
                                      child: const Text(
                                          '保存并继续',
                                          style: TextStyle(
                                              fontSize: 15)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---- Finish measurement ----

  void _finishMeasurement() {
    final hasPoints = _savedPointCount > 0;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('完成测量'),
        content: Text(hasPoints
            ? '已完成本次测量，共保存 $_savedPointCount 个测点。可在项目详情中查看。'
            : '当前还没有保存测点，是否退出本次测量？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('继续测量'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => MeasurementProjectDetailPage(
                    project: widget.activeProject!,
                  ),
                ),
              );
            },
            child: const Text('完成',
                style: TextStyle(
                    color: Color(0xFF5A4724),
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textLabel)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
          ),
        ],
      ),
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
      degree: _isLocked ? (_lockedHeading ?? _displayHeading) : _displayHeading,
      houseGua: _houseGua,
    );

    final displayHeading =
        _isLocked ? (_lockedHeading ?? _displayHeading) : _displayHeading;
    final discRotationDeg = luopanVisualOffset - displayHeading;

    // Status for top panel & lock snapshot
    final status = _buildStatus();
    final displayReading =
        _isLocked ? (_lockedReading ?? reading) : reading;

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
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              switch (v) {
                case 'new_project':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const NewMeasurementProjectPage()),
                  );
                  break;
                case 'projects':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const MeasurementProjectsPage()),
                  );
                  break;
                case 'records':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const CompassRecordsPage()),
                  );
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: 'new_project',
                  child: ListTile(
                      leading: Icon(Icons.add_location_alt),
                      title: Text('新建项目'),
                      dense: true,
                      contentPadding: EdgeInsets.zero)),
              PopupMenuItem(
                  value: 'projects',
                  child: ListTile(
                      leading: Icon(Icons.folder_outlined),
                      title: Text('项目列表'),
                      dense: true,
                      contentPadding: EdgeInsets.zero)),
              PopupMenuItem(
                  value: 'records',
                  child: ListTile(
                      leading: Icon(Icons.history),
                      title: Text('历史记录'),
                      dense: true,
                      contentPadding: EdgeInsets.zero)),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (widget.isProjectMode) _buildProjectBar(),
            _buildTopPanel(
                displayReading, reading, discRotationDeg, status),
            // ---- Luopan disc with bubble overlay ----
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: LuopanDial(
                        heading: displayHeading,
                        houseGua: _houseGua,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 5,
                    bottom: 5,
                    child: _buildLevelIndicator(),
                  ),
                ],
              ),
            ),
            // ---- Bottom controls ----
            _buildBottomPanel(reading, status),
          ],
        ),
      ),
    );
  }

  // ---- Status helper ----

  ({String text, Color color}) _buildStatus() {
    final hStatus = tiltStatus(_tiltH);
    final vStatus = tiltStatus(_tiltV);
    final tiltBothGood =
        hStatus == TiltStatus.good && vStatus == TiltStatus.good;
    final tiltAnyBad =
        hStatus == TiltStatus.bad || vStatus == TiltStatus.bad;
    String text;
    Color color;
    if (_magneticStatus == MagneticStatus.normal) {
      if (tiltBothGood) {
        text = '磁场正常｜校准良好';
        color = const Color(0xFF4CAF50);
      } else if (tiltAnyBad) {
        text = '磁场正常｜姿态偏差大';
        color = const Color(0xFFEF5350);
      } else {
        text = '磁场正常｜轻微偏移';
        color = const Color(0xFFFFC107);
      }
    } else {
      text = '${_magneticStatus.label}｜姿态偏差大';
      color = const Color(0xFFEF5350);
    }
    return (text: text, color: color);
  }

  // ======== PROJECT BAR ========

  Widget _buildProjectBar() {
    final project = widget.activeProject!;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF5A4724),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, size: 16, color: Colors.white70),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              project.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '测点 ${_pointCount}',
            style: const TextStyle(
                color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  int get _pointCount => _savedPointCount;

  // ======== TOP PANEL ========

  Widget _buildTopPanel(CompassReading displayReading,
      CompassReading liveReading, double discRotationDeg,
      ({String text, Color color}) status) {
    final reading = _isLocked ? displayReading : liveReading;
    final starMeta = bazhaiStarMetaMap[reading.bazhaiStar];
    final starElement = starMeta?.element ?? '';
    final bazhaiText =
        '${reading.bazhaiStar}$starElement（${reading.bazhaiRank}）';

    final statusText = _isLocked
        ? '已锁定｜${_lockedStatusText ?? status.text}'
        : status.text;
    final statusColor = _isLocked
        ? (_lockedStatusColor ?? status.color)
        : status.color;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8EED8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: _isLocked
                ? const Color(0xFF5A4724)
                : const Color(0xFFB99A61),
            width: _isLocked ? 2 : 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: compass reading + lock badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${compassDirectionName(reading.facingDegree)}${reading.facingDegree.toStringAsFixed(0)}°',
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2A2118)),
              ),
              if (_isLocked) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5A4724),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('已锁定',
                      style:
                          TextStyle(fontSize: 10, color: Colors.white)),
                ),
              ],
            ],
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

  Widget _buildLevelIndicator() {
    final h = _isLocked ? (_lockedTiltH ?? _tiltH) : _tiltH;
    final v = _isLocked ? (_lockedTiltV ?? _tiltV) : _tiltV;
    return LTypeLevelIndicator(
      horizontalAngle: h,
      verticalAngle: v,
      size: 78,
    );
  }

  // ======== BOTTOM PANEL ========

  Widget _buildBottomPanel(
      CompassReading reading,
      ({String text, Color color}) status) {
    final group = getHouseGroup(_houseGua);
    final hStatus = tiltStatus(_tiltH);
    final vStatus = tiltStatus(_tiltV);
    final tiltAnyBad =
        hStatus == TiltStatus.bad || vStatus == TiltStatus.bad;

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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0E8D5),
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: const Color(0xFFB99A61)),
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
                              fontSize: 11,
                              color: Color(0xFF7A6040))),
                      const Icon(Icons.arrow_drop_down,
                          color: Color(0xFF7A6040), size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ---- Main action buttons ----
          if (_isLocked) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _unlockCompass,
                    icon: const Icon(Icons.lock_open, size: 16),
                    label: const Text('解锁',
                        style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5A4724),
                      side: const BorderSide(
                          color: Color(0xFFB99A61)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () => widget.isProjectMode
                        ? _showSavePointSheet(
                            _lockedReading ?? reading,
                            _lockedStatusText ?? status.text)
                        : _showSaveSheet(
                            _lockedReading ?? reading,
                            _lockedStatusText ?? status.text),
                    icon: const Icon(Icons.save_alt, size: 16),
                    label: Text(
                        widget.isProjectMode ? '保存测点' : '保存罗盘',
                        style: const TextStyle(fontSize: 13)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF5A4724),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () =>
                    _lockCompass(reading, status.text, status.color),
                icon: const Icon(Icons.lock, size: 16),
                label: const Text('锁定罗盘',
                    style: TextStyle(fontSize: 14)),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF5A4724),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ),
          ],
          // ---- Finish measurement (project mode only) ----
          if (widget.isProjectMode) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _finishMeasurement,
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text('完成测量',
                    style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF5A4724),
                  side: const BorderSide(color: Color(0xFF5A4724)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
          // Fixed-height tilt warning slot — never changes height
          SizedBox(
            height: 34,
            child: AnimatedOpacity(
              opacity: (!_isLocked && tiltAnyBad) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD86A32),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '当前姿态偏差大，建议调整后再锁定',
                    style: TextStyle(
                      color: Color(0xFFFFF4E8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // ---- Secondary buttons ----
          Wrap(
            spacing: 6,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: _refreshHeading,
                icon: const Icon(Icons.gps_fixed, size: 14),
                label: const Text('方向重读',
                    style: TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF5A4724),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                ),
              ),
              OutlinedButton(
                onPressed: _resetCalibration,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF5A4724),
                  side: const BorderSide(color: Color(0xFFB99A61)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                ),
                child: const Text('重新检测',
                    style: TextStyle(fontSize: 12)),
              ),
              OutlinedButton(
                onPressed: _showCalibrationGuide,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF5A4724),
                  side: const BorderSide(color: Color(0xFFB99A61)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                ),
                child: const Text('校准说明',
                    style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '方向：真实罗盘',
            style: TextStyle(fontSize: 11, color: Color(0xFF9A8A6A)),
          ),
          if (_showDebug)
            Text(
              'raw:${_rawHeading.toStringAsFixed(1)}° '
              'smooth:${_smoothedHeading.toStringAsFixed(1)}° '
              'display:${_displayHeading.toStringAsFixed(1)}°',
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF888888),
                fontFamily: 'monospace',
              ),
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
