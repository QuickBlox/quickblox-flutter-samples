import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:videocall_webrtc_sample/managers/auth_manager.dart';
import 'package:videocall_webrtc_sample/managers/call_manager.dart';
import 'package:videocall_webrtc_sample/managers/chat_manager.dart';
import 'package:videocall_webrtc_sample/managers/settings_manager.dart';

import '../dependency/dependency_impl.dart';
import '../main.dart';
import 'callback/call_subscription_impl.dart';

const String _isolateName = 'background_call_manager_isolate';
const String _stopTimerEvent = 'stop_timer_event';

const String _tag = 'reject_call_manager';

class RejectCallManager {
  RejectCallManager._internal();

  static final RejectCallManager _instance = RejectCallManager._internal();
  int timerDelay = 5;

  Timer? _timer;

  String? login;
  String? password;
  int? userId;
  String? sessionId;
  RootIsolateToken? firebaseIsolateToken;

  final AuthManager _authManager = DependencyImpl.getInstance().getAuthManager();
  final SettingsManager _settingsManager = DependencyImpl.getInstance().getSettingsManager();
  final ChatManager _chatManager = DependencyImpl.getInstance().getChatManager();
  final CallManager _callManager = DependencyImpl.getInstance().getCallManager();

  static void initQb(
      String login, String password, int userId, String? sessionId, RootIsolateToken firebaseIsolateToken) async {
    bool isNotCorrectUserId = userId <= 0;
    if (_isNotCorrectValue(login) || _isNotCorrectValue(password) || isNotCorrectUserId) {
      print('$_tag: login, password or userId is not exist');
      return;
    }

    await RejectCallManager._instance._initQb(login, password, userId, sessionId, firebaseIsolateToken);
  }

  static void start(String login, String password, int userId, RootIsolateToken firebaseIsolateToken, String? sessionId,
      {int rejectWaitingSeconds = 5}) async {
    _setParameters(login, password, userId, firebaseIsolateToken, sessionId, rejectWaitingSeconds);

    _isolateHandler(RejectCallManager._instance);
  }

  static void startWithIsolate(
      String login, String password, int userId, RootIsolateToken firebaseIsolateToken, String? sessionId,
      {int rejectWaitingSeconds = 5}) async {
    _setParameters(login, password, userId, firebaseIsolateToken, sessionId, rejectWaitingSeconds);

    Isolate.spawn<RejectCallManager>(_isolateHandler, RejectCallManager._instance);
  }

  static void _setParameters(String login, String password, int userId, RootIsolateToken firebaseIsolateToken,
      String? sessionId, int rejectWaitingSeconds) {
    RejectCallManager._instance.login = login;
    RejectCallManager._instance.password = password;
    RejectCallManager._instance.userId = userId;

    RejectCallManager._instance.timerDelay = rejectWaitingSeconds;
    RejectCallManager._instance.firebaseIsolateToken = firebaseIsolateToken;
    RejectCallManager._instance.sessionId = sessionId;
  }

  static String? getSessionId() {
    return RejectCallManager._instance.sessionId;
  }

  static void _isolateHandler(RejectCallManager manager) async {
    bool isNotCorrectUserId = manager.userId == null && manager.userId! <= 0;
    bool isNotCorrectFirebaseIsolateToken = manager.firebaseIsolateToken == null;
    if (_isNotCorrectValue(manager.login) ||
        _isNotCorrectValue(manager.password) ||
        isNotCorrectUserId ||
        isNotCorrectFirebaseIsolateToken) {
      print('$_tag: login, password or userId is not exist');
      return;
    }

    BackgroundIsolateBinaryMessenger.ensureInitialized(manager.firebaseIsolateToken!);

    manager._rejectCallWithDelay(manager.sessionId!, manager.firebaseIsolateToken!, delayInSeconds: 4);

    manager.startTimer(manager.timerDelay);

    final receivePort = ReceivePort();
    IsolateNameServer.registerPortWithName(receivePort.sendPort, _isolateName);

    receivePort.listen((event) {
      if (event == _stopTimerEvent) {
        manager.stopTimer();
      }
    });
  }

  static bool _isNotCorrectValue(String? value) {
    return value == null || value.isEmpty;
  }

  static void stop() {
    final sendPort = IsolateNameServer.lookupPortByName(_isolateName);
    sendPort?.send(_stopTimerEvent);
  }

  void startTimer(int timerDelay) {
    stopTimer();
    _timer = Timer(Duration(seconds: timerDelay), () {
      _releaseCallManagerAndDisconnectChat();
    });
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _initQb(
      String login, String password, int userId, String? sessionId, RootIsolateToken firebaseIsolateToken) async {
    BackgroundIsolateBinaryMessenger.ensureInitialized(firebaseIsolateToken);
    try {
      await _enableLogging();
      await _initQBSDK();

      await _login(login, password);

      await _initManagers(userId, password);
    } on PlatformException catch (e) {
      print('$_tag: Error occurred: $e');
    }
  }

  Future<void> _login(String login, String password) async {
    try {
      await _authManager.login(login, password);
    } on PlatformException catch (e) {
      print('$_tag: Error occurred: $e');
    }
  }

  Future<void> _initManagers(
    int userId,
    String password,
  ) async {
    try {
      await _chatManager.connect(userId, password);
      await _callManager.init();

      await _callManager.initAndSubscribeEvents();
      await _callManager.subscribeCall(CallSubscriptionImpl(
          tag: "RejectCallManager",
          onCallEnd: () async {
            FlutterCallkitIncoming.endAllCalls();
          }));
    } on PlatformException catch (e) {
      print('$_tag: Error occurred: $e');
    }
  }

  Future<void> _rejectCallWithDelay(String sessionId, RootIsolateToken firebaseIsolateToken,
      {int delayInSeconds = 5}) async {
    await Future.delayed(Duration(seconds: delayInSeconds), () async {
      try {
        await _callManager.rejectCallBySessionId(sessionId);
        await Future.delayed(Duration(seconds: 1), () async {
          try {
            await _chatManager.disconnect();
          } on PlatformException catch (e) {
            print('$_tag: Error occurred: $e');
          }
        });

        stopTimer();
      } on PlatformException catch (e) {
        print('$_tag: Error occurred: $e');
        await _releaseCallManagerAndDisconnectChat();
        stopTimer();
      }
    });
  }

  Future<void> _enableLogging() async {
    await _settingsManager.enableXMPPLogging();
    await _settingsManager.enableLogging();
  }

  Future<void> _initQBSDK() async {
    await _settingsManager.init(APPLICATION_ID, AUTH_KEY, AUTH_SECRET, ACCOUNT_KEY);
  }

  Future<void> _releaseCallManagerAndDisconnectChat() async {
    try {
      await _callManager.release();
      await _chatManager.disconnect();
    } on PlatformException catch (e) {
      print('$_tag: Error occurred: $e');
    }
  }
}
