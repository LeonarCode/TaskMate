import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../core/constants.dart';
import '../models/task_model.dart';

class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, AppStrings.dbName);

    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppStrings.tablePersonalTasks} (
        id TEXT PRIMARY KEY,
        uid TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT DEFAULT '',
        deadline INTEGER NOT NULL,
        isCompleted INTEGER DEFAULT 0,
        priority INTEGER DEFAULT 1,
        hasAlarm INTEGER DEFAULT 1,
        isSynced INTEGER DEFAULT 0,
        isDeleted INTEGER DEFAULT 0,
        completedAt INTEGER,
        serverId TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE ${AppStrings.tablePersonalTasks} ADD COLUMN isDeleted INTEGER DEFAULT 0',
      );
    }
  }

  // ── CRUD ────────────────────────────────────────────────────────────────────
  Future<void> insertTask(TaskModel task) async {
    final db = await database;
    await db.insert(
      AppStrings.tablePersonalTasks,
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTask(TaskModel task) async {
    final db = await database;
    await db.update(
      AppStrings.tablePersonalTasks,
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  /// Soft delete — marks task as deleted and unsynced so it can be
  /// pushed to Firestore for deletion on next sync.
  Future<void> softDeleteTask(String id) async {
    final db = await database;
    await db.update(
      AppStrings.tablePersonalTasks,
      {'isDeleted': 1, 'isSynced': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Hard delete — permanently removes from SQLite after Firestore confirms.
  Future<void> hardDeleteTask(String id) async {
    final db = await database;
    await db.delete(
      AppStrings.tablePersonalTasks,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Returns all non-deleted tasks for a user, sorted by deadline.
  Future<List<TaskModel>> getTasksForUser(String uid) async {
    final db = await database;
    final maps = await db.query(
      AppStrings.tablePersonalTasks,
      where: 'uid = ? AND isDeleted = 0',
      whereArgs: [uid],
      orderBy: 'deadline ASC',
    );
    return maps.map(TaskModel.fromMap).toList();
  }

  /// Returns tasks that have been soft-deleted but not yet synced to Firestore.
  Future<List<TaskModel>> getPendingDeletions(String uid) async {
    final db = await database;
    final maps = await db.query(
      AppStrings.tablePersonalTasks,
      where: 'uid = ? AND isDeleted = 1 AND isSynced = 0',
      whereArgs: [uid],
    );
    return maps.map(TaskModel.fromMap).toList();
  }

  Future<List<TaskModel>> getUnsyncedTasks(String uid) async {
    final db = await database;
    final maps = await db.query(
      AppStrings.tablePersonalTasks,
      where: 'uid = ? AND isSynced = 0 AND isDeleted = 0',
      whereArgs: [uid],
    );
    return maps.map(TaskModel.fromMap).toList();
  }

  Future<void> markSynced(String taskId) async {
    final db = await database;
    await db.update(
      AppStrings.tablePersonalTasks,
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  /// Bulk insert from Firestore — skips tasks that already exist locally
  /// (including soft-deleted ones) to avoid overwriting local state.
  Future<void> bulkInsert(List<TaskModel> tasks) async {
    final db = await database;
    final batch = db.batch();
    for (final task in tasks) {
      batch.insert(
        AppStrings.tablePersonalTasks,
        task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
