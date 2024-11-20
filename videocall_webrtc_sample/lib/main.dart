import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:videocall_webrtc_sample/managers/lifecycle_manage.dart';
import 'package:videocall_webrtc_sample/presentation/screens/splash/splash_screen.dart';

import 'dependency/dependency_impl.dart';

const String APPLICATION_ID = "";
const String AUTH_KEY = "";
const String AUTH_SECRET = "";
const String ACCOUNT_KEY = "";

const String ICE_SEVER_URL = "";
const String ICE_SERVER_USER = "";
const String ICE_SERVER_PASSWORD = "";

Future<void> main() async {
  await DependencyImpl.getInstance().init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final LifecycleManager _lifecycleManager = LifecycleManager();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(_lifecycleManager);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleManager);
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
      home: const SplashScreen(),
    );
  }
}
