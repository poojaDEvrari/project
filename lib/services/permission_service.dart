import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<PermissionStatus> cameraStatus() async {
    return Permission.camera.status;
  }

  static Future<PermissionStatus> requestCamera() async {
    final status = await Permission.camera.request();
    return status;
  }

  static Future<bool> openSettings() async {
    return openAppSettings();
  }
}
