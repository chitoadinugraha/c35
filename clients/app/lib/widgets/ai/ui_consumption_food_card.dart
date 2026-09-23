import 'package:alienai_c35/c/consumption/consumption_food.dart';
import 'package:alienai_c35/widgets/io/ask_confirm.dart';
import 'package:alienai_c35/widgets/io/in_fraction.dart';
import 'package:alienai_c35/widgets/ui/ui_img.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:flutter/material.dart';

typedef ConsumptionItemsSave = Future<void> Function(List<ConsumptionItemRow> items);
typedef ConsumptionDeleteCallback = Future<void> Function();
typedef ConsumptionReinspectCallback = Future<void> Function(String correctedName);

class UiConsumptionFoodCard extends StatefulWidget {
  const UiConsumptionFoodCard({
    super.key,
    required this.card,
    this.collapsed = true,
    this.locale = 'en-US',
    this.onSave,
    this.onDelete,
    this.onReinspect,
  });

  final ConsumptionFoodCard card;
  final bool collapsed;
  final String locale;
  final ConsumptionItemsSave? onSave;
  final ConsumptionDeleteCallback? onDelete;
  final ConsumptionReinspectCallback? onReinspect;

  @override
  State<UiConsumptionFoodCard> createState() => _UiConsumptionFoodCardState();
}

class _UiConsumptionFoodCardState extends State<UiConsumptionFoodCard> {
  late final ExpansibleController _ctrl;
  late List<ConsumptionItemRow> _items;
  late final TextEditingController _nameCtrl;
  var _saving = false;
  var _deleting = false;
  var _deleted = false;
  var _reinspecting = false;

  bool get _isId => widget.locale.toLowerCase().startsWith('id');

  @override
  void initState() {
    super.initState();
    _ctrl = ExpansibleController();
    _items = widget.card.items.map((e) => ConsumptionItemRow.fromJson(e.toJson())).toList();
    _nameCtrl = TextEditingController(text: _primaryLabel);
    if (!widget.collapsed) _ctrl.expand();
  }

