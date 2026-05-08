import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/bible_verse.dart';

class DatabaseService {
  static Database? _database;
  static const String tableVerses = 'verses';
  static const String tableFavorites = 'favorites';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'bible.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
    );

    await _importBibleData();
    return _database!;
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableVerses (
        id INTEGER PRIMARY KEY,
        book TEXT,
        chapter INTEGER,
        verse INTEGER,
        text TEXT,
        language TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableFavorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        verseId INTEGER,
        book TEXT,
        chapter INTEGER,
        verse INTEGER,
        text TEXT,
        language TEXT,
        FOREIGN KEY (verseId) REFERENCES $tableVerses (id)
      )
    ''');
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 1) {
      await _createTables(db, 1);
    }
  }

 Future<void> _importBibleData() async {
    final db = await database;

    // Check existing data by language
    final List<Map<String, dynamic>> countResult = await db.rawQuery(
      'SELECT language, COUNT(*) as count FROM $tableVerses GROUP BY language'
    );
    
    Map<String, int> languageCounts = {};
    for (var row in countResult) {
      languageCounts[row['language']] = row['count'];
    }

    debugPrint('Current data: ${languageCounts.toString()}');

    // Import only missing languages
    if (languageCounts['english'] == null || languageCounts['english'] == 0) {
      debugPrint('Importing English Bible...');
      await _importJsonData('assets/bible/english_bible.json', 'english');
    }

    if (languageCounts['kiswahili'] == null || languageCounts['kiswahili'] == 0) {
      debugPrint('Importing Kiswahili Bible...');
      await _importJsonData('assets/bible/kiswahili_bible.json', 'kiswahili');
    }

    debugPrint('Bible import completed');
  }

Future<void> _importJsonData(String assetPath, String language) async {
  try {
    final db = await database;
    String jsonString = await rootBundle.loadString(assetPath);
    debugPrint('JSON raw for $language: ${jsonString.substring(0, 100)}...'); // DEBUG
    
    List<dynamic> jsonData = jsonDecode(jsonString);
    debugPrint('Parsed ${jsonData.length} verses for $language');

    final batch = db.batch();
    int inserted = 0;
    for (var verseData in jsonData) {
      BibleVerse verse = BibleVerse(
        id: verseData['id'],
        book: verseData['book']?.toString() ?? '',
        chapter: verseData['chapter'] ?? 0,
        verse: verseData['verse'] ?? 0,
        text: verseData['text']?.toString() ?? '',
        language: language,
      );
      batch.insert(
        tableVerses, 
        verse.toMap(), 

      );
      inserted++;
    }
    await batch.commit(noResult: true);
    debugPrint('Successfully imported $inserted/${jsonData.length} verses for $language');
  } catch (e) {
    debugPrint('ERROR importing $language: $e');
  }
}
  Future<List<BibleVerse>> getVerses({
    String? book,
    int? chapter,
    String? language,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (book != null) {
      whereClause += 'book = ? ';
      whereArgs.add(book);
    }
    if (chapter != null&& book != null){
      whereClause += whereClause.isEmpty ? 'chapter = ?' : 'AND chapter = ?';
      whereArgs.add(chapter);
    }
    if (language != null) {
      whereClause += whereClause.isEmpty ? 'language = ?' : 'AND language = ?';
      whereArgs.add(language);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      tableVerses,
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'chapter ASC, verse ASC',
    );

    return List.generate(maps.length, (i) => BibleVerse.fromMap(maps[i]));
  }

  Future<List<BibleVerse>> getFavorites(String language) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableFavorites,
      where: 'language = ?',
      whereArgs: [language],
      orderBy: 'book ASC, chapter ASC, verse ASC',
    );

    return List.generate(maps.length, (i) => BibleVerse.fromMap({
      'id': maps[i]['verseId'],
      'book': maps[i]['book'],
      'chapter': maps[i]['chapter'],
      'verse': maps[i]['verse'],
      'text': maps[i]['text'],
      'language': maps[i]['language'],
    }));
  }

  Future<bool> toggleFavorite(BibleVerse verse) async {
    final db = await database;
    
    // Check if already favorite
    final List<Map<String, dynamic>> existing = await db.query(
      tableFavorites,
      where: 'verseId = ? AND book = ? AND chapter = ? AND verse = ? AND language = ?',
      whereArgs: [verse.id, verse.book, verse.chapter, verse.verse, verse.language],
    );

    if (existing.isNotEmpty) {
      // Remove favorite
      await db.delete(
        tableFavorites,
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
      return false;
    } else {
      // Add favorite
      await db.insert(tableFavorites, {
        'verseId': verse.id,
        'book': verse.book,
        'chapter': verse.chapter,
        'verse': verse.verse,
        'text': verse.text,
        'language': verse.language,
      });
      return true;
    }
  }

  Future<List<String>> getBooks(String language) async {
  final db = await database;
  
  // DEBUG: Check ALL data first
  final allData = await db.rawQuery('SELECT * FROM $tableVerses WHERE language = ? LIMIT 5', [language]);
  debugPrint('All $language data: $allData');
  
  final List<Map<String, dynamic>> result = await db.rawQuery(
    'SELECT DISTINCT book FROM $tableVerses WHERE language = ? ORDER BY book',
    [language],
  );
  
  final books = result.map((row) => row['book'] as String).toList();
  debugPrint('Books for $language: $books (count: ${result.length})');
  
  return books;
}
}