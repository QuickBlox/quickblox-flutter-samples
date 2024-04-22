import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class UsersSearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final void Function(String) callback;

  const UsersSearchBar({super.key, required this.searchController, required this.callback});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(
          padding: const EdgeInsets.only(left: 12, right: 10),
          child:
              SizedBox(height: 28, width: 28, child: SvgPicture.asset('assets/icons/search.svg'))),
      Expanded(
          child: TextFormField(
        controller: searchController,
        keyboardType: TextInputType.text,
        maxLines: 1,
        minLines: 1,
        maxLength: 25,
        onChanged: (text) {
          callback(text);
        },
        decoration: const InputDecoration(
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            hintText: "Search",
            hintStyle: TextStyle(fontSize: 15, color: Color(0xFF6C7A92)),
            counterText: ""),
      ))
    ]);
  }
}
