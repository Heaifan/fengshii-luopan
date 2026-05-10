import 'dart:math' as math;
import 'package:flutter/material.dart';

// ==========================================
// Data models (extracted from old luopan_painter)
// ==========================================

class LuopanMountain {
  final String name;
  final String sanyuan;
  final String wuxing;
  final Color color;
  const LuopanMountain(this.name, this.sanyuan, this.wuxing, this.color);
}

class LuopanGua {
  final String name;
  final String liuqin;
  final double angle;
  final List<bool> yaos;
  final Color yaoColor;
  const LuopanGua(this.name, this.liuqin, this.angle, this.yaos, this.yaoColor);
}

class BazhaiStarStyle {
  final String name;
  final String level;
  final Color color;
  const BazhaiStarStyle(this.name, this.level, this.color);
}

// ==========================================
// Static luopan data
// ==========================================

const _tianColor = Color(0xFFc43c32);
const _diColor = Color(0xFF2a5d84);
const _renColor = Color(0xFF4a7741);

const _mountains = <LuopanMountain>[
  LuopanMountain('午', '天', '火', _tianColor),
  LuopanMountain('丁', '人', '火', _renColor),
  LuopanMountain('未', '地', '土', _diColor),
  LuopanMountain('坤', '天', '土', _tianColor),
  LuopanMountain('申', '人', '金', _renColor),
  LuopanMountain('庚', '地', '金', _diColor),
  LuopanMountain('酉', '天', '金', _tianColor),
  LuopanMountain('辛', '人', '金', _renColor),
  LuopanMountain('戌', '地', '土', _diColor),
  LuopanMountain('乾', '天', '金', _tianColor),
  LuopanMountain('亥', '人', '水', _renColor),
  LuopanMountain('壬', '地', '水', _diColor),
  LuopanMountain('子', '天', '水', _tianColor),
  LuopanMountain('癸', '人', '水', _renColor),
  LuopanMountain('丑', '地', '土', _diColor),
  LuopanMountain('艮', '天', '土', _tianColor),
  LuopanMountain('寅', '人', '土', _renColor),
  LuopanMountain('甲', '地', '木', _diColor),
  LuopanMountain('卯', '天', '木', _tianColor),
  LuopanMountain('乙', '人', '木', _renColor),
  LuopanMountain('辰', '地', '木', _diColor),
  LuopanMountain('巽', '天', '木', _tianColor),
  LuopanMountain('巳', '人', '木', _renColor),
  LuopanMountain('丙', '地', '火', _diColor),
];

const _dirs = [
  ('南', 0.0, true),
  ('西南', 45.0, false),
  ('西', 90.0, true),
  ('西北', 135.0, false),
  ('北', 180.0, true),
  ('东北', 225.0, false),
  ('东', 270.0, true),
  ('东南', 315.0, false),
];

const guaList = <LuopanGua>[
  LuopanGua('离', '中女', 0, [true, false, true], Color(0xFF111111)),
  LuopanGua('坤', '母亲', 45, [false, false, false], Color(0xFFd00000)),
  LuopanGua('兑', '少女', 90, [false, true, true], Color(0xFFd00000)),
  LuopanGua('乾', '父亲', 135, [true, true, true], Color(0xFFd00000)),
  LuopanGua('坎', '中男', 180, [false, true, false], Color(0xFF111111)),
  LuopanGua('艮', '少男', 225, [true, false, false], Color(0xFFd00000)),
  LuopanGua('震', '长男', 270, [false, false, true], Color(0xFF111111)),
  LuopanGua('巽', '长女', 315, [true, true, false], Color(0xFF111111)),
];

// Default: 离宅
const _bazhaiStars = <String, String>{
  '离': '伏位', '震': '生气', '巽': '天医', '坎': '延年',
  '乾': '绝命', '兑': '五鬼', '坤': '六煞', '艮': '祸害',
};

const _starStyles = <String, BazhaiStarStyle>{
  '生气': BazhaiStarStyle('生气', '一吉', Color(0xFF2e7d32)),
  '天医': BazhaiStarStyle('天医', '二吉', Color(0xFFb07d3b)),
  '延年': BazhaiStarStyle('延年', '三吉', Color(0xFFb8860b)),
  '伏位': BazhaiStarStyle('伏位', '四吉', Color(0xFF2e7d32)),
  '绝命': BazhaiStarStyle('绝命', '一凶', Color(0xFFb8860b)),
  '五鬼': BazhaiStarStyle('五鬼', '二凶', Color(0xFFc43c32)),
  '六煞': BazhaiStarStyle('六煞', '三凶', Color(0xFF2a5d84)),
  '祸害': BazhaiStarStyle('祸害', '四凶', Color(0xFFb07d3b)),
};

