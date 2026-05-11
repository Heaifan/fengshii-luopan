import 'package:flutter/material.dart';
import '../../../data/models/compass_record.dart';
import '../../../data/models/measurement_project.dart';
import '../../../data/models/measure_type.dart';
import '../../../fengshui/direction_sector.dart';
import '../painters/tiandiren_plate_painter.dart';
import '../utils/plate_record_sorter.dart';

class ProjectPlateExportCard extends StatelessWidget {
  final MeasurementProject project;
  final List<CompassRecord> records;
  final String houseGua;
  final String sittingFacing;

  const ProjectPlateExportCard({
    super.key,
    required this.project,
    required this.records,
    required this.houseGua,
    required this.sittingFacing,
  });

  @override
  Widget build(BuildContext context) {
    const exportWidth = 1080.0;
    final sorted = sortPlateRecords(records);

    return Container(
      width: exportWidth,
      color: const Color(0xFFFFFBF0),
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 36),
          _buildPlate(exportWidth),
          const SizedBox(height: 36),
          _buildSummary(sorted),
          const SizedBox(height: 44),
          _buildSealWatermark(),
        ],
      ),
    );
  }

  // ==========================================
  // Header
  // ==========================================

  Widget _buildHeader() {
    final now = DateTime.now();
    final timeStr =
        '${now.year}-${_pad(now.month)}-${_pad(now.day)} ${_pad(now.hour)}:${_pad(now.minute)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '风水荷盘 · 简易正盘',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1C1208),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '项目：${project.name}｜$houseGua｜$sittingFacing｜测点 ${records.length}个',
          style: const TextStyle(
            fontSize: 28,
            color: Color(0xFF5F4630),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '导出时间：$timeStr',
          style: const TextStyle(
            fontSize: 22,
            color: Color(0xFF7A6040),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // Plate
  // ==========================================

  Widget _buildPlate(double totalWidth) {
    final plateSize = totalWidth - 96;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF0),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFE0C999),
            width: 1,
          ),
        ),
        child: SizedBox(
          width: plateSize,
          height: plateSize,
          child: CustomPaint(
            painter: TiandirenPlatePainter(
              records: records,
              houseGua: houseGua,
              selectedRecord: null,
            ),
            size: Size(plateSize, plateSize),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // Summary
  // ==========================================

  Widget _buildSummary(List<CompassRecord> sorted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '项目测点汇总',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1C1208),
          ),
        ),
        const SizedBox(height: 16),
        ...sorted.asMap().entries.map((entry) {
          final record = entry.value;
          final idx = entry.key;
          final sectorKey =
              DirectionSector.sector8FromHeading(record.heading);
          final palaceLabel =
              DirectionSector.sectorGuaPalaceLabel(sectorKey);
          final mountainInfo =
              DirectionSector.mountainInfoFromHeading(record.heading);
          final typeLabel = MeasureTypes.label(record.measureType);
          final name = record.measureName?.trim().isNotEmpty == true
              ? record.measureName!.trim()
              : typeLabel;
          final isAuspicious = !record.bazhaiText.contains('凶');

          return Container(
            padding: const EdgeInsets.symmetric(
                vertical: 10, horizontal: 12),
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: idx.isEven
                  ? const Color(0xFFF7F0DF)
                  : const Color(0xFFF3E8D5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5A4724),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${idx + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$typeLabel · $name',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1C1208),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${record.directionText}｜$palaceLabel · ${mountainInfo.mountainLabel}',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Color(0xFF5F4630),
                        ),
                      ),
                      Text(
                        record.bazhaiText,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: isAuspicious
                              ? const Color(0xFF2E7D4F)
                              : const Color(0xFFA13A2A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ==========================================
  // Seal-style watermark (朱砂印章风)
  // ==========================================

  Widget _buildSealWatermark() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFC9A96A),
          width: 1.4,
        ),
      ),
      child: Row(
        children: [
          // Seal-style app icon
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFC83A2E),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/icon/app_icon.jpg',
                width: 52,
                height: 52,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '风水荷盘 · 简易正盘',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C1208),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '项目：${project.name}｜$houseGua｜测点 ${records.length}个',
                  style: const TextStyle(
                    fontSize: 22,
                    color: Color(0xFF5F4630),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
