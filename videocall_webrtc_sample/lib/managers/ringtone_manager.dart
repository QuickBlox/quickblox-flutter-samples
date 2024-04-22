import 'package:audioplayers/audioplayers.dart';

class RingtoneManager {
  AudioPlayer? audioPlayer;

  Future<void> startRingtone() async {
    audioPlayer ??= AudioPlayer();
    await audioPlayer?.setReleaseMode(ReleaseMode.loop);
    await audioPlayer?.setPlayerMode(PlayerMode.mediaPlayer);
    await audioPlayer?.play(AssetSource('audio/ringtone.mp3'), volume: 1.0);
  }

  Future<void> release() async {
    await audioPlayer?.release();
    audioPlayer = null;
  }

  Future<void> startBeeps() async {
    audioPlayer ??= AudioPlayer();
    await audioPlayer?.setReleaseMode(ReleaseMode.loop);
    await audioPlayer?.play(AssetSource('audio/beep.wav'), volume: 1.0);
  }
}
