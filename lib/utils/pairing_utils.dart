import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class PairingUtils {
  static Future<String> getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown_ios_device';
      }
    } catch (e) {
      // Fallback
    }
    return 'unknown_device_${Random().nextInt(100000)}';
  }

  static String generatePairingCode() {
    // Generate a 6-digit random code
    final random = Random();
    final code = random.nextInt(900000) + 100000; // ensures 6 digits
    return code.toString();
  }
}
