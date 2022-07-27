import 'package:chat_sample/presentation/navigation/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'bloc/app_info/app_info_screen_bloc.dart';
import 'bloc/chat/chat_screen_bloc.dart';
import 'bloc/chat_info/chat_info_screen_bloc.dart';
import 'bloc/delivered_to/delivered_viewed_screen_bloc.dart';
import 'bloc/dialogs/dialogs_screen_bloc.dart';
import 'bloc/enter_chat_name/enter_chat_name_screen_bloc.dart';
import 'bloc/login/login_screen_bloc.dart';
import 'bloc/select_users/select_users_screen_bloc.dart';
import 'bloc/splash/splash_screen_bloc.dart';
import 'presentation/navigation/router.dart' as router;

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

const String DEFAULT_USER_PASSWORD = "quickblox";

const String APPLICATION_ID = "";
const String AUTH_KEY = "";
const String AUTH_SECRET = "";
const String ACCOUNT_KEY = "";

Future<void> main() async {
  await Hive.initFlutter();
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xff3978fc),
      systemNavigationBarIconBrightness: Brightness.light,
    ));
    return MultiProvider(
      providers: [
        Provider<SplashScreenBloc>.value(value: SplashScreenBloc()),
        Provider<LoginScreenBloc>.value(value: LoginScreenBloc()),
        Provider<DialogsScreenBloc>.value(value: DialogsScreenBloc()),
        Provider<AppInfoScreenBloc>.value(value: AppInfoScreenBloc()),
        Provider<SelectUsersScreenBloc>.value(value: SelectUsersScreenBloc()),
        Provider<ChatScreenBloc>.value(value: ChatScreenBloc()),
        Provider<DeliveredViewedScreenBloc>.value(value: DeliveredViewedScreenBloc()),
        Provider<EnterChatNameScreenBloc>.value(value: EnterChatNameScreenBloc()),
        Provider<ChatInfoScreenBloc>.value(value: ChatInfoScreenBloc())
      ],
      child: MaterialApp(
        title: 'Chat sample',
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.white,
          accentColor: Colors.blue,
          textTheme: Theme.of(context).textTheme.apply(bodyColor: Colors.black87),
          brightness: Brightness.dark,
          primarySwatch: Colors.blue,
        ),
        navigatorKey: NavigationService().navigatorKey,
        onGenerateRoute: router.generateRoute,
        initialRoute: router.SplashScreenRoute,
      ),
    );
  }
}
