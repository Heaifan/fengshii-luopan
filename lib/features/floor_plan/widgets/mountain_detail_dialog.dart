import 'package:flutter/material.dart';
import '../../../data/models/floor_plan_data.dart';
import '../../../fengshui/bagua.dart';
import '../../../fengshui/five_element_relation.dart';
import '../math/mountain_parser.dart';
import '../painter/draw_floor_plan_mountains.dart';

/// 山位详情弹窗：显示山名、所属卦、天地人元、山位尺寸
class MountainDetailDialog extends StatelessWidget {
  final MountainCell cell;
  final FloorPlanData data;
  final Rect floorRect;

  const MountainDetailDialog({
    super.key,
    required this.cell,
    required this.data,
    required this.floorRect,
  });

  @override
  Widget build(BuildContext context) {
    final m = cell.mountain;
    final gua = BaguaCalculator.fromMountain(m);
    final sanyuan = _sanyuanLabel(m);
    final color3 = kSanyuanColor[m] ?? Color3.red;
    final isSitting = m == data.sittingMountain;
    final isFacing = m == data.facingMountain;

    final sanyuanColor = Color(color3Value(color3));
    final sizeText = _mountainSizeText();

    // 山盘八宫与宫盘统一：均以门所在卦宫为伏位
    final palaceResults = calculateEightPalaces(data);
    final palace = palaceResults[gua];
    final relation = palace != null
        ? resolveStarPalaceRelation(palaceGua: gua, starName: palace.star)
        : null;
    final isChuan = palace != null && isChuanGong(gua, palace.star);

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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: sanyuanColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      m,
                      style: TextStyle(
                        color: sanyuanColor,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$m山 · $gua宫',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4A3A12),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$sanyuan · ${isSitting ? '坐山' : isFacing ? '向首' : '普通山位'}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isSitting || isFacing ? const Color(0xFFC43C32) : const Color(0xFF8A7A5A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _row('所属卦宫', gua),
            _row('天地人元', sanyuan),
            _row('山位尺寸', sizeText),
            const Divider(height: 24, color: Color(0xFFDDD3BC)),
            if (palace != null) ...[
              _row('山盘八宫', '$gua-${palace.star}${palace.rank.isNotEmpty ? ' ${palace.rank}' : ''}'),
              _row('宫星关系', relation?.type ?? '-', subtitle: relation?.detail),
              _row('关系说明', relation?.description ?? '-'),
              _row('穿宫判定', isChuan ? '是（星飞对冲宫位）' : '否'),
            ] else ...[
              _row('山盘八宫', '未设置门或坐向，无法判定'),
            ],
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

  String _sanyuanLabel(String m) => color3Label(kSanyuanColor[m] ?? Color3.red);

  String _mountainSizeText() {
    if (floorRect.width <= 0 || floorRect.height <= 0) return '-';
    final w = cell.rect.width / floorRect.width * data.widthCm;
    final h = cell.rect.height / floorRect.height * data.heightCm;
    return '${w.round()}cm × ${h.round()}cm';
  }
}

Future<void> showMountainDetailDialog({
  required BuildContext context,
  required MountainCell cell,
  required FloorPlanData data,
  required Rect floorRect,
}) async {
  await showDialog(
    context: context,
    builder: (_) => MountainDetailDialog(
      cell: cell,
      data: data,
      floorRect: floorRect,
    ),
  );
}
