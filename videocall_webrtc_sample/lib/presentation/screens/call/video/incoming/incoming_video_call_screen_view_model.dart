import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:quickblox_sdk/models/qb_user.dart';
import 'package:videocall_webrtc_sample/managers/call_manager.dart';
import 'package:videocall_webrtc_sample/managers/ringtone_manager.dart';

import '../../../../../dependency/dependency_impl.dart';
import '../../../../../managers/callback/call_subscription.dart';
import '../../../../../managers/callback/call_subscription_impl.dart';
import '../../../../base_view_model.dart';
import '../../../../utils/error_parser.dart';

class IncomingVideoCallScreenViewModel extends BaseViewModel {
  final RingtoneManager _ringtoneManager = DependencyImpl.getInstance().getRingtoneManager();
  final CallManager _callManager = DependencyImpl.getInstance().getCallManager();

  final List<QBUser?> _users = [];

  List<QBUser?> get users => _users;

  bool isCallAccepted = false;
  bool isCallRejected = false;
  bool isCallEnd = false;

  CallSubscription? _callSubscription;

  Future<void> init(List<QBUser?> callUsers) async {
    try {
      _ringtoneManager.startRingtone();
    } on PlatformException catch (e) {
      _showError(ErrorParser.parseFrom(e));
    }

    _callSubscription = _createCallSubscription();
    _subscribeCall();
    _users.addAll(callUsers);
  }

  CallSubscription _createCallSubscription() {
    return CallSubscriptionImpl(
        tag: "IncomingCallScreenViewModel",
        onCallEnd: () {
          _ringtoneManager.release();
          isCallEnd = true;
          notifyListeners();
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
      await _ringtoneManager.release();
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
    super.dispose();
  }
}
