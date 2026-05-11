import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../data/models/compass_record.dart';
import '../../data/models/measurement_project.dart';
import '../../data/storage/settings_storage.dart';
import '../../theme/app_svg_icons.dart';
import '../../widgets/app_svg_icon.dart';
import '../compass/compass_page.dart';
import 'widgets/tiandiren_plate.dart';
import 'widgets/tiandiren_detail_card.dart';

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
      _selectedRecord = records.isNotEmpty ? records.first : null;
      _loading = false;
    });
  }

  String get _projectHouseGua {
    if (_records.isNotEmpty) return _records.first.houseGua;
    return '乾宅';
  }

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
          onRecordSelected: (record) {
            setState(() => _selectedRecord = record);
          },
        ),
        const SizedBox(height: 12),
        if (_selectedRecord != null)
          TiandirenDetailCard(
            record: _selectedRecord!,
            houseGua: houseGua,
          ),
      ],
    );
  }

  Widget _buildProjectHeader(String houseGua) {
    final sittingFacing = _records.isNotEmpty
        ? _records.first.sittingFacingText
        : '未测';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