// ==========================================
// LuopanDiscPainter — only the rotating disc
// ==========================================

class LuopanDiscPainter extends CustomPainter {
  final String houseGua;
  final double scale;
  static const double baseSize = 1000.0;

  LuopanDiscPainter({
    required this.houseGua,
    required this.scale,
  });

  double _visualAngleToRadian(double visualDeg) {
    return visualDeg * math.pi / 180;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = scale;
    final cx = size.width / 2;
    final cy = size.height / 2;

    canvas.save();
    canvas.translate(cx, cy);

    _drawDisc(canvas, s);
    _drawTicks(canvas, s);
    _drawDirections(canvas, s);
    _drawMountains(canvas, s);
    _drawBazhaiStars(canvas, s);
    _drawGuaNames(canvas, s);
    _drawGuaSymbols(canvas, s);
    _drawCircles(canvas, s);

    canvas.restore();
  }

  void _drawDisc(Canvas canvas, double s) {
    canvas.drawCircle(
      Offset.zero,
      500 * s,
      Paint()..color = const Color(0xFFf5e7c3),
    );
  }

  void _drawCircles(Canvas canvas, double s) {
    final paint = Paint()
      ..color = const Color(0xFFa07c50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * s;
    const radii = [500, 410, 320, 230, 145, 75];
    for (final r in radii) {
      canvas.drawCircle(Offset.zero, r * s, paint);
    }
  }

  void _drawDividerLines(Canvas canvas, double s) {
    for (var i = 0; i < 24; i++) {
      final angle = 7.5 + i * 15.0;
      final isBagua = (i % 3 == 1);
      final startR = isBagua ? 75.0 : 320.0;
      final endR = 488.0;
      final rad = _visualAngleToRadian(angle);

      canvas.save();
      canvas.rotate(rad);
      final linePaint = Paint()
        ..color = const Color(0xFFa07c50)
        ..strokeWidth = (isBagua ? 1.5 : 0.8) * s;
      canvas.drawLine(
          Offset(0, startR * s), Offset(0, endR * s), linePaint);
      canvas.restore();
    }
  }

  void _drawTicks(Canvas canvas, double s) {
    _drawDividerLines(canvas, s);

    for (var i = 0; i < 360; i++) {
      final rad = _visualAngleToRadian(i.toDouble());
      final h = (i % 10 == 0) ? 12.0 : (i % 5 == 0) ? 8.0 : 5.0;
      final w = (i % 10 == 0) ? 1.5 : 1.0;
      final offset = 500 - h / 2;

      canvas.save();
      canvas.rotate(rad);
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset(0, offset * s), width: w * s, height: h * s),
        Paint()..color = const Color(0xFFa07c50),
      );
      canvas.restore();
    }

