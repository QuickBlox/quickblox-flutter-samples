import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quickblox_sdk/models/qb_user.dart';
import 'package:videocall_webrtc_sample/dependency/dependency_impl.dart';
import 'package:videocall_webrtc_sample/entities/video_call_entity.dart';
import 'package:videocall_webrtc_sample/managers/call_manager.dart';
import 'package:videocall_webrtc_sample/managers/callback/call_subscription.dart';
import 'package:videocall_webrtc_sample/managers/callback/call_subscription_impl.dart';
import 'package:videocall_webrtc_sample/managers/ringtone_manager.dart';
import 'package:videocall_webrtc_sample/managers/storage_manager.dart';
import 'package:videocall_webrtc_sample/presentation/utils/error_parser.dart';

import '../../../../base_view_model.dart';

class VideoCallScreenViewModel extends BaseViewModel {
  final CallManager _callManager = DependencyImpl.getInstance().getCallManager();
  final RingtoneManager _ringtoneManager = DependencyImpl.getInstance().getRingtoneManager();
  final StorageManager _storageManager = DependencyImpl.getInstance().getStorageManager();

  String? _opponentActionMessage;

  String? get opponentActionMessage => _opponentActionMessage;

  bool _isStartedCall = false;

  bool get isStartedCall => _isStartedCall;

  bool _isEndCall = false;

  bool get isEndCall => _isEndCall;

  CallSubscription? _callSubscription;

  Future<void> init(bool isIncoming, List<QBUser?> users) async {
    _callSubscription = _createCallSubscription(users);
    await _subscribeCall();

    if (isIncoming) {
      await startIncomingCall();
    } else {
      await startOutgoingCall(users);
    }

    await _callManager.switchAudio(AudioOutputTypes.LOUDSPEAKER);
  }

  Future<void> startIncomingCall() async {
    _isStartedCall = true;
    await _callManager.acceptCall();

    notifyListeners();
  }

  Future<void> startOutgoingCall(List<QBUser?> users) async {
    int loggedUserId = await _storageManager.getLoggedUserId();
    List<QBUser?> opponents = await removeLoggedUserFrom(users, loggedUserId);

    await startVideoCall(opponents);
    await _ringtoneManager.startBeeps();
  }

  Future<List<QBUser?>> removeLoggedUserFrom(List<QBUser?> users, int loggedUserId) async {
    try {
      QBUser? loggedUser = users.firstWhere((element) => element?.id == loggedUserId);
      users.remove(loggedUser);
      return users;
    } on StateError catch (e) {
      print(e.message);
    }
    return users;
  }

  List<VideoCallEntity> getVideoCallEntities() {
    return _callManager.videoCallEntities.toList();
  }

  String getOpponentNames(List<QBUser?> users) {
    bool isNotExistOpponents = users.length < 2;
    if (isNotExistOpponents) {
      return "UserName";
    }

    bool isOnlyOneOpponent = users.length == 2;
    if (isOnlyOneOpponent) {
      String opponentNames = users[1]?.fullName ?? users[1]?.login ?? "";
      return opponentNames;
    }

    String opponentNames = "";
    for (var i = 1; i < users.length; i++) {
      opponentNames = '$opponentNames, ${users[i]?.fullName ?? users[i]?.login}';
    }

    return opponentNames;
  }

  CallSubscription _createCallSubscription(List<QBUser?> users) {
    return CallSubscriptionImpl(
      tag: "AudioCallScreenViewModel",
      onCallEnd: () {
        _ringtoneManager.release();
        _isEndCall = true;
        notifyListeners();
      },
      onCallAccept: (userId) {
        _ringtoneManager.release();
        _isStartedCall = true;
        notifyListeners();
      },
      onNotAnswer: (userId) {
        String? name = getUserNameBy(users, userId);
        _showOpponentActionMessage("$name is not answering.");
      },
      onHangup: (userId) {
        String? name = getUserNameBy(users, userId);
        _showOpponentActionMessage("$name hung up.");
      },
      onCallRejected: (userId) {
        String? name = getUserNameBy(users, userId);
        _showOpponentActionMessage("$name rejected the call.");
      },
      onError: (errorMessage) {
        _showError(errorMessage);
      },
    );
  }

  String? getUserNameBy(List<QBUser?> users, int userId) {
    try {
      QBUser? user = users.firstWhere((element) => element?.id == userId);
      return user?.fullName ?? user?.login;
    } on StateError catch (e) {
      return "UserName";
    }
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

  Future<void> startVideoCall(List<QBUser?> users) async {
    try {
      await _callManager.startVideoCall(users);
    } on PlatformException catch (e) {
      showError(ErrorParser.parseFrom(e));
    }
  }

  Future<void> enableAudio(bool enable) async {
    try {
      await _callManager.enableAudio(enable);
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

  Future<void> switchAudioOutput(AudioOutputTypes outputType) async {
    try {
      await _callManager.switchAudio(outputType);
    } on PlatformException catch (e) {
      _showError(ErrorParser.parseFrom(e));
    }
  }

  Future<void> switchCamera() async {
    try {
      await _callManager.switchCamera();
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

  void _showOpponentActionMessage(String message) {
    _opponentActionMessage = message;
    notifyListeners();
  }

  void _showError(String errorMessage) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showError(errorMessage);
    });
  }

  @override
  void dispose() {
    _unsubscribeCall();
    super.dispose();
  }
}
