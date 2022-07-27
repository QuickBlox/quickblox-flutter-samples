import 'dart:collection';
import 'dart:core';

import 'package:chat_sample/data/repository_exception.dart';
import 'package:quickblox_sdk/chat/constants.dart';
import 'package:quickblox_sdk/models/qb_dialog.dart';
import 'package:quickblox_sdk/models/qb_filter.dart';
import 'package:quickblox_sdk/models/qb_message.dart';
import 'package:quickblox_sdk/models/qb_sort.dart';
import 'package:quickblox_sdk/quickblox_sdk.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

class ChatRepository {
  static const String PROPERTY_DIALOG_ID = "dialog_id";
  static const String PROPERTY_NOTIFICATION_TYPE = "notification_type";
  static const int NOTIFICATION_TYPE_CREATE = 1;
  static const int NOTIFICATION_TYPE_ADD = 2;
  static const int NOTIFICATION_TYPE_LEFT = 3;

  static const String _parameterIsNullException = "Required parameters are NULL";

  Future<void> connect(int? userId, String password) async {
    if (userId == null) {
      throw RepositoryException(_parameterIsNullException, affectedParams: ["userId"]);
    }
    await QB.chat.connect(userId, password);
  }

  Future<void> disconnect() async {
    await QB.chat.disconnect();
  }

  Future<bool?> isConnected() async {
    return QB.chat.isConnected();
  }

  void pingServer() async {
    QB.chat.pingServer();
  }

  void pingUser(int userId) async {
    QB.chat.pingUser(userId);
  }

  Future<List<QBDialog?>> loadDialogs(
      {QBSort? sort, QBFilter? filter, int? limit, int? skip}) async {
    return QB.chat.getDialogs(sort: sort, filter: filter, limit: limit, skip: skip);
  }

  Future<QBDialog?> getDialog(String? dialogId) async {
    if (dialogId == null) {
      throw RepositoryException(_parameterIsNullException, affectedParams: ["dialogId"]);
    }
    QBFilter filter = QBFilter();
    filter.field = QBChatDialogFilterFields.ID;
    filter.operator = QBChatDialogFilterOperators.IN;
    filter.value = dialogId;
    List<QBDialog?> dialogList = await QB.chat.getDialogs(filter: filter);
    QBDialog? dialog = dialogList.first;
    return dialog;
  }

  Future<int?> getDialogsCount(QBFilter filter, int limit, int skip) async {
    return await QB.chat.getDialogsCount(qbFilter: filter, limit: limit, skip: skip);
  }

  Future<QBDialog?> updateDialog(String? dialogId,
      {List<int>? addUsers, List<int>? removeUsers}) async {
    if (dialogId == null) {
      throw RepositoryException(_parameterIsNullException, affectedParams: ["dialogId"]);
    }
    return await QB.chat.updateDialog(dialogId, addUsers: addUsers, removeUsers: removeUsers);
  }

  Future<QBDialog?> createDialog(List<int> occupantsIds, String dialogName, int dialogType) async {
    return await QB.chat
        .createDialog(dialogType, dialogName: dialogName, occupantsIds: occupantsIds);
  }

  Future<void> deleteDialog(String? dialogId) async {
    if (dialogId == null) {
      throw RepositoryException(_parameterIsNullException, affectedParams: ["dialogId"]);
    }
    return await QB.chat.deleteDialog(dialogId);
  }

  Future<void> leaveDialog(String? dialogId) async {
    if (dialogId == null) {
      throw RepositoryException(_parameterIsNullException, affectedParams: ["dialogId"]);
    }
    await QB.chat.leaveDialog(dialogId);
  }

  Future<void> joinDialog(String? dialogId) async {
    if (dialogId == null) {
      throw RepositoryException(_parameterIsNullException, affectedParams: ["dialogId"]);
    }
    await QB.chat.joinDialog(dialogId);
  }

  Future<List<int>> getOnlineUsers(String? dialogId) async {
    if (dialogId == null) {
      throw RepositoryException(_parameterIsNullException, affectedParams: ["dialogId"]);
    }
    return QB.chat.getOnlineUsers(dialogId) as Future<List<int>>;
  }

  Future<void> sendMessage(String? dialogId, String messageBody) async {
    if (dialogId == null) {
      throw RepositoryException(_parameterIsNullException, affectedParams: ["dialogId"]);
    }
    await QB.chat.sendMessage(dialogId, body: messageBody, saveToHistory: true, markable: true);
  }

  Future<bool> isJoinedDialog(String? dialogId) async {
    if (dialogId == null) {
      throw RepositoryException(_parameterIsNullException, affectedParams: ["dialogId"]);
    }
    return await QB.chat.isJoinedDialog(dialogId);
  }

  Future<void> sendNotificationMessage(
      String? dialogId, String messageBody, int notificationType) async {
    if (dialogId == null) {
      throw RepositoryException(_parameterIsNullException, affectedParams: ["dialogId"]);
    }
    Map<String, String> property = HashMap();
    property[PROPERTY_NOTIFICATION_TYPE] = notificationType.toString();
    await QB.chat.sendMessage(dialogId,
        body: messageBody, properties: property, markable: true, saveToHistory: true);
  }

  Future<void> sendSystemMessage(String? dialogId, int? recipientId, int notificationType) async {
    if (dialogId == null || recipientId == null) {
      throw RepositoryException(_parameterIsNullException,
          affectedParams: ["dialogId", "recipientId"]);
    }
    Map<String, String> property = HashMap();
    property[PROPERTY_NOTIFICATION_TYPE] = notificationType.toString();

    // we need dialog ID in system message. Now we have to pass it in properties
    property[PROPERTY_DIALOG_ID] = dialogId;
    await QB.chat.sendSystemMessage(recipientId, properties: property);
  }

  void markMessageRead(QBMessage message) async {
    await QB.chat.markMessageRead(message);
  }

  void markMessageDelivered(QBMessage message) async {
    await QB.chat.markMessageDelivered(message);
  }

  Future<void> sendIsTyping(String? dialogId) async {
    if (dialogId == null) {
      throw RepositoryException(_parameterIsNullException, affectedParams: ["dialogId"]);
    }
    await QB.chat.sendIsTyping(dialogId);
  }

  Future<void> sendStoppedTyping(String? dialogId) async {
    if (dialogId == null) {
      throw RepositoryException(_parameterIsNullException, affectedParams: ["dialogId"]);
    }
    await QB.chat.sendStoppedTyping(dialogId);
  }

  Future<List<QBMessage?>> getDialogMessagesByDateSent(String? dialogId,
      {int limit = 100, int skip = 0}) async {
    if (dialogId == null) {
      throw RepositoryException(_parameterIsNullException, affectedParams: ["dialogId"]);
    }
    QBSort sort = QBSort();
    sort.field = QBChatMessageSorts.DATE_SENT;
    sort.ascending = false;

    return await QB.chat
        .getDialogMessages(dialogId, sort: sort, limit: limit, skip: skip, markAsRead: false);
  }

  Future<QBMessage?> getMessageById(String? dialogId, String? messageId) async {
    if (dialogId == null || messageId == null) {
      throw RepositoryException(_parameterIsNullException,
          affectedParams: ["dialogId", "messageId"]);
    }
    QBFilter filter = QBFilter();
    filter.field = QBChatMessageFilterFields.ID;
    filter.value = messageId;
    filter.operator = QBChatMessageFilterOperators.IN;

    List<QBMessage?> messageList = await QB.chat.getDialogMessages(dialogId, filter: filter);
    QBMessage? message = messageList.first;
    return message;
  }
}
