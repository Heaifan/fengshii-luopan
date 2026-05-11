import 'package:uuid/uuid.dart';

class CompassRecord {
  final String id;
  final String name;
  final String? location;
  final String? note;
  final DateTime createdAt;

  // Locked snapshot
  final double heading;
  final String directionText;
  final String sittingFacingText;
  final String sittingMountain;
  final String facingMountain;
  final String palace;
  final String mountainText;
  final String bazhaiText;
  final String statusText;
  final double horizontalAngle;
  final double verticalAngle;
  final String houseGua;

  // Project measurement fields
  final String? projectId;
  final String measureType;
  final String? measureName;
  final String? spaceName;

  const CompassRecord({
    required this.id,
    required this.name,
    this.location,
    this.note,
    required this.createdAt,
    required this.heading,
    required this.directionText,
    required this.sittingFacingText,
    required this.sittingMountain,
    required this.facingMountain,
    required this.palace,
    required this.mountainText,
    required this.bazhaiText,
    required this.statusText,
    required this.horizontalAngle,
    required this.verticalAngle,
    required this.houseGua,
    this.projectId,
    this.measureType = 'other',
    this.measureName,
    this.spaceName,
  });

  factory CompassRecord.create({
    required String name,
    String? location,
    String? note,
    required double heading,
    required String directionText,
    required String sittingFacingText,
    required String sittingMountain,
    required String facingMountain,
    required String palace,
    required String mountainText,
    required String bazhaiText,
    required String statusText,
    required double horizontalAngle,
    required double verticalAngle,
    required String houseGua,
    String? projectId,
    String measureType = 'other',
    String? measureName,
    String? spaceName,
  }) {
    return CompassRecord(
      id: const Uuid().v4(),
      name: name,
      location: location,
      note: note,
      createdAt: DateTime.now(),
      heading: heading,
      directionText: directionText,
      sittingFacingText: sittingFacingText,
      sittingMountain: sittingMountain,
      facingMountain: facingMountain,
      palace: palace,
      mountainText: mountainText,
      bazhaiText: bazhaiText,
      statusText: statusText,
      horizontalAngle: horizontalAngle,
      verticalAngle: verticalAngle,
      houseGua: houseGua,
      projectId: projectId,
      measureType: measureType,
      measureName: measureName,
      spaceName: spaceName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'location': location,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
        'heading': heading,
        'directionText': directionText,
        'sittingFacingText': sittingFacingText,
        'sittingMountain': sittingMountain,
        'facingMountain': facingMountain,
        'palace': palace,
        'mountainText': mountainText,
        'bazhaiText': bazhaiText,
        'statusText': statusText,
        'horizontalAngle': horizontalAngle,
        'verticalAngle': verticalAngle,
        'houseGua': houseGua,
        'projectId': projectId,
        'measureType': measureType,
        'measureName': measureName,
        'spaceName': spaceName,
      };

  factory CompassRecord.fromJson(Map<String, dynamic> json) {
    return CompassRecord(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String?,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      heading: (json['heading'] as num).toDouble(),
      directionText: json['directionText'] as String,
      sittingFacingText: json['sittingFacingText'] as String,
      sittingMountain: json['sittingMountain'] as String,
      facingMountain: json['facingMountain'] as String,
      palace: json['palace'] as String,
      mountainText: json['mountainText'] as String,
      bazhaiText: json['bazhaiText'] as String,
      statusText: json['statusText'] as String,
      horizontalAngle: (json['horizontalAngle'] as num).toDouble(),
      verticalAngle: (json['verticalAngle'] as num).toDouble(),
      houseGua: json['houseGua'] as String,
      projectId: json['projectId'] as String?,
      measureType: json['measureType'] as String? ?? 'other',
      measureName: json['measureName'] as String?,
      spaceName: json['spaceName'] as String?,
    );
  }
}
