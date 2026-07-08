import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/task.dart';
import '../services/database_service.dart';

class AddEditTaskScreen extends StatefulWidget {
  final Task? task;
  const AddEditTaskScreen({super.key, this.task});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _noteCtrl;
  late TaskPriority _priority;
  late String _category;
  late bool _notificationEnabled;
  late bool _isImportant;

  bool get _editing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _noteCtrl = TextEditingController(text: t?.note ?? '');
    _priority = t?.priority ?? TaskPriority.medium;
    _category = t?.category ?? TaskCategories.defaults.first;
    _notificationEnabled = t?.notificationEnabled ?? true;
    _isImportant = t?.isImportant ?? false;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_editing) {
      final t = widget.task!;
      t.title = _titleCtrl.text.trim();
      t.note = _noteCtrl.text.trim();
      t.priority = _priority;
      t.category = _category;
      t.notificationEnabled = _notificationEnabled;
      t.isImportant = _isImportant;
      await t.save();
    } else {
      final task = Task(
        id: const Uuid().v4(),
        title: _titleCtrl.text.trim(),
        note: _noteCtrl.text.trim(),
        priority: _priority,
        category: _category,
        notificationEnabled: _notificationEnabled,
        isImportant: _isImportant,
      );
      await DatabaseService.addTask(task);
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    if (widget.task == null) return;
    await DatabaseService.deleteTask(widget.task!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Sửa công việc' : 'Thêm công việc'),
        actions: [
          if (_editing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Tiêu đề'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tiêu đề' : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'Ghi chú (tùy chọn)'),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            const _SectionLabel('Mức độ ưu tiên'),
            Wrap(
              spacing: 8,
              children: TaskPriority.values.map((p) {
                final label = switch (p) {
                  TaskPriority.low => 'Thấp',
                  TaskPriority.medium => 'Trung bình',
                  TaskPriority.high => 'Cao',
                };
                return ChoiceChip(
                  label: Text(label),
                  selected: _priority == p,
                  onSelected: (_) => setState(() => _priority = p),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const _SectionLabel('Danh mục'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TaskCategories.defaults.map((c) {
                return ChoiceChip(
                  label: Text(c),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _category = c),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Bật thông báo ngẫu nhiên'),
              subtitle: const Text('Công việc này có thể được chọn để nhắc'),
              value: _notificationEnabled,
              onChanged: (v) => setState(() => _notificationEnabled = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Đánh dấu Quan trọng'),
              subtitle: const Text('Xuất hiện thường xuyên hơn trong lời nhắc'),
              value: _isImportant,
              onChanged: (v) => setState(() => _isImportant = v),
              secondary: const Icon(Icons.star_rounded),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(_editing ? 'Lưu thay đổi' : 'Thêm công việc'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
