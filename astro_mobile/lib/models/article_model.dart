class Article {
  final String id;
  final String title;
  final String category;
  final String content;
  final String author;

  Article({
    required this.id,
    required this.title,
    required this.category,
    required this.content,
    required this.author,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      content: json['content'] ?? '',
      author: json['author'] ?? '',
    );
  }
}
