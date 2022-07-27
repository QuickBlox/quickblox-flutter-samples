import 'package:quickblox_sdk/models/qb_user.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

abstract class DeliveredViewedScreenStates {}

class ChatConnectedState extends DeliveredViewedScreenStates {}

class MessageDetailInProgressState extends DeliveredViewedScreenStates {}

class MessageDetailState extends DeliveredViewedScreenStates {
  final int currentUserId;
  final List<QBUser?> users;

  MessageDetailState(this.currentUserId, this.users);
}

class ErrorState extends DeliveredViewedScreenStates {
  final String error;

  ErrorState(this.error);
}
