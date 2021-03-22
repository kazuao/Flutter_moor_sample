import 'package:moor_flutter/moor_flutter.dart';

part 'moor_database.g.dart';

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  DateTimeColumn get dueDate => dateTime().nullable()();
  BoolColumn get completed => boolean().withDefault(Constant(false))();
}

// アノテーションが必要
@UseMoor(tables: [Tasks], daos: [TaskDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase()
      : super(
          FlutterQueryExecutor.inDatabaseFolder(
            path: 'db.sqlite',
            logStatements: true,
          ),
        );

  @override
  int get schemaVersion => 1;
}

@UseDao(
  tables: [Tasks],
  queries: {
    // 3: SQL queryを直接書く方法、non type safe
    'completedTasksGenerated':
        'SELECT * FROM tasks WHERE completed = 1 ORDER BY due_date = DESC, name;',
  },
)
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  final AppDatabase db;

  TaskDao(this.db) : super(db);

  Future<List<Task>> getAllTasks() => select(tasks).get();

  Stream<List<Task>> watchAllTasks() {
    // ()で囲むとカスケードに対し、.watch等の処理を記述できる
    return (select(tasks)
          ..orderBy([
            (t) => OrderingTerm(expression: t.dueDate, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.name),
          ]))
        .watch();
  }

  // 同じqueryを3種類の方法で書くことができる
  // 1: すべてdaoで各方法、type safe
  Stream<List<Task>> watchCompletedTasks() {
    return (select(tasks)
          ..orderBy([
            (t) => OrderingTerm(expression: t.dueDate, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.name),
          ])
          ..where((t) => t.completed.equals(true)))
        .watch();
  }

  // 2: streamの中でカスタムstreamとして各方法、type safe
  Stream<List<Task>> watchCompletedTasksCustom() {
    return customSelectStream(
        'SELECT * FROM tasks WHERE completed = 1 ORDER BY due_date = DESC, name;',
        readsFrom: {tasks}).map((rows) {
      return rows.map((row) => Task.fromData(row.data, db)).toList();
    });
  }

  Future insertTask(Insertable<Task> task) => into(tasks).insert(task);
  Future updateTask(Insertable<Task> task) => update(tasks).replace(task);
  Future deleteTask(Insertable<Task> task) => delete(tasks).delete(task);
}
// flutter packages pub run build_runner watch --delete-conflicting-outputs
