import 'package:moor_flutter/moor_flutter.dart';

part 'moor_database.g.dart';

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  // 外部キーを設定するためには、customCustomConstraintを設定する必要がある
  // nullableが設定されている場合は、NULLを別途設定する必要がある
  TextColumn get tagName =>
      text().nullable().customConstraint('NULL REFERENCES tags(name)')();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  DateTimeColumn get dueDate => dateTime().nullable()();
  BoolColumn get completed => boolean().withDefault(Constant(false))();
}

class Tags extends Table {
  TextColumn get name => text().withLength(min: 1, max: 10)();
  IntColumn get color => integer()();

  @override
  Set<Column> get primaryKey => {name};
}

class TaskWithTag {
  final Task task;
  final Tag tag;

  TaskWithTag({
    @required this.task,
    @required this.tag,
  });
}

// アノテーションが必要
@UseMoor(tables: [Tasks, Tags], daos: [TaskDao, TagDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase()
      : super(
          FlutterQueryExecutor.inDatabaseFolder(
            path: 'db.sqlite',
            logStatements: true,
          ),
        );

  @override
  int get schemaVersion => 2;

  // migration処理 scemaVersionをあげた際に必要になる
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          if (from == 1) {
            await migrator.addColumn(tasks, tasks.tagName);
            await migrator.createTable(tags);
          }
        },
        // 外部キー設定を行った場合に必要になる
        beforeOpen: (db, details) async {
          await db.customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

@UseDao(
  tables: [Tasks, Tags],
  // queries: {
  //   // 3: SQL queryを直接書く方法、non type safe
  //   'completedTasksGenerated':
  //       'SELECT * FROM tasks WHERE completed = 1 ORDER BY due_date = DESC, name;',
  // },
)
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  final AppDatabase db;

  TaskDao(this.db) : super(db);

  Future<List<Task>> getAllTasks() => select(tasks).get();

  Stream<List<TaskWithTag>> watchAllTasks() {
    // ()で囲むとカスケードに対し、.watch等の処理を記述できる
    return (select(tasks)
          ..orderBy([
            (t) => OrderingTerm(expression: t.dueDate, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.name),
          ]))
        .join(
          [
            leftOuterJoin(tags, tags.name.equalsExp(tasks.tagName)),
          ],
        )
        .watch()
        // joinを行った場合に明示的に処理を追加する必要がある
        .map((rows) => rows.map(
              (rows) {
                return TaskWithTag(
                  task: rows.readTable(tasks),
                  tag: rows.readTable(tags),
                );
              },
            ).toList());
  }

  // 同じqueryを3種類の方法で書くことができる
  // 1: すべてdaoで各方法、type safe
  // Stream<List<Task>> watchCompletedTasks() {
  //   return (select(tasks)
  //         ..orderBy([
  //           (t) => OrderingTerm(expression: t.dueDate, mode: OrderingMode.desc),
  //           (t) => OrderingTerm(expression: t.name),
  //         ])
  //         ..where((t) => t.completed.equals(true)))
  //       .watch();
  // }

  // 2: streamの中でカスタムstreamとして各方法、type safe
  // Stream<List<Task>> watchCompletedTasksCustom() {
  //   return customSelectStream(
  //       'SELECT * FROM tasks WHERE completed = 1 ORDER BY due_date = DESC, name;',
  //       readsFrom: {tasks}).map((rows) {
  //     return rows.map((row) => Task.fromData(row.data, db)).toList();
  //   });
  // }

  Future insertTask(Insertable<Task> task) => into(tasks).insert(task);
  Future updateTask(Insertable<Task> task) => update(tasks).replace(task);
  Future deleteTask(Insertable<Task> task) => delete(tasks).delete(task);
}

@UseDao(tables: [Tags])
class TagDao extends DatabaseAccessor<AppDatabase> with _$TagDaoMixin {
  final AppDatabase db;

  TagDao(this.db) : super(db);

  Stream<List<Tag>> watchTags() => select(tags).watch();
  Future insertTag(Insertable<Tag> tag) => into(tags).insert(tag);
}
// flutter packages pub run build_runner watch --delete-conflicting-outputs
