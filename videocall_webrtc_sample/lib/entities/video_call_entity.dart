import 'package:quickblox_sdk/models/qb_user.dart';
import 'package:quickblox_sdk/webrtc/rtc_video_view.dart';

class VideoCallEntity {
  RTCVideoViewController? _controller;

  set controller(RTCVideoViewController value) {
    _controller = value;
  }

  final QBUser? _user;

  int? get userId => _user?.id;

  String? get name => _user?.fullName ?? _user?.login;

  VideoCallEntity(this._user);

  Future<void> playVideo(String sessionId) async {
    await _controller?.play(sessionId, userId!);
  }

  Future<void> releaseVideo() async {
    await _controller?.release();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoCallEntity && other.userId == userId;
  }

  @override
  int get hashCode {
    int hash = 7;
    hash = 31 * hash + (userId != null ? userId.hashCode : 0);
    return hash;
  }
}
