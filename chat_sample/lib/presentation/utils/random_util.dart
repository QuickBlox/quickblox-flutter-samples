import 'dart:math';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

class RandomUtil {
  static String getRandomString(int length) {
    const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    Random _random = Random();
    return String.fromCharCodes(Iterable.generate(length, (_) =>
        _chars.codeUnitAt(_random.nextInt(_chars.length))
    )
    );
  }
}
