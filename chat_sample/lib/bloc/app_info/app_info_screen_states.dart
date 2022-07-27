import 'package:quickblox_sdk/models/qb_settings.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

abstract class AppInfoScreenStates {}

class SettingsErrorState extends AppInfoScreenStates {
  final String error;

  SettingsErrorState(this.error);
}

class SettingsSuccessState extends AppInfoScreenStates {
  final QBSettings? settings;
  final String version;

  SettingsSuccessState(this.settings, this.version);
}

class SettingsInProgressState extends AppInfoScreenStates {}
