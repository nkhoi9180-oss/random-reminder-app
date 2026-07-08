// GENERATED CODE - manually written to match hive_generator output.
// Nếu bạn sửa model AppSettings, hãy chạy:
//   flutter pub run build_runner build --delete-conflicting-outputs

part of 'app_settings.dart';

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 3;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      notificationsEnabled: fields[0] as bool,
      notificationCount: fields[1] as int,
      activeStartHour: fields[2] as int,
      activeEndHour: fields[3] as int,
      sleepStartHour: fields[4] as int,
      sleepEndHour: fields[5] as int,
      randomMode: fields[6] as RandomMode,
      respectDoNotDisturb: fields[7] as bool,
      isDarkMode: fields[8] as bool,
      themeModeIndex: fields[9] as int,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.notificationsEnabled)
      ..writeByte(1)
      ..write(obj.notificationCount)
      ..writeByte(2)
      ..write(obj.activeStartHour)
      ..writeByte(3)
      ..write(obj.activeEndHour)
      ..writeByte(4)
      ..write(obj.sleepStartHour)
      ..writeByte(5)
      ..write(obj.sleepEndHour)
      ..writeByte(6)
      ..write(obj.randomMode)
      ..writeByte(7)
      ..write(obj.respectDoNotDisturb)
      ..writeByte(8)
      ..write(obj.isDarkMode)
      ..writeByte(9)
      ..write(obj.themeModeIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RandomModeAdapter extends TypeAdapter<RandomMode> {
  @override
  final int typeId = 2;

  @override
  RandomMode read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RandomMode.daily;
      case 1:
        return RandomMode.weekly;
      case 2:
        return RandomMode.monthly;
      default:
        return RandomMode.daily;
    }
  }

  @override
  void write(BinaryWriter writer, RandomMode obj) {
    switch (obj) {
      case RandomMode.daily:
        writer.writeByte(0);
        break;
      case RandomMode.weekly:
        writer.writeByte(1);
        break;
      case RandomMode.monthly:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RandomModeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
