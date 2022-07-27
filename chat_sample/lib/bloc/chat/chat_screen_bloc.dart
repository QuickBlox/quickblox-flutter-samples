import 'dart:async';
import 'dart:collection';
import 'dart:ui';

import 'package:chat_sample/data/chat_repository.dart';
import 'package:chat_sample/data/device_repository.dart';
import 'package:chat_sample/data/repository_exception.dart';
import 'package:chat_sample/data/storage_repository.dart';
import 'package:chat_sample/data/users_repository.dart';
import 'package:chat_sample/models/message_wrapper.dart';
import 'package:chat_sample/presentation/screens/chat_info/chat_info_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:quickblox_sdk/chat/constants.dart';
import 'package:quickblox_sdk/mappers/qb_message_mapper.dart';
import 'package:quickblox_sdk/models/qb_dialog.dart';
import 'package:quickblox_sdk/models/qb_message.dart';
import 'package:quickblox_sdk/models/qb_user.dart';
import 'package:quickblox_sdk/quickblox_sdk.dart';

import '../../main.dart';
import '../base_bloc.dart';
import 'chat_screen_events.dart';
import 'chat_screen_states.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

class ChatArguments extends Object {
  final dialogId;
  final isNewChat;

  ChatArguments(this.dialogId, this.isNewChat);
}

