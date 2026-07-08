import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 2)
enum RandomMode {
  @HiveField(0)
  daily,
  @HiveField(1)
  weekly,
  @HiveField(2)
  monthly,
}

@HiveType(typeId: 3)
class AppSettings extends HiveObject {
  @HiveField(0)
  bool notificationsEnabled;

  /// Số lượng thông báo mỗi ngày (khi randomMode = daily),
  /// mỗi tuần (weekly) hoặc mỗi tháng (monthly)
  @HiveField(1)
  int notificationCount;

  /// Giờ bắt đầu được phép gửi (0-23)
  @HiveField(2)
  int activeStartHour;

  /// Giờ kết thúc được phép gửi (0-23)
  @HiveField(3)
  int activeEndHour;

  /// Không gửi trong khung giờ ngủ
  @HiveField(4)
  int sleepStartHour;

  @HiveField(5)
  int sleepEndHour;

  @HiveField(6)
  RandomMode randomMode;

  @HiveField(7)
  bool respectDoNotDisturb;

  @HiveField(8)
  bool isDarkMode; // null = theo hệ thống, dùng cờ riêng themeModeIndex bên dưới

  @HiveField(9)
  int themeModeIndex; // 0=system, 1=light, 2=dark

  AppSettings({
    this.notificationsEnabled = true,
    this.notificationCount = 5,
    this.activeStartHour = 8,
    this.activeEndHour = 22,
    this.sleepStartHour = 23,
    this.sleepEndHour = 7,
    this.randomMode = RandomMode.daily,
    this.respectDoNotDisturb = true,
    this.isDarkMode = false,
    this.themeModeIndex = 0,
  });
}
