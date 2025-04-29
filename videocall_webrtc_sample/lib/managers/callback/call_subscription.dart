import 'package:quickblox_sdk/models/qb_rtc_session.dart';

abstract class CallSubscription {
  void onIncomingCall(QBRTCSession? session, String opponents);

  void onIncomingCall2(QBRTCSession? session, String opponents);

  void onRejectCall(int opponentId);

  void onAcceptCall(int opponentId);

  void onHangupCall(int opponentId);

  void onNotAnswer(int opponentId);

  void onEndCall();

  void onReceivedVideoTrack(int opponentId);

  void onError(String error);
}
