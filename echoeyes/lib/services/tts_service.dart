import 'package:echoeyes/models/settings_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class TTSService {
  static final FlutterTts _flutterTts = FlutterTts();
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static AppSettings _settings = AppSettings();

  static final Set<String> _spokenLabels = {};
  static DateTime _lastSpoken = DateTime.fromMillisecondsSinceEpoch(0);

  static Future<void> initialize(AppSettings settings) async {
    _settings = settings;
    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.setLanguage(_settings.language);
    await _flutterTts.setSpeechRate(_settings.speechRate);
    await _flutterTts.setVolume(_settings.speechVolume);
  }

  static Future<void> speak(String text) async {
    final now = DateTime.now();
    final timeGap = now.difference(_lastSpoken).inMilliseconds;

    if (!_spokenLabels.contains(text) && timeGap > 4000) {
      try {
        _spokenLabels.add(text);
        _lastSpoken = now;

        ///TEST native tts first
        var result = await _flutterTts.speak(text);
        if(result == 1) {
          return;
        } else {
          await _tryGtts(text);
        }
      } catch (e) {
        debugPrint('Text-To-Speech Error: $e');
        await _tryGtts(text);
      }
    }
  }

  static Future<void> _tryGtts(String text) async {
    final connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none){
      debugPrint("No internet connection.");
      return;
    }
    await _speakWithGtts(text);
    
  }

  static Future<void> _speakWithGtts(String text) async {
    try {
      final lang = _settings.language.split('-').first;
      final url = Uri.parse(
          "https://translate.google.com/translate_tts?ie=UTF-8&q=${Uri.encodeComponent(text)}&tl=$lang&client=tw-ob");

          final response = await http.get(url);
          if (response.statusCode == 200) {
            final dir = await getTemporaryDirectory();
            final file = File("${dir.path}/tts.mp3");
            await file.writeAsBytes(response.bodyBytes);
            await _audioPlayer.play(DeviceFileSource(file.path));
            } else {
              debugPrint("google Text-To-Sppeech request failed: ${response.statusCode}");
            }
            } catch (e) {
              debugPrint("google Text-To-Speech Fallback error: $e");
            }
    }
  

  static Future<void> updateSettings(AppSettings settings) async {
    _settings = settings;
    try {
      await _flutterTts.setLanguage(_settings.language);
      await _flutterTts.setSpeechRate(_settings.speechRate);
      await _flutterTts.setVolume(_settings.speechVolume);
    } catch (e) {
      debugPrint('Text-To-Speech Settings Update Error: $e');
    }
  }

  static void clearLabelCache() {
    _spokenLabels.clear();
  }
}
