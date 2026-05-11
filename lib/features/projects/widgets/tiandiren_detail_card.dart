import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../data/models/compass_record.dart';
import '../../../fengshui/direction_sector.dart';
import '../../../fengshui/mountain_24_info.dart';
import '../../../data/models/measure_type.dart';

class TiandirenDetailCard extends StatelessWidget {
  final CompassRecord record;
  final String houseGua;
  final VoidCallback? onLongPress;

  const TiandirenDetailCard({
    super.key,
    required this.record,
    required this.houseGua,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final sectorKey =
        DirectionSector.sector8FromHeading(record.heading);
    final palaceLabel =
        DirectionSector.sectorGuaPalaceLabel(sectorKey);
    final dirLabel =
        DirectionSector.shortSector8Label(sectorKey);
    final mountainChar =
        DirectionSector.mountainFromHeading(record.heading);
    final mountainInfo =
        Mountain24InfoTable.fromMountain(mountainChar);
    final typeLabel = MeasureTypes.label(record.measureType);
    final name = record.measureName?.trim().isNotEmpty == true
        ? record.measureName!.trim()
        : typeLabel;
    final isAuspicious = !record.bazhaiText.contains('凶');

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
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
              '当前选中测点',
              style: TextStyle(
                color: AppTheme.textTitle,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$typeLabel · $name',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            _infoLine('方向', record.directionText),
            const SizedBox(height: 2),
            _infoLine(
                '宫', '$palaceLabel（$dirLabel）'),
            const SizedBox(height: 2),
            _infoLine('山',
                '${mountainInfo.mountainLabel}｜${mountainInfo.yuanLongLabel}｜${mountainInfo.element}'),
            const SizedBox(height: 2),
            Text(
              '星：${record.bazhaiText}',
              style: TextStyle(
                color: isAuspicious
                    ? const Color(0xFF2E7D4F)
                    : const Color(0xFFA13A2A),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '注：测点为方位示意，不代表实际距离比例。',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoLine(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 32,
          child: Text(
            '$label：',
            style: const TextStyle(
              color: AppTheme.textLabel,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
