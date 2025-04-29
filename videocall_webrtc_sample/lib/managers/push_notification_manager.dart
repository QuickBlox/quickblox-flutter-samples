import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:quickblox_sdk/models/qb_subscription.dart';
import 'package:quickblox_sdk/models/qb_user.dart';
import 'package:quickblox_sdk/notifications/constants.dart';
import 'package:quickblox_sdk/push/constants.dart';
import 'package:quickblox_sdk/quickblox_sdk.dart';
import 'package:videocall_webrtc_sample/managers/callkit_manager.dart';
import 'package:videocall_webrtc_sample/presentation/utils/qb_user_parser.dart';

import '../entities/push_notification_entity.dart';

const String androidChannelId = "default_notification_channel_id";
const String androidChannelName = "android_channel_name";
const String androidChannelDescription = "android_channel_description";

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  PushNotificationEntity? notificationEntity = PushNotificationEntity.fromJson(message.data);

  PushNotificationManager._handleRemoteMessageAndShowCallKit(message);

  CallkitManager.handleRejectEvent(notificationEntity.sessionId, RootIsolateToken.instance);
}

class PushNotificationManager {
  static final PushNotificationManager _instance = PushNotificationManager._internal();

  PushNotificationManager._internal();

  factory PushNotificationManager() {
    return _instance;
  }

  static FirebaseMessaging? _firebaseMessaging;

  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
    _firebaseMessaging = FirebaseMessaging.instance;

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _requestPermission();
  }

  static Future<void> _requestPermission() async {
    await _firebaseMessaging?.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static void _handleRemoteMessageAndShowCallKit(RemoteMessage message) {
    final String jsonData = jsonEncode(message.data);
    String jsonOpponents = message.data['opponents'];
    String jsonConferenceType = message.data['conferenceType'];
    String sessionId = message.data['sessionId'];
    String senderId = message.data['senderId'];

    if (_isNotExist(jsonData) || _isNotExist(jsonOpponents) || _isNotExist(jsonConferenceType)) {
      print('Message is empty');
      return;
    }

    List<QBUser?> users = QBUserParser.deserializeOpponents(jsonOpponents);
    bool isVideoCall = jsonConferenceType == "2";

    CallkitManager.showIncomingCall(jsonData, users, isVideoCall, false, sessionId, senderId);
  }

  static bool _isExist(String? value) {
    return value != null && value.isNotEmpty;
  }

  static bool _isNotExist(String? value) {
    return !_isExist(value);
  }

  static Future<String?> getDeviceToken() async {
    try {
      if (Platform.isAndroid) {
        return await _firebaseMessaging?.getToken();
      } else {
        return await CallkitManager.getApnsVoipToken();
      }
    } catch (e) {
      print('Error fetching device token: $e');
      return null;
    }
  }

  static Future<void> subscribeToQbPushNotifications(String token) async {
    String channelName = _getChanelName();

    try {
      await QB.subscriptions.create(token, channelName);
    } catch (e) {
      print('Error subscribing to QB Push Notification: $e');
    }
  }

  static String _getChanelName() {
    if (Platform.isAndroid) {
      return QBPushChannelNames.GCM;
    } else {
      return QBPushChannelNames.APNS_VOIP;
    }
  }

  static Future<void> removeAllQbPushSubscriptions() async {
    List<QBSubscription?> subscriptions = [];
    try {
      List<QBSubscription?> loadedSubscriptions = await QB.subscriptions.get();
      subscriptions.addAll(loadedSubscriptions);
    } on PlatformException catch (e) {
      print('Unsubscribe error: $e');
    }
    await _removeSubscriptions(subscriptions);
  }

  static Future<void> _removeSubscriptions(List<QBSubscription?> subscriptions) async {
    for (final subscription in subscriptions) {
      int subscriptionId = subscription?.id ?? 0;
      if (subscriptionId > 0) {
        await _removeSubscription(subscriptionId);
      }
    }
  }

  static Future<void> _removeSubscription(int subscriptionId) async {
    try {
      await QB.subscriptions.remove(subscriptionId);
    } catch (e) {
      print('Error removing subscription: $e');
    }
  }

  void sendNotification(PushNotificationEntity entity) async {
    String eventType = QBNotificationEventTypes.ONE_SHOT;
    String notificationEventType = QBNotificationTypes.PUSH;

    String? serializeUsers = QBUserParser.serializeOpponents(entity.opponents);

    Map<String, Object> payload = {
      "body": entity.body ?? '',
      "conferenceType": entity.conferenceType?.type ?? '',
      "ios_voip": entity.iosVoip ?? '',
      "opponents": serializeUsers ?? '',
      "recipientIds": entity.recipientIds?.join(',') ?? '',
      "sessionId": entity.sessionId ?? '',
      "timestamp": entity.timestamp ?? '',
      "senderId": entity.senderId ?? '',
      "senderName": entity.senderName ?? '',
    };

    try {
      await QB.events.create(
        eventType,
        notificationEventType,
        entity.senderId!,
        payload,
        active: true,
        recipientsIds: entity.recipientIds,
      );
    } on PlatformException catch (e) {
      print('Error sending notification: $e');
    }
  }
}
