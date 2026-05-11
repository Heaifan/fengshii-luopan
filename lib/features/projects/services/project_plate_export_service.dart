import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ProjectPlateExportService {
  static Future<bool> captureAndShare({
    required GlobalKey repaintKey,
    required String fileName,
  }) async {
    try {
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return false;

      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return false;

      final bytes = byteData.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName.png');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '风水荷盘 · ${fileName.replaceAll('_', ' ')}',
      );

      return true;
    } catch (_) {
      return false;
    }
  }
}
