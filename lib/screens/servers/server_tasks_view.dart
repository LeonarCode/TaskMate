import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/task_model.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/task_card.dart';

class ServerTasksView extends StatelessWidget {
  final String serverId;
  const ServerTasksView({super.key, required this.serverId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firestoreSvc = FirestoreService();

    return StreamBuilder<List<TaskModel>>(
      stream: firestoreSvc.serverTasksStream(serverId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.purple600)));
        }
        final tasks = snapshot.data ?? [];
        if (tasks.isEmpty) {
          return Center(
            child: Text(
              'No tasks for this server yet!',
              style: TextStyle(color: isDark ? AppColors.gray400 : AppColors.gray500, fontSize: 16),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TaskCard(
                task: tasks[i],
                onToggle: () {
                  final updated = tasks[i].copyWith(isCompleted: !tasks[i].isCompleted);
                  firestoreSvc.syncTask(updated);
                  if (updated.isCompleted) {
                    NotificationService().cancelTaskReminders(updated.id);
                  } else if (updated.hasAlarm) {
                    NotificationService().scheduleTaskReminders(updated);
                  }
                },
                onDelete: () {
                  firestoreSvc.deleteTask(tasks[i].id);
                  NotificationService().cancelTaskReminders(tasks[i].id);
                },
              ),
            );
          },
        );
      },
    );
  }
}
