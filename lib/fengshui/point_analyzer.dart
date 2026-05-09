import '../data/models/fengshui_point.dart';
import 'sanyuan_dragon.dart';

class PointAnalysisResult {
  final bool hasHeaven;
  final bool hasHuman;
  final bool hasEarth;
  final List<String> missing;
  final String summary;

  const PointAnalysisResult({
    required this.hasHeaven,
    required this.hasHuman,
    required this.hasEarth,
    required this.missing,
    required this.summary,
  });
}

class PointAnalyzer {
  PointAnalyzer._();

  static PointAnalysisResult analyze(List<FengShuiPoint> points) {
    final hasHeaven = points.any((p) => p.sanyuanType == SanyuanType.heaven);
    final hasHuman = points.any((p) => p.sanyuanType == SanyuanType.human);
    final hasEarth = points.any((p) => p.sanyuanType == SanyuanType.earth);

    final missing = <String>[];
    if (!hasHeaven) missing.add('天位');
    if (!hasHuman) missing.add('人位');
    if (!hasEarth) missing.add('地位');

    final summary = missing.isEmpty ? '天地人齐全' : '缺${missing.join('、')}';

    return PointAnalysisResult(
      hasHeaven: hasHeaven,
      hasHuman: hasHuman,
      hasEarth: hasEarth,
      missing: missing,
      summary: summary,
    );
  }
}
