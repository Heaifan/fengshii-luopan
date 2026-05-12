import 'package:uuid/uuid.dart';

class MeasurementProject {
  final String id;
  final String name;
  final String type;
  final String? location;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String baZhaiMode; // 'wholeHouse' | 'doorPosition'
  final String? basePalace; // e.g. '乾', null = auto-derive

  const MeasurementProject({
    required this.id,
    required this.name,
    required this.type,
    this.location,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.baZhaiMode = 'wholeHouse',
    this.basePalace,
  });

  factory MeasurementProject.create({
    required String name,
    String type = 'other',
    String? location,
    String? note,
    String baZhaiMode = 'wholeHouse',
    String? basePalace,
  }) {
    final now = DateTime.now();
    return MeasurementProject(
      id: const Uuid().v4(),
      name: name,
      type: type,
      location: location,
      note: note,
      createdAt: now,
      updatedAt: now,
      baZhaiMode: baZhaiMode,
      basePalace: basePalace,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'location': location,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'baZhaiMode': baZhaiMode,
        'basePalace': basePalace,
      };

  factory MeasurementProject.fromJson(Map<String, dynamic> json) {
    return MeasurementProject(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String? ?? 'other',
      location: json['location'] as String?,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      baZhaiMode: json['baZhaiMode'] as String? ?? 'wholeHouse',
      basePalace: json['basePalace'] as String?,
    );
  }
}
