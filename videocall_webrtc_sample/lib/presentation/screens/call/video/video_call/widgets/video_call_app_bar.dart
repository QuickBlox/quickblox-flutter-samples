import 'package:flutter/material.dart';

class VideoCallAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String text;

  const VideoCallAppBar({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.black.withOpacity(0.5),
        height: 64,
        width: MediaQuery.of(context).size.width,
        child: Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
            child: Align(
                alignment: FractionalOffset.bottomLeft,
                child: Text(text,
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      decoration: TextDecoration.none,
                      fontSize: 14,
                      color: Colors.white,
                    )))));
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
