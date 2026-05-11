import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/compass_record.dart';
import '../../data/storage/settings_storage.dart';

class CompassRecordDetailPage extends StatelessWidget {
  final CompassRecord record;

  const CompassRecordDetailPage({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final timeStr =
        DateFormat('yyyy-MM-dd HH:mm').format(record.createdAt);
    final isAuspicious = !record.bazhaiText.contains('凶');

    return Scaffold(
      backgroundColor: const Color(0xFFD8D6CF),
      appBar: AppBar(
        title: const Text('记录详情'),
        centerTitle: true,
        backgroundColor: const Color(0xFFc8b898),
        foregroundColor: const Color(0xFF333333),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // ---- A: Core direction card ----
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8EED8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFB99A61)),
              ),
              child: Column(
                children: [
                  Text(record.directionText,
                      style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2A2118))),
                  const SizedBox(height: 4),
                  Text(record.sittingFacingText,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5A4724))),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ---- B: Compass info card ----
            _buildInfoCard(context, '罗盘信息', [
              _row('宫位', record.palace),
              _row('向山', record.mountainText),
              _row('八宅', record.bazhaiText,
                  valueColor: isAuspicious
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFC43C32)),
              _row('状态', record.statusText),
              _row('宅卦', '${record.houseGua}宅'),
            ]),
            const SizedBox(height: 12),

            // ---- C: Record info card ----
            _buildInfoCard(context, '记录信息', [
              _row('名称', record.name),
              if (record.location != null && record.location!.isNotEmpty)
                _row('地点', record.location!),
              if (record.note != null && record.note!.isNotEmpty)
                _row('备注', record.note!),
              _row('时间', timeStr),
            ]),
            const SizedBox(height: 20),

            // ---- Delete button ----
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmDelete(context),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('删除记录'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFC43C32),
                  side: const BorderSide(color: Color(0xFFC43C32)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      BuildContext context, String title, List<Widget> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8EED8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB99A61)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5A4724))),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF9A8A6A))),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? const Color(0xFF2A2118))),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除记录'),
        content: const Text('确定删除这条罗盘记录吗？\n删除后无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await SettingsStorage().deleteRecord(record.id);
              Navigator.pop(ctx);
              Navigator.pop(context, true);
            },
            child: const Text('删除',
                style: TextStyle(color: Color(0xFFC43C32))),
          ),
        ],
      ),
    );
  }
}
