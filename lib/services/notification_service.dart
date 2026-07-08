import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/task.dart';
import 'database_service.dart';

const String kChannelId = 'random_reminder_channel';
const String kChannelName = 'Nhắc việc ngẫu nhiên';
const String kChannelDesc = 'Thông báo nhắc công việc vào thời điểm ngẫu nhiên';

const String actionDone = 'ACTION_DONE';
const String actionSnooze = 'ACTION_SNOOZE_30';

/// Quản lý toàn bộ vòng đời thông báo local: xin quyền, tạo kênh,
/// lên lịch theo giờ ngẫu nhiên, và xử lý khi người dùng bấm nút hành động.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init({
    required void Function(NotificationResponse) onResponse,
  }) async {
    tz_data.initializeTimeZones();
    // Múi giờ thiết bị sẽ được set qua flutter_timezone ở bản mở rộng;
    // ở đây dùng local mặc định của gói timezone.
    tz.setLocalLocation(tz.local);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: onResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    await _createChannel();
  }

  static Future<void> _createChannel() async {
    const channel = AndroidNotificationChannel(
      kChannelId,
      kChannelName,
      description: kChannelDesc,
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Xin các quyền cần thiết trên Android 13+ (POST_NOTIFICATIONS)
  /// và quyền đặt lịch chính xác (SCHEDULE_EXACT_ALARM) trên Android 12+.
  static Future<void> requestPermissions() async {
    await Permission.notification.request();
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();
  }

  /// Kiểm tra chế độ Không làm phiền (DND) đang bật hay không (best-effort,
  /// phụ thuộc quyền Do Not Disturb access mà người dùng cấp thủ công).
  static Future<bool> isDndEnabled() async {
    // permission_handler không expose trực tiếp trạng thái DND;
    // Android yêu cầu quyền đặc biệt "Notification Policy Access".
    // App khai báo intent Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS
    // để người dùng cấp quyền này thủ công (xem README).
    return false;
  }

  static Future<void> scheduleTaskNotification({
    required Task task,
    required DateTime when,
    required int notificationId,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      kChannelId,
      kChannelName,
      channelDescription: kChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(task.title),
      actions: const [
        AndroidNotificationAction(actionDone, 'Hoàn thành'),
        AndroidNotificationAction(actionSnooze, 'Nhắc lại sau 30 phút'),
      ],
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        categoryIdentifier: 'randomReminderCategory',
      ),
    );

    await _plugin.zonedSchedule(
      notificationId,
      '📌 Việc ngẫu nhiên',
      task.title,
      tz.TZDateTime.from(when, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: task.id,
    );
  }

  static Future<void> cancelAll() => _plugin.cancelAll();

  static Future<void> cancel(int id) => _plugin.cancel(id);

  static Future<List<PendingNotificationRequest>> pending() =>
      _plugin.pendingNotificationRequests();

  /// Tạo id thông báo ổn định từ số thứ tự trong ngày (0..N) để tránh trùng.
  static int makeNotificationId(DateTime day, int index) {
    final seed = int.parse(
        '${day.year}${day.month.toString().padLeft(2, '0')}${day.day.toString().padLeft(2, '0')}');
    return (seed * 100 + index) % 2147483647;
  }
}

/// Bắt buộc phải là hàm top-level / static để hoạt động khi app bị đóng hoàn toàn.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  if (response.actionId == actionDone && response.payload != null) {
    await DatabaseService.init();
    final task = DatabaseService.taskBox.get(response.payload);
    if (task != null) {
      task.isDone = true;
      task.progress = 100;
      await task.save();
    }
  } else if (response.actionId == actionSnooze && response.payload != null) {
    await DatabaseService.init();
    final task = DatabaseService.taskBox.get(response.payload);
    if (task != null) {
      final when = DateTime.now().add(const Duration(minutes: 30));
      await NotificationService.scheduleTaskNotification(
        task: task,
        when: when,
        notificationId: Random().nextInt(2000000000),
      );
    }
  }
}
