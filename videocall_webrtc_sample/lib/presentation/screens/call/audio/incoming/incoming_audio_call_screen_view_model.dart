import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quickblox_sdk/auth/module.dart';
import 'package:quickblox_sdk/models/qb_user.dart';
import 'package:videocall_webrtc_sample/managers/call_manager.dart';
import 'package:videocall_webrtc_sample/presentation/utils/error_parser.dart';

import '../../../../../dependency/dependency_impl.dart';
import '../../../../../main.dart';
import '../../../../../managers/auth_manager.dart';
import '../../../../../managers/callback/call_subscription.dart';
import '../../../../../managers/callback/call_subscription_impl.dart';
import '../../../../../managers/callkit_manager.dart';
import '../../../../../managers/chat_manager.dart';
import '../../../../../managers/settings_manager.dart';
import '../../../../../managers/storage_manager.dart';
import '../../../../base_view_model.dart';

enum IncomingAudioCallLaunchedState { FOREGROUND_STATE, BACKGROUND_STATE }

class IncomingAudioCallScreenViewModel extends BaseViewModel {
  final CallManager _callManager = DependencyImpl.getInstance().getCallManager();
  final StorageManager _storageManager = DependencyImpl.getInstance().getStorageManager();
  final AuthManager _authManager = DependencyImpl.getInstance().getAuthManager();
  final ChatManager _chatManager = DependencyImpl.getInstance().getChatManager();
  final SettingsManager _settingsManager = DependencyImpl.getInstance().getSettingsManager();

  List<QBUser?>? _opponents;

  List<QBUser?>? get opponents => _opponents;

  bool isReceivedSession = false;
  bool callAccepted = false;
  bool callRejected = false;
  bool isCallEnd = false;
  CallSubscription? _callSubscription;
  IncomingAudioCallLaunchedState state = IncomingAudioCallLaunchedState.FOREGROUND_STATE;

  Future<void> init(List<QBUser?> opponents, IncomingAudioCallLaunchedState state) async {
    this.state = state;
    _opponents = opponents;

    _startTimer();
    if (state == IncomingAudioCallLaunchedState.FOREGROUND_STATE) {
      await _handleForegroundState();
    } else if (state == IncomingAudioCallLaunchedState.BACKGROUND_STATE) {
      await _handleBackgroundState();
    }
  }

  Timer? _timer;
  int _seconds = 8;

  void _startTimer() {
    _stopTimer();

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _seconds--;

      if (_seconds <= 0) {
        _stopTimer();
        isCallEnd = true;
        notifyListeners();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _handleForegroundState() async {
    _callSubscription = _createCallSubscription();
    _subscribeCall();
    // await acceptCall();
  }

  Future<void> _handleBackgroundState() async {
    await enableLogging();
    await initQBSDK();
    await checkSavedUserAndLogin();
    _callSubscription = _createCallSubscription();
    _subscribeCall();
    await connectToChat();
    await _initWebRTC();
  }

  Future<void> _initWebRTC() async {
    try {
      await _callManager.initAndSubscribeEvents();
    } on PlatformException catch (e) {
      showError(ErrorParser.parseFrom(e));
    }
  }

  @override
  void dispose() {
    _unsubscribeCall();
    _stopTimer();
    super.dispose();
  }

  Future<void> _subscribeCall() async {
    try {
      await _callManager.subscribeCall(_callSubscription);
    } on PlatformException catch (e) {
      _showIncomeError(ErrorParser.parseFrom(e));
    }
  }

  Future<void> _unsubscribeCall() async {
    try {
      await _callManager.unsubscribeCall(_callSubscription);
    } on PlatformException catch (e) {
      _showIncomeError(ErrorParser.parseFrom(e));
    }
  }

  Future<void> acceptCall() async {
    try {
      _stopTimer();
      await _callManager.acceptCall();
      callAccepted = true;
      notifyListeners();
    } on PlatformException catch (e) {
      _showIncomeError(ErrorParser.parseFrom(e));
    }
  }

  Future<void> rejectCall() async {
    try {
      await _callManager.rejectCall();
    } on PlatformException catch (e) {
      _showIncomeError(ErrorParser.parseFrom(e));
    }
  }

  void _showIncomeError(String errorMessage) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showError(errorMessage);
    });
  }

  Future<List<QBUser?>> getOpponents() async {
    int currentUserId = await _storageManager.getLoggedUserId();
    _opponents?.removeWhere((element) => element?.id == currentUserId);
    return opponents ?? [];
  }

  CallSubscription _createCallSubscription() {
    return CallSubscriptionImpl(
        tag: "IncomingCallScreenViewModel",
        onCallEnd: () {
          isCallEnd = true;
          notifyListeners();
        },
        onIncomingCall2: (session, opponentsNames) async {
          acceptCall();
        },
        onError: (errorMessage) {
          _showIncomeError(errorMessage);
        });
  }

  Future<void> connectToChat() async {
    try {
      final userId = await _storageManager.getLoggedUserId();
      final userPassword = await _storageManager.getUserPassword();
      await _chatManager.connect(userId, userPassword);
    } on PlatformException catch (e) {
      showError(ErrorParser.parseFrom(e));
    }
  }

  Future<void> checkSavedUserAndLogin() async {
    try {
      showLoading();

      bool isExistSavedUser = await _storageManager.isExistSavedUser();
      if (isExistSavedUser) {
        String userLogin = await _storageManager.getUserLogin();
        String userPassword = await _storageManager.getUserPassword();
        await _login(userLogin, userPassword);
      }

      hideLoading();
    } on PlatformException catch (e) {
      hideLoading();
      showError(ErrorParser.parseFrom(e));
    }
  }

  Future<void> _login(String userLogin, String userPassword) async {
    QBLoginResult qbLoginResult = await _authManager.login(userLogin, userPassword);
    if (qbLoginResult.qbUser?.id != null) {
      _storageManager.saveUserId(qbLoginResult.qbUser!.id!);
    }
  }

  Future<void> initQBSDK() async {
    try {
      final SettingsManager _settingsManager = DependencyImpl.getInstance().getSettingsManager();
      await _settingsManager.init(APPLICATION_ID, AUTH_KEY, AUTH_SECRET, ACCOUNT_KEY);

      String url = ICE_SEVER_URL;
      if (url.isNotEmpty) {
        String userName = ICE_SERVER_USER;
        String password = ICE_SERVER_PASSWORD;
        await _settingsManager.setIceServers(url, userName, password);
      }
    } on PlatformException catch (e) {
      showError(ErrorParser.parseFrom(e));
    }
  }

  Future<void> enableLogging() async {
    try {
      await _settingsManager.enableXMPPLogging();
      await _settingsManager.enableLogging();
    } on PlatformException catch (e) {
      showError(ErrorParser.parseFrom(e));
    }
  }
}
