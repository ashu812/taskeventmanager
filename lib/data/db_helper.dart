import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/task.dart';
import '../models/event.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _db;
  static const _dbName = 'task_event_manager.db';
  static const _dbVersion = 1;

  // Table names
  static const taskTable = 'tasks';
  static const eventTable = 'events';

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final docs = await getApplicationDocumentsDirectory();
    final path = join(docs.path, _dbName);
    return await openDatabase(path, version: _dbVersion, onCreate: _onCreate);
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    // Tasks table
    await db.execute('''
      CREATE TABLE $taskTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        isDone INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Events table
    await db.execute('''
      CREATE TABLE $eventTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL
      )
    ''');
  }

  // ------------------ TASK CRUD ------------------
  Future<int> insertTask(Task task) async {
    final db = await database;
    return await db.insert(taskTable, task.toMap());
  }

  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final rows = await db.query(taskTable, orderBy: 'id DESC');
    return rows.map((r) => Task.fromMap(r)).toList();
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    return await db.update(
      taskTable,
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete(taskTable, where: 'id = ?', whereArgs: [id]);
  }

  // ------------------ EVENT CRUD ------------------
  Future<int> insertEvent(EventItem event) async {
    final db = await database;
    return await db.insert(eventTable, event.toMap());
  }

  Future<List<EventItem>> getAllEvents() async {
    final db = await database;
    final rows = await db.query(eventTable, orderBy: 'id DESC');
    return rows.map((r) => EventItem.fromMap(r)).toList();
  }

  Future<int> updateEvent(EventItem event) async {
    final db = await database;
    return await db.update(
      eventTable,
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<int> deleteEvent(int id) async {
    final db = await database;
    return await db.delete(eventTable, where: 'id = ?', whereArgs: [id]);
  }

  // optional: close DB
  Future<void> close() async {
    final db = await database;
    await db.close();
    _db = null;
  }
}
