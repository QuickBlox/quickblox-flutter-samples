import 'package:flutter/material.dart';
import 'package:quickblox_sdk/models/qb_subscription.dart';
import 'package:quickblox_sdk/push/constants.dart';
import 'package:quickblox_sdk/quickblox_sdk.dart';
import 'package:quickblox_sdk_example/credentials.dart';
import 'package:quickblox_sdk_example/screens/auth_screen.dart';
import 'package:quickblox_sdk_example/screens/chat_screen.dart';
import 'package:quickblox_sdk_example/screens/conference_screen.dart';
import 'package:quickblox_sdk_example/screens/content_screen.dart';
import 'package:quickblox_sdk_example/screens/custom_objects_screen.dart';
import 'package:quickblox_sdk_example/screens/events_screen.dart';
import 'package:quickblox_sdk_example/screens/settings_screen.dart';
import 'package:quickblox_sdk_example/screens/subscriptions_screen.dart';
import 'package:quickblox_sdk_example/screens/users_screen.dart';
import 'package:quickblox_sdk_example/screens/webrtc_screen.dart';
import 'package:quickblox_sdk_example/widgets/blue_app_bar.dart';
import 'package:quickblox_sdk_example/widgets/blue_button.dart';

import 'firebase_manager.dart';

void main() async {
  // init Firebase when app starts
  await FirebaseManager.init();

  /*
  * some business logic for manage QuickBlox session, login, etc.
  * */

  //Subscribe to push notifications
  String token = await FirebaseManager.getToken();
  List<QBSubscription?> subscriptionsA = await QB.subscriptions.create(token, QBPushChannelNames.GCM);

  //Delete subscription when user logout or need to replace
  await QB.subscriptions.remove(subscriptionId);

  //Load all exist subscriptions
  List<QBSubscription?> subscriptionB = await QB.subscriptions.get();
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainScreen(),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, primary: Colors.blue),
        appBarTheme: AppBarTheme(
          elevation: 4.0,
          color: Colors.blue,
          shadowColor: Theme.of(context).colorScheme.shadow,
        ),
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: BlueAppBar('Flutter Quickblox SDK'),
        body: Center(
            child: Column(children: [
          BlueButton('Auth', () => AuthScreen.show(context)),
          BlueButton('Chat', () => ChatScreen.show(context)),
          BlueButton('Custom objects', () => CustomObjectsScreen.show(context)),
          BlueButton('File', () => ContentScreen.show(context)),
          BlueButton('Events', () => EventsScreen.show(context)),
          BlueButton('Subscriptions', () => SubscriptionsScreen.show(context)),
          BlueButton('Settings', () => SettingsScreen.show(context)),
          BlueButton('Users', () => UsersScreen.show(context)),
          BlueButton('WebRTC', () => WebRTCScreen.show(context)),
          BlueButton('Conference', () => ConferenceScreen.show(context)),
          Padding(
              padding: EdgeInsets.fromLTRB(0, 30, 0, 0),
              child: Text("USER LOGIN: $USER_LOGIN \n USER ID: $LOGGED_USER_ID", style: TextStyle(fontSize: 14)))
        ])));
  }
}
