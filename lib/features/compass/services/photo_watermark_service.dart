import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart' as painting;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

/// Add measurement watermark to a captured photo.
class PhotoWatermarkService {
  static Future<String?> addWatermark({
    required String sourcePath,
    required String headingText,
    required String palaceText,
    required String sittingFacingText,
    required String facingMountainText,
    required String sittingMountainText,
    required String projectName,
    required String pointLabel,
    required String? pointName,
    required String bazhaiText,
    required DateTime takenAt,
    required double? magneticField,
    required double pitch,
    required double roll,
    bool deleteSource = true,
  }) async {
    try {
      final file = File(sourcePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final ui.Image image = await painting.decodeImageFromList(bytes);

      final width = image.width;
      final height = image.height;

      final barHeight = (height * 0.28).round().clamp(120, 320);
      final barRect = Rect.fromLTWH(
        0,
        (height - barHeight).toDouble(),
        width.toDouble(),
        barHeight.toDouble(),
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      );

      // Draw original image
      canvas.drawImage(image, Offset.zero, Paint());

      // Semi-transparent black bar
      canvas.drawRect(barRect, Paint()..color = const Color(0x8C000000));

      // Font sizes relative to image width — enlarged for readability
      final headingSize = (width * 0.08).clamp(24.0, 52.0);
      final normalSize = (width * 0.05).clamp(18.0, 34.0);
      final smallSize = (width * 0.04).clamp(15.0, 26.0);

      final padding = (width * 0.05).round().clamp(12, 28);

      // Build text
      final nameStr = pointName != null && pointName.isNotEmpty
          ? '$projectName · $pointLabel · $pointName'
          : '$projectName · $pointLabel';
      final timeStr = DateFormat('MM-dd HH:mm').format(takenAt);
      final magStr =
          magneticField != null ? '${magneticField.toStringAsFixed(0)}μT' : '未记录';
      final tiltQuality = (pitch.abs() + roll.abs()) / 2;
      final tiltStr = tiltQuality < 15
          ? '良好'
          : tiltQuality < 30
              ? '偏斜'
              : '偏差大';

      final yStart = (height - barHeight + padding).toDouble();
      final maxW = (width - padding * 2).toDouble();

      // Line 1: heading | palace | sitting-facing
      _drawText(canvas, '$headingText｜$palaceText｜$sittingFacingText',
          padding.toDouble(), yStart, headingSize, Colors.white, FontWeight.w900, maxW);

      final y2 = yStart + headingSize * 1.3;
      _drawText(canvas, '$nameStr｜$timeStr',
          padding.toDouble(), y2, normalSize, Colors.white70, FontWeight.w600, maxW);

      final y3 = y2 + normalSize * 1.4;
      final bazhaiIsPending = bazhaiText.contains('待定');
      final bazhaiColor = bazhaiIsPending ? const Color(0xFFFFD54F) : Colors.white;
      _drawText(canvas, bazhaiIsPending ? '八宅：待定' : '八宅：$bazhaiText',
          padding.toDouble(), y3, normalSize, bazhaiColor, FontWeight.w700, maxW);

      final y4 = y3 + normalSize * 1.4;
      _drawText(canvas, '磁场：$magStr｜姿态：$tiltStr',
          padding.toDouble(), y4, smallSize, Colors.white60, FontWeight.w500, maxW);

      final y5 = y4 + smallSize * 1.4;
      _drawText(canvas, '向$facingMountainText｜坐$sittingMountainText',
          padding.toDouble(), y5, smallSize, Colors.white60, FontWeight.w500, maxW);

      // Render
      final picture = recorder.endRecording();
      final finalImage = await picture.toImage(width, height);
      final byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      // Output
      final now = DateTime.now();
      final photoDir = await getApplicationDocumentsDirectory();
      final photoSubDir = Directory('${photoDir.path}/project_photos');
      if (!await photoSubDir.exists()) {
        await photoSubDir.create(recursive: true);
      }
      final outputPath =
          '${photoSubDir.path}/wm_${now.millisecondsSinceEpoch}.png';
      await File(outputPath).writeAsBytes(byteData.buffer.asUint8List());

      // Cleanup source
      if (deleteSource) {
        try { await file.delete(); } catch (_) {}
      }

      return outputPath;
    } catch (e) {
      debugPrint('PhotoWatermarkService error: $e');
      return null;
    }
  }

  static void _drawText(
    Canvas canvas,
    String text,
    double x,
    double y,
    double fontSize,
    Color color,
    FontWeight fontWeight,
    double maxWidth,
  ) {
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    ));

    builder.pushStyle(ui.TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
    ));

    builder.addText(text);

    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: maxWidth));
    canvas.drawParagraph(paragraph, Offset(x, y));
  }
}