    for (var i = 0; i < 360; i += 10) {
      final rad = _visualAngleToRadian(i.toDouble());
      canvas.save();
      canvas.rotate(rad);
      canvas.translate(0, -475 * s);
      final tp = TextPainter(
        text: TextSpan(
          text: '$i',
          style: TextStyle(
              color: const Color(0xFFa07c50),
              fontSize: 11 * s,
              fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.rotate(-rad);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  void _drawDirections(Canvas canvas, double s) {
    for (final d in _dirs) {
      final rad = _visualAngleToRadian(d.$2);
      canvas.save();
      canvas.rotate(rad);
      final tp = TextPainter(
        text: TextSpan(
          text: d.$1,
          style: TextStyle(
              color: const Color(0xFF222222),
              fontSize: d.$3 ? 34 * s : 26 * s,
              fontWeight: FontWeight.w900),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(-tp.width / 2, -455 * s - tp.height / 2));
      canvas.restore();
    }
  }

  void _drawMountains(Canvas canvas, double s) {
    for (var i = 0; i < _mountains.length; i++) {
      final m = _mountains[i];
      final angle = i * 15.0;
      final rad = _visualAngleToRadian(angle);

      canvas.save();
      canvas.rotate(rad);

      final nameTp = TextPainter(
        text: TextSpan(
            text: m.name,
            style: TextStyle(
                color: m.color,
                fontSize: 46 * s,
                fontWeight: FontWeight.w900)),
        textDirection: TextDirection.ltr,
      )..layout();

      final attrTp = TextPainter(
        text: TextSpan(
            text: '${m.sanyuan}${m.wuxing}',
            style: TextStyle(
                color: m.color.withAlpha(217),
                fontSize: 13 * s,
                fontWeight: FontWeight.w900,
                letterSpacing: 1 * s)),
        textDirection: TextDirection.ltr,
      )..layout();

      final totalH = nameTp.height + attrTp.height + 2 * s;
      final nameY = -365 * s - totalH / 2;
      final attrY = nameY + nameTp.height + 2 * s;

      nameTp.paint(canvas, Offset(-nameTp.width / 2, nameY));
      attrTp.paint(canvas, Offset(-attrTp.width / 2, attrY));

      canvas.restore();
    }
  }

  void _drawBazhaiStars(Canvas canvas, double s) {
    for (final g in guaList) {
      final rad = _visualAngleToRadian(g.angle);
      final starName = _bazhaiStars[g.name] ?? '';
      final style = _starStyles[starName];
      if (style == null) continue;

      canvas.save();
      canvas.rotate(rad);

      final nameTp = TextPainter(
        text: TextSpan(
            text: style.name,
            style: TextStyle(
                color: style.color,
                fontSize: 38 * s,
                fontWeight: FontWeight.w900,
                letterSpacing: 2 * s)),
        textDirection: TextDirection.ltr,
      )..layout();

      final levelTp = TextPainter(
        text: TextSpan(
            text: '(${style.level})',
            style: TextStyle(
                color: const Color(0xBF644B37),
                fontSize: 16 * s,
                fontWeight: FontWeight.w700)),
        textDirection: TextDirection.ltr,
      )..layout();

      final totalW = nameTp.width + levelTp.width + 2 * s;
      final startX = -totalW / 2;

      nameTp.paint(
          canvas, Offset(startX, -275 * s - nameTp.height / 2));
      levelTp.paint(canvas,
          Offset(startX + nameTp.width + 2 * s, -275 * s - levelTp.height / 2));

      canvas.restore();
    }
  }

  void _drawGuaNames(Canvas canvas, double s) {
    for (final g in guaList) {
      final rad = _visualAngleToRadian(g.angle);
      canvas.save();
      canvas.rotate(rad);

      final nameTp = TextPainter(
        text: TextSpan(
            text: g.name,
            style: TextStyle(
                color: const Color(0xFF111111),
                fontSize: 44 * s,
                fontWeight: FontWeight.w900)),
        textDirection: TextDirection.ltr,
      )..layout();

      final liuqinTp = TextPainter(
        text: TextSpan(
            text: g.liuqin,
            style: TextStyle(
                color: const Color(0xD94A3B2C),
                fontSize: 14 * s,
                fontWeight: FontWeight.w800,
                letterSpacing: 2 * s)),
        textDirection: TextDirection.ltr,
      )..layout();

      final totalH = nameTp.height + liuqinTp.height + 2 * s;
      final nameY = -188 * s - totalH / 2;
      final liuqinY = nameY + nameTp.height + 2 * s;

      nameTp.paint(canvas, Offset(-nameTp.width / 2, nameY));
      liuqinTp.paint(canvas, Offset(-liuqinTp.width / 2, liuqinY));

      canvas.restore();
    }
  }

  void _drawGuaSymbols(Canvas canvas, double s) {
    for (final g in guaList) {
      final rad = _visualAngleToRadian(g.angle);
      canvas.save();
      canvas.rotate(rad);

      const yaoW = 50.0;
      const yaoH = 7.0;
      const yaoGap = 5.0;
      final totalH = yaoH * 3 + yaoGap * 2;

      for (var j = 0; j < 3; j++) {
        final isYang = g.yaos[j];
        final yaoY = -110 * s - totalH * s / 2 + j * (yaoH + yaoGap) * s;

        if (isYang) {
          canvas.drawRect(
            Rect.fromCenter(
                center: Offset(0, yaoY),
                width: yaoW * s,
                height: yaoH * s),
            Paint()..color = g.yaoColor,
          );
        } else {
          const gapW = 14.0;
          const segW = (yaoW - gapW) / 2;
          canvas.drawRect(
            Rect.fromCenter(
                center: Offset(-(gapW / 2 + segW / 2) * s, yaoY),
                width: segW * s,
                height: yaoH * s),
            Paint()..color = g.yaoColor,
          );
          canvas.drawRect(
            Rect.fromCenter(
                center: Offset((gapW / 2 + segW / 2) * s, yaoY),
                width: segW * s,
                height: yaoH * s),
            Paint()..color = g.yaoColor,
          );
        }
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant LuopanDiscPainter oldDelegate) {
    return oldDelegate.houseGua != houseGua ||
        oldDelegate.scale != scale;
  }
}
