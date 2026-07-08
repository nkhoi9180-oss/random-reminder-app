import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'screens/home_screen.dart';
import 'services/background_service.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'services/scheduler_service.dart';
import 'services/theme_notifier.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseService.init();

  await NotificationService.init(
    onResponse: _onForegroundNotificationResponse,
  );
  await NotificationService.requestPermissions();

  await BackgroundService.init();
  await BackgroundService.registerDailyReschedule();

  // Sinh lịch ngay khi mở app (đảm bảo luôn có lịch cho hôm nay/tuần/tháng).
  await SchedulerService.generateAndSchedule();

  runApp(const RandomReminderApp());
}

/// Xử lý khi người dùng bấm nút trên notification lúc app đang mở (foreground).
void _onForegroundNotificationResponse(NotificationResponse response) async {
  if (response.payload == null) return;
  final task = DatabaseService.taskBox.get(response.payload);
  if (task == null) return;

  if (response.actionId == actionDone) {
    task.isDone = true;
    task.progress = 100;
    await task.save();
  } else if (response.actionId == actionSnooze) {
    final when = DateTime.now().add(const Duration(minutes: 30));
    await NotificationService.scheduleTaskNotification(
      task: task,
      when: when,
      notificationId: DateTime.now().millisecondsSinceEpoch % 2147483647,
    );
  }
}

class RandomReminderApp extends StatelessWidget {
  const RandomReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeNotifier.mode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Nhắc việc ngẫu nhiên',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const HomeScreen(),
        );
      },
    );
  }
}
