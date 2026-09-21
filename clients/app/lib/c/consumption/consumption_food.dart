class ConsumptionItemRow {
  ConsumptionItemRow({
    required this.name,
    this.nameId = '',
    this.qty = 1,
    this.calories = 0,
    this.protein = 0,
    this.fat = 0,
    this.carbs = 0,
    this.fiber = 0,
    this.sugar = 0,
    this.sodium = 0,
  });

  String name;
  String nameId;
  double qty;
  int calories;
  int protein;
  int fat;
  int carbs;
  int fiber;
  int sugar;
  int sodium;

  int kcalScaled() => (calories * qty).round();

  String label(String locale) {
    final id = locale.toLowerCase().startsWith('id');
    final n = name.trim().isNotEmpty ? name.trim() : nameId.trim();
    return n.isEmpty ? (id ? 'Item' : 'Item') : n;
  }

  factory ConsumptionItemRow.fromJson(Map<String, dynamic> j) => ConsumptionItemRow(
        name: j['name']?.toString() ?? '',
        nameId: j['name_id']?.toString() ?? '',
        qty: (j['qty'] as num?)?.toDouble() ?? 1,
        calories: (j['calories'] as num?)?.round() ?? 0,
        protein: (j['protein'] as num?)?.round() ?? 0,
        fat: (j['fat'] as num?)?.round() ?? 0,
        carbs: (j['carbs'] as num?)?.round() ?? 0,
        fiber: (j['fiber'] as num?)?.round() ?? 0,
        sugar: (j['sugar'] as num?)?.round() ?? 0,
        sodium: (j['sodium'] as num?)?.round() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'name_id': nameId,
        'qty': qty,
        'calories': calories,
        'protein': protein,
        'fat': fat,
        'carbs': carbs,
        'fiber': fiber,
        'sugar': sugar,
        'sodium': sodium,
      };
}

class ConsumptionFoodCard {
  ConsumptionFoodCard({
    required this.consumptionId,
    required this.headline,
    this.coach = '',
    this.photoHash = '',
    this.mealKcal = 0,
    this.duplicate = false,
    this.saved = true,
    this.items = const [],
    this.soFar = 0,
    this.after = 0,
    this.goal = 2000,
    this.mealsLogged = 0,
  });

  final String consumptionId;
  final String headline;
  final String coach;
  final String photoHash;
  final int mealKcal;
  final bool duplicate;
  final bool saved;
  final List<ConsumptionItemRow> items;
  final int soFar;
  final int after;
  final int goal;
  final int mealsLogged;

  bool get editable => saved && consumptionId.isNotEmpty;

  factory ConsumptionFoodCard.fromBlockBody(Map<String, dynamic> body) {
    final today = Map<String, dynamic>.from(body['today'] as Map? ?? const {});
    final rawItems = body['items'] as List? ?? const [];
    return ConsumptionFoodCard(
      consumptionId: body['consumption_id']?.toString() ?? '',
      headline: body['headline']?.toString() ?? '',
      coach: body['coach']?.toString() ?? '',
      photoHash: body['photo_hash']?.toString() ?? '',
      mealKcal: (body['meal_kcal'] as num?)?.round() ?? 0,
      duplicate: body['duplicate'] == true,
      saved: body['saved'] != false,
      items: rawItems.map((e) => ConsumptionItemRow.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      soFar: (today['so_far'] as num?)?.round() ?? 0,
      after: (today['after'] as num?)?.round() ?? 0,
      goal: (today['goal'] as num?)?.round() ?? 2000,
      mealsLogged: (today['meals_logged'] as num?)?.round() ?? 0,
    );
  }
}
