import 'dart:math';

import '../models/app_settings.dart';
import '../models/task.dart';
import 'database_service.dart';
import 'notification_service.dart';

/// Chịu trách nhiệm:
/// 1) Sinh ra các thời điểm ngẫu nhiên trong khung giờ cho phép (loại trừ giờ ngủ).
/// 2) Chọn công việc ngẫu nhiên có trọng số, không lặp liên tiếp, phân bố đều.
/// 3) Đặt lịch thông báo cho toàn bộ chu kỳ (ngày/tuần/tháng).
class SchedulerService {
  static final Random _rng = Random();

  /// Sinh lịch thông báo cho "chu kỳ hiện tại" (hôm nay / tuần này / tháng này)
  /// và đặt lịch qua NotificationService. Gọi khi mở app hoặc từ WorkManager.
  static Future<int> generateAndSchedule() async {
    final settings = DatabaseService.getSettings();
    if (!settings.notificationsEnabled) {
      await NotificationService.cancelAll();
      return 0;
    }

    final tasks = DatabaseService.getAllTasks()
        .where((t) => t.notificationEnabled && !t.isDone)
        .toList();
    if (tasks.isEmpty) {
      await NotificationService.cancelAll();
      return 0;
    }

    await NotificationService.cancelAll();

    final periodDays = _periodLengthInDays(settings.randomMode);
    final now = DateTime.now();
    final times = _generateRandomTimes(
      from: now,
      days: periodDays,
      count: settings.notificationCount,
      activeStartHour: settings.activeStartHour,
      activeEndHour: settings.activeEndHour,
      sleepStartHour: settings.sleepStartHour,
      sleepEndHour: settings.sleepEndHour,
    );

    final chosenTasks = _pickTasksNoRepeat(tasks, times.length);

    for (var i = 0; i < times.length; i++) {
      final task = chosenTasks[i];
      final id = NotificationService.makeNotificationId(now, i);
      await NotificationService.scheduleTaskNotification(
        task: task,
        when: times[i],
        notificationId: id,
      );
      task.pickedCount += 1;
      task.lastPickedAt = times[i];
      await task.save();
    }

    return times.length;
  }

  static int _periodLengthInDays(RandomMode mode) {
    switch (mode) {
      case RandomMode.daily:
        return 1;
      case RandomMode.weekly:
        return 7;
      case RandomMode.monthly:
        return 30;
    }
  }

  /// Sinh [count] mốc thời gian ngẫu nhiên, rải trong [days] ngày kể từ [from],
  /// chỉ trong khung [activeStartHour, activeEndHour) và loại trừ khung giờ ngủ.
  static List<DateTime> _generateRandomTimes({
    required DateTime from,
    required int days,
    required int count,
    required int activeStartHour,
    required int activeEndHour,
    required int sleepStartHour,
    required int sleepEndHour,
  }) {
    final List<DateTime> result = [];
    var attempts = 0;
    final maxAttempts = count * 50;

    while (result.length < count && attempts < maxAttempts) {
      attempts++;
      final dayOffset = _rng.nextInt(days);
      final day = DateTime(from.year, from.month, from.day)
          .add(Duration(days: dayOffset));

      final hour = activeStartHour +
          _rng.nextInt(max(1, activeEndHour - activeStartHour));
      final minute = _rng.nextInt(60);
      var candidate = DateTime(day.year, day.month, day.day, hour, minute);

      if (candidate.isBefore(from.add(const Duration(minutes: 1)))) {
        continue; // không đặt lịch cho quá khứ
      }
      if (_isInSleepWindow(candidate, sleepStartHour, sleepEndHour)) {
        continue;
      }
      // tránh 2 thông báo quá gần nhau (< 20 phút) để không dồn dập
      final tooClose = result.any(
        (t) => (t.difference(candidate).inMinutes).abs() < 20,
      );
      if (tooClose) continue;

      result.add(candidate);
    }

    result.sort();
    return result;
  }

  static bool _isInSleepWindow(DateTime t, int sleepStart, int sleepEnd) {
    final hour = t.hour;
    if (sleepStart == sleepEnd) return false;
    if (sleepStart < sleepEnd) {
      return hour >= sleepStart && hour < sleepEnd;
    }
    // khung qua đêm, ví dụ 23h -> 7h
    return hour >= sleepStart || hour < sleepEnd;
  }

  /// Thuật toán chọn [count] công việc từ [tasks]:
  /// - Trọng số cao hơn cho công việc "Quan trọng".
  /// - Trọng số giảm dần theo số lần đã được chọn gần đây (để phân bố đều).
  /// - Không chọn cùng 1 công việc 2 lần liên tiếp (khi có từ 2 việc trở lên).
  static List<Task> _pickTasksNoRepeat(List<Task> tasks, int count) {
    final List<Task> chosen = [];
    if (tasks.isEmpty) return chosen;

    Task? previous;
    for (var i = 0; i < count; i++) {
      final pool = tasks.length > 1 && previous != null
          ? tasks.where((t) => t.id != previous!.id).toList()
          : tasks;

      final picked = _weightedPick(pool);
      chosen.add(picked);
      previous = picked;
    }
    return chosen;
  }

  static Task _weightedPick(List<Task> pool) {
    // Trọng số cơ bản theo độ ưu tiên + cộng thêm nếu "quan trọng".
    // Trừ điểm nếu đã được chọn nhiều lần để phân bố đều hơn.
    final maxPicked = pool.fold<int>(
        0, (m, t) => t.pickedCount > m ? t.pickedCount : m);

    final weights = pool.map((t) {
      double w = switch (t.priority) {
        TaskPriority.low => 1.0,
        TaskPriority.medium => 1.5,
        TaskPriority.high => 2.0,
      };
      if (t.isImportant) w *= 1.8;
      // Việc ít được chọn hơn sẽ có trọng số cao hơn (cân bằng phân bố)
      final balanceBoost = 1.0 + (maxPicked - t.pickedCount) * 0.15;
      w *= max(0.3, balanceBoost);
      return w;
    }).toList();

    final total = weights.fold<double>(0, (a, b) => a + b);
    var roll = _rng.nextDouble() * total;
    for (var i = 0; i < pool.length; i++) {
      roll -= weights[i];
      if (roll <= 0) return pool[i];
    }
    return pool.last;
  }
}
