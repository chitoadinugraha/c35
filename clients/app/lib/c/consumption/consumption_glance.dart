import 'package:alienai_c35/c/consumption/consumption_food.dart';

class ConsumptionMealSummary {
  const ConsumptionMealSummary({required this.id, required this.label, this.kcal = 0, this.itemCount = 0, this.photoHash = ''});

  final String id;
  final String label;
  final int kcal;
  final int itemCount;
  final String photoHash;

  factory ConsumptionMealSummary.fromJson(Map<String, dynamic> j) => ConsumptionMealSummary(
        id: j['id']?.toString() ?? '',
        label: j['label']?.toString() ?? '',
        kcal: (j['kcal'] as num?)?.round() ?? 0,
        itemCount: (j['item_count'] as num?)?.round() ?? 0,
        photoHash: j['photo_hash']?.toString() ?? '',
      );
}

class ConsumptionGlanceCard {
  const ConsumptionGlanceCard({
    required this.dayId,
    this.coach = '',
    this.calories = 0,
    this.protein = 0,
    this.fat = 0,
    this.carbs = 0,
    this.mealsLogged = 0,
    this.calorieGoal = 2000,
    this.caloriesRemaining = 0,
    this.meals = const [],
    this.matchedQuery = '',
    this.matchedItems = const [],
    this.matchedKcal = 0,
  });

  final String dayId;
  final String coach;
  final int calories;
  final int protein;
  final int fat;
  final int carbs;
  final int mealsLogged;
  final int calorieGoal;
  final int caloriesRemaining;
  final List<ConsumptionMealSummary> meals;
  final String matchedQuery;
  final List<ConsumptionItemRow> matchedItems;
  final int matchedKcal;

  double calorieRatio() => calorieGoal <= 0 ? 0 : (calories / calorieGoal).clamp(0.0, 1.5);

  factory ConsumptionGlanceCard.fromBlockBody(Map<String, dynamic> body) {
    final glance = Map<String, dynamic>.from(body['glance'] as Map? ?? const {});
    final rawMeals = body['meals'] as List? ?? const [];
    final rawMatched = body['matched_items'] as List? ?? const [];
    return ConsumptionGlanceCard(
      dayId: body['day_id']?.toString() ?? '',
      coach: body['coach']?.toString() ?? '',
      calories: (glance['calories'] as num?)?.round() ?? 0,
      protein: (glance['protein'] as num?)?.round() ?? 0,
      fat: (glance['fat'] as num?)?.round() ?? 0,
      carbs: (glance['carbs'] as num?)?.round() ?? 0,
      mealsLogged: (glance['meals_logged'] as num?)?.round() ?? 0,
      calorieGoal: (glance['calorie_goal'] as num?)?.round() ?? 2000,
      caloriesRemaining: (glance['calories_remaining'] as num?)?.round() ?? 0,
      meals: rawMeals.map((e) => ConsumptionMealSummary.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      matchedQuery: body['matched_query']?.toString() ?? '',
      matchedItems: rawMatched.map((e) => ConsumptionItemRow.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      matchedKcal: (body['matched_kcal'] as num?)?.round() ?? 0,
    );
  }

  String dayLabel(String locale) {
    final id = locale.toLowerCase().startsWith('id');
    final d = dayId.trim();
    if (d.isEmpty) return id ? 'Hari ini' : 'Today';
    final now = DateTime.now();
    final today = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final yesterday = now.subtract(const Duration(days: 1));
    final yid = '${yesterday.year.toString().padLeft(4, '0')}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    if (d == today) return id ? 'Hari ini' : 'Today';
    if (d == yid) return id ? 'Kemarin' : 'Yesterday';
    return d;
  }
}