  @override
  void didUpdateWidget(covariant UiConsumptionFoodCard old) {
    super.didUpdateWidget(old);
    if (old.card.consumptionId != widget.card.consumptionId || old.card.headline != widget.card.headline) {
      _items = widget.card.items.map((e) => ConsumptionItemRow.fromJson(e.toJson())).toList();
      _nameCtrl.text = _primaryLabel;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String get _primaryLabel {
    if (_items.isEmpty) return widget.card.headline;
    return _items.first.label(widget.locale);
  }

  int get _totalKcal => _items.fold(0, (sum, i) => sum + i.kcalScaled());
  int get _totalFat => _items.fold(0, (sum, i) => sum + (i.fat * (i.qty > 0 ? i.qty : 1)).round());

  bool get _isDirty {
    if (_items.length != widget.card.items.length) return true;
    for (var i = 0; i < _items.length; i++) {
      final orig = widget.card.items[i];
      final curr = _items[i];
      if ((curr.qty - orig.qty).abs() > 0.001) return true;
      if (curr.name.trim() != orig.name.trim()) return true;
      if (curr.nameId.trim() != orig.nameId.trim()) return true;
    }
    return false;
  }

  Color get _coachColor {
    if (widget.card.duplicate && !widget.card.saved) return const Color(0xFF9CA3AF);
    if (widget.card.coach.isEmpty) return const Color(0xFF9CA3AF);
    if (widget.card.after > widget.card.goal) return const Color(0xFFF59E0B);
    return const Color(0xFF6EE7B7);
  }

  String _photoSrc() {
    final h = widget.card.photoHash.trim();
    if (h.isEmpty) return '';
    if (h.startsWith('http://') || h.startsWith('https://') || h.startsWith('/fs/')) return h;
    return '/fs/$h';
  }

  void _onPortionChanged(int index, double newQty) {
    setState(() {
      _items[index].qty = newQty > 0 ? newQty : 1.0;
    });
  }

  Future<void> _handleDelete() async {
    if (_deleting || _deleted) return;
    final confirmed = await askConfirm(
      context,
      title: _isId ? 'Hapus Catatan Makan' : 'Delete Meal Log',
      message: _isId
          ? 'Apakah Anda yakin ingin menghapus catatan $_primaryLabel ini?'
          : 'Are you sure you want to delete this log for $_primaryLabel?',
      confirmLabel: _isId ? 'Hapus' : 'Delete',
      cancelLabel: _isId ? 'Batal' : 'Cancel',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _deleting = true);
    try {
      if (widget.onDelete != null) {
        await widget.onDelete!();
      }
      if (mounted) {
        setState(() {
          _deleted = true;
          _deleting = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _handleReinspect() async {
    final query = _nameCtrl.text.trim();
    if (query.isEmpty || _reinspecting) return;
    setState(() => _reinspecting = true);
    try {
      if (widget.onReinspect != null) {
        await widget.onReinspect!(query);
      }
    } finally {
      if (mounted) setState(() => _reinspecting = false);
    }
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

  @override
  Widget build(BuildContext context) {
    if (_deleted) {
      return Material(
        color: const Color(0xFF18181B).withValues(alpha: 0.6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFF27272A)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _isId ? 'Catatan makanan telah dihapus.' : 'Meal log deleted.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF9CA3AF),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF27272A),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _isId ? 'Dihapus oleh pengguna' : 'Deleted by user',
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF71717A)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final photo = _photoSrc();
    final mainQty = _items.isNotEmpty ? _items.first.qty : 1.0;

    return Material(
      color: const Color(0xFF18181B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFF27272A)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar (Headline / Status banner)
          if (widget.card.headline.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: const BoxDecoration(
                color: Color(0xFF202024),
                border: Border(bottom: BorderSide(color: Color(0xFF27272A))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF6EE7B7)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.card.headline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFFD4D4D8)),
                    ),
                  ),
                ],
              ),
            ),
          // Main ExpansionTile (ListTile)
          ExpansionTile(
            controller: _ctrl,
            tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            leading: photo.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: UiImg(src: photo, width: 36, height: 36, fit: BoxFit.cover),
                  )
                : Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF064E3B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.restaurant_rounded, size: 18, color: Color(0xFF34D399)),
                  ),
            title: Text(
              _primaryLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFF4F4F5)),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_totalKcal kcal · ${_isId ? 'Lemak' : 'Fat'} ${_totalFat}g',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF)),
                ),
                if (widget.card.coach.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    widget.card.coach,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: _coachColor, height: 1.2),
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_items.isNotEmpty)
                  SizedBox(
                    width: 64,
                    height: 32,
                    child: InFraction(
                      value: mainQty > 0 ? mainQty : 1.0,
                      labelText: null,
                      onChanged: (v) => _onPortionChanged(0, v),
                    ),
                  ),
                const SizedBox(width: 4),
                // Delete button on the list tile header itself
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                  icon: _deleting
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFEF4444)))
                      : const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFF9CA3AF)),
                  tooltip: _isId ? 'Hapus' : 'Delete',
                  hoverColor: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  onPressed: _deleting ? null : _handleDelete,
                ),
                const SizedBox(width: 2),
                const Icon(Icons.expand_more_rounded, size: 18, color: Color(0xFF71717A)),
              ],
            ),
            children: [
              const Divider(color: Color(0xFF27272A), height: 12),
              // Today Calorie Progress (compact row)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isId ? 'Target Hari Ini' : 'Today\'s Goal',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF)),
                    ),
                    Text(
                      '${widget.card.after} / ${widget.card.goal} kcal (${(widget.card.after / (widget.card.goal > 0 ? widget.card.goal : 2000) * 100).round()}%)',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFFE4E4E7)),
                    ),
                  ],
                ),
              ),
              // Compact Editable Food Name & Re-inspect
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 34,
                      child: TextField(
                        controller: _nameCtrl,
                        style: const TextStyle(fontSize: 12, color: Color(0xFFF4F4F5)),
                        decoration: UiInputDecoration.of(
                          context,
                          labelText: _isId ? 'Nama Makanan' : 'Food Name',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        ),
                        onChanged: (val) {
                          if (_items.isNotEmpty) {
                            setState(() {
                              if (_isId) {
                                _items.first.nameId = val;
                              } else {
                                _items.first.name = val;
                              }
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    height: 34,
                    child: OutlinedButton.icon(
                      onPressed: _reinspecting ? null : _handleReinspect,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        side: const BorderSide(color: Color(0xFF3F3F46)),
                      ),
                      icon: _reinspecting
                          ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.auto_fix_high_rounded, size: 14, color: Color(0xFF6EE7B7)),
                      label: Text(
                        _isId ? 'Periksa Ulang' : 'Check again',
                        style: const TextStyle(fontSize: 11, color: Color(0xFFE4E4E7)),
                      ),
                    ),
                  ),
                ],
              ),
              // Detailed Nutrition Breakdown (compact 3-column chip layout)
              _buildNutritionBreakdown(),
              // Save button: visible ONLY when user modified portion or name
              if (_isDirty && widget.onSave != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: _saving
                          ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_rounded, size: 15),
                      label: Text(
                        _saving
                            ? (_isId ? 'Menyimpan…' : 'Saving…')
                            : (_isId ? 'Simpan perubahan' : 'Save changes'),
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionBreakdown() {
    final item = _items.isNotEmpty ? _items.first : ConsumptionItemRow(name: '');
    final q = item.qty > 0 ? item.qty : 1.0;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isId ? 'Rincian Nutrisi' : 'Nutrition Details',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6EE7B7)),
              ),
              Text(
                '${(item.calories * q).round()} kcal',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFF4F4F5)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _nutriChip('Protein', '${(item.protein * q).round()}g')),
              const SizedBox(width: 6),
              Expanded(child: _nutriChip(_isId ? 'Lemak' : 'Fat', '${(item.fat * q).round()}g')),
              const SizedBox(width: 6),
              Expanded(child: _nutriChip(_isId ? 'Karbo' : 'Carbs', '${(item.carbs * q).round()}g')),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: _nutriChip(_isId ? 'Serat' : 'Fiber', '${(item.fiber * q).round()}g')),
              const SizedBox(width: 6),
              Expanded(child: _nutriChip(_isId ? 'Gula' : 'Sugar', '${(item.sugar * q).round()}g')),
              const SizedBox(width: 6),
              Expanded(child: _nutriChip(_isId ? 'Natrium' : 'Sodium', '${(item.sodium * q).round()}mg')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _nutriChip(String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E22),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFF71717A))),
            Text(value, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFFE4E4E7))),
          ],
        ),
      );
}
