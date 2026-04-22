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
  final bool isSynced;
  final bool isDeleted; // ← NEW: soft delete flag
  final DateTime? completedAt;
  final String? serverId;

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
    this.isDeleted = false, // ← NEW
    this.completedAt,
    this.serverId,
  });

  // ── SQLite ──────────────────────────────────────────────────────────────────
  // Explicit casting on every field — prevents R8/ProGuard silent failures
  // in release builds where type inference can break
  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      uid: map['uid'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      deadline: DateTime.fromMillisecondsSinceEpoch(map['deadline'] as int),
      isCompleted: (map['isCompleted'] as int? ?? 0) == 1,
      priority: TaskPriority.values[map['priority'] as int? ?? 1],
      hasAlarm: (map['hasAlarm'] as int? ?? 1) == 1,
      isSynced: (map['isSynced'] as int? ?? 0) == 1,
      isDeleted: (map['isDeleted'] as int? ?? 0) == 1, // ← NEW
      completedAt:
          map['completedAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'] as int)
              : null,
      serverId: map['serverId'] as String?,
    );
  }

  // toMap() is used for SQLite — booleans stored as int (0/1)
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
    'isDeleted': isDeleted ? 1 : 0, // ← NEW
    'completedAt': completedAt?.millisecondsSinceEpoch,
    'serverId': serverId,
  };

  // ── Firestore ───────────────────────────────────────────────────────────────
  // Uses Timestamp (not millisecondsSinceEpoch) — consistent with toFirestore()
  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      uid: data['uid'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      deadline: (data['deadline'] as Timestamp).toDate(),
      isCompleted: data['isCompleted'] as bool? ?? false,
      priority: TaskPriority.values[data['priority'] as int? ?? 1],
      hasAlarm: data['hasAlarm'] as bool? ?? true,
      isSynced: true,
      isDeleted: false, // Firestore docs are never soft-deleted locally
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      serverId: data['serverId'] as String?,
    );
  }

  // toFirestore() — uses Timestamp, booleans stay as bool (not 0/1)
  Map<String, dynamic> toFirestore() => {
    'uid': uid,
    'title': title,
    'description': description,
    'deadline': Timestamp.fromDate(deadline),
    'isCompleted': isCompleted,
    'priority': priority.index,
    'hasAlarm': hasAlarm,
    'isSynced': true,
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
    bool? isDeleted, // ← NEW
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
      isDeleted: isDeleted ?? this.isDeleted, // ← NEW
      completedAt: completedAt ?? this.completedAt,
      serverId: serverId ?? this.serverId,
    );
  }

  int get daysUntilDeadline => deadline.difference(DateTime.now()).inDays;
  bool get isOverdue => !isCompleted && deadline.isBefore(DateTime.now());
  bool get isDueSoon =>
      !isCompleted && daysUntilDeadline <= 3 && daysUntilDeadline >= 0;
}
