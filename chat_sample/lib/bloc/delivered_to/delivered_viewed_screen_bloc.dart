import 'dart:async';
import 'dart:collection';

import 'package:chat_sample/data/chat_repository.dart';
import 'package:chat_sample/data/device_repository.dart';
import 'package:chat_sample/data/repository_exception.dart';
import 'package:chat_sample/data/storage_repository.dart';
import 'package:chat_sample/data/users_repository.dart';
import 'package:flutter/services.dart';
import 'package:quickblox_sdk/chat/constants.dart';
import 'package:quickblox_sdk/quickblox_sdk.dart';

import '../../main.dart';
import '../base_bloc.dart';
import 'delivered_viewed_screen_events.dart';
import 'delivered_viewed_screen_states.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

class DeliveredViewedScreenArguments extends Object {
  final String dialogId;
  final String messageId;
  final bool isDeliveredScreen;

  DeliveredViewedScreenArguments(this.dialogId, this.messageId, this.isDeliveredScreen);
}

class DeliveredViewedScreenBloc extends Bloc<DeliveredViewedScreenEvents,
    DeliveredViewedScreenStates, DeliveredViewedScreenArguments> with ConnectionListener {
  final ChatRepository _chatRepository = ChatRepository();
  final UsersRepository _usersRepository = UsersRepository();
  final DeviceRepository _deviceRepository = DeviceRepository();
  final StorageRepository _storageRepository = StorageRepository();

  bool _isDelivered = false;
  int? _userId;
  String? _dialogId;
  String? _messageId;

  StreamSubscription? _messageReadSubscription;
  StreamSubscription? _messageDeliveredSubscription;

  @override
  void init() {
    super.init();
    _deviceRepository.addConnectionListener(this);
    _initBlocData();
    states?.add(MessageDetailInProgressState());
  }

  void _initBlocData() async {
    await _restoreSavedUserId();
    await _connectChat();
  }

  @override
  void setArgs(DeliveredViewedScreenArguments args) {
    _dialogId = args.dialogId;
    _messageId = args.messageId;
    _isDelivered = args.isDeliveredScreen;
  }

  @override
  void onBackgroundMode() async {
    _unsubscribeMessageStatuses();
    await _chatRepository.disconnect();
    _deviceRepository.removeConnectionListener(this);
  }

  @override
  void onForegroundMode() {
    _initBlocData();
  }

  @override
  void dispose() {
    _deviceRepository.removeConnectionListener(this);
    super.dispose();
  }

  Future<void> _restoreSavedUserId() async {
    int userId = await _storageRepository.getUserId();
    if (userId != StorageRepository.NOT_SAVED_USER_ID) {
      _userId = userId;
    } else {
      states?.add(ErrorState("Saved user does not exist"));
    }
  }

  @override
  Future<void> onReceiveEvent(DeliveredViewedScreenEvents receivedEvent) async {
    if (receivedEvent is MessageDetailsEvent) {
      _subscribeDeliveredStatus();
      _subscribeReadStatus();
      _updateMessageDetails();
    }
    if (receivedEvent is MessageDetailCloseEvent) {
      _unsubscribeMessageStatuses();
    }
  }

  void _updateMessageDetails() async {
    try {
      List<int>? usersIds = [];
      await _chatRepository.getMessageById(_dialogId, _messageId).then((message) {
        usersIds = _isDelivered ? message?.deliveredIds : message?.readIds;
      }).whenComplete(() async {
        await _usersRepository.getUsersByIds(usersIds).then((users) {
          if (_userId != null && users.isNotEmpty) {
            users.removeWhere((element) => element == null);
            states?.add(MessageDetailState(_userId!, users));
          }
        });
      });
    } on PlatformException catch (e) {
      states?.add(ErrorState(makeErrorMessage(e)));
    } on RepositoryException catch (e) {
      states?.add(ErrorState(e.message));
    }
  }

  void _subscribeReadStatus() async {
    if (_messageReadSubscription == null) {
      try {
        _messageReadSubscription =
            await QB.chat.subscribeChatEvent(QBChatEvents.MESSAGE_READ, _processMessageReadEvent);
      } on PlatformException catch (e) {
        states?.add(ErrorState(makeErrorMessage(e)));
      }
    }
  }

  void _processMessageReadEvent(dynamic data) {
    LinkedHashMap<dynamic, dynamic> messageStatusHashMap = data;
    Map<String, Object> payloadMap = Map<String, Object>.from(messageStatusHashMap["payload"]);

    String dialogId = payloadMap["dialogId"] as String;
    String messageId = payloadMap["messageId"] as String;

    if (_dialogId == dialogId && messageId == _messageId) {
      _updateMessageDetails();
    }
  }

  void _subscribeDeliveredStatus() async {
    if (_messageDeliveredSubscription == null) {
      try {
        _messageDeliveredSubscription = await QB.chat
            .subscribeChatEvent(QBChatEvents.MESSAGE_DELIVERED, _processMessageDeliveredEvent);
      } on PlatformException catch (e) {
        states?.add(ErrorState(makeErrorMessage(e)));
      }
    }
  }

  void _processMessageDeliveredEvent(dynamic data) {
    LinkedHashMap<dynamic, dynamic> messageStatusHashMap = data;
    Map<String, Object> payloadMap = Map<String, Object>.from(messageStatusHashMap["payload"]);

    String dialogId = payloadMap["dialogId"] as String;
    String messageId = payloadMap["messageId"] as String;

    if (_dialogId == dialogId && messageId == _messageId) {
      _updateMessageDetails();
    }
  }

  void _unsubscribeMessageStatuses() {
    _messageDeliveredSubscription?.cancel();
    _messageDeliveredSubscription = null;

    _messageReadSubscription?.cancel();
    _messageReadSubscription = null;
  }

  Future<void> _connectChat() async {
    try {
      bool isNotExistInternetConnection = !await checkInternetConnection();
      if (isNotExistInternetConnection) {
        return;
      }

      bool connected = await _chatRepository.isConnected() ?? false;
      if (!connected) {
        await _chatRepository.connect(_userId, DEFAULT_USER_PASSWORD);
      }
      states?.add(ChatConnectedState());
    } on PlatformException catch (e) {
      states?.add(ErrorState(makeErrorMessage(e)));
    } on RepositoryException catch (e) {
      states?.add(ErrorState(e.message));
    }
  }

  @override
  void connectionTypeChanged(ConnectionType type) {
    switch (type) {
      case ConnectionType.wifi:
      case ConnectionType.mobile:
        _initBlocData();
        break;
      case ConnectionType.none:
        break;
    }
  }
}
