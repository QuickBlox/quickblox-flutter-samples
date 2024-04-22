import 'package:quickblox_sdk/models/qb_rtc_session.dart';

import 'call_subscription.dart';

class CallSubscriptionImpl implements CallSubscription {
  CallSubscriptionImpl({
    required String tag,
    void Function(QBRTCSession? session)? onIncomingCall,
    void Function(int opponentId)? onCallRejected,
    void Function(int opponentId)? onCallAccept,
    void Function(int opponentId)? onHangup,
    void Function(int opponentId)? onNotAnswer,
    void Function(int opponentId)? onReceivedVideoTrack,
    void Function()? onCallEnd,
    void Function(String error)? onError,
  })  : _tag = tag,
        _onIncomingCall = onIncomingCall,
        _onCallRejected = onCallRejected,
        _onCallAccept = onCallAccept,
        _onHangup = onHangup,
        _onNotAnswer = onNotAnswer,
        _onReceivedVideoTrack = onReceivedVideoTrack,
        _onCallEnd = onCallEnd,
        _onError = onError;

  final String _tag;
  final void Function(QBRTCSession? session)? _onIncomingCall;
  final void Function(int opponentId)? _onCallRejected;
  final void Function(int opponentId)? _onCallAccept;
  final void Function(int opponentId)? _onHangup;
  final void Function(int opponentId)? _onNotAnswer;
  final void Function(int opponentId)? _onReceivedVideoTrack;
  final void Function()? _onCallEnd;
  final void Function(String error)? _onError;

  @override
  void onIncomingCall(QBRTCSession? session) {
    if (_onIncomingCall != null) {
      _onIncomingCall!(session);
    }
  }

  @override
  void onRejectCall(int opponentId) {
    if (_onCallRejected != null) {
      _onCallRejected!(opponentId);
    }
  }

  @override
  void onAcceptCall(int opponentId) {
    if (_onCallAccept != null) {
      _onCallAccept!(opponentId);
    }
  }

  @override
  void onHangupCall(int opponentId) {
    if (_onHangup != null) {
      _onHangup!(opponentId);
    }
  }

  @override
  void onNotAnswer(int opponentId) {
    if (_onNotAnswer != null) {
      _onNotAnswer!(opponentId);
    }
  }

  @override
  void onEndCall() {
    if (_onCallEnd != null) {
      _onCallEnd!();
    }
  }

  @override
  void onError(String error) {
    if (_onError != null) {
      _onError!(error);
    }
  }

  @override
  void onReceivedVideoTrack(int opponentId) {
    if (_onReceivedVideoTrack != null) {
      _onReceivedVideoTrack!(opponentId);
    }
  }

  @override
  bool operator ==(Object other) {
    return other is CallSubscriptionImpl && other._tag == _tag;
  }

  @override
  int get hashCode {
    int hash = 3;
    hash = 53 * hash + _tag.length;
    return hash;
  }
}
