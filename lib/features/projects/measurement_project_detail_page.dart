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

class MeasurementProjectDetailPage extends StatefulWidget {
  final MeasurementProject project;

  const MeasurementProjectDetailPage({
    super.key,
    required this.project,
  });

  @override
  State<MeasurementProjectDetailPage> createState() =>
      _MeasurementProjectDetailPageState();
}

class _MeasurementProjectDetailPageState
    extends State<MeasurementProjectDetailPage> {
  final _storage = SettingsStorage();
  List<CompassRecord> _points = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    final points =
        await _storage.loadRecordsByProject(widget.project.id);
    if (!mounted) return;
    setState(() {
      _points = points;
      _loading = false;
    });
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
                        Text(widget.project.name,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary)),
                        const SizedBox(height: 4),
                        if (widget.project.location != null &&
                            widget.project.location!.isNotEmpty)
                          Text(widget.project.location!,
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary)),
                        Text(
                          BaZhaiBaseResolver.summaryText(
                            project: widget.project,
                            records: _points,
                          ),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textLabel)),
                        Text('已测 ${_points.length} 个点',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textLabel)),
                      ],
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
                          builder: (_) => CompassPage(
                              activeProject: widget.project),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_location_alt,
                        size: 18),
                    label: const Text('继续测量'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5A4724),
                      side: const BorderSide(
                          color: Color(0xFF5A4724)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
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
                          builder: (_) => SimpleProjectPlatePage(
                              project: widget.project),
                        ),
                      );
                    },
                    icon: const Icon(Icons.grid_view, size: 18),
                    label: const Text('简易正盘'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5A4724),
                      side: const BorderSide(
                          color: Color(0xFF5A4724)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
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
                          builder: (_) => TiandirenVentPage(
                              project: widget.project),
                        ),
                      );
                    },
                    icon: const Icon(Icons.circle_outlined,
                        size: 18),
                    label: const Text('天地人通气'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5A4724),
                      side: const BorderSide(
                          color: Color(0xFF5A4724)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
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
              ))
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
          const Icon(Icons.explore_outlined,
              size: 40, color: AppTheme.textHint),
          const SizedBox(height: 10),
          const Text('暂无测点',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          const Text('点击"继续测量"开始采集门、阳台、窗、床、灶等方位。',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildPointCard(int index, CompassRecord point) {
    final typeLabel = MeasureTypes.label(point.measureType);
    final isAuspicious = !point.bazhaiText.contains('凶');
    final timeStr =
        DateFormat('MM-dd HH:mm').format(point.createdAt);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CompassRecordDetailPage(record: point),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F0DF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: const Color(0xFF9A7A3D).withValues(alpha: 0.25)),
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
              child: Text(typeLabel,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (point.measureName != null &&
                      point.measureName!.isNotEmpty)
                    Text(point.measureName!,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                  if (point.spaceName != null &&
                      point.spaceName!.isNotEmpty)
                    Text(point.spaceName!,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textLabel)),
                  Text(
                    '${point.directionText} · ${point.sittingFacingText}',
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textTitle),
                  ),
                  Text(
                    '${point.directionText}｜${DirectionSector.sectorGuaPalaceLabel(DirectionSector.sector8FromHeading(point.heading))} · ${DirectionSector.mountainLabelFromHeading(point.heading)}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary),
                  ),
                  Text(point.bazhaiText,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isAuspicious
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFC43C32))),
                  Text(timeStr,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
