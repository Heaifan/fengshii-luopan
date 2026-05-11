import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // drag handle
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '编辑测点',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textTitle,
            ),
          ),
          const SizedBox(height: 14),

          // type chips
          const Text('测点类型',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textLabel)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: MeasureTypes.all.map((t) {
              final selected = t == _measureType;
              return ChoiceChip(
                label: Text(MeasureTypes.label(t),
                    style: TextStyle(
                        fontSize: 13,
                        color: selected
                            ? Colors.white
                            : AppTheme.textPrimary)),
                selected: selected,
                selectedColor: const Color(0xFF5A4724),
                backgroundColor: const Color(0xFFF0E8D5),
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
                onSelected: (_) {
                  setState(() {
                    _measureType = t;
                    //
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // name
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: '测点名称',
              hintText: '例如：电冰箱',
              filled: true,
              fillColor: Color(0xFFFFF8ED),
              border: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: AppTheme.cardBorder)),
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            style: const TextStyle(
                fontSize: 15, color: AppTheme.textPrimary),
            onChanged: (_) {},
          ),
          const SizedBox(height: 10),

          // space
          TextField(
            controller: _spaceCtrl,
            decoration: const InputDecoration(
              labelText: '空间/位置',
              hintText: '例如：客厅',
              filled: true,
              fillColor: Color(0xFFFFF8ED),
              border: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: AppTheme.cardBorder)),
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            style: const TextStyle(
                fontSize: 15, color: AppTheme.textPrimary),
            onChanged: (_) {},
          ),
          const SizedBox(height: 10),

          // note
          TextField(
            controller: _noteCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: '备注',
              hintText: '可选',
              filled: true,
              fillColor: Color(0xFFFFF8ED),
              border: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: AppTheme.cardBorder)),
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            style: const TextStyle(
                fontSize: 15, color: AppTheme.textPrimary),
            onChanged: (_) {},
          ),
          const SizedBox(height: 16),

          // buttons
          Row(
            children: [
              if (widget.allowDelete)
                TextButton(
                  onPressed: () {
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
                    foregroundColor: const Color(0xFFA13A2A),
                  ),
                  child: const Text('删除测点'),
                ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    MeasurePointFormResult(
                      measureType: _measureType,
                      measureName: _nameCtrl.text.trim(),
                      spaceName: _spaceCtrl.text.trim(),
                      note: _noteCtrl.text.trim(),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF5A4724),
                ),
                child: const Text('保存'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
