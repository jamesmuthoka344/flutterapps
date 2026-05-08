import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/bible_providers.dart';
import '../providers/language_provider.dart';
import 'bible_reader_screen.dart';
import 'favorites_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  // ✅ Make Stateful
  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final currentLanguage = ref.watch(languageProvider);
    final booksAsync = ref.watch(booksProvider(currentLanguage));

    return Scaffold(
      appBar: AppBar(
        title: Text('Bible App'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavoritesScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Language Switcher
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => ref.read(languageProvider.notifier).setLanguage('english'),
                  icon: const Icon(Icons.language),
                  label: const Text('English'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentLanguage == 'english' ? Colors.blue[700] : null,
                    foregroundColor: currentLanguage == 'english' ? Colors.white : null,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.read(languageProvider.notifier).setLanguage('kiswahili'),
                  icon: const Icon(Icons.language),
                  label: const Text('Kiswahili'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentLanguage == 'kiswahili' ? Colors.green[700] : null,
                    foregroundColor: currentLanguage == 'kiswahili' ? Colors.white : null,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: booksAsync.when(
              data: (books) {
                debugPrint('Books for $currentLanguage: $books'); // Debug
                return books.isEmpty
                    ? Center(child: Text('No books found for $currentLanguage'))
                    : ListView.builder(
                        itemCount: books.length,
                        itemBuilder: (context, index) {
                          final book = books[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue[100],
                              child: Text('${index + 1}'),
                            ),
                            title: Text(
                              book,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BibleReaderScreen(book: book),
                                ),
                              );
                            },
                          );
                        },
                      );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}