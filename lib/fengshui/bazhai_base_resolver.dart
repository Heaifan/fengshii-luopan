import '../data/models/compass_record.dart';
import '../data/models/measurement_project.dart';
import 'direction_sector.dart';
import 'bazhai_you_nian_table.dart';

/// Resolves the current base palace (伏位宫) from project settings and records.
class BaZhaiBaseResolver {
  /// Get the active base palace for a project.
  ///
  /// In wholeHouse mode: project.basePalace ?? records.first.houseGua ?? '乾'
  /// In doorPosition mode: derive from first door record's heading
  static String? resolveBasePalace({
    required MeasurementProject project,
    required List<CompassRecord> records,
    String fallback = '乾',
  }) {
    if (project.baZhaiMode == 'doorPosition') {
      // Find the first door measurement point
      final door = records.cast<CompassRecord?>().firstWhere(
        (r) => r!.measureType == 'door',
        orElse: () => null,
      );
      if (door == null) return null; // no door point yet
      final sector = DirectionSector.sector8FromHeading(door.heading);
      final gua = DirectionSector.sectorToGua(sector);
      return gua.isEmpty ? fallback : gua;
    }

    // wholeHouse mode
    return project.basePalace ?? fallback;
  }

  /// Get the house gua label for display.
  /// In wholeHouse: "整宅${gua}宅"
  /// In doorPosition: "门位起伏位"
  static String modeLabel(String mode) {
    return mode == 'doorPosition' ? '门位起伏位' : '整宅宅卦';
  }

  /// Build a display summary like "门位起伏位｜伏位乾宫" or "整宅乾宅｜伏位乾宫".
  static String summaryText({
    required MeasurementProject project,
    required List<CompassRecord> records,
  }) {
    final base = resolveBasePalace(
      project: project,
      records: records,
    );

    if (base == null) {
      return '门位起伏位｜请先测量门位';
    }

    if (project.baZhaiMode == 'doorPosition') {
      return '门位起伏位｜伏位${base}宫';
    }

    return '整宅${base}宅｜伏位${base}宫';
  }

  /// Generate the 8-palace star map for a given base palace.
  /// Returns a map of gua → star name.
  static Map<String, String> generateStarMap(String basePalace) {
    const guas = ['乾', '兑', '艮', '坤', '坎', '震', '巽', '离'];
    final map = <String, String>{};
    for (final gua in guas) {
      map[gua] = getBazhaiStar(
        houseGua: basePalace,
        palaceGua: gua,
      );
    }
    return map;
  }
}
