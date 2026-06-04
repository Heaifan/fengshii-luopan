import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';
import '../../../data/models/compass_record.dart';
import '../../../fengshui/direction_sector.dart';
import '../../../fengshui/mountain_24.dart';
import '../../../fengshui/bazhai_you_nian_table.dart';
import '../../../fengshui/measure_type_meaning.dart';
import '../../../fengshui/palace_element_theme.dart';
import '../../../theme/app_svg_icons.dart';
import '../../../app/theme.dart';

class TiandirenPlatePainter extends CustomPainter {
  final List<CompassRecord> records;
  final String houseGua;
  final CompassRecord? selectedRecord;

  TiandirenPlatePainter({
    required this.records,
    required this.houseGua,
    this.selectedRecord,
  });

  // ---- layout constants ----
  static const _ringOuter = 0.97;
  static const _ringInner = 0.82;
  static const _mountainTextR = 0.92;
  static const _gridHalfSide = 0.62;

  // Traditional luopan: top=S (午), bottom=N (子), left=E (卯), right=W (酉)
  static const _gridLayout = [
    ['southEast', 'south', 'southWest'],
    ['east', 'center', 'west'],
    ['northEast', 'north', 'northWest'],
  ];

  static const _sectorToGua = {
    'north': '坎',
    'northEast': '艮',
    'east': '震',
    'southEast': '巽',
    'south': '离',
    'southWest': '坤',
    'west': '兑',
    'northWest': '乾',
  };

  static const _sectorLabel = {
    'north': '北',
    'northEast': '东北',
    'east': '东',
    'southEast': '东南',
    'south': '南',
    'southWest': '西南',
    'west': '西',
    'northWest': '西北',
  };

  static const _selectedGold = Color(0xFFC8922E);
  static const _auspiciousColor = Color(0xFF1E8E3E);
  static const _inauspiciousColor = Color(0xFFC62828);
  static const _textPrimary = Color(0xFF20160D);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final R = math.min(size.width, size.height) / 2;
    final s = R / 150;

