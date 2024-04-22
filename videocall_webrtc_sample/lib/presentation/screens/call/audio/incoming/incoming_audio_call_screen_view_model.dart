import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quickblox_sdk/models/qb_user.dart';
import 'package:videocall_webrtc_sample/managers/call_manager.dart';
import 'package:videocall_webrtc_sample/managers/users_manager.dart';
import 'package:videocall_webrtc_sample/presentation/utils/error_parser.dart';

import '../../../../../dependency/dependency_impl.dart';
import '../../../../../managers/callback/call_subscription.dart';
import '../../../../../managers/callback/call_subscription_impl.dart';
import '../../../../../managers/ringtone_manager.dart';
import '../../../../../managers/storage_manager.dart';
import '../../../../base_view_model.dart';

class IncomingAudioCallScreenViewModel extends BaseViewModel {
  final RingtoneManager _ringtoneManager = DependencyImpl.getInstance().getRingtoneManager();
  final CallManager _callManager = DependencyImpl.getInstance().getCallManager();
  final UsersManager _usersManager = DependencyImpl.getInstance().getUsersManager();
  final StorageManager _storageManager = DependencyImpl.getInstance().getStorageManager();

  List<QBUser?>? opponents;

  bool callAccepted = false;
  bool callRejected = false;
  bool isCallEnd = false;
  CallSubscription? _callSubscription;

  Future<void> init(List<QBUser?>? opponents) async {
    try {
      _ringtoneManager.startRingtone();
    } on PlatformException catch (e) {
      _showIncomeError(ErrorParser.parseFrom(e));
    }
    _callSubscription = _createCallSubscription();
    _subscribeCall();
    this.opponents = opponents;
  }

  @override
  void dispose() {
    _unsubscribeCall();
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
      await _ringtoneManager.release();
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

  void loadOpponents(List<int>? opponentsIds) async {
    try {
      int currentUserId = await _storageManager.getLoggedUserId();

      opponentsIds?.remove(currentUserId);
      opponents = await _usersManager.getUsersByIds(opponentsIds);
    } on PlatformException catch (e) {
      _showIncomeError(ErrorParser.parseFrom(e));
    }
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
          _showIncomeError(errorMessage);
        });
  }
}
