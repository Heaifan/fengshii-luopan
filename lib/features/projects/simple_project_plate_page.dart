import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../data/models/compass_record.dart';
import '../../data/models/measurement_project.dart';
import '../../data/storage/settings_storage.dart';
import '../../theme/app_svg_icons.dart';
import '../../widgets/app_svg_icon.dart';
import '../../fengshui/direction_sector.dart';
import '../../fengshui/bazhai_base_resolver.dart';
import '../compass/compass_page.dart';
import 'widgets/tiandiren_plate.dart';
import 'widgets/tiandiren_detail_card.dart';
import 'widgets/plate_summary_card.dart';
import 'widgets/palace_points_card.dart';
import 'widgets/measure_point_form_sheet.dart';
import 'widgets/project_plate_export_card.dart';
import 'services/project_plate_export_service.dart';

enum PlateDetailMode { summary, point, palace }

class SimpleProjectPlatePage extends StatefulWidget {
  final MeasurementProject project;

  const SimpleProjectPlatePage({
    super.key,
    required this.project,
  });

  @override
  State<SimpleProjectPlatePage> createState() =>
      _SimpleProjectPlatePageState();
}

class _SimpleProjectPlatePageState
    extends State<SimpleProjectPlatePage> {
  final _storage = SettingsStorage();
  List<CompassRecord> _records = [];
  CompassRecord? _selectedRecord;
  String? _selectedSector;
  PlateDetailMode _detailMode = PlateDetailMode.summary;
  bool _loading = true;
  bool _exporting = false;
  final GlobalKey _exportKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final records =
        await _storage.loadRecordsByProject(widget.project.id);
    if (!mounted) return;
    setState(() {
      _records = records;
      if (_detailMode == PlateDetailMode.summary) {
        _selectedRecord = null;
        _selectedSector = null;
      }
      _loading = false;
    });
  }

  String get _projectBasePalace {
    final base = BaZhaiBaseResolver.resolveBasePalace(
      project: widget.project,
      records: _records,
    );
    return base ?? '乾';
  }

  String get _projectSittingFacing {
    if (_records.isNotEmpty) return _records.first.sittingFacingText;
    return '未测';
  }

  Future<void> _showExportOptions() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF8E8),
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC9A96A),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '导出正盘图片',
                    style: TextStyle(
                      color: Color(0xFF1C1208),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _buildExportTile(
                  icon: Icons.photo_library_outlined,
                  title: '导出图片',
                  subtitle: '导出正盘长图，通过分享保存到相册',
                  onTap: () {
                    Navigator.pop(ctx);
                    _sharePlateImage();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExportTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE0C999),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF4A3A12), size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF1C1208),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6B5A45),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List?> _captureExportBytes() async {
    try {
      // Wait for the offscreen widget to render
      await Future.delayed(const Duration(milliseconds: 200));
      return await ProjectPlateExportService.captureBytes(
          repaintKey: _exportKey);
    } catch (_) {
      return null;
    }
  }

  String get _exportFileName {
    final safe = widget.project.name
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
    final maxLen = 40;
    final truncated =
        safe.length <= maxLen ? safe : safe.substring(0, maxLen);
    return '风水荷盘_${truncated}_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _sharePlateImage() async {
    setState(() => _exporting = true);
    try {
      final bytes = await _captureExportBytes();
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('导出失败，请重试')),
          );
        }
        return;
      }
      final result = await ProjectPlateExportService.shareImage(
          bytes, fileName: _exportFileName);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // ---- Interaction handlers ----

  void _onPointTap(CompassRecord record) {
    setState(() {
      _detailMode = PlateDetailMode.point;
      _selectedRecord = record;
      _selectedSector =
          DirectionSector.sector8FromHeading(record.heading);
    });
  }

  void _onCenterTap() {
    setState(() {
      _detailMode = PlateDetailMode.summary;
      _selectedRecord = null;
      _selectedSector = null;
    });
  }

  void _onPalaceTap(String sector) {
    final points = _records.where((r) {
      return DirectionSector.sector8FromHeading(r.heading) ==
          sector;
    }).toList();

    if (points.isEmpty) {
      setState(() {
        _detailMode = PlateDetailMode.palace;
        _selectedRecord = null;
        _selectedSector = sector;
      });
      return;
    }
    if (points.length == 1) {
      setState(() {
        _detailMode = PlateDetailMode.point;
        _selectedRecord = points.first;
        _selectedSector = sector;
      });
      return;
    }
    setState(() {
      _detailMode = PlateDetailMode.palace;
      _selectedRecord = null;
      _selectedSector = sector;
    });
  }

  Future<void> _onPointLongPress(CompassRecord record) async {
    await _showEditSheet(record);
  }

  Future<void> _showEditSheet(CompassRecord record) async {
    final result = await showMeasurePointFormSheet(
      context: context,
      initialRecord: record,
      houseGua: _projectBasePalace,
      allowDelete: true,
    );

    if (result == null || !mounted) return;

    if (result.delete) {
      await _storage.deleteRecord(record.id);
      await _loadRecords();
      if (!mounted) return;
      setState(() {
        _detailMode = PlateDetailMode.summary;
        _selectedRecord = null;
        _selectedSector = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已删除测点')),
      );
      return;
    }

    final heading = result.heading ?? record.heading;
    final updated = CompassRecord(
      id: record.id,
      name: record.name,
      location: record.location,
      note: result.note,
      createdAt: record.createdAt,
      heading: heading,
      directionText: record.directionText,
      sittingFacingText: record.sittingFacingText,
      sittingMountain: record.sittingMountain,
      facingMountain: record.facingMountain,
      palace: record.palace,
      mountainText: record.mountainText,
      bazhaiText: record.bazhaiText,
      statusText: record.statusText,
      horizontalAngle: record.horizontalAngle,
      verticalAngle: record.verticalAngle,
      houseGua: record.houseGua,
      projectId: record.projectId,
      measureType: result.measureType,
      measureName: result.measureName,
      spaceName: result.spaceName,
    );
    await _storage.updateRecord(updated);

    // Batch recalculate ALL points based on current base palace
    final fresh = await _storage.loadRecordsByProject(widget.project.id);
    final recalculated = BaZhaiBaseResolver.recalculateAllPoints(
      project: widget.project,
      records: fresh,
    );
    final allRecords = await _storage.loadRecords();
    for (final rec in recalculated) {
      final idx = allRecords.indexWhere((r) => r.id == rec.id);
      if (idx >= 0) allRecords[idx] = rec;
    }
    await _storage.saveRecords(allRecords);

    await _loadRecords();

    if (!mounted) return;

    final reloaded = await _storage.loadRecordsByProject(
        widget.project.id);
    final updatedRecord = reloaded.where(
        (r) => r.id == record.id).firstOrNull;
    setState(() {
      _detailMode = PlateDetailMode.point;
      _selectedRecord = updatedRecord;
      _selectedSector =
          DirectionSector.sector8FromHeading(record.heading);
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('测点已更新')),
    );
  }

  // ---- Build ----

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F1),
      appBar: AppBar(
        title: const Text('简易正盘'),
        centerTitle: true,
        backgroundColor: const Color(0xFFc8b898),
        foregroundColor: const Color(0xFF333333),
        actions: [
          if (_records.isNotEmpty)
            IconButton(
              icon: _exporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF333333)))
                  : const Icon(Icons.download_rounded),
              tooltip: '导出图片',
              onPressed: _exporting ? null : _showExportOptions,
            ),
        ],
      ),
      body: Stack(
        children: [
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            _buildNonLoadingContent(),

          // Offscreen export card for PNG capture
          if (!_loading && _records.isNotEmpty)
            Positioned(
              left: -2000,
              top: 0,
              child: RepaintBoundary(
                key: _exportKey,
                child: ProjectPlateExportCard(
                  project: widget.project,
                  records: _records,
                  houseGua: _projectBasePalace,
                  sittingFacing: _projectSittingFacing,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNonLoadingContent() {
    if (_records.isEmpty) return _buildEmptyState();
    return _buildContent();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.grid_view,
                size: 56, color: AppTheme.textHint),
            const SizedBox(height: 16),
            const Text('暂无测点',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            const Text(
              '继续测量门、窗、床、灶等测点后，\n系统会自动生成天地人简易正盘。',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CompassPage(
                        activeProject: widget.project),
                  ),
                );
              },
              icon: const Icon(Icons.add_location_alt, size: 18),
              label: const Text('继续测量'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5A4724),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final houseGua = _projectBasePalace;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
      children: [
        _buildProjectHeader(houseGua),
        const SizedBox(height: 6),
        TiandirenPlate(
          records: _records,
          houseGua: houseGua,
          selectedRecord: _selectedRecord,
          onRecordSelected: _onPointTap,
          onPointLongPress: _onPointLongPress,
          onPalaceTap: _onPalaceTap,
          onCenterTap: _onCenterTap,
        ),
        const SizedBox(height: 12),

        // ---- Detail section (3 modes) ----
        if (_detailMode == PlateDetailMode.summary)
          PlateSummaryCard(
            records: _records,
            houseGua: houseGua,
            onRecordTap: _onPointTap,
            onRecordLongPress: _onPointLongPress,
          ),

        if (_detailMode == PlateDetailMode.point &&
            _selectedRecord != null)
          TiandirenDetailCard(
            record: _selectedRecord!,
            houseGua: houseGua,
            onLongPress: () =>
                _onPointLongPress(_selectedRecord!),
          ),

        if (_detailMode == PlateDetailMode.palace &&
            _selectedSector != null)
          _buildPalacePointsCard(houseGua),
      ],
    );
  }

  Widget _buildPalacePointsCard(String houseGua) {
    final sector = _selectedSector!;
    final palaceRecords = _records.where((r) =>
        DirectionSector.sector8FromHeading(r.heading) ==
        sector).toList();
    return PalacePointsCard(
      sector: sector,
      records: palaceRecords,
      houseGua: houseGua,
      onRecordTap: _onPointTap,
      onRecordLongPress: _onPointLongPress,
    );
  }

  Widget _buildProjectHeader(String houseGua) {
    final sittingFacing = _records.isNotEmpty
        ? _records.first.sittingFacingText
        : '未测';
    final baZhaiSummary = BaZhaiBaseResolver.summaryText(
      project: widget.project,
      records: _records,
    );

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.project.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$baZhaiSummary｜$sittingFacing｜测点 ${_records.length}个',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
