import '../../../data/models/compass_record.dart';

int measureTypePriority(String type) {
  switch (type) {
    case 'door':
      return 1;
    case 'bed':
      return 2;
    case 'stove':
      return 3;
    case 'altar':
      return 4;
    case 'desk':
      return 5;
    case 'livingRoom':
      return 6;
    case 'balcony':
      return 7;
    case 'window':
      return 8;
    default:
      return 9;
  }
}

List<CompassRecord> sortPlateRecords(List<CompassRecord> records) {
  final sorted = [...records];
  sorted.sort((a, b) {
    final pa = measureTypePriority(a.measureType);
    final pb = measureTypePriority(b.measureType);
    if (pa != pb) return pa.compareTo(pb);
    return a.heading.compareTo(b.heading);
  });
  return sorted;
}
