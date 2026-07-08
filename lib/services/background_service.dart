import 'package:workmanager/workmanager.dart';

import 'database_service.dart';
import 'notification_service.dart';
import 'scheduler_service.dart';

const String kDailyRescheduleTask = 'daily_reschedule_task';

/// Callback bắt buộc là hàm top-level, chạy trong isolate riêng biệt của WorkManager.
/// Vì vậy phải tự init lại Hive + timezone + notification plugin ở đây.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case kDailyRescheduleTask:
        await DatabaseService.init();
        await NotificationService.init(onResponse: (_) {});
        await SchedulerService.generateAndSchedule();
        break;
    }
    return Future.value(true);
  });
}

class BackgroundService {
  static Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  /// Đăng ký tác vụ định kỳ ~mỗi 24h để tái tạo lịch cho ngày/tuần/tháng kế tiếp.
  /// Android WorkManager không đảm bảo chạy đúng giờ tuyệt đối (để tiết kiệm pin),
  /// nhưng đảm bảo sẽ chạy trong khoảng thời gian hợp lý kể cả sau khi khởi động lại máy.
  static Future<void> registerDailyReschedule() async {
    await Workmanager().registerPeriodicTask(
      kDailyRescheduleTask,
      kDailyRescheduleTask,
      frequency: const Duration(hours: 24),
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
        requiresCharging: false,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.linear,
    );
  }

  static Future<void> cancelAll() => Workmanager().cancelAll();
}
