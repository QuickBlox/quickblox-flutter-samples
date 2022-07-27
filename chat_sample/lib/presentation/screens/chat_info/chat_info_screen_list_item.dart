import 'dart:ui';

import 'package:chat_sample/presentation/utils/color_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:quickblox_sdk/models/qb_user.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

class ChatInfoListItem extends StatefulWidget {
  final QBUser _user;
  final int _currentUserId;

  const ChatInfoListItem(Key key, this._currentUserId, this._user) : super(key: key);

  @override
  _ChatInfoListItemState createState() => _ChatInfoListItemState(_currentUserId);
}

class _ChatInfoListItemState extends State<ChatInfoListItem> {
  final int _currentUserId;

  _ChatInfoListItemState(this._currentUserId);

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 60,
        color: Color(0x00FFFFFF),
        child: Container(
          padding: EdgeInsets.only(left: 15, right: 11),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.centerLeft,
                margin: EdgeInsets.only(top: 12),
                child: CircleAvatar(
                  backgroundColor: Color(ColorUtil.getColor(widget._user.fullName)),
                  child: Text(
                    '${userName(this.widget._user).substring(0, 1).toUpperCase()}',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              SizedBox(width: 9),
              Expanded(
                  child: Container(
                padding: EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Text(userName(this.widget._user),
                        style: TextStyle(
                            fontSize: 17, color: isCurrentUser() ? Colors.black38 : Colors.black54),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              )),
            ],
          ),
        ));
  }

  bool isCurrentUser() {
    return this.widget._user.id == _currentUserId;
  }

  String userName(QBUser user) {
    String? name = user.fullName != null ? user.fullName : user.login;
    if (isCurrentUser()) {
      name = name! + " (You)";
    }
    return name!;
  }
}
