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