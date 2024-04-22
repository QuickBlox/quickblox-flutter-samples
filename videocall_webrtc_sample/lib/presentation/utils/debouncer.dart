import 'dart:async';

import 'package:flutter/services.dart';

class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 300)});
  final Duration delay;
  Timer? _timer;

  void call(VoidCallback callback) {
    _timer?.cancel();
    _timer = Timer(delay, callback);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
