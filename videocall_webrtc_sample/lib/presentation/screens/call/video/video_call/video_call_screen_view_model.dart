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

import '../../../../../entities/push_notification_entity.dart';
import '../../../../../managers/callkit_manager.dart';
import '../../../../../managers/push_notification_manager.dart';
import '../../../../base_view_model.dart';
import '../../../../utils/qb_user_parser.dart';

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

  Future<void> init(bool isIncoming, List<QBUser> users) async {
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

  Future<void> startOutgoingCall(List<QBUser> users) async {
    await startVideoCall(users);
    await _ringtoneManager.startBeeps();
    await _sendPushNotifications(users);
  }

  Future<void> _sendPushNotifications(List<QBUser> users) async {
    int currentUserId = await getCurrentUserId();
    for (QBUser? user in users) {
      if (user?.id != currentUserId) {
        _sendPushNotification([user?.id], users, ConferenceType.VIDEO);
      }
    }
  }

  Future<void> _sendPushNotification(
      List<int?> recipientIds, List<QBUser> opponents, ConferenceType conferenceType) async {
    int senderId = await getCurrentUserId();
    String senderName = await getCurrentUserName();
    String sessionId = await getCallSessionId();

    List<String> recipientIdsInString = recipientIds.where((e) => e != null).map((e) => e.toString()).toList();

    PushNotificationEntity entity = PushNotificationEntity(
      timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: senderId,
      senderName: senderName,
      sessionId: sessionId,
      opponents: opponents,
      recipientIds: recipientIdsInString,
      conferenceType: conferenceType,
      body: senderName,
    );

    PushNotificationManager().sendNotification(entity);
  }

  List<int> parseUserIdsFrom(List<QBUser?> users) {
    List<int> userIds = [];
    for (QBUser? user in users) {
      userIds.add(user?.id ?? 0);
    }
    return userIds;
  }

  List<String> parseUserNamesFrom(List<QBUser?> users) {
    List<String> userNames = [];
    for (QBUser? user in users) {
      userNames.add(user?.fullName ?? user?.login ?? "User");
    }
    return userNames;
  }

  Future<int> getCurrentUserId() async {
    return await _storageManager.getLoggedUserId();
  }

  Future<String> getCurrentUserName() async {
    return await _storageManager.getNameLogin();
  }

  Future<String> getCallSessionId() async {
    try {
      return await _callManager.getCallSessionId();
    } on PlatformException catch (e) {
      return "";
    }
  }

  Future<List<QBUser?>> removeLoggedUserFrom(List<QBUser?> users, int loggedUserId) async {
    List<QBUser?> opponents = [];

    for (QBUser? user in users) {
      if (user?.id != loggedUserId) {
        opponents.add(user);
      }
    }
    return opponents;
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
      onCallEnd: () async {
        await CallkitManager.endAllCallsInCallkit();

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

  Future<void> startVideoCall(List<QBUser> users) async {
    try {
      Map<String, Object> userInfo = {};

      String json = QBUserParser.serializeOpponents(users);
      userInfo['opponents'] = json;

      int loggedUserId = await _storageManager.getLoggedUserId();
      List<QBUser?> opponents = await removeLoggedUserFrom(users, loggedUserId);
      await _callManager.startVideoCall(opponents, userInfo: userInfo);

      await CallkitManager.showOutgoingCall(opponents, true);
    } on PlatformException catch (e) {
      showError(ErrorParser.parseFrom(e));
    }
  }

  Future<QBUser> getLoggedUser() async {
    QBUser loggedUSer = QBUser();
    loggedUSer.id = await getCurrentUserId();
    loggedUSer.fullName = await getCurrentUserName();
    return loggedUSer;
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
