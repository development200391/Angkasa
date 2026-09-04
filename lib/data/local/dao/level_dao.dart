import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../domain/engine/difficulty_config.dart';
import '../../../domain/models/chapter.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/grade.dart';
import '../../../domain/models/level.dart';

/// Baca konten: planet, zona, dan pos. Tabel-tabel ini hanya ditulis
/// sekali oleh `SeedRunner`, jadi di sini tidak ada satu pun `insert`.
class LevelDao {
  LevelDao(this._db);

  final Database _db;

  Future<List<Grade>> semuaGrade() async {
    final rows = await _db.query('grades', orderBy: 'order_index');
    return rows.map(_grade).toList();
  }

  Future<Grade?> grade(String id) async {
    final rows = await _db.query(
      'grades',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : _grade(rows.first);
  }

  Future<List<Chapter>> chapters(String gradeId) async {
    final rows = await _db.query(
      'chapters',
      where: 'grade_id = ?',
      whereArgs: [gradeId],
      orderBy: 'order_index',
    );
    return rows.map(_chapter).toList();
  }

  Future<Chapter?> chapter(String id) async {
    final rows = await _db.query(
      'chapters',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : _chapter(rows.first);
  }

  Future<List<Level>> levels(String chapterId) async {
    final rows = await _db.query(
      'levels',
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
      orderBy: 'order_index',
    );
    return rows.map(_level).toList();
  }

  Future<Level?> level(String id) async {
    final rows = await _db.query(
      'levels',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : _level(rows.first);
  }

  /// Semua pos di satu planet, dipakai layar hasil dan aturan unlock.
  Future<List<Level>> levelsGrade(String gradeId) async {
    final rows = await _db.rawQuery(
      '''
      SELECT l.* FROM levels l
      JOIN chapters c ON c.id = l.chapter_id
      WHERE c.grade_id = ?
      ORDER BY c.order_index, l.order_index
      ''',
      [gradeId],
    );
    return rows.map(_level).toList();
  }

  Future<int> jumlahPos(String gradeId) async {
    final r = await _db.rawQuery(
      '''
      SELECT COUNT(*) AS n FROM levels l
      JOIN chapters c ON c.id = l.chapter_id
      WHERE c.grade_id = ?
      ''',
      [gradeId],
    );
    return Sqflite.firstIntValue(r) ?? 0;
  }

  /// Semua id pos yang ada di pemasangan ini.
  ///
  /// Dipakai memulihkan cadangan: cadangan bisa saja dibuat oleh versi
  /// aplikasi yang punya pos lebih banyak, dan menulis progres untuk pos
  /// yang belum ada di sini melanggar kunci asingnya.
  Future<Set<String>> semuaIdPos() async {
    final rows = await _db.query('levels', columns: ['id']);
    return {for (final r in rows) r['id']! as String};
  }

  Future<void> bukaGrade(String gradeId) => _db.update(
    'grades',
    {'is_unlocked': 1},
    where: 'id = ?',
    whereArgs: [gradeId],
  );

  static Grade _grade(Map<String, Object?> r) => Grade(
    id: r['id']! as String,
    name: r['name']! as String,
    orderIndex: r['order_index']! as int,
    icon: r['icon']! as String,
    isUnlocked: (r['is_unlocked'] as int? ?? 0) == 1,
  );

  static Chapter _chapter(Map<String, Object?> r) => Chapter(
    id: r['id']! as String,
    gradeId: r['grade_id']! as String,
    title: r['title']! as String,
    icon: r['icon']! as String,
    color: r['color']! as String,
    orderIndex: r['order_index']! as int,
  );

  static Level _level(Map<String, Object?> r) => Level(
    id: r['id']! as String,
    chapterId: r['chapter_id']! as String,
    orderIndex: r['order_index']! as int,
    title: r['title']! as String,
    type: r['type'] == 'boss' ? LevelType.boss : LevelType.practice,
    difficultyConfig: DifficultyConfig.fromJson(
      jsonDecode(r['difficulty_config']! as String) as Map<String, dynamic>,
    ),
    xpReward: r['xp_reward'] as int? ?? 10,
  );
}
