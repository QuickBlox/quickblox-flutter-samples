import 'dart:async';

import 'package:flutter/material.dart';

class OvalBadge extends StatefulWidget {
  const OvalBadge({super.key});

  @override
  _OvalBadgeState createState() => _OvalBadgeState();
}

class _OvalBadgeState extends State<OvalBadge> {
  Timer? _timer;
  String _formattedTime = '00:00';
  int _hours = 0;
  int _minutes = 0;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), _updateTime);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTime(Timer timer) {
    _seconds++;
    if (_seconds == 60) {
      _seconds = 0;
      _minutes++;
      if (_minutes == 60) {
        _minutes = 0;
        _hours++;
      }
    }
    setState(() {
      if (_hours == 0) {
        _formattedTime = '${_formatTime(_minutes)}:${_formatTime(_seconds)}';
      } else {
        _formattedTime = '${_formatTime(_hours)}:${_formatTime(_minutes)}:${_formatTime(_seconds)}';
      }
    });
  }

  String _formatTime(int time) {
    return time.toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Container(
        alignment: Alignment.center,
        width: 60,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF414E5B),
        ),
        child: Text(
          _formattedTime,
          style: const TextStyle(
            decoration: TextDecoration.none,
            fontSize: 11,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
