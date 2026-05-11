import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../data/models/compass_record.dart';
import '../../data/storage/settings_storage.dart';
import '../compass/luopan_dial.dart';
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
            const Icon(Icons.history, size: 56, color: AppTheme.textHint),
            const SizedBox(height: 16),
            const Text('暂无罗盘记录',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            const Text(
              '锁定罗盘后点击"保存罗盘"，\n即可保存看房、店铺、办公室等测量结果。',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF5A4724),
                side: const BorderSide(color: AppTheme.cardBorder),
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F0DF),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: const Color(0xFF9A7A3D).withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            // Thumbnail compass
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                color: AppTheme.cardBg,
                width: 58,
                height: 58,
                child: LuopanDial(
                  heading: record.heading,
                  houseGua: record.houseGua,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Text info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.name,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(record.directionText,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textTitle)),
                      const SizedBox(width: 6),
                      Text('· ${record.sittingFacingText}',
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('${record.palace} · ${record.bazhaiText}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isAuspicious
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFC43C32))),
                  const SizedBox(height: 2),
                  Text(timeStr,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary)),
                  if (record.note != null && record.note!.isNotEmpty)
                    Text(record.note!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
