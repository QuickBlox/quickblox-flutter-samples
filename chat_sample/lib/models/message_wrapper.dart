import 'package:quickblox_sdk/models/qb_message.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

class QBMessageWrapper implements Comparable {
  DateTime _date = DateTime(0);
  String _senderName;
  QBMessage _message;
  int _currentUserId;

  String? get id => _message.id;
  String? get senderName => _senderName;
  QBMessage get qbMessage => _message;
  DateTime get date => _date;
  bool get isIncoming => _message.senderId != _currentUserId;
  int get currentUserId => _currentUserId;

  QBMessageWrapper(this._senderName, this._message, this._currentUserId) {
    int? timeStamp = _message.dateSent ?? 0;
    _date = DateTime.fromMicrosecondsSinceEpoch(timeStamp * 1000);
  }

  @override
  bool operator ==(Object other) {
    return other is QBMessageWrapper && other.runtimeType == runtimeType && other.id == id;
  }

  @override
  int compareTo(other) {
    return date.compareTo(other.date);
  }

  @override
  int get hashCode {
    int hash = 3;
    hash = 53 * hash + id.toString().length;
    return hash;
  }
}
