import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../data/models/compass_record.dart';
import '../../data/models/measurement_project.dart';
import '../../data/models/measure_type.dart';
import '../../data/storage/settings_storage.dart';
import '../../fengshui/direction_sector.dart';
import '../../fengshui/mountain_24.dart';
import '../../fengshui/mountain_24_info.dart';
import '../compass/compass_page.dart';
import 'widgets/tiandiren_vent_widget.dart';

class TiandirenVentPage extends StatefulWidget {
  final MeasurementProject project;

  const TiandirenVentPage({super.key, required this.project});

  @override
  State<TiandirenVentPage> createState() => _TiandirenVentPageState();
}

class _TiandirenVentPageState extends State<TiandirenVentPage> {
  final _storage = SettingsStorage();
  List<CompassRecord> _records = [];
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
      _loading = false;
    });
  }

  String get _statusTitle {
    final n = _records.length;
    if (n == 0) return '当前暂无测点';
    if (n == 1) return '当前为单点记录';
    final hasDoor = _records.any((r) => r.measureType == 'door');
    final hasBed = _records.any((r) => r.measureType == 'bed');
    final hasStove = _records.any((r) => r.measureType == 'stove');
    if (hasDoor && hasBed && hasStove) return '当前为完整门主灶记录';
    return '当前为部分测点记录';
  }

  String get _statusDesc {
    final n = _records.length;
    if (n == 0) return '请先记录门、主、灶或其他关键点位。';
    if (n == 1) {
      return '已识别 1 个测点，可作为后续通气分析基础。';
    }
    final hasDoor = _records.any((r) => r.measureType == 'door');
    final hasBed = _records.any((r) => r.measureType == 'bed');
    final hasStove = _records.any((r) => r.measureType == 'stove');
    if (hasDoor && hasBed && hasStove) {
      return '已识别门、主、灶三个关键点位。';
    }
    return '已识别 $_records.length 个测点，继续补充主、灶等点位后可完善判断。';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F1),
      appBar: AppBar(
        title: const Text('天地人通气'),
        centerTitle: true,
        backgroundColor: const Color(0xFFc8b898),
        foregroundColor: const Color(0xFF333333),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        _buildStatusCard(),
        const SizedBox(height: 12),
        if (_records.isNotEmpty) ...[
          TiandirenVentWidget(records: _records),
          const SizedBox(height: 12),
          _buildPointList(),
          const SizedBox(height: 10),
          _buildNote(),
        ] else ...[
          const SizedBox(height: 20),
          _buildEmptyAction(),
        ],
      ],
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _statusTitle,
            style: const TextStyle(
              color: AppTheme.textTitle,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _statusDesc,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAction() {
    return Center(
      child: FilledButton.icon(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CompassPage(activeProject: widget.project),
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
    );
  }

  Widget _buildPointList() {
    final sorted = _sortedRecords();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '已识别测点',
            style: TextStyle(
              color: AppTheme.textTitle,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ...sorted.asMap().entries.map((entry) {
            final record = entry.value;
            final idx = entry.key;
            final mountain =
                Mountain24Calculator.fromDegree(record.heading);
            final sectorKey =
                DirectionSector.sector8FromHeading(record.heading);
            final palace =
                DirectionSector.sectorGuaPalaceLabel(sectorKey);
            final info =
                Mountain24InfoTable.fromMountain(mountain.mountain);
            final typeLabel = MeasureTypes.label(record.measureType);
            final name = record.measureName?.trim().isNotEmpty == true
                ? record.measureName!.trim()
                : typeLabel;
            final sanyuanLabel = info.yuanLongLabel;

            return _pointRow(
              idx: idx,
              typeLabel: typeLabel,
              name: name,
              direction: record.directionText,
              palace: palace,
              mountainLabel: info.mountainLabel,
              sanyuanLabel: sanyuanLabel,
              sanyuanColor: _sanyuanColor(info.yuanLong),
            );
          }),
        ],
      ),
    );
  }

  List<CompassRecord> _sortedRecords() {
    final sorted = [..._records];
    sorted.sort((a, b) {
      final pa = _typePriority(a.measureType);
      final pb = _typePriority(b.measureType);
      if (pa != pb) return pa.compareTo(pb);
      return a.heading.compareTo(b.heading);
    });
    return sorted;
  }

  int _typePriority(String type) {
    switch (type) {
      case 'door': return 1;
      case 'bed': return 2;
      case 'stove': return 3;
      case 'altar': return 4;
      case 'desk': return 5;
      case 'livingRoom': return 6;
      case 'balcony': return 7;
      case 'window': return 8;
      default: return 9;
    }
  }

  Color _sanyuanColor(String yuanLong) {
    switch (yuanLong) {
      case '天':
        return const Color(0xFF3B8C6E);
      case '地':
        return const Color(0xFF9A5A3A);
      case '人':
        return const Color(0xFFC8922E);
      default:
        return const Color(0xFF5F4630);
    }
  }

  Widget _pointRow({
    required int idx,
    required String typeLabel,
    required String name,
    required String direction,
    required String palace,
    required String mountainLabel,
    required String sanyuanLabel,
    required Color sanyuanColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: idx.isEven
            ? const Color(0xFFF7F0DF)
            : const Color(0xFFF3E8D5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Type badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF5A4724),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(typeLabel,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$typeLabel · $name',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                Text(
                  '$direction｜$palace｜$mountainLabel',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          // Sanyuan badge
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: sanyuanColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              sanyuanLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: sanyuanColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNote() {
    return const Text(
      '本图用于显示项目测点在通气图中的分布。'
      '测点越完整，越便于后续进行门、主、灶关系判断。',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 12,
        height: 1.4,
      ),
    );
  }
}
