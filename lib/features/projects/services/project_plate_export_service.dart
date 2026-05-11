import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ProjectPlateExportResult {
  final bool success;
  final String message;

  const ProjectPlateExportResult({
    required this.success,
    required this.message,
  });
}

class ProjectPlateExportService {
  /// Remove export temp files older than 24 hours.
  static Future<void> cleanupOldExportFiles() async {
    try {
      final dir = await getTemporaryDirectory();
      final exportDir = Directory('${dir.path}/plate_exports');
      if (!await exportDir.exists()) return;
      final now = DateTime.now();
      await for (final entity in exportDir.list()) {
        if (entity is File) {
          try {
            final stat = await entity.stat();
            if (now.difference(stat.modified).inHours >= 24) {
              await entity.delete();
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  /// Capture the RepaintBoundary and return raw PNG bytes.
  static Future<Uint8List?> captureBytes({
    required GlobalKey repaintKey,
  }) async {
    try {
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e, st) {
      debugPrint('captureBytes failed: $e\n$st');
      return null;
    }
  }

  /// Save PNG bytes to a temp file, insert into gallery, then delete the file.
  static Future<ProjectPlateExportResult> saveToGallery(
    Uint8List bytes, {
    required String fileName,
  }) async {
    File? file;
    try {
      await cleanupOldExportFiles();
      final dir = await getTemporaryDirectory();
      final exportDir = Directory('${dir.path}/plate_exports');
      if (!await exportDir.exists()) await exportDir.create();
      file = File('${exportDir.path}/$fileName.png');
      await file.writeAsBytes(bytes);

      await Gal.putImage(file.path);
      return const ProjectPlateExportResult(
        success: true,
        message: '正盘图片已保存到相册',
      );
    } catch (e, st) {
      debugPrint('saveToGallery failed: $e\n$st');
      return const ProjectPlateExportResult(
        success: false,
        message: '保存失败，请检查相册权限',
      );
    } finally {
      if (file != null && await file.exists()) {
        try {
          await file.delete();
        } catch (e) {
          debugPrint('delete temp file failed: $e');
        }
      }
    }
  }

  /// Save PNG bytes to a temp file, share via system sheet.
  /// Temp file kept for sharing, cleaned up via cleanupOldExportFiles later.
  static Future<ProjectPlateExportResult> shareImage(
    Uint8List bytes, {
    required String fileName,
  }) async {
    File? file;
    try {
      await cleanupOldExportFiles();
      final dir = await getTemporaryDirectory();
      final exportDir = Directory('${dir.path}/plate_exports');
      if (!await exportDir.exists()) await exportDir.create();
      file = File('${exportDir.path}/$fileName.png');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '风水荷盘 · ${fileName.replaceAll('_', ' ')}',
      );
      return const ProjectPlateExportResult(
        success: true,
        message: '已打开分享面板',
      );
    } catch (e, st) {
      debugPrint('shareImage failed: $e\n$st');
      return const ProjectPlateExportResult(
        success: false,
        message: '分享失败，请稍后重试',
      );
    }
  }
}
