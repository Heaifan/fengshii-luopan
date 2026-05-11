import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/compass_record.dart';
import '../../data/storage/settings_storage.dart';
import 'compass_record_detail_page.dart';

class CompassRecordsPage extends StatefulWidget {
  const CompassRecordsPage({super.key});

  @override
  State<CompassRecordsPage> createState() => _CompassRecordsPageState();
}

class _CompassRecordsPageState extends State<CompassRecordsPage> {
  final _storage = SettingsStorage();
  List<CompassRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final records = await _storage.loadRecords();
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (!mounted) return;
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD8D6CF),
      appBar: AppBar(
        title: const Text('罗盘记录'),
        centerTitle: true,
        backgroundColor: const Color(0xFFc8b898),
        foregroundColor: const Color(0xFF333333),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
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
            const Icon(Icons.history, size: 56, color: Color(0xFFB99A61)),
            const SizedBox(height: 16),
            const Text('暂无罗盘记录',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2A2118))),
            const SizedBox(height: 8),
            const Text(
              '锁定罗盘后点击"保存罗盘"，\n即可保存看房、店铺、办公室等测量结果。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF9A8A6A)),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF5A4724),
                side: const BorderSide(color: Color(0xFFB99A61)),
              ),
              child: const Text('返回测量'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      itemCount: _records.length,
      itemBuilder: (context, index) {
        final record = _records[index];
        return _buildCard(record);
      },
    );
  }

  Widget _buildCard(CompassRecord record) {
    final timeStr =
        DateFormat('yyyy-MM-dd HH:mm').format(record.createdAt);
    final isAuspicious = !record.bazhaiText.contains('凶');

    return GestureDetector(
      onTap: () async {
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => CompassRecordDetailPage(record: record),
          ),
        );
        if (changed == true) {
          await _loadRecords();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F0DF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x33A58A4A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: name
            Text(record.name,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2A2118))),
            const SizedBox(height: 6),
            // Row 2: direction + sitting-facing
            Row(
              children: [
                Text(record.directionText,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5A4724))),
                const SizedBox(width: 8),
                Text('· ${record.sittingFacingText}',
                    style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7A6040))),
              ],
            ),
            const SizedBox(height: 4),
            // Row 3: palace / bazhai
            Text('${record.palace} · ${record.bazhaiText}',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isAuspicious
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFC43C32))),
            const SizedBox(height: 4),
            // Row 4: time
            Text(timeStr,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF9A8A6A))),
            if (record.note != null && record.note!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(record.note!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF9A8A6A))),
            ],
          ],
        ),
      ),
    );
  }
}
