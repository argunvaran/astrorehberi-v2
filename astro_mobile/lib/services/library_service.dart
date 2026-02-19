import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/article_model.dart';
import 'dart:math';

class LibraryService {
  // Singleton
  static final LibraryService instance = LibraryService._();
  LibraryService._();

  List<Article> _articles = [];
  bool _isLoaded = false;

  Future<void> loadLibrary() async {
    if (_isLoaded) return;
    try {
      final String response = await rootBundle.loadString('assets/data/cosmic_library.json');
      final List<dynamic> data = json.decode(response);
      _articles = data.map((json) => Article.fromJson(json)).toList();
      _isLoaded = true;
      print("Kozmik Kütüphane Yüklendi: ${_articles.length} makale.");
    } catch (e) {
      print("Kütüphane Hatası: $e");
      // Fallback data
      _articles = [
        Article(
          id: "1",
          title: "Merkür Retrosunun Psikolojik Etkileri",
          category: "Akademik Astroloji",
          content: "Merkür retrosu, iletişim gezegeninin Dünya'dan bakıldığında geri gidiyor gibi görünmesidir. Bu süreçte zihinsel süreçler içe döner...",
          author: "Kozmik Bilge"
        )
      ];
    }
  }

  Article getRandomArticle() {
    if (_articles.isEmpty) return Article(id: "0", title: "Yükleniyor...", category: "", content: "", author: "");
    return _articles[Random().nextInt(_articles.length)];
  }

  List<Article> getAllArticles() => _articles;

  List<String> getUniqueCategories() => _articles.map((a) => a.category).toSet().toList();

  List<Article> getArticlesByCategory(String category) {
    return _articles.where((a) => a.category == category).toList();
  }

  /// Verilen anahtar kelimelere (örn: "Güneş", "Koç", "1. Ev") en uygun makaleyi bulur.
  Article findBestMatch(String planet, String sign, String house) {
    if (_articles.isEmpty) return Article(id: "0", title: "Yükleniyor...", category: "", content: "", author: "");

    try {
      // 1. Tam Eşleşme Arama (Örn: "Güneş Koç Burcunda ve 1. Evde")
      // Dosyadaki format: "Güneş Koç Burcunda ve 1. Ev'de"
      final exactMatch = _articles.firstWhere(
        (a) => a.title.toLowerCase().contains(planet.toLowerCase()) && 
               a.title.toLowerCase().contains(sign.toLowerCase()) &&
               a.title.toLowerCase().contains(house.split(" ")[0].toLowerCase()), // "1." kısmını al
        orElse: () => _articles.firstWhere(
            // 2. Yarı Eşleşme (Sadece Gezegen ve Burç)
            (a) => a.title.toLowerCase().contains(planet.toLowerCase()) && 
                   a.title.toLowerCase().contains(sign.toLowerCase()),
            orElse: () => getRandomArticle() // Hiçbiri yoksa rastgele ver
        )
      );
      return exactMatch;
      
    } catch (_) {
      return getRandomArticle();
    }
  }
}
