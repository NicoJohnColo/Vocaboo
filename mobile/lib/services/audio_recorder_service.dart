import 'dart:io';
import 'package:record/record.dart';

class AudioRecorderService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _recordingPath;
  DateTime? _recordingStartedAt;

  static const Duration _minRecordingDuration = Duration(milliseconds: 1500);

  Future<bool> hasPermission() async {
    return await _audioRecorder.hasPermission();
  }

  Stream<double> get onAmplitudeChanged {
    return _audioRecorder.onAmplitudeChanged(const Duration(milliseconds: 50)).map((amp) {
      double current = amp.current;
      if (current < -40) current = -40;
      return (current + 40) / 40.0; // Normalizes to 0.0 - 1.0
    }).asBroadcastStream();
  }

  Future<void> startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final tempDir = Directory.systemTemp;
      _recordingPath = '${tempDir.path}/vocaboo_speech_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _recordingStartedAt = DateTime.now();

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
    // Enforce minimum recording duration so the MPEG4Writer writes enough
    // audio frames for the backend STT to return a meaningful result.
    if (_recordingStartedAt != null) {
      final elapsed = DateTime.now().difference(_recordingStartedAt!);
      if (elapsed < _minRecordingDuration) {
        await Future.delayed(_minRecordingDuration - elapsed);
      }
      _recordingStartedAt = null;
    }
    final path = await _audioRecorder.stop();
    return path ?? _recordingPath;
  }

  void dispose() {
    _audioRecorder.isRecording().then((recording) {
      if (recording) {
        _audioRecorder.stop().then((_) {
          _audioRecorder.dispose();
        }).catchError((e) {
          _audioRecorder.dispose();
        });
      } else {
        _audioRecorder.dispose();
      }
    }).catchError((e) {
      _audioRecorder.dispose();
    });
  }
}
