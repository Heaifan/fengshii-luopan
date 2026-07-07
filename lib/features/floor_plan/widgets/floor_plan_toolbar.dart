import 'package:flutter/material.dart';
import '../../../theme/app_svg_icons.dart';
import '../../../widgets/app_svg_icon.dart';
import '../../../data/models/floor_plan_data.dart';

/// 宅盘图底部工具栏按钮定义
enum FloorPlanToolAction { size, swap, direction, addDoor, grid, taijiLines }

/// 底部工具栏：尺寸 / 横竖 / 坐向 / 加门 / 网格
class FloorPlanToolbar extends StatelessWidget {
  final FloorPlanData data;
  final ValueChanged<FloorPlanToolAction> onAction;

  const FloorPlanToolbar({super.key, required this.data, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: Color(0xFFE6DDC8),
        border: Border(top: BorderSide(color: Color(0xFFBCAA8A), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _btn('尺寸', AppSvgIcons.sizeMeasure, FloorPlanToolAction.size),
          _btn('横竖', AppSvgIcons.swapDimensions, FloorPlanToolAction.swap),
          _btn('坐向', AppSvgIcons.direction, FloorPlanToolAction.direction),
          _btn('加门', AppSvgIcons.doorAdd, FloorPlanToolAction.addDoor),
          _gridBtn(context),
          _taijiBtn(),
        ],
      ),
    );
  }

  Widget _btn(String label, String svg, FloorPlanToolAction action) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onAction(action),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSvgIcon(svg, size: 22, color: const Color(0xFF4A3A12)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF4A3A12), fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _taijiBtn() {
    final active = data.gridMode == 'grid7' && data.overlays.showTaijiLines;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onAction(FloorPlanToolAction.taijiLines),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.line_axis,
              size: 22,
              color: active ? const Color(0xFFC43C32) : const Color(0xFF4A3A12),
            ),
            const SizedBox(height: 2),
            Text(
              '太极',
              style: TextStyle(
                fontSize: 10,
                color: active ? const Color(0xFFC43C32) : const Color(0xFF4A3A12),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gridBtn(BuildContext context) {
    final mode = data.gridMode;
    final label = mode == 'grid4' ? '八宫' : mode == 'grid7' ? '山盘' : '网格关';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onAction(FloorPlanToolAction.grid),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSvgIcon(AppSvgIcons.gridIcon, size: 22, color: const Color(0xFF4A3A12)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF4A3A12), fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
