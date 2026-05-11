import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/compass_record.dart';
import '../models/measurement_project.dart';

class SettingsStorage {
  static const _keyHouseGua = 'house_gua';
  static const _keyCalibrationOffset = 'calibration_offset';
  static const _keyRecords = 'compass_records';
  static const _keyProjects = 'measurement_projects';
  static const _defaultHouseGua = '乾';

  Future<String> loadHouseGua() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyHouseGua) ?? _defaultHouseGua;
  }

  Future<void> saveHouseGua(String gua) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHouseGua, gua);
  }

  Future<double> loadCalibrationOffset() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyCalibrationOffset) ?? 0.0;
  }

  Future<void> saveCalibrationOffset(double offset) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyCalibrationOffset, offset);
  }

  // ---- Records ----

  Future<List<CompassRecord>> loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyRecords);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(CompassRecord.fromJson)
          .toList();
    } catch (e, st) {
      debugPrint('loadRecords failed: $e\n$st');
      await prefs.setString(
          '${_keyRecords}_corrupted_${DateTime.now().millisecondsSinceEpoch}',
          raw);
      return [];
    }
  }

  Future<void> saveRecords(List<CompassRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(records.map((r) => r.toJson()).toList());
    await prefs.setString(_keyRecords, raw);
  }

  Future<void> addRecord(CompassRecord record) async {
    final records = await loadRecords();
    records.insert(0, record);
    await saveRecords(records);
  }

  Future<void> deleteRecord(String id) async {
    final records = await loadRecords();
    records.removeWhere((r) => r.id == id);
    await saveRecords(records);
  }

  Future<void> updateRecord(CompassRecord updated) async {
    final records = await loadRecords();
    final index = records.indexWhere((r) => r.id == updated.id);
    if (index == -1) return;
    records[index] = updated;
    await saveRecords(records);
  }

  Future<List<CompassRecord>> loadRecordsByProject(
      String projectId) async {
    final records = await loadRecords();
    return records
        .where((r) => r.projectId == projectId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // ---- Projects ----

  Future<List<MeasurementProject>> loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyProjects);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(MeasurementProject.fromJson)
          .toList();
    } catch (e, st) {
      debugPrint('loadProjects failed: $e\n$st');
      await prefs.setString(
          '${_keyProjects}_corrupted_${DateTime.now().millisecondsSinceEpoch}',
          raw);
      return [];
    }
  }

  Future<void> saveProjects(
      List<MeasurementProject> projects) async {
    final prefs = await SharedPreferences.getInstance();
    final raw =
        jsonEncode(projects.map((r) => r.toJson()).toList());
    await prefs.setString(_keyProjects, raw);
  }

  Future<void> addProject(MeasurementProject project) async {
    final projects = await loadProjects();
    projects.insert(0, project);
    await saveProjects(projects);
  }

  Future<void> deleteProject(String id) async {
    final projects = await loadProjects();
    projects.removeWhere((p) => p.id == id);
    // Also delete all records belonging to this project
    final records = await loadRecords();
    records.removeWhere((r) => r.projectId == id);
    await saveRecords(records);
    await saveProjects(projects);
  }
}
