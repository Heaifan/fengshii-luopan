import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../data/models/measurement_project.dart';

String _typeLabel(String type) {
  switch (type) {
    case 'residential': return '住宅';
    case 'shop': return '店铺';
    case 'office': return '办公室';
    default: return '其他';
  }
}

/// Sheet that lets the user pick an existing project or create a new one.
class ProjectPickerSheet extends StatelessWidget {
  final List<MeasurementProject> projects;
  final Future<MeasurementProject?> Function() onCreateProject;

  const ProjectPickerSheet({
    super.key,
    required this.projects,
    required this.onCreateProject,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36, height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD2B978).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '选择测量项目',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.titleText,
              ),
            ),
            const SizedBox(height: 12),
            // Project list
            ...projects.map((p) => _projectTile(context, p)),
            const SizedBox(height: 8),
            // Create new
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final created = await onCreateProject();
                  if (created != null && context.mounted) {
                    Navigator.pop(context, created);
                  }
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('新建项目'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF5A4724),
                  side: const BorderSide(color: Color(0xFF5A4724)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _projectTile(BuildContext context, MeasurementProject p) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF5A4724),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.home, color: Colors.white, size: 20),
      ),
      title: Text(
        p.name,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppTheme.bodyText,
        ),
      ),
      subtitle: Text(
        '${_typeLabel(p.type)} · 未设置测点',
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.subText,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18, color: AppTheme.hintText),
      onTap: () => Navigator.pop(context, p),
    );
  }
}
