import 'dart:async';
import 'dart:collection';

import 'package:quickblox_sdk/models/qb_rtc_session.dart';
import 'package:quickblox_sdk/models/qb_user.dart';
import 'package:quickblox_sdk/quickblox_sdk.dart';
import 'package:quickblox_sdk/webrtc/constants.dart';
import 'package:videocall_webrtc_sample/entities/video_call_entity.dart';

import '../mappers/qb_rtc_session_mapper.dart';
import 'callback/call_subscription.dart';

enum CallTypes { AUDIO, VIDEO }

enum AudioOutputTypes { EAR_SPEAKER, LOUDSPEAKER, HEADPHONES, BLUETOOTH }

class CallManager {
  final Set<CallSubscription> _callSubscriptions = <CallSubscription>{};

  final LinkedHashSet<VideoCallEntity> _videoCallEntities = LinkedHashSet<VideoCallEntity>();

  LinkedHashSet<VideoCallEntity> get videoCallEntities => _videoCallEntities;

  QBRTCSession? _session;

  StreamSubscription? _incomeCallSubscription;
  StreamSubscription? _callEndSubscription;
  StreamSubscription? _rejectSubscription;
  StreamSubscription? _acceptSubscription;
  StreamSubscription? _hangUpSubscription;
  StreamSubscription? _notAnswerSubscription;
  StreamSubscription? _videoTracksSubscription;

  Future<void> subscribeCall(CallSubscription? callSubscription) async {
    if (callSubscription != null) {
      _callSubscriptions.add(callSubscription);
    }
  }

  Future<void> unsubscribeCall(CallSubscription? callSubscription) async {
    _callSubscriptions.remove(callSubscription);
  }

  void _notifyIncome(QBRTCSession? session) {
    for (var callSubscription in _callSubscriptions) {
      callSubscription.onIncomingCall(session);
    }
  }

  void _notifyReject(int opponentId) {
    for (var callSubscription in _callSubscriptions) {
      callSubscription.onRejectCall(opponentId);
    }
  }

  void _notifyAccept(int opponentId) {
    for (var callSubscription in _callSubscriptions) {
      callSubscription.onAcceptCall(opponentId);
    }
  }

  void _notifyHangup(int opponentId) {
    for (var callSubscription in _callSubscriptions) {
      callSubscription.onHangupCall(opponentId);
    }
  }

  void _notifyNotAnswer(int opponentId) {
    for (var callSubscription in _callSubscriptions) {
      callSubscription.onNotAnswer(opponentId);
    }
  }

  void _notifyReceivedVideoTrack(int opponentId) {
    for (var callSubscription in _callSubscriptions) {
      callSubscription.onReceivedVideoTrack(opponentId);
    }
  }

  void _notifyCallEnd() {
    for (var callSubscription in _callSubscriptions) {
      callSubscription.onEndCall();
    }
  }

  void _notifyError(String error) {
    for (var callSubscription in _callSubscriptions) {
      callSubscription.onError(error);
    }
  }

  void addVideoCallEntities(Iterable<QBUser?> users) {
    for (final user in users) {
      VideoCallEntity entity = VideoCallEntity(user);
      videoCallEntities.add(entity);
    }
  }

  void _clearVideoCallEntities() {
    videoCallEntities.clear();
  }

  bool isActiveCall() {
    return _session != null;
  }

  Future<void> enableAudio(bool enable) async {
    if (_session != null) {
      String sessionId = _session?.id ?? "";
      await QB.webrtc.enableAudio(sessionId, enable: enable);
    }
  }

  Future<void> enableVideo(bool enable) async {
    if (_session != null) {
      String sessionId = _session?.id ?? "";
      await QB.webrtc.enableVideo(sessionId, enable: enable);
    }
  }

  Future<void> switchAudio(AudioOutputTypes audioOutputType) async {
    int outputType = _parseAudioOutputType(audioOutputType);
    await QB.webrtc.switchAudioOutput(outputType);
  }

  Future<void> switchCamera() async {
    if (_session != null) {
      String sessionId = _session?.id ?? "";
      await QB.webrtc.switchCamera(sessionId);
    }
  }

