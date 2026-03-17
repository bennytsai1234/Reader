import 'package:drift/drift.dart';
import '../app_database.dart';

/// sqflite ConflictAlgorithm 相容 enum
enum ConflictAlgorithm { rollback, abort, fail, ignore, replace }

/// DriftCompatDao - 取代舊版 BaseDao<T>
/// 繼承 Drift DatabaseAccessor，同時提供 sqflite 相容介面
/// 讓現有 DAO 代碼可以最小化改動
abstract class DriftCompatDao<T> extends DatabaseAccessor<AppDatabase> {
  final String tableName;

  DriftCompatDao(AppDatabase db, this.tableName) : super(db);

  /// sqflite 相容的非同步 db 存取器
  Future<DriftSqfliteCompat> get db async => DriftSqfliteCompat(this);

  // ── BaseDao 相容方法 ──

  Future<int> insertOrUpdate(Map<String, dynamic> row) async {
    return (await db).insert(tableName, row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// 重命名為 deleteRows 避免與 DatabaseConnectionUser.delete 衝突
  Future<int> deleteRows(String where, [List<dynamic>? whereArgs]) async {
    return (await db).delete(tableName, where: where, whereArgs: whereArgs);
  }

  Future<List<Map<String, dynamic>>> queryAll({String? orderBy}) async {
    return (await db).query(tableName, orderBy: orderBy);
  }

  Future<int> clearAll() async {
    return (await db).delete(tableName);
  }
}

/// sqflite Database 介面的 Drift 實作，讓 DAO 代碼幾乎無需修改
class DriftSqfliteCompat {
  final DatabaseConnectionUser _conn;

  DriftSqfliteCompat(this._conn);

  Future<List<Map<String, dynamic>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    String? groupBy,
    String? having,
  }) async {
    final cols = columns?.map((c) => '"$c"').join(', ') ?? '*';
    final sb = StringBuffer('SELECT $cols FROM "$table"');
    if (where != null) sb.write(' WHERE $where');
    if (groupBy != null) sb.write(' GROUP BY $groupBy');
    if (having != null) sb.write(' HAVING $having');
    if (orderBy != null) sb.write(' ORDER BY $orderBy');
    if (limit != null) sb.write(' LIMIT $limit');
    return _rawQuery(sb.toString(), whereArgs);
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? args]) {
    return _rawQuery(sql, args);
  }

  Future<List<Map<String, dynamic>>> _rawQuery(String sql, List<dynamic>? args) async {
    final rows = await _conn.customSelect(
      sql,
      variables: (args ?? []).map(_toVar).toList(),
    ).get();
    return rows.map((r) => Map<String, dynamic>.from(r.data)).toList();
  }

  Future<int> insert(
    String table,
    Map<String, dynamic> values, {
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final orClause = _conflictClause(conflictAlgorithm);
    final cols = values.keys.map((k) => '"$k"').join(', ');
    final placeholders = values.keys.map((_) => '?').join(', ');
    final sql = 'INSERT $orClause INTO "$table" ($cols) VALUES ($placeholders)';
    return await _conn.customInsert(
      sql,
      variables: values.values.map(_toVar).toList(),
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final orClause = _conflictClause(conflictAlgorithm);
    final sets = values.keys.map((k) => '"$k" = ?').join(', ');
    final sb = StringBuffer('UPDATE $orClause "$table" SET $sets');
    if (where != null) sb.write(' WHERE $where');
    final allVars = [...values.values.map(_toVar), ...(whereArgs ?? []).map(_toVar)];
    return await _conn.customUpdate(
      sb.toString(),
      variables: allVars,
      updateKind: UpdateKind.update,
    );
  }

  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final sb = StringBuffer('DELETE FROM "$table"');
    if (where != null) sb.write(' WHERE $where');
    return await _conn.customUpdate(
      sb.toString(),
      variables: (whereArgs ?? []).map(_toVar).toList(),
      updateKind: UpdateKind.delete,
    );
  }

  Future<T> transaction<T>(Future<T> Function(DriftSqfliteCompat txn) action) {
    return _conn.transaction(() => action(this));
  }

  DriftBatchCompat batch() => DriftBatchCompat(_conn);

  static String _conflictClause(ConflictAlgorithm? algo) {
    switch (algo) {
      case ConflictAlgorithm.replace:
        return 'OR REPLACE';
      case ConflictAlgorithm.ignore:
        return 'OR IGNORE';
      case ConflictAlgorithm.rollback:
        return 'OR ROLLBACK';
      case ConflictAlgorithm.abort:
        return 'OR ABORT';
      case ConflictAlgorithm.fail:
        return 'OR FAIL';
      default:
        return '';
    }
  }

  static Variable _toVar(dynamic v) {
    if (v == null) return Variable(null);
    if (v is String) return Variable.withString(v);
    if (v is int) return Variable.withInt(v);
    if (v is double) return Variable.withReal(v);
    if (v is bool) return Variable.withBool(v);
    return Variable.withString(v.toString());
  }
}

/// sqflite Batch 的 Drift 相容實作
class DriftBatchCompat {
  final DatabaseConnectionUser _conn;
  final List<(String, List<Variable>)> _ops = [];

  DriftBatchCompat(this._conn);

  void execute(String sql, [List<dynamic>? args]) {
    _ops.add((sql, (args ?? []).map(DriftSqfliteCompat._toVar).toList()));
  }

  void insert(
    String table,
    Map<String, dynamic> values, {
    ConflictAlgorithm? conflictAlgorithm,
  }) {
    final orClause = DriftSqfliteCompat._conflictClause(conflictAlgorithm);
    final cols = values.keys.map((k) => '"$k"').join(', ');
    final placeholders = values.keys.map((_) => '?').join(', ');
    execute(
      'INSERT $orClause INTO "$table" ($cols) VALUES ($placeholders)',
      values.values.toList(),
    );
  }

  void update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) {
    final orClause = DriftSqfliteCompat._conflictClause(conflictAlgorithm);
    final sets = values.keys.map((k) => '"$k" = ?').join(', ');
    var sql = 'UPDATE $orClause "$table" SET $sets';
    if (where != null) sql += ' WHERE $where';
    execute(sql, [...values.values, ...(whereArgs ?? [])]);
  }

  void delete(String table, {String? where, List<dynamic>? whereArgs}) {
    var sql = 'DELETE FROM "$table"';
    if (where != null) sql += ' WHERE $where';
    execute(sql, whereArgs);
  }

  Future<List<Object?>> commit({bool noResult = false}) async {
    for (final (sql, vars) in _ops) {
      await _conn.customStatement(sql, vars);
    }
    return [];
  }
}

/// firstIntValue 相容函數，取代 Sqflite.firstIntValue
int? driftFirstIntValue(List<Map<String, dynamic>> maps) {
  if (maps.isEmpty) return null;
  final first = maps.first;
  if (first.isEmpty) return null;
  final val = first.values.first;
  if (val == null) return null;
  if (val is int) return val;
  return int.tryParse(val.toString());
}
