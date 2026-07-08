import 'package:flutter/material.dart';

import 'database_service.dart';

/// ValueNotifier toàn cục giúp đổi Sáng/Tối/Hệ thống có hiệu lực ngay lập tức
/// mà không cần khởi động lại ứng dụng.
class ThemeNotifier {
  static final ValueNotifier<ThemeMode> mode = ValueNotifier(_fromSettings());

  static ThemeMode _fromSettings() {
    final index = DatabaseService.getSettings().themeModeIndex;
    return switch (index) {
      1 => ThemeMode.light,
      2 => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static void refresh() {
    mode.value = _fromSettings();
  }
}
