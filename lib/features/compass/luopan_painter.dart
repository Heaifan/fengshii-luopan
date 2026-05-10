import 'dart:math' as math;
import 'package:flutter/material.dart';

// ==========================================
// 数据模型
// ==========================================

class LuopanMountain {
  final String name;
  final String sanyuan; // 天/人/地
  final String wuxing; // 金木水火土
  final Color color;

  const LuopanMountain(this.name, this.sanyuan, this.wuxing, this.color);
}

class LuopanGua {
  final String name;
  final String liuqin;
  final double angle; // visual angle, 0=top
  final List<bool> yaos; // true=阳, false=阴, top to bottom
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
// 静态数据
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

const _guaList = <LuopanGua>[
  LuopanGua('离', '中女', 0, [true, false, true], Color(0xFF111111)),
  LuopanGua('坤', '母亲', 45, [false, false, false], Color(0xFFd00000)),
  LuopanGua('兑', '少女', 90, [false, true, true], Color(0xFFd00000)),
  LuopanGua('乾', '父亲', 135, [true, true, true], Color(0xFFd00000)),
  LuopanGua('坎', '中男', 180, [false, true, false], Color(0xFF111111)),
  LuopanGua('艮', '少男', 225, [true, false, false], Color(0xFFd00000)),
  LuopanGua('震', '长男', 270, [false, false, true], Color(0xFF111111)),
  LuopanGua('巽', '长女', 315, [true, true, false], Color(0xFF111111)),
];

// 八宅星表 (离宅默认)
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
// LuopanPainter
// ==========================================

class LuopanPainter extends CustomPainter {
  final double heading; // 方位角 0-360, 0=北
  final String houseGua;
  final double scale;

  static const double baseSize = 1000.0;

  LuopanPainter({
    required this.heading,
    required this.houseGua,
    required this.scale,
  });

  // 视觉角度转弧度: 0=顶部,顺时针
  double _visualAngleToRadian(double visualDeg) {
    return (visualDeg - 90) * math.pi / 180;
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
    _drawCrosshair(canvas, s);
    _drawNeedle(canvas, s);

    canvas.restore();
  }

  // --- 底盘 ---
  void _drawDisc(Canvas canvas, double s) {
    canvas.drawCircle(
      Offset.zero,
      500 * s,
      Paint()..color = const Color(0xFFf5e7c3),
    );
  }

