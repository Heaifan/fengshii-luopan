import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../data/models/floor_plan_data.dart';
import '../math/mountain_parser.dart';

/// 坐向设置面板（仅选择坐山，向首自动生成）
Future<FloorPlanData?> showFloorPlanDirectionPanel({
  required BuildContext context,
  required FloorPlanData existing,
}) {
  return showModalBottomSheet<FloorPlanData>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _DirectionPanel(existing: existing),
  );
}

class _DirectionPanel extends StatefulWidget {
  final FloorPlanData existing;
  const _DirectionPanel({required this.existing});

  @override
  State<_DirectionPanel> createState() => _DirectionPanelState();
}

class _DirectionPanelState extends State<_DirectionPanel> {
  int _selectedIdx = -1;
  String _currentLabel = '';

  @override
  void initState() {
    super.initState();
    _currentLabel = sittingFacingLabel(widget.existing);
    if (widget.existing.sittingMountain != null) {
      _selectedIdx = kMountains24.indexOf(widget.existing.sittingMountain!);
    } else {
      // 默认子山午向 (子 = index 0)
      _selectedIdx = 0;
    }
  }

  String get _sitting => _selectedIdx >= 0 ? kMountains24[_selectedIdx] : '';
  String get _facing =>
      _selectedIdx >= 0 ? kMountains24[(_selectedIdx + 12) % 24] : '';
  String get _label => _sitting.isNotEmpty ? '${_sitting}山${_facing}向' : '';

  void _confirm() {
    if (_selectedIdx < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择一个坐山')),
      );
      return;
    }
    Navigator.of(context).pop(widget.existing.copyWith(
      sittingMountain: _sitting,
      facingMountain: _facing,
    ));
  }

  void _clear() {
    Navigator.of(context).pop(widget.existing.copyWith(
      clearDirection: true,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final screenH = MediaQuery.of(context).size.height;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: screenH * 0.65),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: const BoxDecoration(
          color: Color(0xFFF7F0DF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFBCAA8A),
                borderRadius: BorderRadius.circular(2),
              ),
            )),
            const SizedBox(height: 14),
            const Text('设置坐向',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textTitle)),
            const SizedBox(height: 4),
            Text('当前：$_currentLabel',
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            Text('坐山：$_sitting',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textTitle)),
            const SizedBox(height: 2),
            Text('自动生成：$_label',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF5A4724))),
            const SizedBox(height: 12),
            const Text('选择坐山（向首自动生成）：',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: kMountains24.length,
                itemBuilder: (context, i) {
                  final sel = _selectedIdx == i;
                  final m = kMountains24[i];
                  final facing = kMountains24[(i + 12) % 24];
                  final c = color3Value(kSanyuanColor[m] ?? Color3.red);
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIdx = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: sel ? const Color(0xFF5A4724) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: sel ? const Color(0xFF5A4724) : AppTheme.cardBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(m,
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700,
                                  color: sel ? Colors.white : Color(c))),
                          Text('山', style: TextStyle(
                              fontSize: 13,
                              color: sel ? Colors.white70 : AppTheme.textSecondary)),
                          const SizedBox(width: 4),
                          Text(facing,
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700,
                                  color: sel
                                      ? Colors.white
                                      : Color(color3Value(
                                          kSanyuanColor[facing] ?? Color3.red)))),
                          Text('向', style: TextStyle(
                              fontSize: 13,
                              color: sel ? Colors.white70 : AppTheme.textSecondary)),
                          const Spacer(),
                          if (sel)
                            const Icon(Icons.check, color: Colors.white, size: 18)
                          else
                            Text('${(i + 1) % 24}',
                                style: const TextStyle(fontSize: 11, color: AppTheme.hintText)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clear,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5A4724),
                      side: const BorderSide(color: Color(0xFF5A4724)),
                    ),
                    child: const Text('清除坐向'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _confirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF5A4724),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('确认坐向', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
