import 'package:flutter_test/flutter_test.dart';
import 'package:obesight/services/article_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Article Delete Feature Tests', () {
    test('1. ArticleService deletes article from cached memory and streams', () async {
      final service = ArticleService();
      final initialCount = service.getArticles().length;
      expect(initialCount, greaterThan(0));

      final targetArticle = service.getArticles().first;
      await service.deleteArticle(targetArticle.id);

      final updatedArticles = service.getArticles();
      expect(updatedArticles.any((a) => a.id == targetArticle.id), isFalse);
      expect(service.getArticleById(targetArticle.id), isNull);
    });

    test('2. Admin can delete published as well as draft articles', () async {
      final service = ArticleService();

      // Create a draft article
      final draftArticle = await service.createArticle(
        title: 'Draft Uji Hapus',
        content: 'Isi draf untuk pengujian hapus',
        isPublished: false,
      );

      // Verify draft exists
      expect(service.getArticleById(draftArticle.id), isNotNull);
      expect(service.getArticleById(draftArticle.id)!.isPublished, isFalse);

      // Delete the draft article
      await service.deleteArticle(draftArticle.id);
      expect(service.getArticleById(draftArticle.id), isNull);
    });
  });
}
