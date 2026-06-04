import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../data/models/compass_record.dart';
import '../../../data/models/measure_type.dart';
import '../../../fengshui/direction_sector.dart';
import '../../../fengshui/mountain_24_info.dart';
import '../../../fengshui/five_element_relation.dart';

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

/// Compute sitting mountain from heading.
String _sittingMountainFromHeading(double heading) {
  final sittingDeg = (heading + 180) % 360;
  return DirectionSector.mountainFromHeading(sittingDeg);
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
    final sittingMountain = _sittingMountainFromHeading(record.heading);
    final sittingInfo =
        Mountain24InfoTable.fromMountain(sittingMountain);
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
                color: AppTheme.titleText,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            // Name line
            Text(
              '$typeLabel · $name',
              style: const TextStyle(
                color: AppTheme.bodyText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            // Dual column layout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoLine('方位', record.directionText),
                      const SizedBox(height: 4),
                      _infoLine('宫位',
                          '$palaceLabel（$dirLabel）'),
                      const SizedBox(height: 4),
                      _infoLine('向山',
                          '${mountainInfo.mountainLabel}｜${mountainInfo.yuanLongLabel}'),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Right column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoLine('坐山',
                          '${sittingInfo.mountainLabel}｜${sittingInfo.yuanLongLabel}'),
                      const SizedBox(height: 4),
                      _infoLine('星曜', record.bazhaiText,
                          color: isAuspicious
                              ? AppTheme.goodText
                              : AppTheme.badText),
                      const SizedBox(height: 4),
                      if (relation != null)
                        _infoLine('星与宫',
                            '${relation.type}（${relation.detail}）',
                            color: AppTheme.neutralText)
                      else
                        _infoLine('星与宫', '待定',
                            color: AppTheme.neutralText),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              '注：测点为方位示意，不代表实际距离比例。',
              style: TextStyle(
                color: AppTheme.subText,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoLine(String label, String value, {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label：',
          style: const TextStyle(
            color: AppTheme.subText,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: color ?? AppTheme.bodyText,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
