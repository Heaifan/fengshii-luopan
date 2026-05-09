enum MagneticStatus {
  normal,
  unstable,
  disturbed,
  unavailable,
}

extension MagneticStatusText on MagneticStatus {
  String get label {
    switch (this) {
      case MagneticStatus.normal:
        return '磁场正常';
      case MagneticStatus.unstable:
        return '磁场波动';
      case MagneticStatus.disturbed:
        return '疑似干扰';
      case MagneticStatus.unavailable:
        return '无磁场数据';
    }
  }

  String get suggestion {
    switch (this) {
      case MagneticStatus.normal:
        return '当前罗盘状态较稳定。';
      case MagneticStatus.unstable:
        return '当前角度有波动，建议放平手机并缓慢移动。';
      case MagneticStatus.disturbed:
        return '当前环境可能影响罗盘精度，请远离金属、电器、门框、电梯或配电箱。';
      case MagneticStatus.unavailable:
        return '当前设备未返回指南针数据，请切换手动测试模式。';
    }
  }
}

class HeadingStabilityAnalyzer {
  HeadingStabilityAnalyzer._();

  static MagneticStatus analyze(List<double> recentHeadings) {
    if (recentHeadings.isEmpty) {
      return MagneticStatus.unavailable;
    }

    if (recentHeadings.length < 5) {
      return MagneticStatus.normal;
    }

    final diffs = <double>[];

    for (var i = 1; i < recentHeadings.length; i++) {
      var diff = (recentHeadings[i] - recentHeadings[i - 1]).abs();
      if (diff > 180) diff = 360 - diff;
      diffs.add(diff);
    }

    final maxDiff = diffs.reduce((a, b) => a > b ? a : b);

    if (maxDiff > 25) return MagneticStatus.disturbed;
    if (maxDiff > 12) return MagneticStatus.unstable;
    return MagneticStatus.normal;
  }
}
