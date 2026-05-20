import 'dart:io';
import 'package:record/record.dart';

class AudioRecorderService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _recordingPath;

  Future<bool> hasPermission() async {
    return await _audioRecorder.hasPermission();
  }

  Future<void> startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final tempDir = Directory.systemTemp;
      _recordingPath = '${tempDir.path}/vocaboo_speech_${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _recordingPath!,
      );
    }
  }

  Future<String?> stopRecording() async {
    final path = await _audioRecorder.stop();
    return path ?? _recordingPath;
  }

  void dispose() {
    _audioRecorder.dispose();
  }
}
