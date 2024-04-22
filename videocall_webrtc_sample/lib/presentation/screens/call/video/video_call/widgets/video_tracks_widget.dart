import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';
import 'package:videocall_webrtc_sample/entities/video_call_entity.dart';
import 'package:videocall_webrtc_sample/presentation/screens/call/video/video_call/widgets/video_track_widget.dart';

class VideoTracksWidget extends StatelessWidget {
  final List<VideoCallEntity> _videCallEntities;

  const VideoTracksWidget(this._videCallEntities, {super.key});

  @override
  Widget build(BuildContext context) {
    return _buildGrid(context);
  }

  Widget _buildGrid(BuildContext context) {
    final rows = calcViewTable(_videCallEntities.length);
    final totalRows = rows.item1 + rows.item2 + rows.item3;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    int index = 0;
    return Positioned(
        top: 0,
        left: 0,
        child: Column(children: [
          for (var i = 0; i < rows.item1; i++)
            Row(children: [
              VideoTrackWidget(_videCallEntities[index++], screenWidth, screenHeight / totalRows)
            ]),
          for (var i = 0; i < rows.item2; i++)
            Row(children: [
              for (var j = 0; j < 2; j++)
                VideoTrackWidget(_videCallEntities[index++], screenWidth / 2, screenHeight / totalRows)
            ]),
          for (var i = 0; i < rows.item3; i++)
            Row(children: [
              for (var j = 0; j < 3; j++)
                VideoTrackWidget(_videCallEntities[index++], screenWidth / 3, screenHeight / totalRows)
            ])
        ]));
  }

  Tuple3<int, int, int> calcViewTable(int opponentsQuantity) {
    int rowsThreeUsers = 0;
    int rowsTwoUsers = 0;
    int rowsOneUser = 0;
    if (opponentsQuantity == 1) {
      rowsOneUser = 1;
      return Tuple3(rowsOneUser, rowsTwoUsers, rowsThreeUsers);
    }

    if (opponentsQuantity == 2) {
      rowsOneUser = 2;
      return Tuple3(rowsOneUser, rowsTwoUsers, rowsThreeUsers);
    }

    if (opponentsQuantity == 3) {
      rowsTwoUsers = 1;
      rowsOneUser = 1;
      return Tuple3(rowsOneUser, rowsTwoUsers, rowsThreeUsers);
    }

    switch (opponentsQuantity % 3) {
      case 0:
        rowsThreeUsers = opponentsQuantity ~/ 3;
        break;
      case 1:
        rowsTwoUsers = 2;
        rowsThreeUsers = (opponentsQuantity - 2) ~/ 3;
        break;
      case 2:
        rowsTwoUsers = 1;
        rowsThreeUsers = (opponentsQuantity - 1) ~/ 3;
        break;
    }
    return Tuple3(rowsOneUser, rowsTwoUsers, rowsThreeUsers);
  }
}
