import 'package:echoeyes/models/settings_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  static final FlutterTts _flutterTts = FlutterTts();
  static AppSettings _settings = AppSettings();

  static final Set<String> _spokenLabels = {};
  static DateTime _lastSpoken = DateTime.fromMillisecondsSinceEpoch(0);

  // USE INITIALIZED SETTINGS FROM APPSETTINGS (SETTINGS MODEL)
  static Future<void> initialize(AppSettings settings) async {
    _settings = settings;

    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.setLanguage(_settings.language);
    await _flutterTts.setSpeechRate(_settings.speechRate);
    await _flutterTts.setVolume(_settings.speechVolume);
  }

  // SPEAK AUDIO
  static Future<void> speak(String text) async {
    final now = DateTime.now();
    final timeGap = now.difference(_lastSpoken).inMilliseconds;

    // SPEAK AFTER 4S HAVE PASSED (AVOID REPETITIVE SPEECH OUTPUT)
    if (!_spokenLabels.contains(text) && timeGap > 2500) {
      try {
        _spokenLabels.add(text);
        _lastSpoken = now;

        //TEST NATIVE TTS FIRST
        await _flutterTts.speak(text);
      } catch (e) {
        // ERROR MESSAGE
        debugPrint('Text-To-Speech Error: $e');
      }
    }
  }

  // USE UPDATED SETTINGS
  static Future<void> updateSettings(AppSettings settings) async {
    _settings = settings;
    try {
      await _flutterTts.setLanguage(_settings.language);
      await _flutterTts.setSpeechRate(_settings.speechRate);
      await _flutterTts.setVolume(_settings.speechVolume);
    } catch (e) {
      // ERROR MESSAGE
      debugPrint('Text-To-Speech Settings Update Error: $e');
    }
  }

  // CLEAR SPOKEN LABEL CACHE
  static void clearLabelCache() {
    _spokenLabels.clear();
  }
}
