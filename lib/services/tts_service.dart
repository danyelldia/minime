import 'package:flutter_tts/flutter_tts.dart';

/// Wrapper simplu peste text-to-speech, folosit pentru citirea cu voce
/// a notitelor/to-do-urilor - la cerere (buton in card) sau cand userul
/// deschide aplicatia dintr-o notificare.
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    await _tts.setLanguage('ro-RO');
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
