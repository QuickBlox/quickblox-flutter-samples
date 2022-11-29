import 'package:flutter/material.dart';
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

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: MainScreen());
  }
}

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: _buildAppBar(),
        body: Center(
            child: Column(children: [
          _buildButton(context, 'Auth', AuthScreen()),
          _buildButton(context, 'Chat', ChatScreen()),
          _buildButton(context, 'Custom objects', CustomObjectsScreen()),
          _buildButton(context, 'File', ContentScreen()),
          _buildButton(context, 'Events', EventsScreen()),
          _buildButton(context, 'Subscriptions', SubscriptionsScreen()),
          _buildButton(context, 'Settings', SettingsScreen()),
          _buildButton(context, 'Users', UsersScreen()),
          _buildButton(context, 'WebRTC', WebRTCScreen()),
          _buildButton(context, 'Conference', ConferenceScreen()),
          Padding(
              padding: EdgeInsets.fromLTRB(0, 30, 0, 0),
              child: Text("USER LOGIN: $USER_LOGIN \n USER ID: $LOGGED_USER_ID", style: TextStyle(fontSize: 14)))
        ])));
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(title: const Text('Flutter Quickblox SDK'), centerTitle: true);
  }

  Widget _buildButton(BuildContext context, String title, Widget screen) {
    return MaterialButton(
        minWidth: 200,
        child: Text(title),
        color: Theme.of(context).primaryColor,
        textColor: Colors.white,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => screen)));
  }
}
