import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../data/models/compass_record.dart';
import '../../../data/models/measure_type.dart';
import '../utils/plate_record_info.dart';
import '../utils/plate_record_sorter.dart';

class PlateSummaryCard extends StatelessWidget {
  final List<CompassRecord> records;
  final String houseGua;
  final ValueChanged<CompassRecord> onRecordTap;
  final VoidCallback? onRecordLongPress;

  const PlateSummaryCard({
    super.key,
    required this.records,
    required this.houseGua,
    required this.onRecordTap,
    this.onRecordLongPress,
  });

  @override
  Widget build(BuildContext context) {
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
            '项目测点汇总',
            style: TextStyle(
              color: AppTheme.textTitle,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '共 ${records.length} 个测点',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ...sortPlateRecords(records).asMap().entries.map((entry) {
            final info = buildPlateRecordInfo(
              record: entry.value,
              houseGua: houseGua,
            );
            final typeLabel =
                MeasureTypes.label(entry.value.measureType);
            final name =
                entry.value.measureName?.trim().isNotEmpty == true
                    ? entry.value.measureName!.trim()
                    : typeLabel;
            return _buildRow(entry.key, info, typeLabel, name);
          }),
          const SizedBox(height: 6),
          const Text(
            '注：测点为方位示意，不代表实际距离比例。',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(int index, PlateRecordInfo info, String typeLabel,
      String name) {
    final isEven = index.isEven;
    return GestureDetector(
      onTap: () => onRecordTap(info.record),
      onLongPress: onRecordLongPress != null
          ? () => onRecordLongPress!.call()
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isEven
              ? const Color(0xFFF7F0DF)
              : const Color(0xFFF3E8D5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF5A4724),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$typeLabel · $name',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    info.palaceLine,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    info.bazhaiText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: info.bazhaiText.contains('凶')
                          ? const Color(0xFFA13A2A)
                          : const Color(0xFF2E7D4F),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: AppTheme.textHint),
          ],
        ),
      ),
    );
  }
}
