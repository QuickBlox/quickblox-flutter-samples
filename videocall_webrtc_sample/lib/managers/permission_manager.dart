import 'package:permission_handler/permission_handler.dart';

class PermissionManager {
  Future<bool> checkPermissionsForAudioCall() async {
    bool microphoneDenied = await Permission.microphone.status.isDenied;
    bool bluetoothDenied = await Permission.bluetoothConnect.status.isDenied;
    bool isAllPermissionsGranted = true;

    if (microphoneDenied || bluetoothDenied) {
      Map<Permission, PermissionStatus> statuses =
          await [Permission.bluetoothConnect, Permission.microphone].request();
      isAllPermissionsGranted = _isAllPermissionsGranted(statuses);
    }

    return isAllPermissionsGranted;
  }

  Future<bool> checkPermissionsForVideoCall() async {
    bool cameraDenied = await Permission.camera.status.isDenied;
    bool microphoneDenied = await Permission.microphone.status.isDenied;
    bool bluetoothDenied = await Permission.bluetoothConnect.status.isDenied;

    bool isAllPermissionsGranted = true;

    if (cameraDenied || microphoneDenied || bluetoothDenied) {
      Map<Permission, PermissionStatus> statuses =
          await [Permission.bluetoothConnect, Permission.camera, Permission.microphone].request();

      isAllPermissionsGranted = _isAllPermissionsGranted(statuses);
    }

    return isAllPermissionsGranted;
  }

  Future<bool> checkNotificationPermission() async {
    bool notificationDenied = await Permission.notification.status.isDenied;

    bool isAllPermissionsGranted = true;

    if (notificationDenied) {
      Map<Permission, PermissionStatus> statuses = await [Permission.notification].request();
      isAllPermissionsGranted = _isAllPermissionsGranted(statuses);
    }

    return isAllPermissionsGranted;
  }

  bool _isAllPermissionsGranted(Map<Permission, PermissionStatus> statuses) {
    bool isAllPermissionsGranted = true;
    statuses.forEach((key, value) {
      if (value == PermissionStatus.denied || value == PermissionStatus.permanentlyDenied) {
        isAllPermissionsGranted = false;
        return;
      }
    });

    return isAllPermissionsGranted;
  }
}
