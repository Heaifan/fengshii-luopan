import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../data/models/compass_record.dart';
import '../../data/models/measure_type.dart';
import '../../data/models/measurement_project.dart';
import '../../data/storage/settings_storage.dart';
import '../../theme/app_svg_icons.dart';
import '../../widgets/app_svg_icon.dart';
import '../../fengshui/direction_sector.dart';
import '../../fengshui/bazhai_base_resolver.dart';
import '../compass/compass_page.dart';
import '../records/compass_record_detail_page.dart';
import 'simple_project_plate_page.dart';
import 'tiandiren_vent_page.dart';
import '../floor_plan/floor_plan_page.dart';
import 'edit_project_page.dart';
import 'widgets/measure_point_form_sheet.dart';

class MeasurementProjectDetailPage extends StatefulWidget {
  final MeasurementProject project;

  const MeasurementProjectDetailPage({super.key, required this.project});

  @override
  State<MeasurementProjectDetailPage> createState() =>
      _MeasurementProjectDetailPageState();
}

class _MeasurementProjectDetailPageState
    extends State<MeasurementProjectDetailPage> {
  final _storage = SettingsStorage();
  List<CompassRecord> _points = [];
  MeasurementProject? _project;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    final points = await _storage.loadRecordsByProject(_project!.id);
    final projects = await _storage.loadProjects();
    final updated = projects.where((p) => p.id == _project!.id).firstOrNull;
    if (!mounted) return;
    setState(() {
      _points = points;
      _project = updated ?? _project!;
      _loading = false;
    });
  }

  String get _projectBaseGua {
    final base = BaZhaiBaseResolver.resolveBasePalace(
      project: _project!,
      records: _points,
    );
    return base ?? '乾';
  }

  Future<void> _onEditPoint(CompassRecord point) async {
    final result = await showMeasurePointFormSheet(
      context: context,
      initialRecord: point,
      houseGua: _projectBaseGua,
      allowDelete: true,
    );
    if (result == null || !mounted) return;

    if (result.delete) {
      await _storage.deleteRecord(point.id);
      await _loadPoints();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已删除测点')),
      );
      return;
    }

    final heading = result.heading ?? point.heading;
    final updatedRecord = CompassRecord(
      id: point.id,
      name: point.name,
      location: point.location,
      note: result.note,
      createdAt: point.createdAt,
      heading: heading,
      directionText: point.directionText,
      sittingFacingText: point.sittingFacingText,
      sittingMountain: point.sittingMountain,
      facingMountain: point.facingMountain,
      palace: point.palace,
      mountainText: point.mountainText,
      bazhaiText: point.bazhaiText,
      statusText: point.statusText,
      horizontalAngle: point.horizontalAngle,
      verticalAngle: point.verticalAngle,
      houseGua: point.houseGua,
      projectId: point.projectId,
      measureType: result.measureType,
      measureName: result.measureName,
      spaceName: result.spaceName,
    );
    await _storage.updateRecord(updatedRecord);

    final fresh = await _storage.loadRecordsByProject(_project!.id);
    final recalculated = BaZhaiBaseResolver.recalculateAllPoints(
      project: _project!,
      records: fresh,
    );
    final allRecords = await _storage.loadRecords();
    for (final rec in recalculated) {
      final idx = allRecords.indexWhere((r) => r.id == rec.id);
      if (idx >= 0) allRecords[idx] = rec;
    }
    await _storage.saveRecords(allRecords);
    await _loadPoints();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('测点已更新')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD8D6CF),
      appBar: AppBar(
        title: const Text('项目详情'),
        centerTitle: true,
        backgroundColor: const Color(0xFFc8b898),
        foregroundColor: const Color(0xFF333333),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // ---- Project info card ----
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(
                children: [
                  const AppSvgIcon(
                    AppSvgIcons.home,
                    size: 28,
                    color: Color(0xFF4A3A12),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _project!.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (_project!.location != null &&
                            _project!.location!.isNotEmpty)
                          Text(
                            _project!.location!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        Text(
                          BaZhaiBaseResolver.summaryText(
                            project: _project!,
                            records: _points,
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textLabel,
                          ),
                        ),
                        if (_project!.baZhaiMode == 'doorPosition')
                          Text(
                            BaZhaiBaseResolver.doorSourceText(
                              project: _project!,
                              records: _points,
                            ) ?? '伏位来源：无门位数据',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        Text(
                          '已测 ${_points.length} 个点',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final edited = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProjectPage(project: _project!),
                        ),
                      );
                      if (edited == true) {
                        await _loadPoints();
                        if (mounted) setState(() {});
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: AppTheme.textHint,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ---- Action buttons ----
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CompassPage(activeProject: _project!),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_location_alt, size: 18),
                    label: const Text('继续测量'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5A4724),
                      side: const BorderSide(color: Color(0xFF5A4724)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              SimpleProjectPlatePage(project: _project!),
                        ),
                      );
                    },
                    icon: const Icon(Icons.grid_view, size: 18),
                    label: const Text('简易正盘'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5A4724),
                      side: const BorderSide(color: Color(0xFF5A4724)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TiandirenVentPage(project: _project!),
                        ),
                      );
                    },
                    icon: const Icon(Icons.circle_outlined, size: 18),
                    label: const Text('天地人通气'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5A4724),
                      side: const BorderSide(color: Color(0xFF5A4724)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              FloorPlanPage(project: _project!),
                        ),
                      );
                    },
                    icon: const Icon(Icons.home_outlined, size: 18),
                    label: const Text('宅盘图'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5A4724),
                      side: const BorderSide(color: Color(0xFF5A4724)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ---- Points list ----
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_points.isEmpty)
              _buildEmptyPoints()
            else
              ..._points.asMap().entries.map((e) {
                return _buildPointCard(e.key, e.value);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPoints() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.explore_outlined,
            size: 40,
            color: AppTheme.textHint,
          ),
          const SizedBox(height: 10),
          const Text(
            '暂无测点',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '点击"继续测量"开始采集门、阳台、窗、床、灶等方位。',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPointCard(int index, CompassRecord point) {
    final typeLabel = MeasureTypes.label(point.measureType);
    final isAuspicious = !point.bazhaiText.contains('凶');
    final timeStr = DateFormat('MM-dd HH:mm').format(point.createdAt);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CompassRecordDetailPage(record: point),
          ),
        );
      },
      onLongPress: () => _onEditPoint(point),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F0DF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF9A7A3D).withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            // Type badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF5A4724),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                typeLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (point.measureName != null &&
                      point.measureName!.isNotEmpty)
                    Text(
                      point.measureName!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  if (point.spaceName != null && point.spaceName!.isNotEmpty)
                    Text(
                      point.spaceName!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textLabel,
                      ),
                    ),
                  Text(
                    '${point.directionText} · ${point.sittingFacingText}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textTitle,
                    ),
                  ),
                  Text(
                    '${point.directionText}｜${DirectionSector.sectorGuaPalaceLabel(DirectionSector.sector8FromHeading(point.heading))} · ${DirectionSector.mountainLabelFromHeading(point.heading)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    point.bazhaiText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isAuspicious
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFC43C32),
                    ),
                  ),
                  Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (point.photoPath != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _buildThumbnail(point.photoPath!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(String photoPath) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _PhotoViewerPage(file: File(photoPath)),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(photoPath),
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFECECEC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.broken_image_outlined,
                size: 20, color: AppTheme.hintText),
          ),
        ),
      ),
    );
  }
}

class _PhotoViewerPage extends StatelessWidget {
  final File file;
  const _PhotoViewerPage({required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('现场照片'),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(file, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
