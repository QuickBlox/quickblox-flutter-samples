import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseManager {
  static final FlutterLocalNotificationsPlugin localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  FirebaseManager.privateConstructor();

  static Future<void> init() async {
    await Firebase.initializeApp();

    await _requestPushPermissions();

    _subscribeToForegroundMessages();
    _subscribeToBackgroundMessages();

    _initLocalNotifications();
  }

  static Future<void> _requestPushPermissions() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  static void _subscribeToForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _buildAndShowNotification("FOREGROUND message", _getMessageBody(message));
      print("The foreground message received: ${message.messageId}");
    });
  }

  static void _subscribeToBackgroundMessages() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static void _initLocalNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    localNotificationsPlugin.initialize(initializationSettings);
  }

  static Future<String> getToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    if (_isNotCorrectToken(token)) {
      //TODO: change to some specific exception when method will be moved into data layer
      throw Exception('Failed to get token');
    }

    return token!;
  }

  static bool _isNotCorrectToken(String? token) {
    return token == null || token.isEmpty;
  }

  static Future<void> _buildAndShowNotification(String title, String body) async {
    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
        'temp_channel_id', 'temp_channel_name',
        channelDescription: 'temp_channel_description',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker');

    const NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);

    await localNotificationsPlugin.show(Random().nextInt(1000), title, body, notificationDetails);
  }

  static String _getMessageBody(RemoteMessage message) {
    bool isExistBody = message.data.isNotEmpty &&
        message.data.containsKey("message") &&
        message.data["message"] != null &&
        message.data["message"]!.isNotEmpty;

    if (isExistBody) {
      return message.data["message"];
    } else {
      return "Message without body";
    }
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  FirebaseManager._buildAndShowNotification(
      "BACKGROUND/KILLED_STATE message", FirebaseManager._getMessageBody(message));
  print("The background/killed_state message received: ${message.messageId}");
}
