import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obesight/models/article_model.dart';
import 'package:obesight/services/article_service.dart';

void main() {
  group('ArticleModel Tests', () {
    test('1. ArticleModel fallback values are safe when map is partially empty', () {
      final model = ArticleModel.fromMap({
        'id': 'article_test_1',
        'title': 'Uji Coba Judul',
      });

      expect(model.id, 'article_test_1');
      expect(model.title, 'Uji Coba Judul');
      expect(model.snippet, '');
      expect(model.date, '21 September 2026');
      expect(model.readTime, '4 Menit Baca');
      expect(model.headerColor, const Color(0xFF36785A));
      expect(model.icon, Icons.menu_book_rounded);
      expect(model.imageAsset, 'assets/articles/article_porsi_piring_gizi_seimbang.jpg');
      expect(model.category, 'Edukasi Kesehatan');
      expect(model.isPublished, true);
      expect(model.takeaways, isEmpty);
    });

    test('2. ArticleModel parses hex colors and icon names correctly', () {
      final model = ArticleModel.fromMap({
        'id': 2,
        'title': 'Artikel 2',
        'snippet': 'Ringkasan',
        'headerColorHex': '#818CF8',
        'iconName': 'nightlight',
        'category': 'Pola Tidur',
        'takeaways': ['Poin 1', 'Poin 2'],
      });

      expect(model.id, '2');
      expect(model.headerColor, const Color(0xFF818CF8));
      expect(model.icon, Icons.nightlight_round);
      expect(model.category, 'Pola Tidur');
      expect(model.takeaways.length, 2);
    });

    test('3. ArticleModel toFirestoreMap formats keys properly', () {
      final model = ArticleModel(
        id: 'article_custom',
        title: 'Custom Title',
        snippet: 'Custom Snippet',
        imageAsset: 'assets/articles/article_5_pola_makan.jpg',
        content: 'Konten artikel...',
        headerColor: const Color(0xFF7E96AC),
        icon: Icons.restaurant_menu_rounded,
        takeaways: const ['Takeaway 1'],
        date: '20 September 2026',
        publishedAt: DateTime(2026, 9, 20),
        updatedAt: DateTime(2026, 9, 20),
      );

      final map = model.toFirestoreMap();
      expect(map['title'], 'Custom Title');
      expect(map['snippet'], 'Custom Snippet');
      expect(map['date'], '20 September 2026');
      expect(map['imageAsset'], 'assets/articles/article_5_pola_makan.jpg');
      expect(map['headerColorHex'], '#7E96AC');
      expect(map['iconName'], 'restaurant_menu');
      expect(map['isPublished'], true);
      expect(model.headerColorHex, '#7E96AC');
      expect(model.iconName, 'restaurant_menu');
    });
  });

  group('ArticleService Tests', () {
    final service = ArticleService();

    test('1. Initial articles list contains 6 complete articles with valid assets', () {
      final articles = service.getArticles();
      expect(articles.length, 6);

      for (int i = 0; i < 6; i++) {
        final art = articles[i];
        expect(art.id, 'article_${i + 1}');
        expect(art.title.isNotEmpty, true);
        expect(art.snippet.isNotEmpty, true);
        expect(art.content.isNotEmpty, true);
        expect(art.imageAsset.startsWith('assets/articles/'), true);
        expect(art.isPublished, true);
      }
    });

    test('2. getFeaturedArticles returns 4 items', () {
      final featured = service.getFeaturedArticles();
      expect(featured.length, 4);
      expect(featured.first.id, 'article_1');
    });

    test('3. getArticleById finds article by string or int id', () {
      final byStr = service.getArticleById('article_1');
      final byInt = service.getArticleById(1);
      final byShortStr = service.getArticleById('1');

      expect(byStr, isNotNull);
      expect(byInt, isNotNull);
      expect(byShortStr, isNotNull);
      expect(byStr!.title, byInt!.title);
      expect(byStr.title, byShortStr!.title);
    });

    test('4. searchArticles filters correctly by title and snippet', () {
      final searchTidur = service.searchArticles('tidur');
      expect(searchTidur.length, 1);
      expect(searchTidur.first.title, 'Pentingnya kualitas tidur');

      final searchEmpty = service.searchArticles('');
      expect(searchEmpty.length, 6);

      final searchNonExistent = service.searchArticles('xyz123abc');
      expect(searchNonExistent, isEmpty);
    });

    test('5. getArticlesByCategory filters correctly', () {
      final nutritionArticles = service.getArticlesByCategory('Nutrisi & Gizi');
      expect(nutritionArticles.length, 1);
      expect(nutritionArticles.first.id, 'article_1');

      final allWhenEmpty = service.getArticlesByCategory('');
      expect(allWhenEmpty.length, 6);
    });

    test('6. fetchArticleById returns cached article without remote call', () async {
      final art = await service.fetchArticleById('article_1');
      expect(art, isNotNull);
      expect(art!.title, 'Porsi piring gizi seimbang');
    });
  });
}
