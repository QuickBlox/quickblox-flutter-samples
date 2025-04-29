import 'package:quickblox_sdk/models/qb_user.dart';

class UserEntity {
  bool selected;
  QBUser user;

  int? get userId => user.id;

  String? get name => user.fullName ?? user.login;

  UserEntity(this.selected, this.user);

  @override
  bool operator ==(Object other) {
    return other is UserEntity && other.runtimeType == runtimeType && other.userId == userId;
  }

  @override
  int get hashCode {
    int hash = 3;
    hash = 53 * hash + userId.toString().length;
    return hash;
  }
}
