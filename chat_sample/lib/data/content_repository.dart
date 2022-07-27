import 'dart:async';

import 'package:chat_sample/data/repository_exception.dart';
import 'package:flutter/services.dart';
import 'package:quickblox_sdk/models/qb_file.dart';
import 'package:quickblox_sdk/quickblox_sdk.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

class ContentRepository {
  Future<QBFile?> upload(String url) async {
    try {
      return await QB.content.upload(url);
    } on PlatformException catch (e) {
      throw RepositoryException(e.message);
    }
  }

  Future<QBFile?> getInfo(int fileId) async {
    QBFile? file;
    try {
      file = await QB.content.getInfo(fileId);
      int? id = file?.id;
    } on PlatformException catch (e) {
      throw RepositoryException(e.message);
    }
    return file;
  }

  Future<String?> getPublicURL(String uid) async {
    try {
      return await QB.content.getPublicURL(uid);
    } on PlatformException catch (e) {
      throw RepositoryException(e.message);
    }
  }

  Future<String?> getPrivateURL(String uid) async {
    try {
      return await QB.content.getPrivateURL(uid);
    } on PlatformException catch (e) {
      throw RepositoryException(e.message);
    }
  }
}
