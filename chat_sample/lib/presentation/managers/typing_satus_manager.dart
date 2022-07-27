import 'dart:async';
import 'dart:ui';

enum TypingStates { start, stop }

class TypingStatusManager {
  static final TypingStatusManager _instance = TypingStatusManager._();

  TypingStatusManager._();

  bool _isNotTyping = true;
  static Timer? _timer;

  static void typing(Function(TypingStates) callback) {
    if (_instance._isNotTyping) {
      _instance._isNotTyping = false;
      callback(TypingStates.start);
    }

    _instance._restartTimer(() {
      _instance._isNotTyping = true;
      callback(TypingStates.stop);
    });
  }

  void _restartTimer(VoidCallback callback) {
    _timer?.cancel();
    _timer = Timer(Duration(seconds: 1), callback);
  }

  static void cancelTimer() {
    _instance._isNotTyping = true;
    _timer?.cancel();
  }
}
