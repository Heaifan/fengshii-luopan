import '../../../data/models/compass_record.dart';
import '../../../fengshui/direction_sector.dart';

class PlateRecordInfo {
  final CompassRecord record;
  final String directionText;
  final String sectorKey;
  final String directionLabel;
  final String palaceLabel;
  final String mountainLabel;
  final String yuanLongLabel;
  final String element;
  final String bazhaiText;

  const PlateRecordInfo({
    required this.record,
    required this.directionText,
    required this.sectorKey,
    required this.directionLabel,
    required this.palaceLabel,
    required this.mountainLabel,
    required this.yuanLongLabel,
    required this.element,
    required this.bazhaiText,
  });

  String get mountainFull => '$mountainLabel｜$yuanLongLabel｜$element';
  String get palaceLine => '$directionText｜$palaceLabel · $mountainLabel';
  String get fullLine => '$directionText｜$palaceLabel · $mountainLabel｜$bazhaiText';
}

PlateRecordInfo buildPlateRecordInfo({
  required CompassRecord record,
  required String houseGua,
}) {
  final sectorKey =
      DirectionSector.sector8FromHeading(record.heading);
  final directionLabel =
      DirectionSector.shortSector8Label(sectorKey);
  final palaceLabel =
      DirectionSector.sectorGuaPalaceLabel(sectorKey);
  final mountainInfo =
      DirectionSector.mountainInfoFromHeading(record.heading);

  return PlateRecordInfo(
    record: record,
    directionText: record.directionText,
    sectorKey: sectorKey,
    directionLabel: directionLabel,
    palaceLabel: palaceLabel,
    mountainLabel: mountainInfo.mountainLabel,
    yuanLongLabel: mountainInfo.yuanLongLabel,
    element: mountainInfo.element,
    bazhaiText: record.bazhaiText,
  );
}
