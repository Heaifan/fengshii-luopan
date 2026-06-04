import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../data/models/measurement_project.dart';
import '../../data/storage/settings_storage.dart';

const _projectTypes = ['residential', 'shop', 'office', 'other'];
const _baZhaiModes = ['wholeHouse', 'doorPosition'];
const _guas = ['乾', '兑', '艮', '坤', '坎', '震', '巽', '离'];

String _typeLabel(String type) {
  switch (type) {
    case 'residential':
      return '住宅';
    case 'shop':
      return '店铺';
    case 'office':
      return '办公室';
    default:
      return '其他';
  }
}

String _baZhaiModeLabel(String mode) {
  return mode == 'doorPosition' ? '门位起伏位' : '整宅宅卦';
}

class EditProjectPage extends StatefulWidget {
  final MeasurementProject project;

  const EditProjectPage({super.key, required this.project});

  @override
  State<EditProjectPage> createState() => _EditProjectPageState();
}

class _EditProjectPageState extends State<EditProjectPage> {
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late String _type;
  late String _baZhaiMode;
  late String _baseGua;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.project.name;
    _locationCtrl.text = widget.project.location ?? '';
    _noteCtrl.text = widget.project.note ?? '';
    _type = widget.project.type;
    _baZhaiMode = widget.project.baZhaiMode;
    _baseGua = widget.project.basePalace ?? '乾';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final updated = MeasurementProject(
      id: widget.project.id,
      name: _nameCtrl.text.trim(),
      type: _type,
      location: _locationCtrl.text.trim().isEmpty
          ? null
          : _locationCtrl.text.trim(),
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      createdAt: widget.project.createdAt,
      updatedAt: DateTime.now(),
      baZhaiMode: _baZhaiMode,
      basePalace: _baZhaiMode == 'wholeHouse' ? _baseGua : null,
    );

    await SettingsStorage().updateProject(updated);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD8D6CF),
      appBar: AppBar(
        title: const Text('编辑项目'),
        centerTitle: true,
        backgroundColor: const Color(0xFFc8b898),
        foregroundColor: const Color(0xFF333333),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '项目名称 *',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textLabel,
                ),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _nameCtrl,
                inputFormatters: [LengthLimitingTextInputFormatter(30)],
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  hintText: '例如：A小区 3栋1201',
                  hintStyle: TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: Color(0xFFFFF8ED),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.cardBorder),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请输入项目名称' : null,
              ),
              const SizedBox(height: 16),

              const Text(
                '项目类型',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textLabel,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _projectTypes.map((t) {
                  final selected = t == _type;
                  return ChoiceChip(
                    label: Text(
                      _typeLabel(t),
                      style: TextStyle(
                        fontSize: 14,
                        color: selected ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    selected: selected,
                    selectedColor: const Color(0xFF5A4724),
                    backgroundColor: const Color(0xFFF0E8D5),
                    side: BorderSide(
                      color: selected
                          ? const Color(0xFF5A4724)
                          : AppTheme.cardBorder,
                    ),
                    onSelected: (_) => setState(() => _type = t),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              const Text(
                '八宅起法',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textLabel,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: _baZhaiModes.map((m) {
                  final selected = m == _baZhaiMode;
                  return ChoiceChip(
                    label: Text(
                      _baZhaiModeLabel(m),
                      style: TextStyle(
                        fontSize: 14,
                        color: selected ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    selected: selected,
                    selectedColor: const Color(0xFF5A4724),
                    backgroundColor: const Color(0xFFF0E8D5),
                    side: BorderSide(
                      color: selected
                          ? const Color(0xFF5A4724)
                          : AppTheme.cardBorder,
                    ),
                    onSelected: (_) => setState(() => _baZhaiMode = m),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              if (_baZhaiMode == 'wholeHouse') ...[
                const Text(
                  '宅卦',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textLabel,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _guas.map((g) {
                    final selected = g == _baseGua;
                    return ChoiceChip(
                      label: Text(
                        '$g宅',
                        style: TextStyle(
                          fontSize: 14,
                          color: selected ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      selected: selected,
                      selectedColor: const Color(0xFF5A4724),
                      backgroundColor: const Color(0xFFF0E8D5),
                      side: BorderSide(
                        color: selected
                            ? const Color(0xFF5A4724)
                            : AppTheme.cardBorder,
                      ),
                      onSelected: (_) => setState(() => _baseGua = g),
                    );
                  }).toList(),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8ED),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: const Text(
                    '伏位由项目中的"门"测点自动推导。\n修改门测点后伏位会自动更新。',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              const Text(
                '地点（可选）',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textLabel,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _locationCtrl,
                inputFormatters: [LengthLimitingTextInputFormatter(50)],
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  hintText: '例如：XX小区',
                  hintStyle: TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: Color(0xFFFFF8ED),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.cardBorder),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                '备注（可选）',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textLabel,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _noteCtrl,
                maxLines: 2,
                inputFormatters: [LengthLimitingTextInputFormatter(100)],
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  hintText: '例如：空房初看，只测门和阳台',
                  hintStyle: TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: Color(0xFFFFF8ED),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.cardBorder),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save, size: 20),
                  label: Text(
                    _saving ? '保存中...' : '保存',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF5A4724),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
