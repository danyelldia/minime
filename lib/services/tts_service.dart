import 'package:flutter_tts/flutter_tts.dart';

/// Simple wrapper around text-to-speech, used to read notes/to-dos aloud
/// on request (button on the card) or when the user opens the app from
/// a notification.
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    _initialized = true;
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _ensureInit();
    await _tts.stop();
    await _tts.speak(text);
  }
}
