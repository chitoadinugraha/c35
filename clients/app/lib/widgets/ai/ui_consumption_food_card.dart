import 'package:alienai_c35/c/consumption/consumption_food.dart';
import 'package:alienai_c35/widgets/ui/ui_img.dart';
import 'package:flutter/material.dart';

typedef ConsumptionItemsSave = Future<void> Function(List<ConsumptionItemRow> items);

class UiConsumptionFoodCard extends StatefulWidget {
  const UiConsumptionFoodCard({super.key, required this.card, this.collapsed = true, this.locale = 'en-US', this.onSave});

  final ConsumptionFoodCard card;
  final bool collapsed;
  final String locale;
  final ConsumptionItemsSave? onSave;

  @override
  State<UiConsumptionFoodCard> createState() => _UiConsumptionFoodCardState();
}

class _UiConsumptionFoodCardState extends State<UiConsumptionFoodCard> {
  late final ExpansibleController _ctrl;
  late List<ConsumptionItemRow> _items;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = ExpansibleController();
    _items = widget.card.items.map((e) => ConsumptionItemRow.fromJson(e.toJson())).toList();
    if (!widget.collapsed) _ctrl.expand();
  }

  @override
  void didUpdateWidget(covariant UiConsumptionFoodCard old) {
    super.didUpdateWidget(old);
    if (old.card.consumptionId != widget.card.consumptionId || old.card.headline != widget.card.headline) {
      _items = widget.card.items.map((e) => ConsumptionItemRow.fromJson(e.toJson())).toList();
    }
  }

  Color get _coachColor {
    if (widget.card.duplicate && !widget.card.saved) return const Color(0xFF9CA3AF);
    if (widget.card.coach.isEmpty) return const Color(0xFF9CA3AF);
    return const Color(0xFF6EE7B7);
  }

  String _photoSrc() {
    final h = widget.card.photoHash.trim();
    if (h.isEmpty) return '';
    if (h.startsWith('http://') || h.startsWith('https://') || h.startsWith('/fs/')) return h;
    return '/fs/$h';
  }

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF27272A))),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          controller: _ctrl,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          title: Text(widget.card.headline, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: Color(0xFFF4F4F5))),
          subtitle: widget.card.coach.isEmpty
              ? null
              : Text(widget.card.coach, style: TextStyle(fontSize: 13, color: _coachColor, height: 1.35)),
          children: [
            if (_photoSrc().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: UiImg(src: _photoSrc(), height: 160, width: double.infinity, fit: BoxFit.cover),
              ),
            const SizedBox(height: 10),
            _macroRow('Meal', '${widget.card.mealKcal} kcal'),
            _macroRow('Today', '${widget.card.after} / ${widget.card.goal} kcal'),
            const SizedBox(height: 8),
            for (var i = 0; i < _items.length; i++) _itemRow(i),
            if (widget.onSave != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check_rounded, size: 18),
                  label: Text(_saving ? 'Saving…' : 'Save portions'),
                ),
              ),
          ],
        ),
      );

  Widget _macroRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(width: 72, child: Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF)))),
            Text(value, style: const TextStyle(fontSize: 12.5, color: Color(0xFFE4E4E7))),
          ],
        ),
      );

  Widget _itemRow(int i) {
    final item = _items[i];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label(widget.locale), style: const TextStyle(fontSize: 13.5, color: Color(0xFFF4F4F5))),
                Text('${item.kcalScaled()} kcal · P${(item.protein * item.qty).round()} F${(item.fat * item.qty).round()} C${(item.carbs * item.qty).round()}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF))),
              ],
            ),
          ),
          if (widget.onSave != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: item.qty <= 0.25 ? null : () => setState(() => item.qty = (item.qty - 0.25).clamp(0.25, 99)),
                  icon: const Icon(Icons.remove_circle_outline, size: 18),
                ),
                Text(item.qty % 1 == 0 ? item.qty.toStringAsFixed(0) : item.qty.toStringAsFixed(2), style: const TextStyle(fontSize: 13, color: Color(0xFFE4E4E7))),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => item.qty = (item.qty + 0.25).clamp(0.25, 99)),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (widget.onSave == null || _saving) return;
    setState(() => _saving = true);
    try {
      await widget.onSave!(_items);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
