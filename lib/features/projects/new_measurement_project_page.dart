import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/models/measurement_project.dart';
import '../../data/storage/settings_storage.dart';
import '../compass/compass_page.dart';

const _projectTypes = ['residential', 'shop', 'office', 'other'];

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

class NewMeasurementProjectPage extends StatefulWidget {
  const NewMeasurementProjectPage({super.key});

  @override
  State<NewMeasurementProjectPage> createState() =>
      _NewMeasurementProjectPageState();
}

class _NewMeasurementProjectPageState
    extends State<NewMeasurementProjectPage> {
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _type = 'residential';
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _startMeasurement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final project = MeasurementProject.create(
      name: _nameCtrl.text.trim(),
      type: _type,
      location: _locationCtrl.text.trim().isEmpty
          ? null
          : _locationCtrl.text.trim(),
      note:
          _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );

    await SettingsStorage().addProject(project);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CompassPage(activeProject: project),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD8D6CF),
      appBar: AppBar(
        title: const Text('新建测量项目'),
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
              // ---- Name ----
              const Text('项目名称 *',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textLabel)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _nameCtrl,
                autofocus: true,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  hintText: '例如：A小区 3栋1201',
                  hintStyle: TextStyle(
                      color: AppTheme.textHint,
                      fontSize: 15,
                      fontWeight: FontWeight.w500),
                  filled: true,
                  fillColor: Color(0xFFFFF8ED),
                  border: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: AppTheme.cardBorder)),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请输入项目名称' : null,
              ),
              const SizedBox(height: 16),

              // ---- Type ----
              const Text('项目类型',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textLabel)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _projectTypes.map((t) {
                  final selected = t == _type;
                  return ChoiceChip(
                    label: Text(_typeLabel(t),
                        style: TextStyle(
                            fontSize: 14,
                            color: selected
                                ? Colors.white
                                : AppTheme.textPrimary)),
                    selected: selected,
                    selectedColor: const Color(0xFF5A4724),
                    backgroundColor: const Color(0xFFF0E8D5),
                    side: BorderSide(
                        color: selected
                            ? const Color(0xFF5A4724)
                            : AppTheme.cardBorder),
                    onSelected: (_) => setState(() => _type = t),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // ---- Location ----
              const Text('地点（可选）',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textLabel)),
              const SizedBox(height: 4),
              TextField(
                controller: _locationCtrl,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  hintText: '例如：XX小区',
                  hintStyle: TextStyle(
                      color: AppTheme.textHint,
                      fontSize: 15,
                      fontWeight: FontWeight.w500),
                  filled: true,
                  fillColor: Color(0xFFFFF8ED),
                  border: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: AppTheme.cardBorder)),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 16),

              // ---- Note ----
              const Text('备注（可选）',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textLabel)),
              const SizedBox(height: 4),
              TextField(
                controller: _noteCtrl,
                maxLines: 2,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  hintText: '例如：空房初看，只测门和阳台',
                  hintStyle: TextStyle(
                      color: AppTheme.textHint,
                      fontSize: 15,
                      fontWeight: FontWeight.w500),
                  filled: true,
                  fillColor: Color(0xFFFFF8ED),
                  border: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: AppTheme.cardBorder)),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 24),

              // ---- Start button ----
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _startMeasurement,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.play_arrow, size: 20),
                  label: Text(_saving ? '创建中...' : '开始测量',
                      style: const TextStyle(fontSize: 16)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF5A4724),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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
