import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ProjectPlateExportService {
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
    } catch (_) {
      return null;
    }
  }

  /// Save PNG bytes directly to the device gallery.
  static Future<bool> saveToGallery(Uint8List bytes,
      {required String fileName}) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName.png');
      await file.writeAsBytes(bytes);

      await Gal.putImage(file.path);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Save PNG to a temp file and trigger the system share sheet.
  static Future<bool> shareImage(Uint8List bytes,
      {required String fileName}) async {
    try {
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
