import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme.dart';
import '../../../data/models/compass_record.dart';
import '../../../data/models/measure_type.dart';

class MeasurePointFormResult {
  final String measureType;
  final String measureName;
  final String spaceName;
  final String note;
  final bool delete;

  const MeasurePointFormResult({
    required this.measureType,
    required this.measureName,
    required this.spaceName,
    required this.note,
    this.delete = false,
  });
}

Future<MeasurePointFormResult?> showMeasurePointFormSheet({
  required BuildContext context,
  required CompassRecord initialRecord,
  bool allowDelete = true,
}) {
  return showModalBottomSheet<MeasurePointFormResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return _MeasurePointFormSheet(
        initialRecord: initialRecord,
        allowDelete: allowDelete,
      );
    },
  );
}

class _MeasurePointFormSheet extends StatefulWidget {
  final CompassRecord initialRecord;
  final bool allowDelete;

  const _MeasurePointFormSheet({
    required this.initialRecord,
    this.allowDelete = true,
  });

  @override
  State<_MeasurePointFormSheet> createState() =>
      _MeasurePointFormSheetState();
}

class _MeasurePointFormSheetState
    extends State<_MeasurePointFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _spaceCtrl;
  late final TextEditingController _noteCtrl;
  late String _measureType;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
        text: widget.initialRecord.measureName ?? '');
    _spaceCtrl = TextEditingController(
        text: widget.initialRecord.spaceName ?? '');
    _noteCtrl = TextEditingController(
        text: widget.initialRecord.note ?? '');
    _measureType = widget.initialRecord.measureType;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _spaceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Color _chipBg(bool selected) =>
      selected ? const Color(0xFF4A3A12) : const Color(0xFFFFFBF0);
  Color _chipFg(bool selected) =>
      selected ? const Color(0xFFFFF4D6) : AppTheme.textPrimary;
  Color _chipBorder(bool selected) =>
      selected ? const Color(0xFF4A3A12) : AppTheme.cardBorder;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        top: false,
        child: FractionallySizedBox(
          heightFactor: bottom > 0 ? 0.92 : 0.72,
          child: Container(
            decoration: const BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // drag handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD2B978)
                            .withValues(alpha: 0.6),
                        borderRadius:
                            BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '编辑测点',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textTitle,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // type chips
                  const Text('测点类型',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textLabel)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: MeasureTypes.all.map((t) {
                      final selected =
                          t == _measureType;
                      return ChoiceChip(
                        label: Text(
                            MeasureTypes.label(t),
                            style: TextStyle(
                                fontSize: 13,
                                color:
                                    _chipFg(selected),
                                fontWeight: FontWeight.w600)),
                        selected: selected,
                        selectedColor: _chipBg(true),
                        backgroundColor: _chipBg(false),
                        side: BorderSide(
                            color:
                                _chipBorder(selected)),
                        visualDensity:
                            VisualDensity.compact,
                        onSelected: (_) {
                          setState(
                              () => _measureType = t);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // name
                  const Text('测点名称',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textLabel)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameCtrl,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(20),
                    ],
                    decoration: _inputDeco('例如：电冰箱'),
                    style: const TextStyle(
                        fontSize: 15,
                        color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 14),

                  // space
                  const Text('空间/位置',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textLabel)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _spaceCtrl,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(30),
                    ],
                    decoration: _inputDeco('例如：客厅'),
                    style: const TextStyle(
                        fontSize: 15,
                        color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 14),

                  // note
                  const Text('备注',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textLabel)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _noteCtrl,
                    maxLines: 2,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(100),
                    ],
                    decoration: _inputDeco('可选'),
                    style: const TextStyle(
                        fontSize: 15,
                        color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 24),

                  // buttons
                  Row(
                    children: [
                      if (widget.allowDelete)
                        TextButton(
                          onPressed: () async {
                            final confirmed =
                                await showDialog<bool>(
                              context: context,
                              builder: (ctx) {
                                return AlertDialog(
                                  title: const Text(
                                      '删除测点？'),
                                  content: const Text(
                                      '删除后无法恢复。'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(
                                              ctx, false),
                                      child:
                                          const Text('取消'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(
                                              ctx, true),
                                      style: TextButton
                                          .styleFrom(
                                        foregroundColor:
                                            const Color(
                                                0xFFA13A2A),
                                      ),
                                      child: const Text(
                                          '删除'),
                                    ),
                                  ],
                                );
                              },
                            );
                            if (confirmed != true) return;
                            Navigator.pop(
                              context,
                              const MeasurePointFormResult(
                                measureType: 'other',
                                measureName: '',
                                spaceName: '',
                                note: '',
                                delete: true,
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor:
                                const Color(0xFFA13A2A),
                          ),
                          child:
                              const Text('删除测点'),
                        ),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: () =>
                            Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              const Color(0xFF5A4724),
                          side: const BorderSide(
                              color: Color(0xFF5A4724)),
                        ),
                        child: const Text('取消'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            MeasurePointFormResult(
                              measureType: _measureType,
                              measureName:
                                  _nameCtrl.text.trim(),
                              spaceName:
                                  _spaceCtrl.text.trim(),
                              note: _noteCtrl.text.trim(),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF4A3A12),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('保存'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
          color: AppTheme.textHint, fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFFFFBF0),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppTheme.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppTheme.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
            color: Color(0xFFC8922E), width: 1.4),
      ),
    );
  }
}
