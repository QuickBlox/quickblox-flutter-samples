import 'package:flutter/services.dart';

class ErrorParser {
  static String parseFrom(PlatformException? e) {
    String message = e?.message ?? "";
    String code = e?.code ?? "";
    if (e?.message == null) {
      return code;
    }
    return "$code : $message";
  }
}
