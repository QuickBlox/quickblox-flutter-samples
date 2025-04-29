import 'package:quickblox_sdk/models/qb_filter.dart';
import 'package:quickblox_sdk/models/qb_sort.dart';
import 'package:quickblox_sdk/models/qb_user.dart';
import 'package:quickblox_sdk/quickblox_sdk.dart';
import 'package:quickblox_sdk/users/constants.dart';

class UsersManager {
  Future<List<QBUser>> getUsers(int page, int perPage, {QBSort? sort, QBFilter? filter}) async {
    List<QBUser?> users = await QB.users.getUsers(sort: sort, page: page, perPage: perPage, filter: filter);
    return users.whereType<QBUser>().toList();
  }

  Future<List<QBUser>> getUsersByIds(List<int>? userIds) async {
    String? filterValue = userIds?.join(",");
    QBFilter filter = QBFilter();
    filter.field = QBUsersFilterFields.ID;
    filter.operator = QBUsersFilterOperators.IN;
    filter.value = filterValue;
    filter.type = QBUsersFilterTypes.STRING;

    List<QBUser?> users = await QB.users.getUsers(filter: filter);
    return users.whereType<QBUser>().toList();
  }

  Future<bool> pingUser(int userId) async {
    return QB.chat.pingUser(userId);
  }
}