  int _parseAudioOutputType(AudioOutputTypes outputType) {
    switch (outputType) {
      case AudioOutputTypes.EAR_SPEAKER:
        return 0;
      case AudioOutputTypes.LOUDSPEAKER:
        return 1;
      case AudioOutputTypes.HEADPHONES:
        return 2;
      case AudioOutputTypes.BLUETOOTH:
        return 3;
    }
  }

  Future<void> startAudioCall(List<QBUser?> users) async {
    List<int> userIds = _getUserIdsFrom(users);
    await _createSession(userIds, CallTypes.AUDIO);
  }

  Future<void> startVideoCall(List<QBUser?> users) async {
    List<int> userIds = _getUserIdsFrom(users);
    await _createSession(userIds, CallTypes.VIDEO);
  }

  List<int> _getUserIdsFrom(List<QBUser?> users) {
    List<int> list = [];
    for (final user in users) {
      if (user?.id != null) {
        list.add(user!.id!);
      }
    }
    return list;
  }

  Future<QBRTCSession?> _createSession(List<int> opponentsIds, CallTypes callType) async {
    int sessionCallType = _parseCallType(callType);
    QBRTCSession? session = await QB.webrtc.call(opponentsIds, sessionCallType);
    _session = session;
    return session;
  }

  int _parseCallType(CallTypes callType) {
    switch (callType) {
      case CallTypes.VIDEO:
        return 1;
      case CallTypes.AUDIO:
        return 2;
    }
  }

  Future<void> rejectCall() async {
    if (_session != null) {
      String sessionId = _session?.id ?? "";
      await QB.webrtc.reject(sessionId);
    }
  }

  Future<void> acceptCall() async {
    if (_session != null) {
      String sessionId = _session?.id ?? "";
      await QB.webrtc.accept(sessionId);
    }
  }

  Future<void> hangUpCall() async {
    if (_session != null) {
      String sessionId = _session?.id ?? "";
      QB.webrtc.hangUp(sessionId);
    }
  }

  Future<List<int>?> getOpponentIdsFromCall() async {
    List<int>? opponentsIds = _session?.opponentsIds;
    int? initiatorId = _session?.initiatorId;
    if (initiatorId != null) {
      opponentsIds?.add(initiatorId);
    }
    return opponentsIds;
  }

  Future<void> initAndSubscribeEvents() async {
    await _setRTCConfigs();
    await QB.webrtc.init();
    await _subscribeEvents();
  }

  Future<void> _setRTCConfigs() async {
    await QB.rtcConfig.setAnswerTimeInterval(30);
    await QB.rtcConfig.setDialingTimeInterval(15);
  }

  Future<void> _subscribeEvents() async {
    await _subscribeIncoming();
    await _subscribeHangUp();
    await _subscribeCallEnd();
    await _subscribeAccept();
    await _subscribeReject();
    await _subscribeNotAnswer();
    await _subscribeVideoTracks();
  }

  Future<void> _subscribeIncoming() async {
    _incomeCallSubscription = await QB.webrtc.subscribeRTCEvent(QBRTCEventTypes.CALL, (data) async {
      final session = _parseSessionFrom(data);
      if (isActiveCall()) {
        await QB.webrtc.reject(session!.id!);
      } else {
        _session = session;
        _notifyIncome(_session);
      }
    }, onErrorMethod: (e) => _notifyError(e.toString()));
  }

  QBRTCSession? _parseSessionFrom(dynamic data) {
    Map<dynamic, dynamic> payloadMap = Map<dynamic, dynamic>.from(data["payload"]);
    Map<dynamic, dynamic> sessionMap = Map<dynamic, dynamic>.from(payloadMap["session"]);

    final session = QBRTCSessionMapper.mapToQBRtcSession(sessionMap);
    return session;
  }

