import 'package:flutter/material.dart';
import 'package:videocall_webrtc_sample/entities/user_entity.dart';
import 'package:videocall_webrtc_sample/presentation/utils/colors_util.dart';

class UsersListItem extends StatefulWidget {
  final UserEntity userEntity;
  final void Function(bool remove, UserEntity userWrapper)
      handleChangeSelectedUsers;

  const UsersListItem(this.userEntity, this.handleChangeSelectedUsers,
      {super.key, required});

  @override
  UsersListItemState createState() => UsersListItemState();
}

class UsersListItemState extends State<UsersListItem> {
  bool _isSelected = false;

  @override
  Widget build(BuildContext context) {
    _isSelected = widget.userEntity.selected;

    return Container(
        color: _isSelected ? const Color(0xFFD9E3F7) : Colors.white,
        height: 60,
        child: Row(
          children: <Widget>[
            Padding(
                padding: const EdgeInsets.only(top: 0, left: 17),
                child: _generateAvatarFromName(widget.userEntity.name)),
            const Padding(padding: EdgeInsets.only(left: 9)),
            Expanded(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(_formatString(widget.userEntity.name),
                    style: const TextStyle(fontSize: 17),
                    overflow: TextOverflow.ellipsis),
              ],
            )),
            SizedBox(width: 95, child: buildCheckboxItem()),
          ],
        ));
  }

  Widget buildCheckboxItem() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Checkbox(
                value: _isSelected,
                fillColor: MaterialStateColor.resolveWith((states) =>
                    states.contains(MaterialState.selected)
                        ? Colors.blue
                        : Colors.white),
                checkColor: Colors.white,
                activeColor: Colors.white,
                onChanged: (changed) {
                  setState(() {
                    _isSelected = changed ?? false;
                    widget.handleChangeSelectedUsers(
                        !_isSelected, widget.userEntity);
                  });
                }))
      ],
    );
  }

  String _formatString(String? sourceString) {
    String formattedString = "";
    if (sourceString != null && sourceString.isNotEmpty) {
      formattedString = sourceString.replaceAll("\n", " ");
    }
    return formattedString;
  }

  Widget _generateAvatarFromName(String? name) {
    name ??= "noname";
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
          color: Color(ColorUtil.getColor(name)),
          borderRadius: const BorderRadius.all(Radius.circular(20))),
      child: Center(
        child: Text(
          name.substring(0, 1).toUpperCase(),
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
