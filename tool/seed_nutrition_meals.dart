import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:obesight/firebase_options.dart';
import 'package:obesight/services/meal_plan_service.dart';

/// Script Seeder untuk mengunggah katalog 35 master menu rekomendasi gizi ObeSight
/// ke koleksi Cloud Firestore: `nutrition_meals/{mealId}`.
///
/// PERINGATAN:
/// - File ini TIDAK dijalankan secara otomatis di aplikasi produksi.
/// - Idempotent: Menggunakan ID dokumen tetap dari `meal.id` sehingga aman
///   dijalankan berulang kali tanpa risiko duplikasi data.
/// - Foto TIDAK diunggah ke Firebase Storage; hanya path asset lokal yang dicatat.
class NutritionMealSeeder {
  NutritionMealSeeder._();

  static Future<void> seed() async {
    WidgetsFlutterBinding.ensureInitialized();

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    final firestore = FirebaseFirestore.instance;
    final meals = MealPlanService.allMasterMeals;

    debugPrint('Memulai seeding ${meals.length} menu ke koleksi nutrition_meals...');

    int successCount = 0;
    for (final meal in meals) {
      final docRef = firestore.collection('nutrition_meals').doc(meal.id);

      await docRef.set({
        'id': meal.id,
        'name': meal.name,
        'type': meal.type,
        'mealTime': meal.mealTime,
        'category': meal.category,
        'calories': meal.calories,
        'protein': meal.protein,
        'carbs': meal.carbs,
        'fat': meal.fat,
        'portionGram': meal.portionGram,
        'pills': meal.pills,
        'thumbImg': meal.thumbImg,
        'heroImg': meal.heroImg,
        'desc': meal.desc,
        'detailDesc': meal.detailDesc,
        'benefits': meal.benefits,
        'targetCategory': meal.targetCategory,
        'hasCustomPhoto': meal.hasCustomPhoto,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      successCount++;
      debugPrint('[$successCount/${meals.length}] Tersimpan: ${meal.id} - ${meal.name}');
    }

    debugPrint('Seeding selesai! Total $successCount menu berhasil disimpan ke Firestore.');
  }
}

Future<void> main() async {
  await NutritionMealSeeder.seed();
}
