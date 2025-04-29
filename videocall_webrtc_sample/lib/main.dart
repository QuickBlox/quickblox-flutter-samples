import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quickblox_sdk/models/qb_user.dart';
import 'package:videocall_webrtc_sample/managers/reject_call_manager.dart';
import 'package:videocall_webrtc_sample/presentation/screens/call/audio/incoming/incoming_audio_call_screen.dart';
import 'package:videocall_webrtc_sample/presentation/screens/call/audio/incoming/incoming_audio_call_screen_view_model.dart';
import 'package:videocall_webrtc_sample/presentation/screens/call/video/incoming/incoming_video_call_screen.dart';
import 'package:videocall_webrtc_sample/presentation/screens/call/video/incoming/incoming_video_call_screen_view_model.dart';
import 'package:videocall_webrtc_sample/presentation/screens/splash/splash_screen.dart';

import 'dependency/dependency_impl.dart';
import 'managers/callkit_manager.dart';
import 'managers/push_notification_manager.dart';

const String APPLICATION_ID = "";
const String AUTH_KEY = "";
const String AUTH_SECRET = "";
const String ACCOUNT_KEY = "";

const String ICE_SEVER_URL = "";
const String ICE_SERVER_USER = "";
const String ICE_SERVER_PASSWORD = "";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DependencyImpl.getInstance().init();
  if (Platform.isAndroid) {
    await PushNotificationManager.initializeFirebase();
  }

  CallkitManager.init();
  RejectCallManager.stop();

  bool? isVideoCall;
  List<QBUser>? opponents;
  bool isActiveCallkit = await CallkitManager.isActiveCallKit();
  if (isActiveCallkit) {
    isVideoCall = await CallkitManager.isVideoCall();
    opponents = await CallkitManager.getOpponentsFromEntity();
  } else {
    DependencyImpl.getInstance().getLifecycleManager().setIsForeground(true);
  }

  runApp(MyApp(isActiveCallkit, isVideoCall, opponents));
}

class MyApp extends StatefulWidget {
  bool? isActiveCallkit;
  bool? isVideoCall;
  List<QBUser>? opponents;

  MyApp(this.isActiveCallkit, this.isVideoCall, this.opponents, {super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(DependencyImpl.getInstance().getLifecycleManager());
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(DependencyImpl.getInstance().getLifecycleManager());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Colors.blue,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.blue,
        ),
      ),
      home: widget.isActiveCallkit == false
          ? const SplashScreen()
          : _showIncomingCallScreen(widget.isVideoCall!, widget.opponents ?? []),
    );
  }

  Widget _showIncomingCallScreen(bool isVideoCall, List<QBUser> opponents) {
    return isVideoCall
        ? IncomingVideoCallScreen(opponents, IncomingVideoCallLaunchedState.BACKGROUND_STATE)
        : IncomingAudioCallScreen(opponents, IncomingAudioCallLaunchedState.BACKGROUND_STATE);
  }
}
