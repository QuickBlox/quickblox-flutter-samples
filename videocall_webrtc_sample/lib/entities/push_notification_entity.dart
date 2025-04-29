import 'dart:convert';

import 'package:quickblox_sdk/models/qb_user.dart';

import '../presentation/utils/qb_user_parser.dart';

enum ConferenceType {
  AUDIO("1"),
  VIDEO("2");

  final String type;

  const ConferenceType(this.type);
}

class PushNotificationEntity {
  final ConferenceType? conferenceType;
  final List<QBUser>? opponents;
  final List<String>? recipientIds;
  final String? sessionId;
  final String? body;
  String? iosVoip = "1";
  String? timestamp = DateTime.now().millisecondsSinceEpoch.toString();
  final String? senderName;
  final int? senderId;

  PushNotificationEntity({
    this.conferenceType,
    this.recipientIds,
    this.opponents,
    this.sessionId,
    this.body,
    this.iosVoip = "1",
    this.timestamp,
    this.senderName,
    this.senderId,
  });

  factory PushNotificationEntity.fromString(String message) {
    final Map<String, dynamic> data = jsonDecode(message);
    return PushNotificationEntity.fromJson(data);
  }

  factory PushNotificationEntity.fromJson(Map<String, dynamic> json) {
    return PushNotificationEntity(
      conferenceType: _parseConferenceType(json['conferenceType'] as String?),
      opponents: _parseOpponents((jsonDecode(json['opponents']) as List<dynamic>?)),
      recipientIds: (json['recipientIds'] as String?)?.split(','),
      sessionId: json['sessionId'] as String?,
      body: json['body'] as String?,
      iosVoip: json['ios_voip'] as String?,
      timestamp: json['timestamp'] as String?,
      senderName: json['senderName'] as String?,
      senderId: json['senderId'] != null ? int.tryParse(json['senderId'].toString()) : null,
    );
  }

  static ConferenceType? _parseConferenceType(String? type) {
    if (type == "2") {
      return ConferenceType.VIDEO;
    } else {
      return ConferenceType.AUDIO;
    }
  }

  static List<QBUser> _parseOpponents(List<dynamic>? json) {
    List<QBUser> users = [];

    for (var user in json ?? []) {
      users.add(QBUserParser.deserializeUser(user as Map<String, dynamic>));
    }
    return users;
  }

  Map<String, dynamic> toJson() {
    return {
      'conferenceType': conferenceType?.type,
      'opponents': QBUserParser.serializeOpponents(opponents),
      'sessionId': sessionId,
      'body': body,
      'ios_voip': iosVoip,
      'timestamp': timestamp,
      'senderName': senderName,
      'senderId': senderId,
    };
  }

  bool isVideoCall() {
    return conferenceType == ConferenceType.VIDEO;
  }
}
