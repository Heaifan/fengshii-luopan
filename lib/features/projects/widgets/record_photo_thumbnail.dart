import 'dart:io';
import 'package:flutter/material.dart';
import '../../../app/theme.dart';

/// Small thumbnail for a record's photo, with tap-to-preview.
class RecordPhotoThumbnail extends StatelessWidget {
  final String? photoPath;
  final double size;

  const RecordPhotoThumbnail({
    super.key,
    required this.photoPath,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    if (photoPath == null || photoPath!.isEmpty) {
      return const SizedBox.shrink();
    }

    final file = File(photoPath!);
    if (!file.existsSync()) {
      return _missingPlaceholder();
    }

    return GestureDetector(
      onTap: () => _openPreview(context, file),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          file,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _missingPlaceholder(),
        ),
      ),
    );
  }

  Widget _missingPlaceholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFECECEC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_outlined, size: 16, color: AppTheme.hintText),
          SizedBox(height: 2),
          Text('缺失', style: TextStyle(fontSize: 9, color: AppTheme.hintText)),
        ],
      ),
    );
  }

  void _openPreview(BuildContext context, File file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PhotoPreviewPage(file: file),
      ),
    );
  }
}

/// Full-screen photo preview page.
class _PhotoPreviewPage extends StatelessWidget {
  final File file;

  const _PhotoPreviewPage({required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('现场照片'),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(
            file,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image, color: Colors.white54, size: 48),
                SizedBox(height: 8),
                Text('照片加载失败', style: TextStyle(color: Colors.white54)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
