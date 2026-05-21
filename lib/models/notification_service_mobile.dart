import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final _plugin = FlutterLocalNotificationsPlugin();
bool _initialized = false;

Future<void> initMobile() async {
  if (_initialized) return;
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const settings = InitializationSettings(android: android);
  await _plugin.initialize(settings,
      onDidReceiveNotificationResponse: (_) {});
  _initialized = true;
}

Future<void> showMobileNotification({
  required int id,
  required String title,
  required String body,
}) async {
  const androidDetails = AndroidNotificationDetails(
    'findex_channel',
    'Findex Alerts',
    channelDescription: 'Budget and transaction alerts',
    importance: Importance.high,
    priority: Priority.high,
  );
  await _plugin.show(id, title, body,
      const NotificationDetails(android: androidDetails));
}