  Future<void> _subscribeCallEnd() async {
    _callEndSubscription =
        await QB.webrtc.subscribeRTCEvent(QBRTCEventTypes.CALL_END, (data) async {
      final session = _parseSessionFrom(data);
      if (session?.id != _session?.id) {
        return;
      }

      _session = null;
      await _releaseViews();
      _clearVideoCallEntities();

      _notifyCallEnd();
    }, onErrorMethod: (e) => _notifyError(e.toString()));
  }

  Future<void> _subscribeNotAnswer() async {
    _notAnswerSubscription = await QB.webrtc.subscribeRTCEvent(QBRTCEventTypes.NOT_ANSWER, (data) {
      int opponentId = data["payload"]["userId"];

      _notifyNotAnswer(opponentId);
    }, onErrorMethod: (e) => _notifyError(e.toString()));
  }

  Future<void> _subscribeReject() async {
    _rejectSubscription = await QB.webrtc.subscribeRTCEvent(QBRTCEventTypes.REJECT, (data) {
      int opponentId = data["payload"]["userId"];

      _notifyReject(opponentId);
    }, onErrorMethod: (e) => _notifyError(e.toString()));
  }

  Future<void> _subscribeAccept() async {
    _acceptSubscription = await QB.webrtc.subscribeRTCEvent(QBRTCEventTypes.ACCEPT, (data) {
      int opponentId = data["payload"]["userId"];
      _notifyAccept(opponentId);
    }, onErrorMethod: (e) => _notifyError(e.toString()));
  }

  Future<void> _subscribeHangUp() async {
    _hangUpSubscription = await QB.webrtc.subscribeRTCEvent(QBRTCEventTypes.HANG_UP, (data) {
      int opponentId = data["payload"]["userId"];

      VideoCallEntity? entity = getEntityBy(opponentId);
      entity?.releaseVideo();

      _notifyHangup(opponentId);
    }, onErrorMethod: (e) => _notifyError(e.toString()));
  }

  VideoCallEntity? getEntityBy(int opponentId) {
    try {
      return _videoCallEntities.firstWhere((element) => element.userId == opponentId);
    } on StateError catch (e) {
      return null;
    }
  }

  Future<void> _subscribeVideoTracks() async {
    _videoTracksSubscription =
        await QB.webrtc.subscribeRTCEvent(QBRTCEventTypes.RECEIVED_VIDEO_TRACK, (data) {
      Map<dynamic, dynamic> payloadMap = Map<dynamic, dynamic>.from(data["payload"]);

      int opponentId = payloadMap["userId"];

      VideoCallEntity? entity = getEntityBy(opponentId);
      entity?.playVideo(_session!.id!);

      _notifyReceivedVideoTrack(opponentId);
    });
  }

  Future<void> release() async {
    await unsubscribeEvents();
    await _releaseViews();
    await QB.webrtc.release();
  }

  Future<void> unsubscribeEvents() async {
    _unsubscribeIncoming();
    _unsubscribeCallEnd();
    _unsubscribeReject();
    _unsubscribeAccept();
    _unsubscribeHangup();
    _unsubscribeNotAnswer();
    _unsubscribeVideoTracks();
  }

  Future<void> _releaseViews() async {
    for (var entity in _videoCallEntities) {
      await entity.releaseVideo();
    }
  }

  Future<void> _unsubscribeIncoming() async {
    await _incomeCallSubscription?.cancel();
    _incomeCallSubscription = null;
  }

  Future<void> _unsubscribeCallEnd() async {
    await _callEndSubscription?.cancel();
    _callEndSubscription = null;
  }

  void _unsubscribeReject() {
    _rejectSubscription?.cancel();
    _rejectSubscription = null;
  }

  void _unsubscribeAccept() {
    _acceptSubscription?.cancel();
    _acceptSubscription = null;
  }

  void _unsubscribeHangup() {
    _hangUpSubscription?.cancel();
    _hangUpSubscription = null;
  }

  void _unsubscribeNotAnswer() {
    _notAnswerSubscription?.cancel();
    _notAnswerSubscription = null;
  }

  void _unsubscribeVideoTracks() {
    _videoTracksSubscription?.cancel();
    _videoTracksSubscription = null;
  }
}
