import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bible_verse.dart';
import '../services/database_service.dart';

final bibleServiceProvider = Provider<DatabaseService>((ref) => DatabaseService());

final versesProvider = FutureProvider.family<List<BibleVerse>, ({String book, String language})>((ref, params) async {
  final service = ref.watch(bibleServiceProvider);
  return service.getVerses(
    book: params.book,
    language: params.language,
  );
});

final favoritesProvider = FutureProvider.family<List<BibleVerse>, String>((ref, language) async {
  final service = ref.watch(bibleServiceProvider);
  return service.getFavorites(language);
});

final booksProvider = FutureProvider.family<List<String>, String>((ref, language) async {
  final service = ref.watch(bibleServiceProvider);
  return service.getBooks(language);
});