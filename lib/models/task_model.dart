import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';

class TaskModel {
  final String id;
  final String uid;
  final String title;
  final String description;
  final DateTime deadline;
  final bool isCompleted;
  final TaskPriority priority;
  final bool hasAlarm;
  final bool isSynced; // false = local only
  final DateTime? completedAt;
  final String? serverId; // null = personal task

  const TaskModel({
    required this.id,
    required this.uid,
    required this.title,
    this.description = '',
    required this.deadline,
    this.isCompleted = false,
    this.priority = TaskPriority.medium,
    this.hasAlarm = true,
    this.isSynced = false,
    this.completedAt,
    this.serverId,
  });

  // ── SQLite ──────────────────────────────────────────────────────────────────
  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'],
      uid: map['uid'],
      title: map['title'],
      description: map['description'] ?? '',
      deadline: DateTime.fromMillisecondsSinceEpoch(map['deadline']),
      isCompleted: map['isCompleted'] == 1,
      priority: TaskPriority.values[map['priority'] ?? 1],
      hasAlarm: map['hasAlarm'] == 1,
      isSynced: map['isSynced'] == 1,
      completedAt:
          map['completedAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'])
              : null,
      serverId: map['serverId'],
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'uid': uid,
    'title': title,
    'description': description,
    'deadline': deadline.millisecondsSinceEpoch,
    'isCompleted': isCompleted ? 1 : 0,
    'priority': priority.index,
    'hasAlarm': hasAlarm ? 1 : 0,
    'isSynced': isSynced ? 1 : 0,
    'completedAt': completedAt?.millisecondsSinceEpoch,
    'serverId': serverId,
  };

  // ── Firestore ───────────────────────────────────────────────────────────────
  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      uid: data['uid'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      deadline: (data['deadline'] as Timestamp).toDate(),
      isCompleted: data['isCompleted'] ?? false,
      priority: TaskPriority.values[data['priority'] ?? 1],
      hasAlarm: data['hasAlarm'] ?? true,
      isSynced: true,
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      serverId: data['serverId'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'uid': uid,
    'title': title,
    'description': description,
    'deadline': Timestamp.fromDate(deadline),
    'isCompleted': isCompleted,
    'priority': priority.index,
    'hasAlarm': hasAlarm,
    'completedAt':
        completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    'serverId': serverId,
  };

  TaskModel copyWith({
    String? title,
    String? description,
    DateTime? deadline,
    bool? isCompleted,
    TaskPriority? priority,
    bool? hasAlarm,
    bool? isSynced,
    DateTime? completedAt,
    String? serverId,
  }) {
    return TaskModel(
      id: id,
      uid: uid,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      hasAlarm: hasAlarm ?? this.hasAlarm,
      isSynced: isSynced ?? this.isSynced,
      completedAt: completedAt ?? this.completedAt,
      serverId: serverId ?? this.serverId,
    );
  }

  /// Days until deadline
  int get daysUntilDeadline => deadline.difference(DateTime.now()).inDays;

  bool get isOverdue => !isCompleted && deadline.isBefore(DateTime.now());

  bool get isDueSoon =>
      !isCompleted && daysUntilDeadline <= 3 && daysUntilDeadline >= 0;
}
