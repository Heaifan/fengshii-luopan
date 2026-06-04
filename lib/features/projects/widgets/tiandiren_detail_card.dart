import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../data/models/compass_record.dart';
import '../../../fengshui/direction_sector.dart';
import '../../../fengshui/mountain_24_info.dart';
import '../../../fengshui/five_element_relation.dart';
import '../../../data/models/measure_type.dart';

/// Extract star name from bazhaiText like "五鬼火（二凶）" → "五鬼".
String _starNameFromBazhai(String text) {
  const stars = ['生气', '天医', '延年', '伏位', '绝命', '五鬼', '六煞', '祸害'];
  for (final s in stars) {
    if (text.startsWith(s)) return s;
  }
  return '';
}

/// Extract gua from palace like "离宫" → "离".
String _guaFromPalace(String palace) {
  if (palace.isEmpty) return '';
  return palace[0];
}

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

    // Star-palace relation
    final gua = _guaFromPalace(record.palace);
    final starName = _starNameFromBazhai(record.bazhaiText);
    final hasRelation =
        gua.isNotEmpty && starName.isNotEmpty;
    final relation = hasRelation
        ? resolveStarPalaceRelation(
            palaceGua: gua, starName: starName)
        : null;

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
            _infoLine('宫', '$palaceLabel（$dirLabel）'),
            const SizedBox(height: 2),
            _infoLine('山',
                '${mountainInfo.mountainLabel}｜${mountainInfo.yuanLongLabel}｜${mountainInfo.element}'),
            const SizedBox(height: 2),
            Text(
              '星：${record.bazhaiText}',
              style: TextStyle(
                color: isAuspicious
                    ? const Color(0xFF3E7A4B)
                    : const Color(0xFF9A4A3D),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (relation != null) ...[
              const SizedBox(height: 2),
              Text(
                '星宫：${relation.type}（${relation.detail}）',
                style: const TextStyle(
                  color: Color(0xFF6B5A44),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else ...[
              const SizedBox(height: 2),
              const Text(
                '星宫：待定',
                style: TextStyle(
                  color: Color(0xFF6B5A44),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
