import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../core/constants.dart';
import '../models/task_model.dart';
import '../services/local_db_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class TaskProvider extends ChangeNotifier {
  final LocalDbService _localDb;
  final FirestoreService _firestore;
  final NotificationService _notif;

  List<TaskModel> _tasks = [];
  bool _isLoading = false;
  String? _error;

  List<TaskModel> get tasks => List.unmodifiable(_tasks);
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<TaskModel> get pendingTasks =>
      _tasks.where((t) => !t.isCompleted).toList();
  List<TaskModel> get completedTasks =>
      _tasks.where((t) => t.isCompleted).toList();
  List<TaskModel> get overdueTasks => _tasks.where((t) => t.isOverdue).toList();
  List<TaskModel> get dueSoonTasks =>
      _tasks.where((t) => t.isDueSoon && !t.isOverdue).toList();

  TaskProvider(this._localDb, this._firestore, this._notif);

  // ── Load tasks ───────────────────────────────────────────────────────────────
  Future<void> loadTasks(String uid) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load from local DB first (offline-first)
      _tasks = await _localDb.getTasksForUser(uid);
      notifyListeners();

      // Then try to sync with Firestore if online
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.first != ConnectivityResult.none) {
        await _syncFromFirestore(uid);
      }
    } catch (e) {
      _error = 'Failed to load tasks';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _syncFromFirestore(String uid) async {
    try {
      // Push unsynced local tasks
      final unsyncedTasks = await _localDb.getUnsyncedTasks(uid);
      for (final task in unsyncedTasks) {
        await _firestore.syncTask(task);
        await _localDb.markSynced(task.id);
      }

      // Pull from Firestore
      final remoteTasks = await _firestore.fetchUserTasks(uid);
      await _localDb.bulkInsert(remoteTasks);

      // Reload from local (single source of truth)
      _tasks = await _localDb.getTasksForUser(uid);
      notifyListeners();
    } catch (_) {
      // Offline — keep local data
    }
  }

  // ── Add task ─────────────────────────────────────────────────────────────────
  Future<void> addTask({
    required String uid,
    required String title,
    String description = '',
    required DateTime deadline,
    TaskPriority priority = TaskPriority.medium,
    bool hasAlarm = true,
  }) async {
    const uuid = Uuid();
    final task = TaskModel(
      id: uuid.v4(),
      uid: uid,
      title: title,
      description: description,
      deadline: deadline,
      priority: priority,
      hasAlarm: hasAlarm,
      isSynced: false,
    );

    // Save locally
    await _localDb.insertTask(task);
    _tasks.add(task);
    _tasks.sort((a, b) => a.deadline.compareTo(b.deadline));
    notifyListeners();

    // Schedule notifications
    if (hasAlarm) {
      await _notif.scheduleTaskReminders(task);
    }

    // Sync to Firestore if online
    _trySyncTask(task);
  }

  // ── Update task ──────────────────────────────────────────────────────────────
  Future<void> updateTask(TaskModel updated) async {
    await _localDb.updateTask(updated);
    final index = _tasks.indexWhere((t) => t.id == updated.id);
    if (index != -1) _tasks[index] = updated;
    notifyListeners();

    // Re-schedule notifications
    await _notif.cancelTaskReminders(updated.id);
    if (updated.hasAlarm && !updated.isCompleted) {
      await _notif.scheduleTaskReminders(updated);
    }

    _trySyncTask(updated);
  }

  // ── Toggle complete ──────────────────────────────────────────────────────────
  Future<void> toggleComplete(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final task = _tasks[index];
    final updated = task.copyWith(
      isCompleted: !task.isCompleted,
      completedAt: !task.isCompleted ? DateTime.now() : null,
    );

    await updateTask(updated);

    // Cancel reminders if completed
    if (updated.isCompleted) {
      await _notif.cancelTaskReminders(taskId);
    }
  }

  // ── Delete task ──────────────────────────────────────────────────────────────
  Future<void> deleteTask(String taskId) async {
    await _localDb.deleteTask(taskId);
    await _notif.cancelTaskReminders(taskId);
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
  }

  Future<void> _trySyncTask(TaskModel task) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.first != ConnectivityResult.none) {
        await _firestore.syncTask(task.copyWith(isSynced: true));
        await _localDb.markSynced(task.id);
      }
    } catch (_) {
      // Will sync on next load
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
