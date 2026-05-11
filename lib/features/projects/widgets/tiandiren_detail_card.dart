import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../data/models/compass_record.dart';
import '../../../fengshui/direction_sector.dart';
import '../../../fengshui/measure_type_meaning.dart';
import '../../../data/models/measure_type.dart';

class TiandirenDetailCard extends StatelessWidget {
  final CompassRecord record;
  final String houseGua;

  const TiandirenDetailCard({
    super.key,
    required this.record,
    required this.houseGua,
  });

  @override
  Widget build(BuildContext context) {
    final sectorKey =
        DirectionSector.sector8FromHeading(record.heading);
    final sector = DirectionSector.sector8Label(sectorKey);
    final mountain =
        DirectionSector.mountainLabelFromHeading(record.heading);
    final typeLabel = MeasureTypes.label(record.measureType);
    final name = record.measureName?.trim().isNotEmpty == true
        ? record.measureName!.trim()
        : typeLabel;

    final isAuspicious = !record.bazhaiText.contains('凶');

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
          // title
          const Text(
            '当前选中测点',
            style: TextStyle(
              color: AppTheme.textTitle,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),

          // type · name
          Text(
            '$typeLabel · $name',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),

          // palace · mountain
          Text(
            '归位：$sector · $mountain',
            style: const TextStyle(
              color: AppTheme.textLabel,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),

          const Divider(height: 20),

          // Tian
          _buildLine(
            '天',
            '$houseGua${sector}为${record.bazhaiText}',
            isAuspicious,
          ),
          const SizedBox(height: 6),

          // Di
          _buildLine(
            '地',
            '$name落于$sector$mountain',
            null,
          ),
          const SizedBox(height: 6),

          // Ren
          _buildLine(
            '人',
            MeasureTypeMeaning.humanMeaning(record.measureType),
            null,
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
    );
  }

  Widget _buildLine(String prefix, String content, bool? isGood) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF5A4724),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            prefix,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            content,
            style: TextStyle(
              color:
                  isGood != null ? (isGood ? const Color(0xFF2E7D32) : const Color(0xFFC43C32)) : AppTheme.textPrimary,
              fontSize: 14,
              fontWeight:
                  isGood != null ? FontWeight.w700 : FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
