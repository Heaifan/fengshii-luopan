import '../data/models/compass_record.dart';
import '../data/models/measure_type.dart';
import '../data/models/measurement_project.dart';
import 'compass_math.dart';
import 'compass_reading_builder.dart';
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
      final door = resolveBaseDoor(records);
      if (door == null) return null; // no door point yet
      final sector = DirectionSector.sector8FromHeading(door.heading);
      final gua = DirectionSector.sectorToGua(sector);
      return gua.isEmpty ? fallback : gua;
    }

    // wholeHouse mode
    return project.basePalace ?? fallback;
  }

  /// Find the base door with priority: entranceDoor > roomDoor > legacy door.
  static CompassRecord? resolveBaseDoor(List<CompassRecord> records) {
    for (final r in records) {
      if (r.measureType == MeasureTypes.entranceDoor) return r;
    }
    for (final r in records) {
      if (r.measureType == MeasureTypes.roomDoor) return r;
    }
    for (final r in records) {
      if (r.measureType == MeasureTypes.door) return r;
    }
    return null;
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
    final base = resolveBasePalace(project: project, records: records);

    if (base == null) {
      return '门位起伏位｜请先测量门位';
    }

    if (project.baZhaiMode == 'doorPosition') {
      return '门位起伏位｜伏位$base宫';
    }

    return '整宅$base宅｜伏位$base宫';
  }

  /// Build a detailed door-source display for doorPosition mode.
  /// Returns null if no door is found.
  static String? doorSourceText({
    required MeasurementProject project,
    required List<CompassRecord> records,
  }) {
    if (project.baZhaiMode != 'doorPosition') return null;
    final door = resolveBaseDoor(records);
    if (door == null) return null;
    final name = door.measureName?.trim().isNotEmpty == true
        ? door.measureName!.trim()
        : MeasureTypes.label(door.measureType);
    final sector = DirectionSector.sector8FromHeading(door.heading);
    final gua = DirectionSector.sectorToGua(sector);

    if (door.measureType == MeasureTypes.entranceDoor) {
      return '伏位来源：$name｜${door.directionText}｜${gua}宫';
    }
    // roomDoor or legacy door — add note
    return '伏位来源：$name｜${door.directionText}｜${gua}宫（无入户门，临时采用）';
  }

  /// Find the first door record for 伏位 source.
  static CompassRecord? firstDoor(List<CompassRecord> records) {
    return resolveBaseDoor(records);
  }

  /// Recalculate all records' bazhai data based on current base palace.
  /// When base is null (e.g. doorPosition with no door), sets bazhaiText to '伏位待定'.
  static List<CompassRecord> recalculateAllPoints({
    required MeasurementProject project,
    required List<CompassRecord> records,
  }) {
    final baseGua = resolveBasePalace(project: project, records: records);

    return records.map((r) {
      if (baseGua == null) {
        return CompassRecord(
          id: r.id,
          name: r.name,
          location: r.location,
          note: r.note,
          createdAt: r.createdAt,
          heading: r.heading,
          directionText: r.directionText,
          sittingFacingText: r.sittingFacingText,
          sittingMountain: r.sittingMountain,
          facingMountain: r.facingMountain,
          palace: r.palace,
          mountainText: r.mountainText,
          bazhaiText: '伏位待定',
          statusText: r.statusText,
          horizontalAngle: r.horizontalAngle,
          verticalAngle: r.verticalAngle,
          houseGua: r.houseGua,
          projectId: r.projectId,
          measureType: r.measureType,
          measureName: r.measureName,
          spaceName: r.spaceName,
        );
      }

      final reading = CompassReadingBuilder.build(
        degree: r.heading,
        houseGua: baseGua,
      );
      final dirText =
          '${compassDirectionName(r.heading)}${r.heading.toStringAsFixed(0)}°';
      final meta = bazhaiStarMetaMap[reading.bazhaiStar];
      final bazhaiText =
          '${reading.bazhaiStar}${meta?.element ?? ''}（${reading.bazhaiRank}）';

      return CompassRecord(
        id: r.id,
        name: r.name,
        location: r.location,
        note: r.note,
        createdAt: r.createdAt,
        heading: r.heading,
        directionText: dirText,
        sittingFacingText: reading.sittingFacingText,
        sittingMountain: reading.sittingMountain,
        facingMountain: reading.facingMountain,
        palace: '${reading.facingGua}宫',
        mountainText: reading.fullSanyuanText,
        bazhaiText: bazhaiText,
        statusText: r.statusText,
        horizontalAngle: r.horizontalAngle,
        verticalAngle: r.verticalAngle,
        houseGua: baseGua,
        projectId: r.projectId,
        measureType: r.measureType,
        measureName: r.measureName,
        spaceName: r.spaceName,
      );
    }).toList();
  }

  /// Generate the 8-palace star map for a given base palace.
  /// Returns a map of gua → star name.
  static Map<String, String> generateStarMap(String basePalace) {
    const guas = ['乾', '兑', '艮', '坤', '坎', '震', '巽', '离'];
    final map = <String, String>{};
    for (final gua in guas) {
      map[gua] = getBazhaiStar(houseGua: basePalace, palaceGua: gua);
    }
    return map;
  }
}
