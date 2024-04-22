import 'dart:async';

import 'package:flutter/material.dart';

class TimerWidget extends StatefulWidget {
  const TimerWidget({super.key});

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
   Timer? _timer;
  int _seconds = 0;
  int _minutes = 0;
  int _hours = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), _updateTimer);
  }

  void _updateTimer(Timer timer) {
    setState(() {
      _seconds++;
      if (_seconds == 60) {
        _seconds = 0;
        _minutes++;
      }
      if (_minutes == 60) {
        _minutes = 0;
        _hours++;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child:Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTimeText(_hours.toString().padLeft(2, '0')),
          _buildDivider(),
          _buildTimeText(_minutes.toString().padLeft(2, '0')),
          _buildDivider(),
          _buildTimeText(_seconds.toString().padLeft(2, '0')),
        ],
      )
    );
  }

  Widget _buildTimeText(String time) {
    return Text(
      time,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildDivider() {
    return const Text(
      ':',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}