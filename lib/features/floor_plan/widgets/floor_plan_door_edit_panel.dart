import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme.dart';
import '../../../data/models/floor_plan_data.dart';
import '../math/door_position_math.dart';

/// 编辑入户门面板
Future<FloorPlanDoor?> showDoorEditPanel({
  required BuildContext context,
  required FloorPlanData data,
}) {
  final door = data.mainDoor;
  if (door == null) return Future.value(null);
  return showModalBottomSheet<FloorPlanDoor>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _DoorEditPanel(data: data, door: door),
  );
}

class _DoorEditPanel extends StatefulWidget {
  final FloorPlanData data;
  final FloorPlanDoor door;
  const _DoorEditPanel({required this.data, required this.door});

  @override
  State<_DoorEditPanel> createState() => _DoorEditPanelState();
}

class _DoorEditPanelState extends State<_DoorEditPanel> {
  late final TextEditingController _widthCtrl;
  late final TextEditingController _offsetCtrl;
  late final FocusNode _widthFocus;
  late final FocusNode _offsetFocus;
  final _wallLabels = {'top': '上', 'bottom': '下', 'left': '左', 'right': '右'};

  @override
  void initState() {
    super.initState();
    _widthCtrl = TextEditingController(
        text: widget.door.widthCm.round().toString());
    _offsetCtrl = TextEditingController(
        text: widget.door.offsetCm.round().toString());
    _widthFocus = FocusNode()..addListener(() => _onFocus(_widthFocus, _widthCtrl));
    _offsetFocus = FocusNode()..addListener(() => _onFocus(_offsetFocus, _offsetCtrl));
  }

  @override
  void dispose() {
    _widthFocus.dispose();
    _offsetFocus.dispose();
    _widthCtrl.dispose();
    _offsetCtrl.dispose();
    super.dispose();
  }

  void _onFocus(FocusNode node, TextEditingController ctrl) {
    if (node.hasFocus && ctrl.text.isNotEmpty) {
      ctrl.selection = TextSelection(baseOffset: 0, extentOffset: ctrl.text.length);
    }
  }

  void _submit({bool delete = false}) {
    if (delete) {
      Navigator.of(context).pop(null);
      return;
    }

    final wallLen = doorWallLength(widget.data, widget.door.wall);
    final w = double.tryParse(_widthCtrl.text);
    final off = double.tryParse(_offsetCtrl.text);

    if (w == null || w <= 0) {
      _err('请输入有效门长');
      return;
    }
    if (off == null || off < 0) {
      _err('请输入有效距墙距离');
      return;
    }
    if (w < 30) {
      _err('门长不能小于 30 cm');
      return;
    }
    if (w > wallLen) {
      _err('门长不能大于当前墙长（${wallLen.round()} cm）');
      return;
    }
    if (off > wallLen - w) {
      _err('距墙距离超出范围（最大 ${(wallLen - w).round()} cm）');
      return;
    }

    Navigator.of(context).pop(widget.door.copyWith(
      widthCm: w,
      offsetCm: off,
    ));
  }

  void _err(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final wallLen = doorWallLength(widget.data, widget.door.wall);
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: const BoxDecoration(
          color: Color(0xFFF7F0DF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFBCAA8A),
                borderRadius: BorderRadius.circular(2),
              ),
            )),
            const SizedBox(height: 14),
            const Text('编辑入户门',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textTitle)),
            const SizedBox(height: 4),
            Text('所在边：${_wallLabels[widget.door.wall] ?? widget.door.wall} | 墙长：${wallLen.round()} cm',
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _buildField('门长 (cm)', _widthCtrl, _widthFocus, '90')),
                const SizedBox(width: 12),
                Expanded(child: _buildField('距墙距离 (cm)', _offsetCtrl, _offsetFocus, '0')),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text('门长 30~${wallLen.round()} | 距墙 0~${(wallLen - widget.door.widthCm).round()}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.hintText)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _submit(delete: true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFC62828),
                      side: const BorderSide(color: Color(0xFFC62828)),
                    ),
                    child: const Text('删除门'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () => _submit(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF5A4724),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('确认', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, FocusNode focus, String hint) {
    return TextField(
      controller: ctrl,
      focusNode: focus,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.cardBorder),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}
