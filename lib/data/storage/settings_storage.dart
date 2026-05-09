import 'package:shared_preferences/shared_preferences.dart';

class SettingsStorage {
  static const _keyHouseGua = 'house_gua';
  static const _keyCalibrationOffset = 'calibration_offset';
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
}
