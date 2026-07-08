import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/scheduler_service.dart';
import '../services/theme_notifier.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = DatabaseService.getSettings();
  }

  Future<void> _persist() async {
    await DatabaseService.saveSettings(_settings);
    await SchedulerService.generateAndSchedule();
    setState(() {});
  }

  Future<void> _pickHour({
    required int initial,
    required String title,
    required ValueChanged<int> onPicked,
  }) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial, minute: 0),
      helpText: title,
    );
    if (time != null) onPicked(time.hour);
  }

  Future<void> _exportBackup() async {
    final file = await DatabaseService.exportBackup();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã lưu file sao lưu tại:\n${file.path}')),
    );
  }

  Future<void> _importBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return;
    final file = File(result.files.single.path!);
    await DatabaseService.importBackup(file);
    _settings = DatabaseService.getSettings();
    await SchedulerService.generateAndSchedule();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Khôi phục dữ liệu thành công')),
    );
  }

  String _modeLabel(RandomMode m) => switch (m) {
        RandomMode.daily => 'Ngẫu nhiên trong ngày',
        RandomMode.weekly => 'Ngẫu nhiên trong tuần',
        RandomMode.monthly => 'Ngẫu nhiên trong tháng',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'Thông báo',
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Bật thông báo ngẫu nhiên'),
                value: _settings.notificationsEnabled,
                onChanged: (v) async {
                  _settings.notificationsEnabled = v;
                  if (v) await NotificationService.requestPermissions();
                  await _persist();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Số lượng thông báo mỗi chu kỳ'),
                subtitle: Text('${_settings.notificationCount} lần'),
                trailing: SizedBox(
                  width: 160,
                  child: Slider(
                    value: _settings.notificationCount.toDouble(),
                    min: 1,
                    max: 20,
                    divisions: 19,
                    label: '${_settings.notificationCount}',
                    onChanged: (v) => setState(() => _settings.notificationCount = v.round()),
                    onChangeEnd: (_) => _persist(),
                  ),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Chế độ random'),
                subtitle: Text(_modeLabel(_settings.randomMode)),
                trailing: DropdownButton<RandomMode>(
                  value: _settings.randomMode,
                  items: RandomMode.values
                      .map((m) => DropdownMenuItem(value: m, child: Text(_modeLabel(m))))
                      .toList(),
                  onChanged: (m) {
                    if (m == null) return;
                    _settings.randomMode = m;
                    _persist();
                  },
                ),
              ),
            ],
          ),
          _SectionCard(
            title: 'Khung giờ hoạt động',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Bắt đầu'),
                subtitle: Text('${_settings.activeStartHour}:00'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _pickHour(
                  initial: _settings.activeStartHour,
                  title: 'Giờ bắt đầu gửi thông báo',
                  onPicked: (h) {
                    _settings.activeStartHour = h;
                    _persist();
                  },
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Kết thúc'),
                subtitle: Text('${_settings.activeEndHour}:00'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _pickHour(
                  initial: _settings.activeEndHour,
                  title: 'Giờ kết thúc gửi thông báo',
                  onPicked: (h) {
                    _settings.activeEndHour = h;
                    _persist();
                  },
                ),
              ),
            ],
          ),
          _SectionCard(
            title: 'Giờ ngủ (không gửi thông báo)',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Bắt đầu ngủ'),
                subtitle: Text('${_settings.sleepStartHour}:00'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _pickHour(
                  initial: _settings.sleepStartHour,
                  title: 'Giờ bắt đầu ngủ',
                  onPicked: (h) {
                    _settings.sleepStartHour = h;
                    _persist();
                  },
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Thức dậy'),
                subtitle: Text('${_settings.sleepEndHour}:00'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _pickHour(
                  initial: _settings.sleepEndHour,
                  title: 'Giờ thức dậy',
                  onPicked: (h) {
                    _settings.sleepEndHour = h;
                    _persist();
                  },
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tôn trọng chế độ Không làm phiền'),
                subtitle: const Text('Cần cấp quyền "Notification policy access" trong Android'),
                value: _settings.respectDoNotDisturb,
                onChanged: (v) {
                  _settings.respectDoNotDisturb = v;
                  _persist();
                },
              ),
            ],
          ),
          _SectionCard(
            title: 'Giao diện',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Chủ đề'),
                trailing: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Hệ thống')),
                    ButtonSegment(value: 1, label: Text('Sáng')),
                    ButtonSegment(value: 2, label: Text('Tối')),
                  ],
                  selected: {_settings.themeModeIndex},
                  onSelectionChanged: (s) {
                    _settings.themeModeIndex = s.first;
                    _persist();
                    ThemeNotifier.refresh();
                  },
                ),
              ),
            ],
          ),
          _SectionCard(
            title: 'Dữ liệu',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.upload_file_outlined),
                title: const Text('Sao lưu dữ liệu'),
                subtitle: const Text('Xuất công việc + cài đặt ra file JSON'),
                onTap: _exportBackup,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.download_outlined),
                title: const Text('Khôi phục dữ liệu'),
                subtitle: const Text('Nhập lại từ file sao lưu JSON'),
                onTap: _importBackup,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                )),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}
