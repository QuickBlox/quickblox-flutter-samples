import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quickblox_sdk/models/qb_user.dart';
import 'package:videocall_webrtc_sample/dependency/dependency_impl.dart';
import 'package:videocall_webrtc_sample/managers/call_manager.dart';

import '../../../../../managers/callback/call_subscription.dart';
import '../../../../../managers/callback/call_subscription_impl.dart';
import '../../../../../managers/ringtone_manager.dart';
import '../../../../base_view_model.dart';
import '../../../../utils/error_parser.dart';

class AudioCallScreenViewModel extends BaseViewModel {
  final CallManager _callManager = DependencyImpl.getInstance().getCallManager();
  final RingtoneManager _ringtoneManager = DependencyImpl.getInstance().getRingtoneManager();

  List<QBUser?>? _opponents;
  List<QBUser?>? get opponents => _opponents;

  bool _isStartedCall = false;

  bool get isStartedCall => _isStartedCall;

  bool _isEndCall = false;

  bool get isEndCall => _isEndCall;

  String? callAcceptErrorMessage;

  CallSubscription? _callSubscription;

  Future<void> init(bool isIncoming, List<QBUser?> opponents) async {
    _opponents = opponents;

    _callSubscription = _createCallSubscription();
    await _subscribeCall();

    if (isIncoming) {
      _isStartedCall = true;
      notifyListeners();
    } else {
      _ringtoneManager.startBeeps();
    }
  }

  int getOpponentsLength() {
    return _opponents?.length ?? 0;
  }

  CallSubscription _createCallSubscription() {
    return CallSubscriptionImpl(
        tag: "AudioCallScreenViewModel",
        onCallEnd: () {
          _ringtoneManager.release();
          _isEndCall = true;
          notifyListeners();
        },
        onCallAccept: (opponentId) {
          _ringtoneManager.release();
          _isStartedCall = true;
          notifyListeners();
        },
        onError: (errorMessage) {
          _showError(errorMessage);
        });
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

  void _showError(String errorMessage) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      callAcceptErrorMessage = errorMessage;
      notifyListeners();
    });
  }

  Future<void> enableAudio(bool enable) async {
    try {
      await _callManager.enableAudio(enable);
    } on PlatformException catch (e) {
      _showError(ErrorParser.parseFrom(e));
    }
  }

  Future<void> switchAudioOutput(AudioOutputTypes outputType) async {
    try {
      await _callManager.switchAudio(outputType);
    } on PlatformException catch (e) {
      _showError(ErrorParser.parseFrom(e));
    }
  }

  Future<void> hangUpCall() async {
    try {
      await _callManager.hangUpCall();
    } on PlatformException catch (e) {
      _showError(ErrorParser.parseFrom(e));
    }
  }
}
