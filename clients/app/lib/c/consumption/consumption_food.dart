class ConsumptionItemRow {
  ConsumptionItemRow({
    required this.name,
    this.nameId = '',
    this.qty = 1,
    this.objId = 0,
    this.calories = 0,
    this.protein = 0,
    this.fat = 0,
    this.carbs = 0,
    this.fiber = 0,
    this.sugar = 0,
    this.sodium = 0,
    this.potassium = 0,
    this.iron = 0,
    this.cholesterol = 0,
    this.purines = 0,
  });

  String name;
  String nameId;
  double qty;
  int objId;
  int calories;
  int protein;
  int fat;
  int carbs;
  int fiber;
  int sugar;
  int sodium;
  int potassium;
  int iron;
  int cholesterol;
  int purines;

  int kcalScaled() => (calories * qty).round();

  String label(String locale) {
    final isId = locale.toLowerCase().startsWith('id');
    if (isId && nameId.trim().isNotEmpty) return nameId.trim();
    if (!isId && name.trim().isNotEmpty) return name.trim();
    if (nameId.trim().isNotEmpty) return nameId.trim();
    if (name.trim().isNotEmpty) return name.trim();
    return isId ? 'Makanan' : 'Food item';
  }

  factory ConsumptionItemRow.fromJson(Map<String, dynamic> j) => ConsumptionItemRow(
        name: j['name']?.toString() ?? '',
        nameId: j['name_id']?.toString() ?? '',
        qty: (j['qty'] as num?)?.toDouble() ?? 1,
        objId: (j['obj_id'] as num?)?.toInt() ?? 0,
        calories: (j['calories'] as num?)?.round() ?? 0,
        protein: (j['protein'] as num?)?.round() ?? 0,
        fat: (j['fat'] as num?)?.round() ?? 0,
        carbs: (j['carbs'] as num?)?.round() ?? 0,
        fiber: (j['fiber'] as num?)?.round() ?? 0,
        sugar: (j['sugar'] as num?)?.round() ?? 0,
        sodium: (j['sodium'] as num?)?.round() ?? 0,
        potassium: (j['potassium'] as num?)?.round() ?? 0,
        iron: (j['iron'] as num?)?.round() ?? 0,
        cholesterol: (j['cholesterol'] as num?)?.round() ?? 0,
        purines: (j['purines'] as num?)?.round() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'name_id': nameId,
        'qty': qty,
        'obj_id': objId,
        'calories': calories,
        'protein': protein,
        'fat': fat,
        'carbs': carbs,
        'fiber': fiber,
        'sugar': sugar,
        'sodium': sodium,
        'potassium': potassium,
        'iron': iron,
        'cholesterol': cholesterol,
        'purines': purines,
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
