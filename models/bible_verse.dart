class BibleVerse {
  final int id;
  final String book;
  final int chapter;
  final int verse;
  final String text;
  final String language;

  BibleVerse({
    required this.id,
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
    required this.language,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'book': book,
      'chapter': chapter,
      'verse': verse,
      'text': text,
      'language': language,
    };
  }

  factory BibleVerse.fromMap(Map<String, dynamic> map) {
    return BibleVerse(
      id: map['id'],
      book: map['book'],
      chapter: map['chapter'],
      verse: map['verse'],
      text: map['text'],
      language: map['language'],
    );
  }
}