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

/// Extract rank from bazhaiText like "绝命金（一凶）" → "一凶".
String _rankFromBazhai(String text) {
  final start = text.indexOf('（');
  final end = text.indexOf('）');
  if (start >= 0 && end > start) {
    return text.substring(start + 1, end);
  }
  return '';
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
    final hasRelation = gua.isNotEmpty && starName.isNotEmpty;
    final relation = hasRelation
        ? resolveStarPalaceRelation(palaceGua: gua, starName: starName)
        : null;

    // Badge color
    final badgeColor = isAuspicious ? AppTheme.goodText : AppTheme.badText;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              '当前选中测点',
              style: TextStyle(
                color: AppTheme.titleText,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            // Name line with auspicious badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$typeLabel · $name',
                    style: const TextStyle(
                      color: AppTheme.bodyText,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                // Auspicious/bad badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    isAuspicious ? '吉' : '凶',
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ---- Dual column data ----
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column
                Expanded(
                  child: _dataBlock([
                    _dataRow('方位', record.directionText),
                    _dataRow('宫位', '$palaceLabel（$dirLabel）'),
                    _dataRow('向山', '${mountainInfo.mountainLabel}｜${mountainInfo.yuanLongLabel}'),
                  ]),
                ),
                const SizedBox(width: 12),
                // Right column
                Expanded(
                  child: _dataBlock([
                    _dataRow('坐山', '${sittingInfo.mountainLabel}｜${sittingInfo.yuanLongLabel}'),
                    _dataRow('星曜', record.bazhaiText, color: badgeColor),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ---- Conclusion area ----
            _buildConclusionArea(relation, isAuspicious),

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

  Widget _dataBlock(List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }

  Widget _dataRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
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
      ),
    );
  }

  Widget _buildConclusionArea(StarPalaceRelation? relation, bool isAuspicious) {
    final bazhaiRank = _rankFromBazhai(record.bazhaiText);
    final relationType = relation?.type ?? '待定';
    final relationDetail = relation?.detail ?? '';

    // Build hint
    String hint;
    if (bazhaiRank.isEmpty) {
      hint = '待定';
    } else if (relation != null) {
      hint = buildGoodBadHint(
        bazhaiRank: bazhaiRank,
        relationType: relationType,
      );
    } else {
      hint = '$bazhaiRank，星与宫关系待定';
    }

    final hintColor = isAuspicious ? AppTheme.goodText : AppTheme.badText;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0C98A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Star-palace relation
          Row(
            children: [
              const Text(
                '【星与宫】',
                style: TextStyle(
                  color: AppTheme.neutralText,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Expanded(
                child: Text(
                  relation != null
                      ? '$relationType（$relationDetail）'
                      : '待定',
                  style: const TextStyle(
                    color: AppTheme.neutralText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Good/bad hint
          Row(
            children: [
              const Text(
                '【吉凶提示】',
                style: TextStyle(
                  color: AppTheme.neutralText,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Expanded(
                child: Text(
                  hint,
                  style: TextStyle(
                    color: hintColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
