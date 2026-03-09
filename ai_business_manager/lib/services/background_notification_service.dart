import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_cache.dart';
import '../providers/branch_provider.dart';
import '../services/google_sheet_service.dart';
import 'dart:developer' as dev;

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    dev.log('Background task started: $task');

    try {
      final prefs = await SharedPreferences.getInstance();
      final cache = AppCache(prefs);

      final container = ProviderContainer(
        overrides: [appCacheProvider.overrideWithValue(cache)],
      );

      final branchesList = container.read(branchesListProvider);

      if (branchesList.isEmpty) {
        dev.log('No branches connected, skipping check');
        return true;
      }

      final sheetService = container.read(googleSheetServiceProvider);
      await sheetService.initialize('assets/credentials.json');

      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      const initializationSettingsAndroid = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
      );

      for (var branch in branchesList) {
        bool hasRecentUpdates = false;

        final sheets = ['Enquiry', 'Bookings', 'Sold'];
        for (var sheetName in sheets) {
          try {
            final data = await sheetService.getSheetData(
              branch.googleSheetId,
              '$sheetName!A2:B20',
            );
            if (data != null && data.isNotEmpty) {
              for (var row in data) {
                if (row.length > 1) {
                  final dateStr = row[1].toString();
                  final date = _parseDateSafely(dateStr);
                  if (DateTime.now().difference(date).inHours <= 2) {
                    hasRecentUpdates = true;
                    break;
                  }
                }
              }
            }
          } catch (e) {
            dev.log(
              'Error checking sheet $sheetName for branch ${branch.name}: $e',
            );
          }
          if (hasRecentUpdates) break;
        }

        if (!hasRecentUpdates) {
          await _showNotification(
            plugin: flutterLocalNotificationsPlugin,
            title: 'Branch Needs Update',
            body:
                '${branch.name} branch: no new entries in last 2 hours. Check Bookings/Sales!',
            id: branch.id.hashCode,
          );
        }
      }
    } catch (e) {
      dev.log('Background task failed: $e');
    }

    return true;
  });
}

Future<void> _showNotification({
  required FlutterLocalNotificationsPlugin plugin,
  required String title,
  required String body,
  required int id,
}) async {
  const androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'data_freshness_channel',
    'Data Freshness Notifications',
    channelDescription: 'Notifications for stale branch data',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
  );
  const platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );

  await plugin.show(
    id: id,
    title: title,
    body: body,
    notificationDetails: platformChannelSpecifics,
  );
}

DateTime _parseDateSafely(String value) {
  if (value.isEmpty) return DateTime.now().subtract(const Duration(days: 365));

  final isoDate = DateTime.tryParse(value);
  if (isoDate != null) return isoDate;

  try {
    final cleanValue = value.trim();
    List<String> parts = [];
    if (cleanValue.contains('/')) {
      parts = cleanValue.split('/');
    } else if (cleanValue.contains('-')) {
      parts = cleanValue.split('-');
    }

    if (parts.length >= 3) {
      int day = int.parse(parts[0]);
      int month = int.parse(parts[1]);
      String yearStr = parts[2].split(' ')[0];
      int year = int.parse(yearStr);
      if (year < 100) year += 2000;
      return DateTime(year, month, day);
    }
  } catch (e) {
    // ignore
  }
  return DateTime.now().subtract(const Duration(days: 365));
}
