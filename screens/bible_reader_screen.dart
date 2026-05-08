import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bible_verse.dart';

import '../providers/bible_providers.dart';
import '../providers/language_provider.dart';
import '../services/database_service.dart';

class BibleReaderScreen extends ConsumerStatefulWidget {
  final String book;
  const BibleReaderScreen({super.key, required this.book});

  @override
  // ignore: library_private_types_in_public_api
  _BibleReaderScreenState createState() => _BibleReaderScreenState();
}

class _BibleReaderScreenState extends ConsumerState<BibleReaderScreen> {
  int currentChapter = 1;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFavoriteStatus();
    });
  }

  // ✅ FIXED VERSION
  Future<void> _checkFavoriteStatus() async {
    final language = ref.read(languageProvider);
    final service = DatabaseService();
    
    // Do all async work FIRST
    final verses = await service.getVerses(
      book: widget.book,
      chapter: currentChapter,
      language: language,
    );
    
    bool favoriteStatus = false;
    if (verses.isNotEmpty) {
      final favorites = await service.getFavorites(language);
      favoriteStatus = favorites.any((f) => 
          f.book == widget.book && f.chapter == currentChapter);
    }
    
    // ONLY NOW call setState() synchronously
    if (mounted) {
      setState(() {
        isFavorite = favoriteStatus;
      });
    }
  }

  Future<void> _toggleFavorite(BibleVerse verse) async {
    final service = DatabaseService();
    final isNowFavorite = await service.toggleFavorite(verse);
    
    if (mounted) {
      setState(() {
        isFavorite = isNowFavorite;
      });
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isNowFavorite ? 'Added to favorites' : 'Removed from favorites'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

 @override
Widget build(BuildContext context) {
  final language = ref.watch(languageProvider);
  final versesAsync = ref.watch(versesProvider((book: widget.book, language: language)));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : null,
            ),
            onPressed: versesAsync.when(
              data: (verses) => verses.isNotEmpty 
                  ? () => _toggleFavorite(verses.first)
                  : null,
              loading: () => null,
              // ignore: unnecessary_underscores
              error: (_, __) => null,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Chapter Navigation
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: currentChapter > 1 
                      ? () {
                          setState(() => currentChapter--);
                          _checkFavoriteStatus();
                        }
                      : null,
                  icon: const Icon(Icons.arrow_back_ios),
                ),
                Text(
                  'Chapter $currentChapter',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: null,
                  icon: const Icon(Icons.arrow_forward_ios),
                ),
              ],
            ),
          ),
          Expanded(
            child: versesAsync.when(
              data: (verses) => verses.isEmpty
                  ? const Center(child: Text('No verses found'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: verses.length,
                      itemBuilder: (context, index) {
                        final verse = verses[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue[100],
                              child: Text('${verse.verse}'),
                            ),
                            title: Text(
                              verse.text,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.6,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}