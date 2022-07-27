import 'dart:async';
import 'dart:core';

import 'package:chat_sample/data/repository_exception.dart';
import 'package:flutter/services.dart';
import 'package:quickblox_sdk/models/qb_custom_object.dart';
import 'package:quickblox_sdk/quickblox_sdk.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

class CustomObjectsRepository {
  Future<QBCustomObject?> createCustomObject(
      String className, Map<String, Object> fieldsMap) async {
    QBCustomObject? customObject;
    try {
      List<QBCustomObject?> customObjectsList =
          await QB.data.create(className: className, fields: fieldsMap);
      customObject = customObjectsList[0];
      String? id = customObject?.id;
    } on PlatformException catch (e) {
      throw RepositoryException(e.message);
    }
    return customObject;
  }

  Future<void> removeCustomObject(String className, List<String> ids) async {
    try {
      await QB.data.remove(className, ids);
    } on PlatformException catch (e) {
      throw RepositoryException(e.message);
    }
  }

  Future<List<QBCustomObject?>> getCustomObjectsByIds(String className, List<String> ids) async {
    List<QBCustomObject?> customObjects = [];
    try {
      customObjects = await QB.data.getByIds(className, ids);
      int size = customObjects.length;
    } on PlatformException catch (e) {
      throw RepositoryException(e.message);
    }
    return customObjects;
  }

  Future<List<QBCustomObject?>?> getCustomObjects(String className) async {
    try {
      return await QB.data.get(className);
    } on PlatformException catch (e) {
      throw RepositoryException(e.message);
    }
  }

  Future<void> updateCustomObject(String className, String objectId) async {
    try {
      QBCustomObject? customObject = await QB.data.update(className, id: objectId);
      String? id = customObject?.id;
    } on PlatformException catch (e) {
      throw RepositoryException(e.message);
    }
  }
}
