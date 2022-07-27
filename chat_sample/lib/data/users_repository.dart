import 'dart:async';

import 'package:quickblox_sdk/models/qb_filter.dart';
import 'package:quickblox_sdk/models/qb_sort.dart';
import 'package:quickblox_sdk/models/qb_user.dart';
import 'package:quickblox_sdk/quickblox_sdk.dart';
import 'package:quickblox_sdk/users/constants.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

class UsersRepository {
  Future<QBUser?> createUser(String login, String fullName, String password) async {
    return QB.users.createUser(login, password, fullName: fullName);
  }

  Future<List<QBUser?>> getUsers(int page, int perPage, {QBSort? sort, QBFilter? filter}) async {
    return QB.users.getUsers(sort: sort, page: page, perPage: perPage, filter: filter);
  }

  Future<List<QBUser?>> getUsersByIds(List<int>? userIds) async {
    String? filterValue = userIds?.join(",");
    QBFilter filter = QBFilter();
    filter.field = QBUsersFilterFields.ID;
    filter.operator = QBUsersFilterOperators.IN;
    filter.value = filterValue;
    filter.type = QBUsersFilterTypes.STRING;

    return await QB.users.getUsers(filter: filter);
  }

  Future<QBUser?> updateUser(String login, String fullName) async {
    return QB.users.updateUser(login: login, fullName: fullName);
  }
}
