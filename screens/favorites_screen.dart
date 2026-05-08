import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../providers/bible_providers.dart';
import '../providers/language_provider.dart';

import 'bible_reader_screen.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final favoritesAsync = ref.watch(favoritesProvider(language));

    return Scaffold(
      appBar: AppBar(
        title: Text('Favorite Verses'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: favoritesAsync.when(
        data: (favorites) => favorites.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No favorite verses yet', style: TextStyle(fontSize: 18)),
                  ],
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final verse = favorites[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: Colors.red[100],
                        child: Text('${verse.chapter}:${verse.verse}'),
                      ),
                      title: Text(
                        '${verse.book} ${verse.chapter}:${verse.verse}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        verse.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BibleReaderScreen(book: verse.book),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}