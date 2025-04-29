import 'dart:convert';

import 'package:quickblox_sdk/models/qb_user.dart';

class QBUserParser {
  static Map<String, dynamic> serializeUser(QBUser user) {
    return {
      'blobId': user.blobId,
      'customData': user.customData,
      'email': user.email,
      'externalId': user.externalId,
      'facebookId': user.facebookId,
      'fullName': user.fullName,
      'id': user.id,
      'login': user.login,
      'phone': user.phone,
      'tags': user.tags,
      'twitterId': user.twitterId,
      'website': user.website,
      'lastRequestAt': user.lastRequestAt,
    };
  }

  static String serializeOpponents(List<QBUser>? opponents) {
    final jsonList = opponents?.map((user) {
      return serializeUser(user);
    }).toList();
    return jsonEncode(jsonList);
  }

  static List<QBUser> deserializeOpponents(String jsonOpponents) {
    final List<dynamic> jsonList = jsonDecode(jsonOpponents);

    List<QBUser> users = [];

    for (var json in jsonList) {
      if (json == null) {
        continue;
      }

      QBUser user = deserializeUser(json as Map<String, dynamic>);
      users.add(user);
    }

    return users;
  }

  static QBUser deserializeUser(Map<String, dynamic> json) {
    return QBUser()
      ..blobId = json['blobId'] as int?
      ..customData = json['customData'] as String?
      ..email = json['email'] as String?
      ..externalId = json['externalId'] as String?
      ..facebookId = json['facebookId'] as String?
      ..fullName = json['fullName'] as String?
      ..id = json['id'] as int?
      ..login = json['login'] as String?
      ..phone = json['phone'] as String?
      ..tags = (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList()
      ..twitterId = json['twitterId'] as String?
      ..website = json['website'] as String?
      ..lastRequestAt = json['lastRequestAt'] as String?;
  }
}
