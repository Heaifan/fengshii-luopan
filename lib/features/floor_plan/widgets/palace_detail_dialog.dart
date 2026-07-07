import 'package:flutter/material.dart';
import '../../../data/models/floor_plan_data.dart';
import '../../../fengshui/bazhai_you_nian_table.dart';
import '../../../fengshui/five_element_relation.dart';
import '../math/mountain_parser.dart';

/// 八宫详情弹窗：显示宫位、星名、五行、rank、宫星关系、穿宫判定、宫位尺寸
class PalaceDetailDialog extends StatelessWidget {
  final PalaceHitInfo hitInfo;
  final FloorPlanData data;
  final Rect floorRect;

  const PalaceDetailDialog({
    super.key,
    required this.hitInfo,
    required this.data,
    required this.floorRect,
  });

  @override
  Widget build(BuildContext context) {
    final palace = hitInfo.palace;
    final pe = palaceElement(palace.gua);
    final se = starElement(palace.star);
    final relation = resolveStarPalaceRelation(
      palaceGua: palace.gua,
      starName: palace.star,
    );
    final isChuanGong = _isChuanGong(palace.gua, palace.star);
    final sizeText = _palaceSizeText();

    final meta = bazhaiStarMetaMap[palace.star];
    final starColor = meta?.color ?? (palace.isAuspicious ? const Color(0xFF2E7D32) : const Color(0xFF8A6D3B));

    return Dialog(
      backgroundColor: const Color(0xFFF9F5EB),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: starColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      palace.gua,
                      style: TextStyle(
                        color: starColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${palace.gua}宫 · ${palace.star}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4A3A12),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      palace.rank.isNotEmpty ? palace.rank : (palace.isAuspicious ? '吉星' : '凶星'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: palace.isAuspicious ? const Color(0xFF2E7D32) : const Color(0xFFC43C32),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _row('宫位五行', pe),
            _row('星名五行', se),
            _row('宫位尺寸', sizeText),
            const Divider(height: 24, color: Color(0xFFDDD3BC)),
            _row('宫星关系', relation.type, subtitle: relation.detail),
            _row('关系说明', relation.description),
            _row('穿宫判定', isChuanGong ? '是（星飞对冲宫位）' : '否'),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭', style: TextStyle(color: Color(0xFF7A5C2E), fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Color(0xFF8A7A5A)),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4A3A12),
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF9A8A6A)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _palaceSizeText() {
    if (floorRect.width <= 0 || floorRect.height <= 0) return '-';
    final palaceW = hitInfo.rect.width / floorRect.width * data.widthCm;
    final palaceH = hitInfo.rect.height / floorRect.height * data.heightCm;
    return '${palaceW.round()}cm × ${palaceH.round()}cm';
  }

  bool _isChuanGong(String currentGua, String starName) =>
      isChuanGong(currentGua, starName);
}

Future<void> showPalaceDetailDialog({
  required BuildContext context,
  required PalaceHitInfo hitInfo,
  required FloorPlanData data,
  required Rect floorRect,
}) async {
  await showDialog(
    context: context,
    builder: (_) => PalaceDetailDialog(
      hitInfo: hitInfo,
      data: data,
      floorRect: floorRect,
    ),
  );
}
