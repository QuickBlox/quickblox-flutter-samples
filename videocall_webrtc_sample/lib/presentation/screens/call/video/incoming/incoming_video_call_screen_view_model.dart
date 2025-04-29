import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:quickblox_sdk/auth/module.dart';
import 'package:quickblox_sdk/models/qb_user.dart';
import 'package:videocall_webrtc_sample/managers/call_manager.dart';

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
import '../../../../utils/error_parser.dart';

enum IncomingVideoCallLaunchedState { FOREGROUND_STATE, BACKGROUND_STATE }

class IncomingVideoCallScreenViewModel extends BaseViewModel {
  final CallManager _callManager = DependencyImpl.getInstance().getCallManager();
  final StorageManager _storageManager = DependencyImpl.getInstance().getStorageManager();
  final AuthManager _authManager = DependencyImpl.getInstance().getAuthManager();
  final ChatManager _chatManager = DependencyImpl.getInstance().getChatManager();
  final SettingsManager _settingsManager = DependencyImpl.getInstance().getSettingsManager();

  List<QBUser> _users = [];

  List<QBUser> get users => _users;

  bool isCallAccepted = false;
  bool isCallRejected = false;
  bool isCallEnd = false;
  bool isReceivedSession = false;

  CallSubscription? _callSubscription;

  IncomingVideoCallLaunchedState state = IncomingVideoCallLaunchedState.FOREGROUND_STATE;

  Timer? _timer;
  int _seconds = 8;

  Future<void> init(List<QBUser> opponents, IncomingVideoCallLaunchedState state) async {
    this.state = state;
    _users = opponents;

    _startTimer();

    if (state == IncomingVideoCallLaunchedState.FOREGROUND_STATE) {
      await _handleDefaultState();
    } else if (state == IncomingVideoCallLaunchedState.BACKGROUND_STATE) {
      await _handleBackgroundState();
    }
  }

  Future<void> _handleDefaultState() async {
    _callSubscription = _createCallSubscription();
    _subscribeCall();
    await loadCallUsers();
    // acceptCall();
  }

  Future<void> _handleBackgroundState() async {
    await _enableLogging();
    await _initQBSDK();
    await _checkSavedUserAndLogin();
    await loadCallUsers();
    _callSubscription = _createCallSubscription();
    _subscribeCall();

    await _connectToChat();
    await _initWebRTC();
  }

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

  Future<List<QBUser?>?> loadCallUsers() async {
    try {
      int currentUserId = await _storageManager.getLoggedUserId();

      QBUser? currentUser = _users.firstWhere((element) => element?.id == currentUserId);
      users.remove(currentUser);
      users.insert(0, currentUser);

      _callManager.addVideoCallEntities(_users);
      return users;
    } on PlatformException catch (e) {
      _showError(ErrorParser.parseFrom(e));
    }
    return null;
  }

  CallSubscription _createCallSubscription() {
    return CallSubscriptionImpl(
        tag: "IncomingCallScreenViewModel",
        onCallEnd: () {
          _stopTimer();
          isCallEnd = true;
          notifyListeners();
        },
        onIncomingCall2: (session, opponentsNames) {
          acceptCall();
        },
        onError: (errorMessage) {
          _showError(errorMessage);
        });
  }

  int getOpponentsCount() {
    return users.length;
  }

  Future<void> _subscribeCall() async {
    try {
      await _callManager.subscribeCall(_callSubscription);
    } on PlatformException catch (e) {
      _showError(ErrorParser.parseFrom(e));
    }
  }

  Future<void> _unsubscribeCall() async {
    try {
      await _callManager.unsubscribeCall(_callSubscription);
    } on PlatformException catch (e) {
      _showError(ErrorParser.parseFrom(e));
    }
  }

  Future<void> acceptCall() async {
    try {
      _stopTimer();
      isCallAccepted = true;
      notifyListeners();
    } on PlatformException catch (e) {
      _showError(ErrorParser.parseFrom(e));
    }
  }

  Future<void> enableVideo(bool enable) async {
    try {
      await _callManager.enableVideo(enable);
    } on PlatformException catch (e) {
      _showError(ErrorParser.parseFrom(e));
    }
  }

  Future<void> rejectCall() async {
    try {
      _stopTimer();

      await _callManager.rejectCall();
    } on PlatformException catch (e) {
      _showError(ErrorParser.parseFrom(e));
    }
  }

  void _showError(String errorMessage) {
    WidgetsBinding.instance.addPostFrameCallback((_) => showError(errorMessage));
  }

  @override
  void dispose() {
    _unsubscribeCall();
    _stopTimer();
    super.dispose();
  }

  Future<void> _initWebRTC() async {
    try {
      await _callManager.initAndSubscribeEvents();
    } on PlatformException catch (e) {
      showError(ErrorParser.parseFrom(e));
    }
  }

  Future<void> _connectToChat() async {
    try {
      final userId = await _storageManager.getLoggedUserId();
      final userPassword = await _storageManager.getUserPassword();
      await _chatManager.connect(userId, userPassword);
    } on PlatformException catch (e) {
      showError(ErrorParser.parseFrom(e));
    }
  }

  Future<void> _checkSavedUserAndLogin() async {
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

  Future<void> _initQBSDK() async {
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

  Future<void> _enableLogging() async {
    try {
      await _settingsManager.enableXMPPLogging();
      await _settingsManager.enableLogging();
    } on PlatformException catch (e) {
      showError(ErrorParser.parseFrom(e));
    }
  }

  List<String?> getOpponentsNames(List<QBUser?> list) {
    List<String> names = [];

    for (var user in list) {
      names.add(user?.fullName ?? user?.login ?? '');
    }
    return names;
  }
}
