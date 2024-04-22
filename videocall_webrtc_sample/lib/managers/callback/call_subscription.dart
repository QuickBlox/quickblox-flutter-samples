import 'package:quickblox_sdk/models/qb_rtc_session.dart';

abstract class CallSubscription {
  void onIncomingCall(QBRTCSession? session);

  void onRejectCall(int opponentId);

  void onAcceptCall(int opponentId);

  void onHangupCall(int opponentId);

  void onNotAnswer(int opponentId);

  void onEndCall();

  void onReceivedVideoTrack(int opponentId);

  void onError(String error);
}
