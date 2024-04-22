import 'dart:io';

import 'package:flutter/material.dart';
import 'package:quickblox_sdk/webrtc/rtc_video_view.dart';
import 'package:videocall_webrtc_sample/entities/video_call_entity.dart';

class VideoTrackWidget extends StatefulWidget {
  final VideoCallEntity _videCallEntity;
  final double _width;
  final double _height;

  const VideoTrackWidget(
    this._videCallEntity,
    this._width,
    this._height, {
    super.key,
  });

  @override
  State<VideoTrackWidget> createState() => _VideoTrackWidget();
}

class _VideoTrackWidget extends State<VideoTrackWidget> {
  bool isVideoViewVisible = false;

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      Future.delayed(const Duration(milliseconds: 2), () {
        setState(() => isVideoViewVisible = true);
      });
    } else {
      isVideoViewVisible = true;
    }

    return Container(
      margin: const EdgeInsets.all(0.2),
      width: widget._width,
      height: widget._height,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(color: Colors.black54),
      child: isVideoViewVisible
          ? RTCVideoView(onVideoViewCreated: (controller) {
              widget._videCallEntity.controller = controller;
            })
          : const SizedBox(),
    );
  }
}
