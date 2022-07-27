import 'dart:async';
import 'dart:core';

import 'package:chat_sample/data/repository_exception.dart';
import 'package:flutter/services.dart';
import 'package:quickblox_sdk/models/qb_event.dart';
import 'package:quickblox_sdk/quickblox_sdk.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

class EventsRepository {
  Future<List<QBEvent?>?> createNotification(
      String type, String notificationEventType, int senderId, Map<String, Object> payload) async {
    try {
      return await QB.events.create(type, notificationEventType, senderId, payload);
    } on PlatformException catch (e) {
      throw RepositoryException(e.message);
    }
  }

  Future<QBEvent?> updateNotification(int id) async {
    QBEvent? qbEvent;
    try {
      qbEvent = await QB.events.update(id);
      int? notificationId = qbEvent?.id;
    } on PlatformException catch (e) {
      throw RepositoryException(e.message);
    }
    return qbEvent;
  }

  Future<void> removeNotification(int id) async {
    try {
      await QB.events.remove(id);
    } on PlatformException catch (e) {
      throw RepositoryException(e.message);
    }
  }

  Future<QBEvent?> getNotificationById(int id) async {
    try {
      return await QB.events.getById(id);
    } on PlatformException catch (e) {
      throw RepositoryException(e.message);
    }
  }

  Future<List<QBEvent?>?> getNotifications() async {
    try {
      return await QB.events.get();
    } on PlatformException catch (e) {
      throw RepositoryException(e.message);
    }
  }
}
