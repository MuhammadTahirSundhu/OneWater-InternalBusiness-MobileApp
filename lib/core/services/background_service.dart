import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import '../constants/api_endpoints.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      final storage = SecureStorageService();
      final token = await storage.getAccessToken();

      if (token == null || token.isEmpty) return true;

      final dio = Dio();
      final response = await dio.get(
        ApiEndpoints.notifications,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final notifications = response.data as List;
      final unreadCount = notifications.where((n) => !(n['is_read'] as bool)).length;

      if (unreadCount > 0) {
        final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
        
        const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
        const initSettings = InitializationSettings(android: androidInit);
        
        await flutterLocalNotificationsPlugin.initialize(initSettings);

        const androidDetails = AndroidNotificationDetails(
          'onewater_notifications',
          'OneWater Notifications',
          channelDescription: 'Notifications for OneWater Business',
          importance: Importance.max,
          priority: Priority.high,
        );

        await flutterLocalNotificationsPlugin.show(
          0,
          'New Notifications',
          'You have $unreadCount unread notification${unreadCount > 1 ? 's' : ''}.',
          const NotificationDetails(android: androidDetails),
        );
      }
      return true;
    } catch (err) {
      return false;
    }
  });
}

class BackgroundService {
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
    );

    await Workmanager().registerPeriodicTask(
      'notification_poll',
      'notification_poll_task',
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}
