import 'dart:async';

import 'package:quickblox_sdk/models/qb_ice_server.dart';
import 'package:quickblox_sdk/models/qb_settings.dart';
import 'package:quickblox_sdk/quickblox_sdk.dart';

class SettingsManager {
  Future<void> init(String appId, String authKey, String authSecret, String accountKey,
      {String? apiEndpoint, String? chatEndpoint}) async {
    await QB.settings.init(appId, authKey, authSecret, accountKey,
        apiEndpoint: apiEndpoint, chatEndpoint: chatEndpoint);
  }

  Future<QBSettings?> get() async {
    return await QB.settings.get();
  }

  Future<void> initStreamManagement(bool autoReconnect, int messageTimeout) async {
    await QB.settings.initStreamManagement(messageTimeout, autoReconnect: autoReconnect);
  }

  Future<void> enableXMPPLogging() async {
    await QB.settings.enableXMPPLogging();
  }

  Future<void> enableLogging() async {
    await QB.settings.enableLogging();
  }

  Future<void> enableAutoReconnect(bool enable) async {
    await QB.settings.enableAutoReconnect(enable);
  }

  Future<void> setIceServers(String url, String userName, String password) async {
    QBIceServer server = QBIceServer();
    server.url = url;
    server.userName = userName;
    server.password = password;

    await QB.rtcConfig.setIceServers([server]);
  }
}
