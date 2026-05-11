import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../data/models/compass_record.dart';
import '../../data/models/measurement_project.dart';
import '../../data/storage/settings_storage.dart';
import '../../theme/app_svg_icons.dart';
import '../../widgets/app_svg_icon.dart';
import '../../fengshui/direction_sector.dart';
import '../compass/compass_page.dart';
import 'widgets/tiandiren_plate.dart';
import 'widgets/tiandiren_detail_card.dart';
import 'widgets/plate_summary_card.dart';
import 'widgets/palace_points_card.dart';
import 'widgets/measure_point_form_sheet.dart';

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

  String get _projectHouseGua {
    if (_records.isNotEmpty) return _records.first.houseGua;
    return '乾宅';
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
      allowDelete: true,
    );

    if (result == null || !mounted) return;

    if (result.delete) {
      await _storage.deleteRecord(record.id);
    } else {
      final updated = record.copyWith(
        measureType: result.measureType,
        measureName: result.measureName,
        spaceName: result.spaceName,
        note: result.note,
      );
      await _storage.updateRecord(updated);
    }

    await _loadRecords();

    if (!mounted) return;

    if (result.delete) {
      setState(() {
        _detailMode = PlateDetailMode.summary;
        _selectedRecord = null;
        _selectedSector = null;
      });
    } else {
      // Reload the updated record from storage
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
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.delete ? '已删除测点' : '测点已更新'),
      ),
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
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? _buildEmptyState()
              : _buildContent(),
    );
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
    final houseGua = _projectHouseGua;

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
            onRecordLongPress: () =>
                _selectedRecord != null
                    ? _onPointLongPress(_selectedRecord!)
                    : null,
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
      onRecordLongPress: palaceRecords.length == 1
          ? () => _onPointLongPress(palaceRecords.first)
          : null,
    );
  }

  Widget _buildProjectHeader(String houseGua) {
    final sittingFacing = _records.isNotEmpty
        ? _records.first.sittingFacingText
        : '未测';

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
                  '$houseGua｜$sittingFacing｜测点 ${_records.length}',
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