class ChatScreenBloc extends Bloc<ChatScreenEvents, ChatScreenStates, ChatArguments>
    with ConnectionListener {
  static const int PAGE_SIZE = 20;
  static const int TEXT_MESSAGE_MAX_SIZE = 1000;

  final ChatRepository _chatRepository = ChatRepository();
  final UsersRepository _usersRepository = UsersRepository();
  final DeviceRepository _deviceRepository = DeviceRepository();
  final StorageRepository _storageRepository = StorageRepository();

  int? _localUserId;
  String? _dialogId;
  QBDialog? _dialog;
  bool _isNewChat = false;
  TypingStatusTimer? _typingStatusTimer = TypingStatusTimer();
  Map<int, QBUser> _participantsMap = HashMap<int, QBUser>();
  Set<QBMessageWrapper> _wrappedMessageSet = HashSet<QBMessageWrapper>();
  List<String> _typingUsersNames = <String>[];

  StreamSubscription? _incomingMessagesSubscription;
  StreamSubscription? _connectedChatSubscription;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _stopTypingSubscription;
  StreamSubscription? _messageReadSubscription;
  StreamSubscription? _messageDeliveredSubscription;

  @override
  void init() async {
    super.init();
    await _initBlocData();
  }

  Future<void> _initBlocData() async {
    await _restoreSavedUserId();
    await _subscribeConnectedChat();
    _deviceRepository.addConnectionListener(this);
    states?.add(ChatConnectingState());
    await _connectChat();
    await _subscribeEvents();
  }

  @override
  void setArgs(ChatArguments arguments) {
    _dialogId = arguments.dialogId;
    _isNewChat = arguments.isNewChat;
  }

  @override
  void onBackgroundMode() async {
    await _unsubscribeEvents();
    await _chatRepository.disconnect();
    await _unsubscribeConnectedChat();
    _typingUsersNames.clear();
    _deviceRepository.removeConnectionListener(this);
  }

  @override
  void onForegroundMode() async {
    await _initBlocData();
  }

  @override
  void dispose() async {
    await _unsubscribeConnectedChat();
    _typingUsersNames.clear();
    _typingStatusTimer?.cancel();
    super.dispose();
  }

  @override
  Future<void> onReceiveEvent(ChatScreenEvents receivedEvent) async {
    if (receivedEvent is ConnectChatEvent) {
      await _initBlocData();
    }
    if (receivedEvent is UpdateChatEvent) {
      try {
        _wrappedMessageSet.clear();
        await _updateDialog();
        await _loadMessages();
      } on PlatformException catch (e) {
        states?.add(UpdateChatErrorState(makeErrorMessage(e)));
      }
    }
    if (receivedEvent is LoadNextMessagesPageEvent) {
      try {
        await _loadMessages();
      } on PlatformException catch (e) {
        states?.add(LoadNextMessagesErrorState(makeErrorMessage(e)));
      }
    }
    if (receivedEvent is ReturnToDialogsEvent) {
      await _unsubscribeEvents();
      _deviceRepository.removeConnectionListener(this);
      states?.add(ReturnToDialogsState());
    }
    if (receivedEvent is SendMessageEvent) {
      if (receivedEvent.textMessage == null) {
        states?.add(SendMessageErrorState("Message is empty", null));
        return;
      }
      String trimmedMessage = receivedEvent.textMessage!.trim();
      if (trimmedMessage.isEmpty) {
        return;
      }
      try {
        await _chatRepository.sendStoppedTyping(_dialogId);
        await Future.delayed(const Duration(milliseconds: 300), () async {
          await _sendTextMessage(trimmedMessage);
        });
      } on PlatformException catch (e) {
        states?.add(SendMessageErrorState(makeErrorMessage(e), receivedEvent.textMessage));
      } on RepositoryException catch (e) {
        states?.add(SendMessageErrorState(e.message, receivedEvent.textMessage));
      }
    }
    if (receivedEvent is MarkMessageRead) {
      _chatRepository.markMessageRead(receivedEvent.message);
    }
    if (receivedEvent is StartTypingEvent) {
      try {
        await _chatRepository.sendIsTyping(_dialogId);
      } on RepositoryException catch (e) {
        states?.add(ErrorState(e.message));
      }
    }
    if (receivedEvent is StopTypingEvent) {
      try {
        await _chatRepository.sendStoppedTyping(_dialogId);
      } on RepositoryException catch (e) {
        states?.add(ErrorState(e.message));
      }
    }
    if (receivedEvent is UsersAddedEvent) {
      if (receivedEvent.addedUsersIds.contains(ChatInfoScreen.NO_USERS_SELECTED)) {
        return;
      }
      try {
        _chatRepository
            .updateDialog(_dialogId, addUsers: receivedEvent.addedUsersIds)
            .then((dialog) {
          _dialog = dialog;
          _usersRepository.getUsersByIds(receivedEvent.addedUsersIds).then((addedUsers) {
            _sendNotificationMessageAddedUsers(addedUsers);
            _sendSystemMessagesAddedUsers(_dialog?.occupantsIds); // to occupants
          });
        });
      } on RepositoryException catch (e) {
        states?.add(ErrorState(e.message));
      }
    }
    if (receivedEvent is LeaveChatScreenEvent) {
      _deviceRepository.removeConnectionListener(this);
      await _unsubscribeEvents();
    }
    if (receivedEvent is ReturnChatScreenEvent) {
      _deviceRepository.addConnectionListener(this);
      await _initBlocData();
    }
    if (receivedEvent is LeaveChatEvent) {
      ConnectionType connectionType = await _deviceRepository.checkInternetConnection();
      if (connectionType == ConnectionType.none) {
        states?.add(LeaveChatErrorState("Unable to perform operation without connection"));
        return;
      }

      try {
        states?.add(LoadMessagesInProgressState());
        await _sendNotificationMessageLeftChat();
        await _leaveChat();
        await _sendSystemMessagesLeftChat();

        states?.add(ReturnToDialogsState());
      } on PlatformException catch (e) {
        states?.add(LeaveChatErrorState(makeErrorMessage(e)));
      } on RepositoryException catch (e) {
        states?.add(LeaveChatErrorState(e.message));
      }
    }
    if (receivedEvent is DeleteChatEvent) {
      try {
        await _chatRepository.deleteDialog(_dialogId);
        states?.add(ReturnToDialogsState());
      } on PlatformException catch (e) {
        states?.add(DeleteChatErrorState(makeErrorMessage(e)));
      } on RepositoryException catch (e) {
        states?.add(DeleteChatErrorState(e.message));
      }
    }
  }

  Future<void> _unsubscribeEvents() async {
    await _unsubscribeIncomingMessages();
    await _unsubscribeMessageStatuses();
    await _unsubscribeTypingStatus();
  }

  Future<void> _subscribeEvents() async {
    await _subscribeTypingStatus();
    await _subscribeIncomingMessages();
    await _subscribeDeliveredStatus();
    await _subscribeReadStatus();
  }

  Future<void> _sendNotificationMessageCreatedChat() async {
    if (_dialog == null || _dialog!.name == null) {
      states?.add(ErrorState("Dialog is null"));
    }
    String userName = await _storageRepository.getUserFullName();
    String messageBody = userName + ' created the group chat "${_dialog!.name}"';
    await _chatRepository.sendNotificationMessage(
        _dialogId, messageBody, ChatRepository.NOTIFICATION_TYPE_CREATE);
  }

  void _sendSystemMessagesCreatedChat() async {
    _dialog?.occupantsIds?.forEach((occupantId) async {
      if (occupantId == _localUserId) {
        return;
      }
      await Future.delayed(const Duration(milliseconds: 200), () {
        _chatRepository.sendSystemMessage(
            _dialogId, occupantId, ChatRepository.NOTIFICATION_TYPE_CREATE);
      });
    });
  }

  void _sendNotificationMessageAddedUsers(List<QBUser?> users) async {
    List<String?> namesList = [];
    users.forEach((element) {
      namesList.add(element?.fullName ?? element?.login);
    });
    String usersNames = namesList.join(', ');
    String userName = await _storageRepository.getUserFullName();
    String messageBody = userName + ' added ' + usersNames;
    _chatRepository.sendNotificationMessage(
        _dialogId, messageBody, ChatRepository.NOTIFICATION_TYPE_ADD);
  }

  void _sendSystemMessagesAddedUsers(List<int>? ids) {
    for (int id in ids!) {
      _chatRepository.sendSystemMessage(_dialogId, id, ChatRepository.NOTIFICATION_TYPE_ADD);
    }
  }

  Future<void> _sendNotificationMessageLeftChat() async {
    String messageBody = await _storageRepository.getUserFullName() + " has left";
    _chatRepository.sendNotificationMessage(
        _dialogId, messageBody, ChatRepository.NOTIFICATION_TYPE_LEFT);
  }

  Future<void> _sendSystemMessagesLeftChat() async {
    _dialog?.occupantsIds?.forEach((occupantId) async {
      if (occupantId != _localUserId) {
        await Future.delayed(const Duration(milliseconds: 200), () {
          _chatRepository.sendSystemMessage(
              _dialogId, occupantId, ChatRepository.NOTIFICATION_TYPE_LEFT);
        });
      }
    });
  }

  Future<void> _leaveChat() async {
    if (_localUserId == null || _dialogId == null) {
      states?.add(ErrorState("UserId or DialogId is null"));
      return;
    }
    await _chatRepository.leaveDialog(_dialogId);
    await _chatRepository.updateDialog(_dialogId, removeUsers: [_localUserId!]);
  }

  List<QBMessageWrapper> _getMessageListSortedByDate() {
    List<QBMessageWrapper> list = _wrappedMessageSet.toList();
    list.sort((first, second) => first.date.compareTo(second.date));
    return list;
  }

  Future<void> _subscribeReadStatus() async {
    await _messageReadSubscription?.cancel();
    _messageReadSubscription = null;

    try {
      _messageReadSubscription =
          await QB.chat.subscribeChatEvent(QBChatEvents.MESSAGE_READ, _processMessageReadEvent);
    } on PlatformException catch (e) {
      states?.add(ErrorState(makeErrorMessage(e)));
    }
  }

  void _processMessageReadEvent(dynamic data) {
    LinkedHashMap<dynamic, dynamic> messageStatusHashMap = data;
    Map<String, Object> payloadMap = Map<String, Object>.from(messageStatusHashMap["payload"]);

    String? dialogId = payloadMap["dialogId"] as String;
    String? messageId = payloadMap["messageId"] as String;
    int? userId = payloadMap["userId"] as int;

    if (_dialogId == dialogId) {
      for (QBMessageWrapper message in _wrappedMessageSet) {
        if (message.id == messageId) {
          message.qbMessage.readIds?.add(userId);
          break;
        }
      }
      states?.add(LoadMessagesSuccessState(_getMessageListSortedByDate(), true));
    }
  }

  Future<void> _subscribeDeliveredStatus() async {
    await _messageDeliveredSubscription?.cancel();
    _messageDeliveredSubscription = null;

    try {
      _messageDeliveredSubscription = await QB.chat
          .subscribeChatEvent(QBChatEvents.MESSAGE_DELIVERED, _processMessageDeliveredEvent);
    } on PlatformException catch (e) {
      states?.add(ErrorState(makeErrorMessage(e)));
    }
  }

  void _processMessageDeliveredEvent(dynamic data) {
    LinkedHashMap<dynamic, dynamic> messageStatusMap = data;
    Map<String, Object> payloadMap = Map<String, Object>.from(messageStatusMap["payload"]);

    String? dialogId = payloadMap["dialogId"] as String;
    String? messageId = payloadMap["messageId"] as String;
    int? userId = payloadMap["userId"] as int;

    if (_dialogId == dialogId) {
      for (QBMessageWrapper message in _wrappedMessageSet) {
        if (message.id == messageId) {
          message.qbMessage.deliveredIds?.add(userId);
          break;
        }
      }
      states?.add(LoadMessagesSuccessState(_getMessageListSortedByDate(), true));
    }
  }

  Future<void> _subscribeIncomingMessages() async {
    await _unsubscribeIncomingMessages();

    try {
      _incomingMessagesSubscription = await QB.chat
          .subscribeChatEvent(QBChatEvents.RECEIVED_NEW_MESSAGE, _processIncomingMessageEvent);
    } on PlatformException catch (e) {
      states?.add(ErrorState(makeErrorMessage(e)));
    }
  }

  void _processIncomingMessageEvent(dynamic data) async {
    Map<String, Object> map = Map<String, Object>.from(data);
    Map<String?, Object?> payload =
        Map<String?, Object?>.from(map["payload"] as Map<Object?, Object?>);

    String? dialogId = payload["dialogId"] as String;
    if (dialogId == _dialogId) {
      QBMessage? message = QBMessageMapper.mapToQBMessage(payload);
      _wrappedMessageSet.addAll(await _wrapMessages([message]));
      states?.add(LoadMessagesSuccessState(_getMessageListSortedByDate(), true));
    }
  }

  Future<void> _subscribeConnectedChat() async {
    if (_connectedChatSubscription != null) {
      return;
    }
    try {
      _connectedChatSubscription =
          await QB.chat.subscribeChatEvent(QBChatEvents.CONNECTED, _processConnectedChatEvent);
    } on PlatformException catch (e) {
      states?.add(ErrorState(makeErrorMessage(e)));
    }
  }

  void _processConnectedChatEvent(dynamic data) async {
    states?.add(ChatConnectedState(_localUserId!));
  }

  Future<void> _unsubscribeConnectedChat() async {
    await _connectedChatSubscription?.cancel();
    _connectedChatSubscription = null;
  }

  Future<void> _unsubscribeMessageStatuses() async {
    await _messageDeliveredSubscription?.cancel();
    _messageDeliveredSubscription = null;

    await _messageReadSubscription?.cancel();
    _messageReadSubscription = null;
  }

  Future<void> _unsubscribeIncomingMessages() async {
    await _incomingMessagesSubscription?.cancel();
    _incomingMessagesSubscription = null;
  }

  Future<void> _restoreSavedUserId() async {
    int userId = await _storageRepository.getUserId();
    if (userId != StorageRepository.NOT_SAVED_USER_ID) {
      _localUserId = userId;
    } else {
      states?.add(SavedUserErrorState());
    }
  }

  Future<void> _connectChat() async {
    if (_localUserId == null) {
      states?.add(ChatConnectingErrorState("UserId is null"));
    }
    try {
      bool connected = await _chatRepository.isConnected() ?? false;
      if (connected) {
        states?.add(ChatConnectedState(_localUserId!));
      } else {
        _chatRepository.connect(_localUserId, DEFAULT_USER_PASSWORD);
      }
    } on PlatformException catch (e) {
      states?.add(ChatConnectingErrorState(makeErrorMessage(e)));
    } on RepositoryException catch (e) {
      states?.add(ChatConnectingErrorState(e.message));
    }
  }

  Future<void> _updateDialog() async {
    states?.add(UpdateChatInProgressState());
    try {
      _dialog = await _chatRepository.getDialog(_dialogId);

      if (_dialog == null) {
        return;
      }

      states?.add(UpdateChatSuccessState(_dialog!));
      if (_dialog?.type != QBChatDialogTypes.CHAT) {
        bool isJoined = await _chatRepository.isJoinedDialog(_dialogId);
        if (!isJoined) {
          await _chatRepository.joinDialog(_dialogId);
        }
      }
      if (_isNewChat && _dialog?.type == QBChatDialogTypes.GROUP_CHAT) {
        await _sendNotificationMessageCreatedChat().then((_) => _sendSystemMessagesCreatedChat());
        _isNewChat = false;
      }
    } on PlatformException catch (e) {
      states?.add(UpdateChatErrorState(makeErrorMessage(e)));
    } on RepositoryException catch (e) {
      states?.add(UpdateChatErrorState(e.message));
    }
  }

  Future<void> _loadMessages() async {
    int skip = 0;
    if (_wrappedMessageSet.length > 0) {
      skip = _wrappedMessageSet.length;
    }

    states?.add(LoadMessagesInProgressState());
    List<QBMessage?>? messages;
    try {
      messages = await _chatRepository.getDialogMessagesByDateSent(_dialogId,
          limit: PAGE_SIZE, skip: skip);
    } on PlatformException catch (e) {
      states?.add(UpdateChatErrorState(makeErrorMessage(e)));
    } on RepositoryException catch (e) {
      states?.add(UpdateChatErrorState(e.message));
    }

    if (messages != null || _localUserId != null) {
      _loadUsers(messages!);
      List<QBMessageWrapper> wrappedMessages = await _wrapMessages(messages);

      _wrappedMessageSet.addAll(wrappedMessages);
      bool hasMore = messages.length == PAGE_SIZE;

      if (skip == 0) {
        await _subscribeEvents();
      }

      states?.add(LoadMessagesSuccessState(_getMessageListSortedByDate(), hasMore));
    }
  }

  void _loadUsers(List<QBMessage?> messages) async {
    if (messages.length == 0) {
      return;
    }

    Set<int> usersIds = HashSet<int>();
    if (_localUserId != null) {
      usersIds.add(_localUserId!);
    }
    messages.forEach((message) {
      if (message != null && message.senderId != null) {
        usersIds.add(message.senderId!);
      }
    });

    List<QBUser?> users = await _usersRepository.getUsersByIds(usersIds.toList());
    if (users.length > 0) {
      _saveParticipants(users);
    }
  }

  Future<void> _sendTextMessage(String text) async {
    if (text.length > TEXT_MESSAGE_MAX_SIZE) {
      text = text.substring(0, TEXT_MESSAGE_MAX_SIZE);
    }

    await _chatRepository.sendMessage(_dialogId, text);
  }

  Future<List<QBMessageWrapper>> _wrapMessages(List<QBMessage?> messages) async {
    List<QBMessageWrapper> wrappedMessages = [];
    for (QBMessage? message in messages) {
      if (message == null) {
        break;
      }

      QBUser? sender = _getParticipantById(message.senderId);
      if (sender == null && message.senderId != null) {
        List<QBUser?> users = await _usersRepository.getUsersByIds([message.senderId!]);
        if (users.length > 0) {
          sender = users[0];
          _saveParticipants(users);
        }
      }
      String senderName = sender?.fullName ?? sender?.login ?? "DELETED User";
      wrappedMessages.add(QBMessageWrapper(senderName, message, _localUserId!));
    }
    return wrappedMessages;
  }

  Future<void> _subscribeTypingStatus() async {
    await _unsubscribeTypingStatus();

    try {
      _typingSubscription =
          await QB.chat.subscribeChatEvent(QBChatEvents.USER_IS_TYPING, _processIsTypingEvent);
    } on PlatformException catch (e) {
      states?.add(ErrorState(makeErrorMessage(e)));
    }

    try {
      _stopTypingSubscription = await QB.chat
          .subscribeChatEvent(QBChatEvents.USER_STOPPED_TYPING, _processStopTypingEvent);
    } on PlatformException catch (e) {
      states?.add(ErrorState(makeErrorMessage(e)));
    }
  }

  Future<void> _unsubscribeTypingStatus() async {
    await _typingSubscription?.cancel();
    _typingSubscription = null;

    await _stopTypingSubscription?.cancel();
    _stopTypingSubscription = null;
  }

  void _processIsTypingEvent(dynamic data) async {
    Map<String, Object> map = Map<String, Object>.from(data);
    Map<String?, Object?> payload =
        Map<String?, Object?>.from(map["payload"] as Map<Object?, Object?>);

    String dialogId = payload["dialogId"] as String;
    int userId = payload["userId"] as int;

    if (userId == _localUserId) {
      return;
    }
    if (dialogId == this._dialogId) {
      var user = _getParticipantById(userId);
      if (user == null) {
        List<QBUser?> users = await _usersRepository.getUsersByIds([userId]);
        if (users.length > 0) {
          _saveParticipants(users);
          user = users[0];
        }
      }

      String? userName = user?.fullName ?? user?.login;
      if (userName == null || userName.isEmpty) {
        userName = "Unknown";
      }
      _typingUsersNames.remove(userName);
      _typingUsersNames.insert(0, userName);
      states?.add(OpponentIsTypingState(_typingUsersNames));
      _typingStatusTimer?.cancelWithDelay(() {
        states?.add(OpponentStoppedTypingState());
        _typingUsersNames.remove(userName);
      });
    }
  }

  void _processStopTypingEvent(dynamic data) {
    Map<String, Object> map = Map<String, Object>.from(data);
    Map<String?, Object?> payload =
        Map<String?, Object?>.from(map["payload"] as Map<Object?, Object?>);

    String dialogId = payload["dialogId"] as String;
    int userId = payload["userId"] as int;

    if (dialogId == _dialogId) {
      var user = _getParticipantById(userId);
      var userName = user?.fullName ?? user?.login;

      _typingUsersNames.remove(userName);
      if (_typingUsersNames.isEmpty) {
        states?.add(OpponentStoppedTypingState());
      } else {
        states?.add(OpponentIsTypingState(_typingUsersNames));
      }
    }
  }

  void _saveParticipants(List<QBUser?> users) {
    for (QBUser? user in users) {
      if (user?.id != null) {
        if (_participantsMap.containsKey(user?.id)) {
          _participantsMap.update(user!.id!, (value) => user);
        } else {
          _participantsMap[user!.id!] = user;
        }
      }
    }
  }

  QBUser? _getParticipantById(int? userId) {
    return _participantsMap.containsKey(userId) ? _participantsMap[userId] : null;
  }

  @override
  void connectionTypeChanged(ConnectionType type) async {
    switch (type) {
      case ConnectionType.wifi:
      case ConnectionType.mobile:
        await _initBlocData();
        break;
      case ConnectionType.none:
        await _unsubscribeConnectedChat();
        await _unsubscribeEvents();
        break;
    }
  }
}

class TypingStatusTimer {
  static const int TIMER_DELAY = 30;
  Timer? _timer;

  cancelWithDelay(VoidCallback callback) {
    _timer?.cancel();
    _timer = Timer(Duration(seconds: TIMER_DELAY), callback);
  }

  cancel() {
    _timer?.cancel();
  }
}
