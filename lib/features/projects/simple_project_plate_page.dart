import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../data/models/compass_record.dart';
import '../../data/models/measurement_project.dart';
import '../../data/storage/settings_storage.dart';
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
      backgroundColor: const Color(0xFFD8D6CF),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        _buildProjectHeader(houseGua),
        const SizedBox(height: 8),
        _buildTiandirenSummary(),
        const SizedBox(height: 12),

        // plate
        TiandirenPlate(
          records: _records,
          houseGua: houseGua,
          selectedRecord: _selectedRecord,
          onRecordSelected: (record) {
            setState(() => _selectedRecord = record);
          },
        ),

        const SizedBox(height: 12),

        // detail card
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.home, color: AppTheme.textLabel),
          const SizedBox(width: 10),
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
                const SizedBox(height: 4),
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

  Widget _buildTiandirenSummary() {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppTheme.cardBorder.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: const [
          Expanded(
            child: Text(
              '山：元龙五行',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '宫：八宅游年',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '点：测点用途',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
