import 'package:quickblox_sdk/quickblox_sdk.dart';

class ChatManager {
  Future<void> connect(int userId, String password) async {
    await QB.chat.connect(userId, password);
  }

  Future<void> disconnect() async {
    await QB.chat.disconnect();
  }

  Future<bool?> isConnected() async {
    return QB.chat.isConnected();
  }
}
