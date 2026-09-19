import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/models.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  static Database? _database;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'lingoflow.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE translations (
            id TEXT PRIMARY KEY,
            sender_name TEXT NOT NULL,
            original_text TEXT NOT NULL,
            detected_language TEXT NOT NULL,
            translated_sinhala TEXT NOT NULL,
            translated_english TEXT NOT NULL,
            timestamp INTEGER NOT NULL,
            source_app TEXT NOT NULL,
            is_favorite INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE contact_preferences (
            contact_name TEXT PRIMARY KEY,
            translation_enabled INTEGER NOT NULL DEFAULT 1,
            preferred_mode TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE INDEX idx_timestamp ON translations (timestamp DESC);
        ''');
      },
    );
  }

  // --- Translation Messages ---

  Future<void> insertTranslation(TranslationMessage message) async {
    final db = await database;
    await db.insert(
      'translations',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TranslationMessage>> getAllTranslations({int limit = 100}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'translations',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return maps.map((m) => TranslationMessage.fromMap(m)).toList();
  }

  Future<List<TranslationMessage>> getRecentTranslations({int limit = 5}) async {
    return getAllTranslations(limit: limit);
  }

  Future<List<TranslationMessage>> searchTranslations(String query, {String? languageFilter}) async {
    final db = await database;
    String whereClause = '(sender_name LIKE ? OR original_text LIKE ? OR translated_sinhala LIKE ? OR translated_english LIKE ?)';
    List<dynamic> whereArgs = ['%$query%', '%$query%', '%$query%', '%$query%'];

    if (languageFilter != null && languageFilter.isNotEmpty && languageFilter != 'all') {
      whereClause += ' AND detected_language = ?';
      whereArgs.add(languageFilter);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'translations',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
    );
    return maps.map((m) => TranslationMessage.fromMap(m)).toList();
  }

  Future<void> toggleFavorite(String id, bool isFavorite) async {
    final db = await database;
    await db.update(
      'translations',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteTranslation(String id) async {
    final db = await database;
    await db.delete(
      'translations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAllTranslations() async {
    final db = await database;
    await db.delete('translations');
  }

  Future<void> autoPurgeOldTranslations(String period) async {
    if (period == 'never') return;
    final db = await database;
    final now = DateTime.now();
    DateTime threshold;

    if (period == '24h') {
      threshold = now.subtract(const Duration(hours: 24));
    } else if (period == '7d') {
      threshold = now.subtract(const Duration(days: 7));
    } else if (period == '30d') {
      threshold = now.subtract(const Duration(days: 30));
    } else {
      return;
    }

    await db.delete(
      'translations',
      where: 'timestamp < ? AND is_favorite = 0',
      whereArgs: [threshold.millisecondsSinceEpoch],
    );
  }

  // --- Contact Preferences ---

  Future<void> setContactPreference(ContactPreference preference) async {
    final db = await database;
    await db.insert(
      'contact_preferences',
      preference.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ContactPreference?> getContactPreference(String contactName) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'contact_preferences',
      where: 'contact_name = ?',
      whereArgs: [contactName],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ContactPreference.fromMap(maps.first);
  }

  Future<List<ContactPreference>> getAllContactPreferences() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'contact_preferences',
      orderBy: 'contact_name ASC',
    );
    return maps.map((m) => ContactPreference.fromMap(m)).toList();
  }

  Future<void> deleteContactPreference(String contactName) async {
    final db = await database;
    await db.delete(
      'contact_preferences',
      where: 'contact_name = ?',
      whereArgs: [contactName],
    );
  }

  // Statistics
  Future<Map<String, int>> getStats() async {
    final db = await database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;

    final totalTodayRes = await db.rawQuery(
      'SELECT COUNT(*) as count FROM translations WHERE timestamp >= ?',
      [startOfDay],
    );
    final totalToday = Sqflite.firstIntValue(totalTodayRes) ?? 0;

    final totalSinhalaRes = await db.rawQuery(
      'SELECT COUNT(*) as count FROM translations WHERE translated_sinhala != ""',
    );
    final totalSinhala = Sqflite.firstIntValue(totalSinhalaRes) ?? 0;

    final totalEnglishRes = await db.rawQuery(
      'SELECT COUNT(*) as count FROM translations WHERE translated_english != ""',
    );
    final totalEnglish = Sqflite.firstIntValue(totalEnglishRes) ?? 0;

    return {
      'today': totalToday,
      'sinhala': totalSinhala,
      'english': totalEnglish,
    };
  }
}
