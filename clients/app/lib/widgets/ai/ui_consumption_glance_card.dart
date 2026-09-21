import 'package:alienai_c35/c/consumption/consumption_glance.dart';
import 'package:alienai_c35/widgets/ui/ui_img.dart';
import 'package:flutter/material.dart';

class UiConsumptionGlanceCard extends StatefulWidget {
  const UiConsumptionGlanceCard({super.key, required this.card, this.collapsed = false, this.locale = 'en-US'});

  final ConsumptionGlanceCard card;
  final bool collapsed;
  final String locale;

  @override
  State<UiConsumptionGlanceCard> createState() => _UiConsumptionGlanceCardState();
}

class _UiConsumptionGlanceCardState extends State<UiConsumptionGlanceCard> {
  late final ExpansibleController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = ExpansibleController();
    if (!widget.collapsed) _ctrl.expand();
  }

  Color _ringColor() {
    final goal = widget.card.calorieGoal > 0 ? widget.card.calorieGoal : 2000;
    final ratio = goal > 0 ? widget.card.calories / goal : 0.0;
    if (ratio >= 1) return const Color(0xFFF87171);
    if (ratio >= 0.85) return const Color(0xFFFBBF24);
    return const Color(0xFF34D399);
  }

  Color _coachColor() {
    final goal = widget.card.calorieGoal > 0 ? widget.card.calorieGoal : 2000;
    if (widget.card.calories > goal) return const Color(0xFFFBBF24);
    return const Color(0xFF6EE7B7);
  }

  String _photoSrc(String hash) {
    final h = hash.trim();
    if (h.isEmpty) return '';
    if (h.startsWith('http://') || h.startsWith('https://') || h.startsWith('/fs/')) return h;
    return '/fs/$h';
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final locale = widget.locale;
    final goal = card.calorieGoal > 0 ? card.calorieGoal : 2000;
    final ringColor = _ringColor();
    final ringValue = goal > 0 ? (card.calories / goal).clamp(0.0, 1.0) : 0.0;
    final id = locale.toLowerCase().startsWith('id');

    return Material(
      color: const Color(0xFF18181B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF27272A))),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        controller: _ctrl,
        initiallyExpanded: !widget.collapsed,
        tilePadding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: ringValue,
                    strokeWidth: 4,
                    strokeCap: StrokeCap.round,
                    backgroundColor: ringColor.withValues(alpha: 0.14),
                    valueColor: AlwaysStoppedAnimation(ringColor),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${card.calories}', style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 11, fontWeight: FontWeight.w700, height: 1.1)),
                      Text('kcal', style: TextStyle(color: ringColor, fontSize: 8, fontWeight: FontWeight.w600, height: 1.1)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(card.dayLabel(locale), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: Color(0xFFF4F4F5))),
                  const SizedBox(height: 3),
                  Text(
                    id ? '$goal kcal target · ${card.mealsLogged} makan' : '$goal kcal goal · ${card.mealsLogged} meals',
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF), height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: card.coach.trim().isEmpty
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 6, left: 68),
                child: Text(card.coach, style: TextStyle(fontSize: 12.5, color: _coachColor(), height: 1.35)),
              ),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _MacroChip(label: id ? 'Protein' : 'Protein', value: card.protein),
              _MacroChip(label: id ? 'Lemak' : 'Fat', value: card.fat),
              _MacroChip(label: id ? 'Karbo' : 'Carbs', value: card.carbs),
              _MacroChip(
                label: id ? 'Sisa' : 'Left',
                value: card.caloriesRemaining,
                suffix: ' kcal',
              ),
            ],
          ),
          if (card.matchedQuery.trim().isNotEmpty && card.matchedItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              id ? '“${card.matchedQuery}” · ${card.matchedKcal} kcal' : '"${card.matchedQuery}" · ${card.matchedKcal} kcal',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFFE4E4E7)),
            ),
            const SizedBox(height: 6),
            for (final item in card.matchedItems)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(child: Text(item.label(locale), style: const TextStyle(fontSize: 12.5, color: Color(0xFFA1A1AA)))),
                    Text('${item.kcalScaled()} kcal', style: const TextStyle(fontSize: 12, color: Color(0xFF71717A))),
                  ],
                ),
              ),
          ],
          if (card.meals.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(id ? 'Makanan tercatat' : 'Logged meals', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF71717A))),
            const SizedBox(height: 6),
            for (final meal in card.meals)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (_photoSrc(meal.photoHash).isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: UiImg(src: _photoSrc(meal.photoHash), width: 36, height: 36, fit: BoxFit.cover),
                      )
                    else
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: const Color(0xFF27272A), borderRadius: BorderRadius.circular(6)),
                        child: const Icon(Icons.restaurant_rounded, size: 16, color: Color(0xFF71717A)),
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(meal.label, style: const TextStyle(fontSize: 13, color: Color(0xFFF4F4F5))),
                          Text('${meal.itemCount} ${id ? 'item' : 'items'}', style: const TextStyle(fontSize: 11, color: Color(0xFF71717A))),
                        ],
                      ),
                    ),
                    Text('${meal.kcal} kcal', style: const TextStyle(fontSize: 12.5, color: Color(0xFFA1A1AA), fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({required this.label, required this.value, this.suffix = 'g'});

  final String label;
  final int value;
  final String suffix;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F23),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF27272A)),
        ),
        child: Text('$label $value$suffix', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.w500)),
      );
}
