import 'dart:async';

class TimerUtil {
  Timer _timer;

  void startTimer({int duration, Function callback}) {
    _timer = Timer(Duration(seconds: duration), callback);
  }

  void cancelTimer() {
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }
  }
}