    _drawBackground(canvas, center, R);
    _drawMountainRing(canvas, center, R, s);
    _drawPalaceGrid(canvas, center, R, s);
    _drawPointAnchors(canvas, center, R, s);
  }

  @override
  bool shouldRepaint(TiandirenPlatePainter oldDelegate) => true;

  /// Get the grid bounding rect (the 3×3 square).
  Rect _gridRect(Offset center, double R) {
    final halfSide = R * _gridHalfSide;
    return Rect.fromLTWH(
      center.dx - halfSide,
      center.dy - halfSide,
      halfSide * 2,
      halfSide * 2,
    );
  }

  // ============================================================
  // Background
  // ============================================================

  void _drawBackground(Canvas canvas, Offset center, double R) {
    canvas.drawCircle(
      center, R,
      Paint()..color = AppTheme.cardBg,
    );
    canvas.drawCircle(
      center, R,
      Paint()
        ..color = AppTheme.cardBorder.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  // ============================================================
  // Mountain ring - single char
  // ============================================================

  void _drawMountainRing(Canvas canvas, Offset center, double R, double s) {
    final outerR = R * _ringOuter;
    final innerR = R * _ringInner;

    final ringPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: outerR))
      ..addOval(Rect.fromCircle(center: center, radius: innerR))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(ringPath, Paint()..color = const Color(0xFFFFF6E3));

    String? selMountain;
    if (selectedRecord != null) {
      selMountain =
          DirectionSector.mountainFromHeading(selectedRecord!.heading);
    }

    for (int i = 0; i < 24; i++) {
      final mountain = Mountain24Calculator.mountains[i];
      final centerDeg = i * 15.0;
      final centerRad = (centerDeg + 90) * math.pi / 180;

      final startDeg = centerDeg - 7.5;
      final startRad = (startDeg + 90) * math.pi / 180;
      canvas.drawLine(
        center + Offset(math.cos(startRad) * innerR, math.sin(startRad) * innerR),
        center + Offset(math.cos(startRad) * outerR, math.sin(startRad) * outerR),
        Paint()
          ..color = const Color(0xFFD2B978).withValues(alpha: 0.25)
          ..strokeWidth = 0.5,
      );

      final textPos = center +
          Offset(math.cos(centerRad) * R * _mountainTextR,
              math.sin(centerRad) * R * _mountainTextR);

      final isSelected = mountain == selMountain;
      _drawText(
        canvas, mountain, textPos,
        isSelected ? 13 * s : 12 * s,
        isSelected ? FontWeight.w800 : FontWeight.w500,
        isSelected ? _selectedGold : const Color(0xFF4F351F),
      );
    }
  }

  // ============================================================
  // 3×3 palace grid (correct orientation)
  // ============================================================

  void _drawPalaceGrid(Canvas canvas, Offset center, double R, double s) {
    final halfSide = R * _gridHalfSide;
    final cellSize = 2 * halfSide / 3;

    String? selSector;
    if (selectedRecord != null) {
      selSector = DirectionSector.sector8FromHeading(selectedRecord!.heading);
    }

    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        final sector = _gridLayout[row][col];
        final left = center.dx - halfSide + col * cellSize;
        final top = center.dy - halfSide + row * cellSize;
        final cellRect = Rect.fromLTWH(left, top, cellSize, cellSize);

        final isSelected = selSector != null && sector == selSector;

        // Pure background color — no opacity stacking
        final element = PalaceElementTheme.elementForSector(sector);
        canvas.drawRect(cellRect, Paint()..color = PalaceElementTheme.colorForElement(element));

        if (isSelected) {
          canvas.drawRect(
            cellRect,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5
              ..color = _selectedGold,
          );
        }

        if (sector == 'center') {
          _drawCenteredText(canvas, '中宫', cellRect.center,
              15 * s, FontWeight.w800, _textPrimary);
        } else {
          final label = _sectorLabel[sector]!;
          final gua = _sectorToGua[sector]!;
          final star = getBazhaiStar(houseGua: houseGua, palaceGua: gua);
          final meta = bazhaiStarMetaMap[star];
          final isGood = meta?.isGood ?? false;
          final rank = getBazhaiStarRank(houseGua: houseGua, starName: star);
          final starLine = star.isNotEmpty ? '$star / $rank' : '';

          // direction name (top of cell)
          _drawCenteredText(
            canvas, label,
            Offset(cellRect.center.dx, cellRect.center.dy - cellSize * 0.20),
            14 * s, FontWeight.w800, _textPrimary,
          );

          // gua (middle)
          _drawCenteredText(
            canvas, gua,
            Offset(cellRect.center.dx, cellRect.center.dy - cellSize * 0.02),
            10 * s, FontWeight.w500, const Color(0xFF5F4630),
          );

          // star / rank (bottom)
          if (starLine.isNotEmpty) {
            _drawCenteredText(
              canvas, starLine,
              Offset(cellRect.center.dx, cellRect.center.dy + cellSize * 0.18),
              10 * s, FontWeight.w700,
              isGood ? _auspiciousColor : _inauspiciousColor,
            );
          }
        }
      }
    }

    // grid lines
    final linePaint = Paint()
      ..color = const Color(0xFFBFA05F).withValues(alpha: 0.35)
      ..strokeWidth = 1.0;

    for (int col = 1; col < 3; col++) {
      final x = center.dx - halfSide + col * cellSize;
      canvas.drawLine(Offset(x, center.dy - halfSide), Offset(x, center.dy + halfSide), linePaint);
    }
    for (int row = 1; row < 3; row++) {
      final y = center.dy - halfSide + row * cellSize;
      canvas.drawLine(Offset(center.dx - halfSide, y), Offset(center.dx + halfSide, y), linePaint);
    }
    canvas.drawRect(
      Rect.fromLTWH(center.dx - halfSide, center.dy - halfSide, halfSide * 2, halfSide * 2),
      linePaint,
    );
  }

  // ============================================================
  // Point anchors
  // ============================================================

  void _drawPointAnchors(Canvas canvas, Offset center, double R, double s) {
    final gridRect = _gridRect(center, R);

    for (final record in records) {
      final isSelected = selectedRecord?.id == record.id;
      final type = record.measureType;

      Offset pos;
      if (type == 'entranceDoor') {
        pos = _entranceDoorPosition(gridRect, center, record.heading);
      } else {
        pos = _pointPosition(record, center, R);
      }

      if (isSelected) {
        canvas.drawCircle(pos, 14 * s, Paint()
          ..color = _selectedGold.withValues(alpha: 0.5)
          ..style = PaintingStyle.fill);
        canvas.drawCircle(pos, 14 * s, Paint()
          ..color = _selectedGold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
      }

      if (type == 'entranceDoor' || type == 'roomDoor') {
        _drawSvgDoorIcon(canvas, pos, isSelected ? 10 * s : 8 * s, type);
      } else {
        final label = MeasureTypeMeaning.pointShortLabel(
          type: type, measureName: record.measureName,
        );
        canvas.drawCircle(pos, isSelected ? 10 * s : 8 * s, Paint()..color = AppTheme.pointTagBg);
        _drawCenteredText(canvas, label, pos, 10 * s, FontWeight.bold, Colors.white);
      }
    }
  }

  // ============================================================
  // Entrance door: ray → grid-edge intersection
  // ============================================================

  /// Compute the intersection point of the heading ray with the grid square,
  /// then push outward by a small margin so the icon sits just outside.
  Offset _entranceDoorPosition(Rect gridRect, Offset center, double heading) {
    // Plate angle: heading + 90° (same as _pointPosition)
    final theta = (heading + 90) * math.pi / 180;
    final dx = math.cos(theta);
    final dy = math.sin(theta);

    // t values for each of the 4 grid edges
    final tx = dx > 0
        ? (gridRect.right - center.dx) / dx
        : dx < 0
            ? (gridRect.left - center.dx) / dx
            : double.infinity;

    final ty = dy > 0
        ? (gridRect.bottom - center.dy) / dy
        : dy < 0
            ? (gridRect.top - center.dy) / dy
            : double.infinity;

    final t = math.min(tx.abs(), ty.abs());

    // Push outward by ~8% of half-side
    final outwardOffset = gridRect.width * 0.04;

    return Offset(
      center.dx + dx * (t + outwardOffset),
      center.dy + dy * (t + outwardOffset),
    );
  }

  // ============================================================
  // SVG door icon drawing via path_drawing
  // ============================================================

  void _drawSvgDoorIcon(Canvas canvas, Offset pos, double r, String type) {
    final isEntrance = type == 'entranceDoor';
    // Background circle — red for entrance, dark brown for room door
    canvas.drawCircle(pos, r, Paint()..color = isEntrance ? AppTheme.entranceDoorBg : AppTheme.roomDoorBg);

    final iconSize = r * 1.6;
    final iconRect = Rect.fromCenter(
      center: pos,
      width: iconSize,
      height: iconSize,
    );

    final paths = isEntrance
        ? AppSvgIcons.entranceDoorPaths
        : AppSvgIcons.roomDoorPaths;

    _drawSvgPaths(
      canvas: canvas,
      paths: paths,
      rect: iconRect,
      color: Colors.white, // Always white icon
    );
  }

  /// Draw a set of SVG path data into a given rect.
  void _drawSvgPaths({
    required Canvas canvas,
    required List<String> paths,
    required Rect rect,
    required Color color,
  }) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    canvas.save();

    final scale = math.min(rect.width / 1024.0, rect.height / 1024.0);
    final dx = rect.left + (rect.width - 1024 * scale) / 2;
    final dy = rect.top + (rect.height - 1024 * scale) / 2;

    canvas.translate(dx, dy);
    canvas.scale(scale);

    for (final data in paths) {
      final path = parseSvgPathData(data);
      canvas.drawPath(path, paint);
    }

    canvas.restore();
  }

  // ============================================================
  // Helpers
  // ============================================================

  double _radiusFactor(String type) {
    switch (type) {
      case 'door': return 0.48;
      // entranceDoor uses edge-intersection, not radius factor
      case 'roomDoor': return 0.44;
      case 'balcony': return 0.44;
      case 'window': return 0.40;
      case 'stove': return 0.36;
      case 'bed': return 0.30;
      case 'desk': return 0.26;
      case 'altar': return 0.32;
      default: return 0.36;
    }
  }

  Offset _pointPosition(CompassRecord record, Offset center, double R) {
    final rad = (record.heading + 90) * math.pi / 180;
    final r = R * _radiusFactor(record.measureType);
    return Offset(center.dx + math.cos(rad) * r, center.dy + math.sin(rad) * r);
  }

  void _drawText(Canvas canvas, String text, Offset pos, double size,
      FontWeight weight, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: size, fontWeight: weight, fontFamily: 'serif'),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawCenteredText(Canvas canvas, String text, Offset center, double size,
      FontWeight weight, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: size, fontWeight: weight, fontFamily: 'serif'),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  List<MapEntry<CompassRecord, Offset>> anchorPositions(
      Size size, List<CompassRecord> records) {
    final center = Offset(size.width / 2, size.height / 2);
    final R = math.min(size.width, size.height) / 2;
    final gridRect = _gridRect(center, R);
    return records.map((r) {
      final pos = r.measureType == 'entranceDoor'
          ? _entranceDoorPosition(gridRect, center, r.heading)
          : _pointPosition(r, center, R);
      return MapEntry(r, pos);
    }).toList();
  }
}
