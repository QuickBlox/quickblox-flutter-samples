import 'dart:async';

import 'package:quickblox_sdk/models/qb_settings.dart';
import 'package:quickblox_sdk/quickblox_sdk.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

class SettingsRepository {
  Future<void> init(String appId, String authKey, String authSecret, String accountKey,
      {String? apiEndpoint, String? chatEndpoint}) async {
    await QB.settings.init(appId, authKey, authSecret, accountKey,
        apiEndpoint: apiEndpoint, chatEndpoint: chatEndpoint);
  }

  Future<QBSettings?> get() async {
    return await QB.settings.get();
  }

  Future<void> enableCarbons() async {
    await QB.settings.enableCarbons();
  }

  Future<void> disableCarbons() async {
    await QB.settings.disableCarbons();
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
}
