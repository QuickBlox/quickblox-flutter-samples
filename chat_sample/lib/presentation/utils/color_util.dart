/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

class ColorUtil {
  static int getColor(String? text) {
    List<int> colors = [
      0xFF53C6A2,
      0xFFFDD762,
      0xFF9261D3,
      0xFF43DCE7,
      0xFFFFCC5A,
      0xFFEA4398,
      0xFF4A5DE1,
      0xFFE95555,
      0xFF7EDA54,
      0xFFF9B647
    ];

    if (text == null) {
      text = "Noname";
    }

    return colors[(text.split('').reversed.join() + text).hashCode % 10];
  }
}