  // --- 同心圆 ---
  void _drawCircles(Canvas canvas, double s) {
    final paint = Paint()
      ..color = const Color(0xFFa07c50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * s;
    const radii = [500, 410, 330, 250, 170, 110];
    for (final r in radii) {
      canvas.drawCircle(Offset.zero, r * s, paint);
    }
  }

  // --- 分割线 ---
  void _drawDividerLines(Canvas canvas, double s) {
    for (var i = 0; i < 24; i++) {
      final angle = 7.5 + i * 15.0;
      final isBagua = (i % 3 == 1); // 八卦主分割线
      final startR = isBagua ? 110.0 : 330.0;
      final endR = 488.0;

      final rad = _visualAngleToRadian(angle);

      canvas.save();
      canvas.rotate(rad);

      final linePaint = Paint()
        ..color = const Color(0xFFa07c50)
        ..strokeWidth = (isBagua ? 1.5 : 0.8) * s;

      canvas.drawLine(
        Offset(0, startR * s),
        Offset(0, endR * s),
        linePaint,
      );
      canvas.restore();
    }
  }

  // --- 360° 刻度 + 数字 ---
  void _drawTicks(Canvas canvas, double s) {
    // 分割线
    _drawDividerLines(canvas, s);

    // 刻度
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

    // 数字
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
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      // 数字保持正向不旋转
      canvas.rotate(-rad);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  // --- 八大方向 ---
  void _drawDirections(Canvas canvas, double s) {
    for (final d in _dirs) {
      final rad = _visualAngleToRadian(d.$2);

      canvas.save();
      canvas.rotate(rad);

      // 计算 _discRotation 对显示的影响：文字需随盘面旋转
      // 此处不额外旋转方向文字，因为 HTML 中方向不随盘面转动(盘面旋转=罗盘旋转)
      final tp = TextPainter(
        text: TextSpan(
          text: d.$1,
          style: TextStyle(
            color: const Color(0xFF222222),
            fontSize: d.$3 ? 34 * s : 26 * s,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(-tp.width / 2, -455 * s - tp.height / 2));
      canvas.restore();
    }
  }

  // --- 二十四山 ---
  void _drawMountains(Canvas canvas, double s) {
    for (var i = 0; i < _mountains.length; i++) {
      final m = _mountains[i];
      final angle = i * 15.0;
      final rad = _visualAngleToRadian(angle);

      canvas.save();
      canvas.rotate(rad);

      // 山名
      final nameTp = TextPainter(
        text: TextSpan(
          text: m.name,
          style: TextStyle(
            color: m.color,
            fontSize: 44 * s,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // 属性
      final attrTp = TextPainter(
        text: TextSpan(
          text: '${m.sanyuan}${m.wuxing}',
          style: TextStyle(
            color: m.color.withAlpha(217),
            fontSize: 13 * s,
            fontWeight: FontWeight.w900,
            letterSpacing: 1 * s,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final totalH = nameTp.height + attrTp.height + 2 * s;
      final nameY = -370 * s - totalH / 2;
      final attrY = nameY + nameTp.height + 2 * s;

      nameTp.paint(canvas, Offset(-nameTp.width / 2, nameY));
      attrTp.paint(canvas, Offset(-attrTp.width / 2, attrY));

      canvas.restore();
    }
  }

  // --- 八宅星 ---
  void _drawBazhaiStars(Canvas canvas, double s) {
    final starMap =
        _bazhaiStars; // TODO: 支持切换宅卦时查不同表

    for (final g in _guaList) {
      final rad = _visualAngleToRadian(g.angle);
      final starName = starMap[g.name] ?? '';
      final style = _starStyles[starName];
      if (style == null) continue;

      canvas.save();
      canvas.rotate(rad);

      // 星名
      final nameTp = TextPainter(
        text: TextSpan(
          text: style.name,
          style: TextStyle(
            color: style.color,
            fontSize: 36 * s,
            fontWeight: FontWeight.w900,
            letterSpacing: 2 * s,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // 等级
      final levelTp = TextPainter(
        text: TextSpan(
          text: '(${style.level})',
          style: TextStyle(
            color: const Color(0xBF644B37),
            fontSize: 16 * s,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final totalW = nameTp.width + levelTp.width + 2 * s;
      final startX = -totalW / 2;

      nameTp.paint(canvas, Offset(startX, -290 * s - nameTp.height / 2));
      levelTp.paint(canvas,
          Offset(startX + nameTp.width + 2 * s, -290 * s - levelTp.height / 2));

      canvas.restore();
    }
  }

  // --- 卦名六亲 ---
  void _drawGuaNames(Canvas canvas, double s) {
    for (final g in _guaList) {
      final rad = _visualAngleToRadian(g.angle);

      canvas.save();
      canvas.rotate(rad);

      final nameTp = TextPainter(
        text: TextSpan(
          text: g.name,
          style: TextStyle(
            color: const Color(0xFF111111),
            fontSize: 42 * s,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final liuqinTp = TextPainter(
        text: TextSpan(
          text: g.liuqin,
          style: TextStyle(
            color: const Color(0xD94A3B2C),
            fontSize: 14 * s,
            fontWeight: FontWeight.w800,
            letterSpacing: 2 * s,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final totalH = nameTp.height + liuqinTp.height + 2 * s;
      final nameY = -210 * s - totalH / 2;
      final liuqinY = nameY + nameTp.height + 2 * s;

      nameTp.paint(canvas, Offset(-nameTp.width / 2, nameY));
      liuqinTp.paint(canvas, Offset(-liuqinTp.width / 2, liuqinY));

      canvas.restore();
    }
  }

  // --- 卦象 ---
  void _drawGuaSymbols(Canvas canvas, double s) {
    for (final g in _guaList) {
      final rad = _visualAngleToRadian(g.angle);

      canvas.save();
      canvas.rotate(rad);

      const yaoW = 48.0;
      const yaoH = 7.0;
      const yaoGap = 5.0;
      final totalH = yaoH * 3 + yaoGap * 2;

      for (var j = 0; j < 3; j++) {
        final isYang = g.yaos[j];
        final yaoY = -140 * s - totalH * s / 2 + j * (yaoH + yaoGap) * s;

        if (isYang) {
          // 阳爻：完整横线
          canvas.drawRect(
            Rect.fromCenter(
                center: Offset(0, yaoY),
                width: yaoW * s,
                height: yaoH * s),
            Paint()..color = g.yaoColor,
          );
        } else {
          // 阴爻：左右两段
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

  // --- 十字线 ---
  void _drawCrosshair(Canvas canvas, double s) {
    final paint = Paint()
      ..color = const Color(0xA6d00000)
      ..strokeWidth = 1.0 * s;

    canvas.drawLine(Offset(0, -500 * s), Offset(0, 500 * s), paint);
    canvas.drawLine(Offset(-500 * s, 0), Offset(500 * s, 0), paint);
  }

  // --- 指针 + 天池 ---
  void _drawNeedle(Canvas canvas, double s) {
    // 指针主体
    final needlePaint = Paint()
      ..color = const Color(0xFF1a1a1a)
      ..strokeWidth = 2.5 * s;

    canvas.drawLine(
      Offset(0, -190 * s),
      Offset(0, 190 * s),
      needlePaint,
    );

    // 双红点
    final dotPaint = Paint()..color = const Color(0xFFd00000);
    const dotR = 4.0;
    canvas.drawCircle(Offset(-8 * s, 170 * s), dotR * s, dotPaint);
    canvas.drawCircle(Offset(8 * s, 170 * s), dotR * s, dotPaint);

    // 中心轴
    canvas.drawCircle(Offset.zero, 7 * s,
        Paint()..color = const Color(0xFF444444));
    canvas.drawCircle(Offset.zero, 5 * s,
        Paint()..color = const Color(0xFF222222));
  }

  @override
  bool shouldRepaint(covariant LuopanPainter oldDelegate) {
    return oldDelegate.heading != heading ||
        oldDelegate.houseGua != houseGua ||
        oldDelegate.scale != scale;
  }
}

class LuopanDial extends StatelessWidget {
  final double heading;
  final String houseGua;

  const LuopanDial({
    super.key,
    required this.heading,
    required this.houseGua,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size =
            math.min(constraints.maxWidth, constraints.maxHeight);
        final scale = size / LuopanPainter.baseSize;

        return Transform.rotate(
          angle: heading * math.pi / 180,
          child: CustomPaint(
            size: Size(size, size),
            painter: LuopanPainter(
              heading: heading,
              houseGua: houseGua,
              scale: scale,
            ),
          ),
        );
      },
    );
  }
}
