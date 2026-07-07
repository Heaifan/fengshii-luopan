import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme.dart';
import '../../../data/models/floor_plan_data.dart';

/// 宅盘尺寸设置面板（底部弹出）
Future<FloorPlanData?> showFloorPlanSizePanel({
  required BuildContext context,
  required FloorPlanData? existing,
}) {
  return showModalBottomSheet<FloorPlanData>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _FloorPlanSizePanel(existing: existing),
  );
}

class _FloorPlanSizePanel extends StatefulWidget {
  final FloorPlanData? existing;
  const _FloorPlanSizePanel({this.existing});

  @override
  State<_FloorPlanSizePanel> createState() => _FloorPlanSizePanelState();
}

class _FloorPlanSizePanelState extends State<_FloorPlanSizePanel> {
  late final TextEditingController _widthCtrl;
  late final TextEditingController _heightCtrl;
  late final FocusNode _widthFocus;
  late final FocusNode _heightFocus;
  double _widthCm = 720;
  double _heightCm = 980;

  @override
  void initState() {
    super.initState();
    _widthCm = widget.existing?.widthCm ?? 720;
    _heightCm = widget.existing?.heightCm ?? 980;
    _widthCtrl = TextEditingController(text: _widthCm.round().toString());
    _heightCtrl = TextEditingController(text: _heightCm.round().toString());
    _widthFocus = FocusNode();
    _heightFocus = FocusNode();
    _widthFocus.addListener(_onWidthFocusChange);
    _heightFocus.addListener(_onHeightFocusChange);
  }

  @override
  void dispose() {
    _widthFocus.removeListener(_onWidthFocusChange);
    _heightFocus.removeListener(_onHeightFocusChange);
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    _widthFocus.dispose();
    _heightFocus.dispose();
    super.dispose();
  }

  void _onWidthFocusChange() {
    if (_widthFocus.hasFocus) {
      _selectAll(_widthCtrl);
    }
  }

  void _onHeightFocusChange() {
    if (_heightFocus.hasFocus) {
      _selectAll(_heightCtrl);
    }
  }

  void _selectAll(TextEditingController ctrl) {
    if (ctrl.text.isNotEmpty) {
      ctrl.selection = TextSelection(
        baseOffset: 0,
        extentOffset: ctrl.text.length,
      );
    }
  }

  String? _validate(double? val, String label) {
    if (val == null || val <= 0) {
      return '$label 不能为空或零';
    }
    if (val < 100) {
      return '$label 不能小于 100 cm';
    }
    if (val > 5000) {
      return '$label 不能大于 5000 cm';
    }
    return null;
  }

  void _submit() {
    final w = double.tryParse(_widthCtrl.text);
    final h = double.tryParse(_heightCtrl.text);

    final errW = _validate(w, '宽度');
    final errH = _validate(h, '高度');

    if (errW != null || errH != null) {
      final msg = [errW, errH].whereType<String>().join('；');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
      return;
    }

    Navigator.of(context).pop(FloorPlanData(
      widthCm: w!,
      heightCm: h!,
      gridMode: widget.existing?.gridMode ?? 'grid4',
      overlays: widget.existing?.overlays ?? const FloorPlanOverlays(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFBCAA8A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text('宅盘尺寸',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textTitle)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildField('宽度 (cm)', _widthCtrl, _widthFocus, '720')),
                const SizedBox(width: 12),
                Expanded(child: _buildField('高度 (cm)', _heightCtrl, _heightFocus, '980')),
              ],
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text('范围：100 ~ 5000 cm', style: TextStyle(fontSize: 11, color: AppTheme.hintText)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF5A4724),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('确认尺寸', style: TextStyle(fontSize: 16)),
              ),
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
