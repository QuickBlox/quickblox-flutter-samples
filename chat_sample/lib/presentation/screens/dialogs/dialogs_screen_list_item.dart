import 'package:chat_sample/bloc/base_bloc.dart';
import 'package:chat_sample/bloc/dialogs/dialogs_screen_bloc.dart';
import 'package:chat_sample/bloc/dialogs/dialogs_screen_events.dart';
import 'package:chat_sample/presentation/utils/color_util.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quickblox_sdk/models/qb_dialog.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

class DialogsListItem extends StatefulWidget {
  final QBDialog _dialog;
  final bool _deleteState;

  const DialogsListItem(Key key, this._dialog, this._deleteState) : super(key: key);

  @override
  _DialogsListItemState createState() => _DialogsListItemState(_dialog, _deleteState);
}

class _DialogsListItemState extends State<DialogsListItem> {
  QBDialog _dialog;
  bool _deleteState;
  bool _isSelected = false;
  Bloc? _bloc;

  _DialogsListItemState(this._dialog, this._deleteState);

  @override
  Widget build(BuildContext context) {
    _bloc = Provider.of<DialogsScreenBloc>(context, listen: false);

    if (_dialog.name == null) {
      _dialog.name = "";
    }

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
                  backgroundColor: Color(ColorUtil.getColor(_dialog.name)),
                  child: Text(
                    _buildAvatarSymbol(),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              Container(padding: EdgeInsets.only(left: 9)),
              Expanded(
                  child: Container(
                padding: EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(_formatString(_dialog.name!),
                        style: TextStyle(fontSize: 17), overflow: TextOverflow.ellipsis),
                    Padding(padding: EdgeInsets.only(top: 2)),
                    Text(_dialog.lastMessage != null ? _formatString(_dialog.lastMessage!) : "",
                        style: TextStyle(fontSize: 15, color: Color(0xFF6C7A92)),
                        overflow: TextOverflow.ellipsis),
                    Padding(
                      padding: EdgeInsets.only(top: 1),
                    ),
                  ],
                ),
              )),
              Container(width: 85, child: _deleteState ? buildCheckboxItem() : buildChatItem())
            ],
          ),
        ));
  }

  String _buildAvatarSymbol() {
    int? firstCharacter = _dialog.name?.runes.first;
    String avatarSymbol = "";
    if (firstCharacter != null) {
      avatarSymbol = String.fromCharCode(firstCharacter).toUpperCase();
    }
    return avatarSymbol;
  }

  Widget buildChatItem() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(top: 13),
          child: Text(
            _dialog.lastMessageDateSent != null && _dialog.lastMessageDateSent! > 0
                ? '${_buildDate(_dialog.lastMessageDateSent!)}'
                : "no date",
            style: TextStyle(fontSize: 12, color: Color(0xFF6C7A92)),
          ),
        ),
        Padding(padding: EdgeInsets.only(top: 1)),
        _dialog.unreadMessagesCount != null && _dialog.unreadMessagesCount! > 0
            ? _generateUnreadMessagesBubble(_dialog.unreadMessagesCount!)
            : Text("")
      ],
    );
  }

  Widget buildCheckboxItem() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Padding(
            padding: EdgeInsets.only(top: 12),
            child: Checkbox(
                value: _isSelected,
                fillColor: MaterialStateColor.resolveWith((states) =>
                    states.contains(MaterialState.selected) ? Colors.blue : Colors.grey),
                checkColor: Colors.white,
                activeColor: Colors.grey,
                onChanged: (bool? changed) {
                  setState(() {
                    _isSelected = changed ?? false;
                    _bloc?.events?.add(ChangedChatsToDeleteEvent(_dialog, !_isSelected));
                  });
                }))
      ],
    );
  }

  String _formatString(String sourceString) {
    if (sourceString.length > 0) {
      sourceString = sourceString.replaceAll("\n", " ");
    }
    return sourceString;
  }

  Widget _generateUnreadMessagesBubble(int unreadMessagesCount) {
    String counter = unreadMessagesCount > 99 ? "99+" : unreadMessagesCount.toString();
    int width = 24;
    if (counter.length == 2) {
      width = 29;
    } else if (counter.length == 3) {
      width = 34;
    }

    return Container(
      width: width.toDouble(),
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.elliptical(50, 50)),
        color: Color(0xff00cc4c),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            counter,
            style: TextStyle(color: Colors.white, fontSize: 12),
          )
        ],
      ),
    );
  }

  String _buildDate(int timeStamp) {
    String completedDate = "";

    DateFormat todayFormat = DateFormat("HH:mm");
    DateFormat dayFormat = DateFormat("d MMMM");
    DateFormat lastYearFormat = DateFormat("dd.MM.yy");

    DateTime now = DateTime.now();
    DateTime messageTime = DateTime.fromMicrosecondsSinceEpoch(timeStamp * 1000);

    var yesterday = DateTime(now.year, now.month, now.day - 1);
    DateTime messageDate = DateTime(messageTime.year, messageTime.month, messageTime.day);

    if (now.difference(messageDate).inDays == 0) {
      completedDate = todayFormat.format(messageTime);
    } else if (yesterday == messageDate) {
      completedDate = "Yesterday";
    } else if (now.year == messageTime.year) {
      completedDate = dayFormat.format(messageTime);
    } else {
      completedDate = lastYearFormat.format(messageTime);
    }

    return completedDate;
  }
}
