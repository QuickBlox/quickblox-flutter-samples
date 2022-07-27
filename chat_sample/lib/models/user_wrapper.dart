import 'package:quickblox_sdk/models/qb_user.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

class QBUserWrapper {
  bool _checked;
  QBUser? _user;

  int? get id => _user?.id;
  String? get name => _user?.fullName ?? _user?.login;
  bool get checked => _checked;
  set checked(bool isChecked) => this._checked = isChecked;

  QBUserWrapper(this._checked, this._user);

  @override
  bool operator ==(Object other) {
    return other is QBUserWrapper && other.runtimeType == runtimeType && other.id == id;
  }

  @override
  int get hashCode {
    int hash = 3;
    hash = 53 * hash + id.toString().length;
    return hash;
  }
}
