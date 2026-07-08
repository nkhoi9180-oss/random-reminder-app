import 'package:flutter/material.dart';

class StatsRow extends StatelessWidget {
  final int total;
  final int completed;
  final int notificationsToday;

  const StatsRow({
    super.key,
    required this.total,
    required this.completed,
    required this.notificationsToday,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(icon: Icons.checklist_rounded, label: 'Tổng số', value: '$total')),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(icon: Icons.task_alt_rounded, label: 'Hoàn thành', value: '$completed')),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(icon: Icons.notifications_active_rounded, label: 'Thông báo hôm nay', value: '$notificationsToday')),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: scheme.primary, size: 22),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
