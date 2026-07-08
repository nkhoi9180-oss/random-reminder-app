import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/scheduler_service.dart';
import '../widgets/stats_row.dart';
import '../widgets/task_card.dart';
import 'add_edit_task_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Task> _tasks = [];
  int _pendingNotificationsToday = 0;
  String _filterCategory = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final tasks = DatabaseService.getAllTasks()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final pending = await NotificationService.pending();
    final today = DateTime.now();
    final todayCount = pending.where((_) => true).length; // ước lượng tổng lịch đang chờ
    setState(() {
      _tasks = tasks;
      _pendingNotificationsToday = todayCount;
    });
    // ignore: unnecessary_statements
    today;
  }

  List<Task> get _visibleTasks => _filterCategory == 'Tất cả'
      ? _tasks
      : _tasks.where((t) => t.category == _filterCategory).toList();

  Future<void> _openAddEdit({Task? task}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditTaskScreen(task: task)),
    );
    await SchedulerService.generateAndSchedule();
    _refresh();
  }

  Future<void> _toggleDone(Task task) async {
    task.isDone = !task.isDone;
    if (task.isDone) task.progress = 100;
    await task.save();
    _refresh();
  }

  Future<void> _delete(Task task) async {
    await DatabaseService.deleteTask(task.id);
    await SchedulerService.generateAndSchedule();
    _refresh();
  }

  Future<void> _updateProgress(Task task, double value) async {
    task.progress = value.round();
    if (task.progress == 100) task.isDone = true;
    await task.save();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final total = _tasks.length;
    final done = _tasks.where((t) => t.isDone).length;
    final categories = ['Tất cả', ...TaskCategories.defaults];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhắc việc ngẫu nhiên'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              _refresh();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              sliver: SliverToBoxAdapter(
                child: StatsRow(
                  total: total,
                  completed: done,
                  notificationsToday: _pendingNotificationsToday,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final cat = categories[i];
                      final selected = cat == _filterCategory;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: selected,
                        onSelected: (_) => setState(() => _filterCategory = cat),
                      );
                    },
                  ),
                ),
              ),
            ),
            if (_visibleTasks.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(onAdd: () => _openAddEdit()),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                sliver: SliverList.builder(
                  itemCount: _visibleTasks.length,
                  itemBuilder: (context, index) {
                    final task = _visibleTasks[index];
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: TaskCard(
                        key: ValueKey(task.id),
                        task: task,
                        onTap: () => _openAddEdit(task: task),
                        onToggleDone: () => _toggleDone(task),
                        onDelete: () => _delete(task),
                        onProgressChanged: (v) => _updateProgress(task, v),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEdit(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm việc'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.checklist_rtl_rounded, size: 72, color: scheme.outline),
            const SizedBox(height: 16),
            Text('Chưa có công việc nào',
                style: TextStyle(fontSize: 16, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text('Nhấn "Thêm việc" để bắt đầu tạo lời nhắc ngẫu nhiên cho bản thân.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Thêm việc đầu tiên'),
            ),
          ],
        ),
      ),
    );
  }
}
