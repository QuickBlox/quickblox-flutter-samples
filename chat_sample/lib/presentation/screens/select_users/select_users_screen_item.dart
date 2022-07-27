import 'package:chat_sample/bloc/base_bloc.dart';
import 'package:chat_sample/bloc/select_users/select_users_screen_bloc.dart';
import 'package:chat_sample/bloc/select_users/select_users_screen_events.dart';
import 'package:chat_sample/models/user_wrapper.dart';
import 'package:chat_sample/presentation/utils/color_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

/// Created by Injoit on 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

class SelectUsersScreenItem extends StatefulWidget {
  final QBUserWrapper _qbUserWrapper;

  SelectUsersScreenItem(this._qbUserWrapper);

  @override
  _SelectUsersScreenItemState createState() => _SelectUsersScreenItemState();
}

class _SelectUsersScreenItemState extends State<SelectUsersScreenItem>
    with AutomaticKeepAliveClientMixin {
  Bloc? _bloc;
  bool _isSelected = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    _bloc = Provider.of<SelectUsersScreenBloc>(context, listen: false);
    _isSelected = widget._qbUserWrapper.checked;

    return Container(
        color: _isSelected ? Color(0xFFD9E3F7) : Color(0xFFF4F6F9),
        height: 60,
        child: Row(
          children: <Widget>[
            Padding(
                padding: EdgeInsets.only(top: 0, left: 17),
                child: _generateAvatarFromName(widget._qbUserWrapper.name)),
            Padding(padding: EdgeInsets.only(left: 9)),
            Expanded(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(_formatString(widget._qbUserWrapper.name),
                    style: TextStyle(fontSize: 17), overflow: TextOverflow.ellipsis),
              ],
            )),
            Container(width: 95, child: buildCheckboxItem()),
          ],
        ));
  }

  Widget buildCheckboxItem() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Padding(
            padding: EdgeInsets.only(top: 6),
            child: Checkbox(
                value: _isSelected,
                fillColor: MaterialStateColor.resolveWith((states) =>
                    states.contains(MaterialState.selected) ? Colors.blue : Colors.grey),
                checkColor: Colors.white,
                activeColor: Colors.grey,
                onChanged: (bool? changed) {
                  setState(() {
                    _isSelected = changed ?? false;
                    _bloc?.events
                        ?.add(ChangedSelectedUsersEvent(widget._qbUserWrapper, !_isSelected));
                  });
                }))
      ],
    );
  }

  String _formatString(String? sourceString) {
    String formattedString = "";
    if (sourceString != null && sourceString.length > 0) {
      formattedString = sourceString.replaceAll("\n", " ");
    }
    return formattedString;
  }

  Widget _generateAvatarFromName(String? name) {
    if (name == null) {
      name = "noname";
    }
    return Container(
      width: 40,
      height: 40,
      decoration: new BoxDecoration(
          color: Color(ColorUtil.getColor(name)),
          borderRadius: new BorderRadius.all(Radius.circular(20))),
      child: Center(
        child: Text(
          '${name.substring(0, 1).toUpperCase()}',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
