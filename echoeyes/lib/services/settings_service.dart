import 'package:echoeyes/models/settings_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _keySpeechRate = 'speechRate';
  static const _keyLanguage = 'language';
  static const _keySpeechVolume = 'speechVolume';
  static const _keySwitchMode = 'switchMode';
  static const _keyConfidenceThreshold = 'confidenceThreshold';
  static const _keyFontSize = 'fontSize';
  //static const _keyDirectionMode = 'directionMode';

  static Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    return AppSettings(
      speechRate: prefs.getDouble(_keySpeechRate) ?? 0.5,
      language: prefs.getString(_keyLanguage) ?? 'en-US',
      speechVolume: prefs.getDouble(_keySpeechVolume) ?? 1.0,
      switchMode: prefs.getBool(_keySwitchMode) ?? false,
      confidenceThreshold: prefs.getDouble(_keyConfidenceThreshold) ?? 0.5,
      fontSize: prefs.getDouble(_keyFontSize) ?? 13.0,
      //directionMode: prefs.getBool(_keyDirectionMode) ?? false,
    );
  }

  static Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble(_keySpeechRate, settings.speechRate);
    await prefs.setString(_keyLanguage, settings.language);
    await prefs.setDouble(_keySpeechVolume, settings.speechVolume);
    await prefs.setBool(_keySwitchMode, settings.switchMode);
    await prefs.setDouble(
      _keyConfidenceThreshold,
      settings.confidenceThreshold,
    );
    await prefs.setDouble(_keyFontSize, settings.fontSize);
    //await prefs.setBool(_keyDirectionMode, settings.directionMode);
  }
}
