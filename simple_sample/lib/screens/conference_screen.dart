import 'dart:async';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quickblox_sdk/conference/conference_video_view.dart';
import 'package:quickblox_sdk/conference/constants.dart';
import 'package:quickblox_sdk/models/qb_conference_rtc_session.dart';
import 'package:quickblox_sdk/quickblox_sdk.dart';
import 'package:quickblox_sdk_example/credentials.dart';
import 'package:quickblox_sdk_example/utils/dialog_utils.dart';
import 'package:quickblox_sdk_example/utils/snackbar_utils.dart';
import 'package:quickblox_sdk_example/widgets/blue_app_bar.dart';
import 'package:quickblox_sdk_example/widgets/blue_button.dart';

class ConferenceScreen extends StatefulWidget {
  static show(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => ConferenceScreen()));
  }

  @override
  State<StatefulWidget> createState() => _ConferenceScreenState();
}

class _ConferenceScreenState extends State<ConferenceScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String? _sessionId;

  ConferenceVideoViewController? _localVideoViewController;
  ConferenceVideoViewController? _remoteVideoViewController;

  StreamSubscription? _videoTrackSubscription;
  StreamSubscription? _participantReceivedSubscription;
  StreamSubscription? _participantLeftSubscription;
  StreamSubscription? _errorSubscription;
  StreamSubscription? _conferenceClosedSubscription;
  StreamSubscription? _conferenceStateChangedSubscription;

  @override
  void dispose() {
    super.dispose();

    unsubscribeVideoTrack();
    unsubscribeParticipantReceived();
    unsubscribeParticipantLeft();
    unsubscribeErrors();
    unsubscribeConferenceClosed();
    unsubscribeConferenceStateChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: BlueAppBar('Conference'),
        body: Center(
            child: SingleChildScrollView(
                child: Column(children: [
          BlueButton('init', () => init()),
          BlueButton('release', () => release()),
          BlueButton('release Video Views', () => releaseVideoViews()),
          BlueButton('create session', () => create(QBConferenceSessionTypes.VIDEO)),
          BlueButton('join as publisher', () => joinAsPublisher(QBConferenceSessionTypes.VIDEO)),
          BlueButton('get online participants', () => getOnlineParticipants()),
          BlueButton('leave session', () => leaveSession()),
          BlueButton('disable video', () => enableVideo(false)),
          BlueButton('enable video', () => enableVideo(true)),
          BlueButton('disable audio', () => enableAudio(false)),
          BlueButton('enable audio', () => enableAudio(true)),
          BlueButton('switch camera', () => switchCamera()),
          BlueButton('switch audio to LOUDSPEAKER', () => switchAudioOutput(QBConferenceAudioOutputTypes.LOUDSPEAKER)),
          BlueButton('switch audio to EARSPEAKER', () => switchAudioOutput(QBConferenceAudioOutputTypes.EARSPEAKER)),
          BlueButton('subscribe Conference events', () {
            subscribeVideoTrack();
            subscribeParticipantReceived();
            subscribeParticipantLeft();
            subscribeErrors();
            subscribeConferenceClosed();
            subscribeConferenceStateChanged();
          }),
          BlueButton('unsubscribe Conference events', () {
            unsubscribeVideoTrack();
            unsubscribeParticipantReceived();
            unsubscribeParticipantLeft();
            unsubscribeErrors();
            unsubscribeConferenceClosed();
            unsubscribeConferenceStateChanged();
          }),
          Container(margin: EdgeInsets.all(20.0), height: 1, width: double.maxFinite, color: Colors.grey),
          OrientationBuilder(builder: (context, orientation) {
            Alignment localVideoViewAlignment = orientation == Orientation.landscape
                ? const FractionalOffset(0.5, 0.1)
                : const FractionalOffset(0.0, 0.5);

            Alignment remoteVideoViewAlignment = orientation == Orientation.landscape
                ? const FractionalOffset(0.5, 0.5)
                : const FractionalOffset(1.0, 0.5);

            return Container(
                decoration: BoxDecoration(color: Colors.white),
                child: Stack(children: <Widget>[
                  _buildVideoView(localVideoViewAlignment, (controller) => _localVideoViewController = controller),
                  _buildVideoView(remoteVideoViewAlignment, (controller) => _remoteVideoViewController = controller)
                ]));
          })
        ]))));
  }

  Widget _buildVideoView(Alignment alignment, Function(ConferenceVideoViewController) callback) {
    return Align(
        alignment: alignment,
        child: Container(
            margin: EdgeInsets.all(10.0),
            width: 160.0,
            height: 160.0,
            child: ConferenceVideoView(onVideoViewCreated: callback),
            decoration: BoxDecoration(color: Colors.black54)));
  }

  Future<void> init() async {
    try {
      await QB.conference.init(JANUS_SERVER_URL);
      SnackBarUtils.showResult(_scaffoldKey, "Conference was initiated");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> release() async {
    try {
      await QB.conference.release();
      SnackBarUtils.showResult(_scaffoldKey, "Conference was released");
      _sessionId = null;
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> releaseVideoViews() async {
    try {
      await _localVideoViewController?.release();
      await _remoteVideoViewController?.release();
      SnackBarUtils.showResult(_scaffoldKey, "Video Views were released");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> create(int sessionType) async {
    try {
      QBConferenceRTCSession? session = await QB.conference.create(DIALOG_ID, sessionType);
      _sessionId = session!.id;
      SnackBarUtils.showResult(_scaffoldKey, "The session with id \n $_sessionId \n was created");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> joinAsPublisher(int sessionType) async {
    try {
      List<int?> participants = await QB.conference.joinAsPublisher(_sessionId!);

      for (int index = 0; index < participants.length; index++) {
        int userId = participants[index]!;
        subscribeToParticipant(_sessionId!, userId);
      }

      SnackBarUtils.showResult(_scaffoldKey, "Joined to session \n $_sessionId \n with participants $participants");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> getOnlineParticipants() async {
    try {
      List<int?> participants = await QB.conference.getOnlineParticipants(_sessionId!);
      SnackBarUtils.showResult(_scaffoldKey, "Online participants: \n $participants");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> subscribeToParticipant(String sessionId, int userId) async {
    try {
      await QB.conference.subscribeToParticipant(sessionId, userId);
      SnackBarUtils.showResult(_scaffoldKey, "Subscribed to $userId \n Session id: $sessionId");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> leaveSession() async {
    try {
      await QB.conference.leave(_sessionId!);
      SnackBarUtils.showResult(_scaffoldKey, "Session with id: \n $_sessionId \n was leaved");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> enableVideo(bool enable) async {
    try {
      await QB.conference.enableVideo(_sessionId!, enable: enable);
      SnackBarUtils.showResult(_scaffoldKey, "The video was enable $enable");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> enableAudio(bool enable) async {
    try {
      await QB.conference.enableAudio(_sessionId!, enable: enable);
      SnackBarUtils.showResult(_scaffoldKey, "The audio was enable $enable");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> switchCamera() async {
    try {
      await QB.conference.switchCamera(_sessionId!);
      SnackBarUtils.showResult(_scaffoldKey, "Camera was switched");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> switchAudioOutput(int output) async {
    try {
      await QB.conference.switchAudioOutput(output);
      SnackBarUtils.showResult(_scaffoldKey, "Audio was switched");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> startRenderingLocal() async {
    try {
      await _localVideoViewController!.play(_sessionId!, LOGGED_USER_ID);
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> startRenderingRemote(int opponentId) async {
    try {
      await _remoteVideoViewController!.play(_sessionId!, opponentId);
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> subscribeVideoTrack() async {
    if (_videoTrackSubscription != null) {
      SnackBarUtils.showResult(
          _scaffoldKey, "You already have a subscription:" + QBConferenceEventTypes.CONFERENCE_VIDEO_TRACK_RECEIVED);
      return;
    }

    try {
      _videoTrackSubscription =
          await QB.conference.subscribeConferenceEvent(QBConferenceEventTypes.CONFERENCE_VIDEO_TRACK_RECEIVED, (data) {
        Map<dynamic, dynamic> payloadMap = Map<dynamic, dynamic>.from(data["payload"]);

        int opponentId = payloadMap["userId"];

        if (opponentId == LOGGED_USER_ID) {
          startRenderingLocal();
        } else {
          startRenderingRemote(opponentId);
        }

        SnackBarUtils.showResult(_scaffoldKey, "Received video track for user : $opponentId");
      });
      SnackBarUtils.showResult(_scaffoldKey, "Subscribed: " + QBConferenceEventTypes.CONFERENCE_VIDEO_TRACK_RECEIVED);
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  void subscribeParticipantReceived() async {
    if (_participantReceivedSubscription != null) {
      SnackBarUtils.showResult(
          _scaffoldKey, "You already have a subscription:" + QBConferenceEventTypes.CONFERENCE_PARTICIPANT_RECEIVED);
      return;
    }

    try {
      _participantReceivedSubscription =
          await QB.conference.subscribeConferenceEvent(QBConferenceEventTypes.CONFERENCE_PARTICIPANT_RECEIVED, (data) {
        int userId = data["payload"]["userId"];
        String sessionId = data["payload"]["sessionId"];

        SnackBarUtils.showResult(_scaffoldKey, "Received participant: $userId \n Session id: $sessionId");

        subscribeToParticipant(sessionId, userId);
      });
      SnackBarUtils.showResult(_scaffoldKey, "Subscribed: " + QBConferenceEventTypes.CONFERENCE_PARTICIPANT_RECEIVED);
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  void subscribeParticipantLeft() async {
    if (_participantLeftSubscription != null) {
      SnackBarUtils.showResult(
          _scaffoldKey, "You already have a subscription:" + QBConferenceEventTypes.CONFERENCE_PARTICIPANT_LEFT);
      return;
    }

    try {
      _participantLeftSubscription =
          await QB.conference.subscribeConferenceEvent(QBConferenceEventTypes.CONFERENCE_PARTICIPANT_LEFT, (data) {
        String sessionId = data["payload"]["sessionId"];
        int userId = data["payload"]["userId"];

        SnackBarUtils.showResult(_scaffoldKey, "Left participant: $userId \n Session id: $sessionId");

        unsubscribeFromParticipant(sessionId, userId);
      });
      SnackBarUtils.showResult(_scaffoldKey, "Subscribed: " + QBConferenceEventTypes.CONFERENCE_PARTICIPANT_LEFT);
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> unsubscribeFromParticipant(String sessionId, int userId) async {
    try {
      await QB.conference.unsubscribeFromParticipant(sessionId, userId);
      SnackBarUtils.showResult(_scaffoldKey, "Unsubscribed to $userId \n Session id: $sessionId");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  void subscribeErrors() async {
    if (_errorSubscription != null) {
      SnackBarUtils.showResult(
          _scaffoldKey, "You already have a subscription:" + QBConferenceEventTypes.CONFERENCE_ERROR_RECEIVED);
      return;
    }

    try {
      _errorSubscription =
          await QB.conference.subscribeConferenceEvent(QBConferenceEventTypes.CONFERENCE_ERROR_RECEIVED, (data) {
        String errorMessage = data["payload"]["errorMessage"];
        String sessionId = data["payload"]["sessionId"];

        SnackBarUtils.showResult(_scaffoldKey, "Received error: $errorMessage \n Session id: $sessionId");
      });
      SnackBarUtils.showResult(_scaffoldKey, "Subscribed: " + QBConferenceEventTypes.CONFERENCE_ERROR_RECEIVED);
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  void subscribeConferenceClosed() async {
    if (_conferenceClosedSubscription != null) {
      SnackBarUtils.showResult(
          _scaffoldKey, "You already have a subscription:" + QBConferenceEventTypes.CONFERENCE_CLOSED);
      return;
    }

    try {
      _conferenceClosedSubscription =
          await QB.conference.subscribeConferenceEvent(QBConferenceEventTypes.CONFERENCE_CLOSED, (data) {
        String sessionId = data["payload"]["sessionId"];

        SnackBarUtils.showResult(_scaffoldKey, "Closed session: $sessionId");
      });
      SnackBarUtils.showResult(_scaffoldKey, "Subscribed: " + QBConferenceEventTypes.CONFERENCE_CLOSED);
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  void subscribeConferenceStateChanged() async {
    if (_conferenceStateChangedSubscription != null) {
      SnackBarUtils.showResult(
          _scaffoldKey, "You already have a subscription:" + QBConferenceEventTypes.CONFERENCE_STATE_CHANGED);
      return;
    }

    try {
      _conferenceStateChangedSubscription =
          await QB.conference.subscribeConferenceEvent(QBConferenceEventTypes.CONFERENCE_STATE_CHANGED, (data) {
        int state = data["payload"]["state"];
        String sessionId = data["payload"]["sessionId"];

        String parsedState = _parseState(state);

        SnackBarUtils.showResult(_scaffoldKey, "Changed state to: $parsedState \n for session $sessionId");
      });
      SnackBarUtils.showResult(_scaffoldKey, "Subscribed: " + QBConferenceEventTypes.CONFERENCE_STATE_CHANGED);
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  String _parseState(int state) {
    String parsedState = "";

    switch (state) {
      case 0:
        parsedState = "NEW";
        break;
      case 1:
        parsedState = "PENDING";
        break;
      case 2:
        parsedState = "CONNECTING";
        break;
      case 3:
        parsedState = "CONNECTED";
        break;
      case 4:
        parsedState = "CLOSED";
        break;
    }

    return parsedState;
  }

  void unsubscribeParticipantReceived() {
    _participantReceivedSubscription?.cancel();
    _participantReceivedSubscription = null;
  }

  void unsubscribeParticipantLeft() {
    _participantLeftSubscription?.cancel();
    _participantLeftSubscription = null;
  }

  void unsubscribeVideoTrack() {
    _videoTrackSubscription?.cancel();
    _videoTrackSubscription = null;
  }

  void unsubscribeErrors() {
    _errorSubscription?.cancel();
    _errorSubscription = null;
  }

  void unsubscribeConferenceClosed() {
    _conferenceClosedSubscription?.cancel();
    _conferenceClosedSubscription = null;
  }

  void unsubscribeConferenceStateChanged() {
    _conferenceStateChangedSubscription?.cancel();
    _conferenceStateChangedSubscription = null;
  }
}
