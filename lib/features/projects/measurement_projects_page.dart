import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../data/models/measurement_project.dart';
import '../../data/storage/settings_storage.dart';
import 'measurement_project_detail_page.dart';
import 'new_measurement_project_page.dart';

class MeasurementProjectsPage extends StatefulWidget {
  const MeasurementProjectsPage({super.key});

  @override
  State<MeasurementProjectsPage> createState() =>
      _MeasurementProjectsPageState();
}

class _MeasurementProjectsPageState
    extends State<MeasurementProjectsPage> {
  final _storage = SettingsStorage();
  List<_ProjectWithCount> _projects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final projects = await _storage.loadProjects();
    final result = <_ProjectWithCount>[];
    for (final p in projects) {
      final points = await _storage.loadRecordsByProject(p.id);
      result.add(_ProjectWithCount(p, points.length));
    }
    if (!mounted) return;
    setState(() {
      _projects = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD8D6CF),
      appBar: AppBar(
        title: const Text('测量项目'),
        centerTitle: true,
        backgroundColor: const Color(0xFFc8b898),
        foregroundColor: const Color(0xFF333333),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新建项目',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const NewMeasurementProjectPage()),
              );
              await _loadProjects();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _projects.isEmpty
              ? _buildEmptyState()
              : _buildList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_open,
                size: 56, color: AppTheme.textHint),
            const SizedBox(height: 16),
            const Text('暂无测量项目',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            const Text('点击右上角 + 创建新项目，\n开始连续测量多个测点。',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const NewMeasurementProjectPage()),
                );
                await _loadProjects();
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('新建项目'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5A4724),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      itemCount: _projects.length,
      itemBuilder: (context, index) {
        final item = _projects[index];
        return _buildCard(item);
      },
    );
  }

  Widget _buildCard(_ProjectWithCount item) {
    final p = item.project;
    final timeStr =
        DateFormat('yyyy-MM-dd HH:mm').format(p.createdAt);
    final typeLabel = _typeName(p.type);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                MeasurementProjectDetailPage(project: p),
          ),
        );
        await _loadProjects();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F0DF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFF9A7A3D).withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF5A4724),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text('${item.pointCount}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text('$typeLabel · 已测 ${item.pointCount} 个点',
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary)),
                  const SizedBox(height: 2),
                  Text(timeStr,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppTheme.textHint),
          ],
        ),
      ),
    );
  }

  String _typeName(String type) {
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
}

class _ProjectWithCount {
  final MeasurementProject project;
  final int pointCount;
  const _ProjectWithCount(this.project, this.pointCount);
}
