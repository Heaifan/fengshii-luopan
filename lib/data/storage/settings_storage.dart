import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/compass_record.dart';

class SettingsStorage {
  static const _keyHouseGua = 'house_gua';
  static const _keyCalibrationOffset = 'calibration_offset';
  static const _keyRecords = 'compass_records';
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

  Future<List<CompassRecord>> loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyRecords);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => CompassRecord.fromJson(e as Map<String, dynamic>))
        .toList();
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
}
