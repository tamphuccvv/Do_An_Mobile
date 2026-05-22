// lib/services/local_db_service.dart
// SQLite: cache bài báo đã đọc để xem offline

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/article_model.dart';

class LocalDbService {
  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'newsflow.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE articles (
            id          TEXT PRIMARY KEY,
            title       TEXT NOT NULL,
            content     TEXT,
            summary     TEXT,
            imageUrl    TEXT,
            category    TEXT,
            author      TEXT,
            sourceUrl   TEXT,
            publishedAt INTEGER
          )
        ''');
      },
    );
  }

  // ── Cache bài đã đọc ─────────────────────────────────────────
  Future<void> cacheArticle(ArticleModel article) async {
    final db = await database;
    await db.insert(
      'articles',
      article.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── Lấy tất cả bài đã cache ──────────────────────────────────
  Future<List<ArticleModel>> getCachedArticles() async {
    final db = await database;
    final rows = await db.query('articles',
        orderBy: 'publishedAt DESC', limit: 50);
    return rows.map(ArticleModel.fromSqlite).toList();
  }

  // ── Xoá cache cũ (giữ 50 bài mới nhất) ──────────────────────
  Future<void> trimCache() async {
    final db = await database;
    await db.rawDelete('''
      DELETE FROM articles WHERE id NOT IN (
        SELECT id FROM articles ORDER BY publishedAt DESC LIMIT 50
      )
    ''');
  }

  // ── Xoá toàn bộ cache ────────────────────────────────────────
  Future<void> clearCache() async {
    final db = await database;
    await db.delete('articles');
  }
}