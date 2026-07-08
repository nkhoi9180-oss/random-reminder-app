import 'dart:convert';
import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../models/task.dart';
import '../models/app_settings.dart';

/// Lớp trung tâm truy cập dữ liệu offline (Hive).
/// Toàn bộ app hoạt động không cần mạng.
class DatabaseService {
  static const String taskBoxName = 'tasks_box';
  static const String settingsBoxName = 'settings_box';
  static const String settingsKey = 'app_settings';

  static Box<Task>? _taskBox;
  static Box<AppSettings>? _settingsBox;

  /// Gọi 1 lần ở main() trước runApp, và cũng được gọi lại
  /// trong isolate nền của WorkManager vì mỗi isolate cần init riêng.
  static Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TaskAdapter());
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TaskPriorityAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(RandomModeAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(AppSettingsAdapter());
    }

    _taskBox = await Hive.openBox<Task>(taskBoxName);
    _settingsBox = await Hive.openBox<AppSettings>(settingsBoxName);

    if (_settingsBox!.get(settingsKey) == null) {
      await _settingsBox!.put(settingsKey, AppSettings());
    }
  }

  static Box<Task> get taskBox => _taskBox!;
  static Box<AppSettings> get settingsBox => _settingsBox!;

  // ----------- TASK CRUD -----------
  static List<Task> getAllTasks() => taskBox.values.toList();

  static Future<void> addTask(Task task) async {
    await taskBox.put(task.id, task);
  }

  static Future<void> updateTask(Task task) async {
    await taskBox.put(task.id, task);
  }

  static Future<void> deleteTask(String id) async {
    await taskBox.delete(id);
  }

  // ----------- SETTINGS -----------
  static AppSettings getSettings() {
    return settingsBox.get(settingsKey) ?? AppSettings();
  }

  static Future<void> saveSettings(AppSettings settings) async {
    await settingsBox.put(settingsKey, settings);
  }

  // ----------- BACKUP / RESTORE -----------
  /// Xuất toàn bộ dữ liệu (công việc + cài đặt) ra file JSON để người dùng lưu/chia sẻ.
  static Future<File> exportBackup() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/random_reminder_backup.json');

    final settings = getSettings();
    final data = {
      'exportedAt': DateTime.now().toIso8601String(),
      'tasks': getAllTasks().map((t) => t.toJson()).toList(),
      'settings': {
        'notificationsEnabled': settings.notificationsEnabled,
        'notificationCount': settings.notificationCount,
        'activeStartHour': settings.activeStartHour,
        'activeEndHour': settings.activeEndHour,
        'sleepStartHour': settings.sleepStartHour,
        'sleepEndHour': settings.sleepEndHour,
        'randomMode': settings.randomMode.index,
        'respectDoNotDisturb': settings.respectDoNotDisturb,
        'themeModeIndex': settings.themeModeIndex,
      },
    };

    await file.writeAsString(jsonEncode(data));
    return file;
  }

  /// Khôi phục dữ liệu từ file JSON đã xuất trước đó.
  static Future<void> importBackup(File file) async {
    final content = await file.readAsString();
    final Map<String, dynamic> data = jsonDecode(content);

    await taskBox.clear();
    for (final t in (data['tasks'] as List)) {
      final task = Task.fromJson(t as Map<String, dynamic>);
      await taskBox.put(task.id, task);
    }

    final s = data['settings'] as Map<String, dynamic>;
    final settings = AppSettings(
      notificationsEnabled: s['notificationsEnabled'] ?? true,
      notificationCount: s['notificationCount'] ?? 5,
      activeStartHour: s['activeStartHour'] ?? 8,
      activeEndHour: s['activeEndHour'] ?? 22,
      sleepStartHour: s['sleepStartHour'] ?? 23,
      sleepEndHour: s['sleepEndHour'] ?? 7,
      randomMode: RandomMode.values[s['randomMode'] ?? 0],
      respectDoNotDisturb: s['respectDoNotDisturb'] ?? true,
      themeModeIndex: s['themeModeIndex'] ?? 0,
    );
    await saveSettings(settings);
  }
}
