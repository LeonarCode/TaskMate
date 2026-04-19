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
    // Use FFI for desktop platforms
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, AppStrings.dbName);

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
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
        completedAt INTEGER,
        serverId TEXT
      )
    ''');
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

  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.delete(
      AppStrings.tablePersonalTasks,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<TaskModel>> getTasksForUser(String uid) async {
    final db = await database;
    final maps = await db.query(
      AppStrings.tablePersonalTasks,
      where: 'uid = ?',
      whereArgs: [uid],
      orderBy: 'deadline ASC',
    );
    return maps.map(TaskModel.fromMap).toList();
  }

  Future<List<TaskModel>> getUnsyncedTasks(String uid) async {
    final db = await database;
    final maps = await db.query(
      AppStrings.tablePersonalTasks,
      where: 'uid = ? AND isSynced = 0',
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

  Future<void> bulkInsert(List<TaskModel> tasks) async {
    final db = await database;
    final batch = db.batch();
    for (final task in tasks) {
      batch.insert(
        AppStrings.tablePersonalTasks,
        task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore, // don't overwrite local
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
