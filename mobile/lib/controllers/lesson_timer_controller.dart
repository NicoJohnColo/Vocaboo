import 'dart:async';
import 'package:flutter/foundation.dart';

class LessonTimerController extends ChangeNotifier {
  Timer? _timer;
  int _secondsRemaining = 10;
  final int _duration;
  final VoidCallback onTimeUp;
  
  LessonTimerController({int duration = 10, required this.onTimeUp}) : _duration = duration {
    _secondsRemaining = duration;
  }

  int get secondsRemaining => _secondsRemaining;
  bool get isRunning => _timer != null && _timer!.isActive;

  void start({int? duration}) {
    stop();
    if (duration != null) {
      _secondsRemaining = duration;
    } else {
      _secondsRemaining = _duration;
    }
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        notifyListeners();
      } else {
        stop();
        onTimeUp();
      }
    });
  }

  void pause() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
      notifyListeners();
    }
  }

  void resume() {
    if (_secondsRemaining > 0 && !isRunning) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
          notifyListeners();
        } else {
          stop();
          onTimeUp();
        }
      });
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
