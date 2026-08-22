import 'package:device_calendar/device_calendar.dart';

Future<bool> requestCalendarAccess() async {
  final calendar = DeviceCalendarPlugin();
  final permissions = await calendar.hasPermissions();
  if (permissions.data == true) {
    return true;
  }

  final requested = await calendar.requestPermissions();
  return requested.data == true;
}