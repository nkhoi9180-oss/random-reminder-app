import 'package:hive/hive.dart';

part 'task.g.dart';

/// Mức độ ưu tiên của công việc
@HiveType(typeId: 1)
enum TaskPriority {
  @HiveField(0)
  low,
  @HiveField(1)
  medium,
  @HiveField(2)
  high,
}

/// Danh mục công việc mặc định (người dùng có thể thêm danh mục tuỳ chỉnh -> lưu dạng String)
class TaskCategories {
  static const List<String> defaults = [
    'Học tập',
    'Công việc',
    'Sức khỏe',
    'Thể dục',
    'Đọc sách',
    'Khác',
  ];
}

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String note;

  @HiveField(3)
  TaskPriority priority;

  @HiveField(4)
  String category;

  @HiveField(5)
  bool notificationEnabled;

  @HiveField(6)
  bool isDone;

  /// Mức độ hoàn thành 0 - 100 (thanh progress)
  @HiveField(7)
  int progress;

  /// Đánh dấu "Quan trọng" -> tăng trọng số random
  @HiveField(8)
  bool isImportant;

  @HiveField(9)
  DateTime createdAt;

  /// Lần cuối công việc này được chọn để nhắc (dùng cho thuật toán tránh lặp)
  @HiveField(10)
  DateTime? lastPickedAt;

  /// Số lần đã được chọn để nhắc (thống kê / cân bằng phân bố)
  @HiveField(11)
  int pickedCount;

  Task({
    required this.id,
    required this.title,
    this.note = '',
    this.priority = TaskPriority.medium,
    this.category = 'Khác',
    this.notificationEnabled = true,
    this.isDone = false,
    this.progress = 0,
    this.isImportant = false,
    DateTime? createdAt,
    this.lastPickedAt,
    this.pickedCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  Task copyWith({
    String? title,
    String? note,
    TaskPriority? priority,
    String? category,
    bool? notificationEnabled,
    bool? isDone,
    int? progress,
    bool? isImportant,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      note: note ?? this.note,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      isDone: isDone ?? this.isDone,
      progress: progress ?? this.progress,
      isImportant: isImportant ?? this.isImportant,
      createdAt: createdAt,
      lastPickedAt: lastPickedAt,
      pickedCount: pickedCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'priority': priority.index,
        'category': category,
        'notificationEnabled': notificationEnabled,
        'isDone': isDone,
        'progress': progress,
        'isImportant': isImportant,
        'createdAt': createdAt.toIso8601String(),
        'lastPickedAt': lastPickedAt?.toIso8601String(),
        'pickedCount': pickedCount,
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        title: json['title'],
        note: json['note'] ?? '',
        priority: TaskPriority.values[json['priority'] ?? 1],
        category: json['category'] ?? 'Khác',
        notificationEnabled: json['notificationEnabled'] ?? true,
        isDone: json['isDone'] ?? false,
        progress: json['progress'] ?? 0,
        isImportant: json['isImportant'] ?? false,
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        lastPickedAt: json['lastPickedAt'] != null
            ? DateTime.tryParse(json['lastPickedAt'])
            : null,
        pickedCount: json['pickedCount'] ?? 0,
      );
}
