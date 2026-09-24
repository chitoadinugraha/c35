import 'package:alienai_c35/c/consumption/consumption_food.dart';
import 'package:alienai_c35/widgets/io/ask_confirm.dart';
import 'package:alienai_c35/widgets/io/in_fraction.dart';
import 'package:alienai_c35/widgets/ui/ui_img.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:flutter/material.dart';

typedef ConsumptionItemsSave = Future<void> Function(List<ConsumptionItemRow> items);
typedef ConsumptionDeleteCallback = Future<void> Function();
typedef ConsumptionReinspectCallback = Future<void> Function(String correctedName);
typedef ConsumptionCollapsedChanged = void Function(bool collapsed);

class UiConsumptionFoodCard extends StatefulWidget {
  const UiConsumptionFoodCard({
    super.key,
    required this.card,
    this.collapsed = true,
    this.locale = 'en-US',
    this.onSave,
    this.onDelete,
    this.onReinspect,
    this.onCollapsedChanged,
  });

  final ConsumptionFoodCard card;
  final bool collapsed;
  final String locale;
  final ConsumptionItemsSave? onSave;
  final ConsumptionDeleteCallback? onDelete;
  final ConsumptionReinspectCallback? onReinspect;
  final ConsumptionCollapsedChanged? onCollapsedChanged;

  @override
  State<UiConsumptionFoodCard> createState() => _UiConsumptionFoodCardState();
}

class _UiConsumptionFoodCardState extends State<UiConsumptionFoodCard> {
  late final ExpansibleController _ctrl;
  late List<ConsumptionItemRow> _items;
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
    if (!widget.collapsed) {
      _ctrl.expand();
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onCollapsedChanged?.call(false));
    }
  }

  @override
  void didUpdateWidget(covariant UiConsumptionFoodCard old) {
    super.didUpdateWidget(old);
    if (old.card.consumptionId != widget.card.consumptionId || old.card.headline != widget.card.headline) {
      _items = widget.card.items.map((e) => ConsumptionItemRow.fromJson(e.toJson())).toList();
    }
    if (!widget.collapsed && !_ctrl.isExpanded) _ctrl.expand();
  }

  String get _headlineLabel => consumptionFoodHeadlineLabel(widget.card.headline, widget.locale);

  String get _primaryLabel {
    if (_items.isEmpty) return _headlineLabel;
    return _items.first.label(widget.locale);
  }

  int get _totalKcal => _items.fold(0, (sum, i) => sum + i.kcalScaled());
  int get _totalFat => _items.fold(0, (sum, i) => sum + (i.fat * (i.qty > 0 ? i.qty : 1)).round());
  int get _totalCholesterol => _items.fold(0, (sum, i) => sum + (i.cholesterol * (i.qty > 0 ? i.qty : 1)).round());
  int get _totalPurines => _items.fold(0, (sum, i) => sum + (i.purines * (i.qty > 0 ? i.qty : 1)).round());

  String get _collapsedNutritionSummary => _isId
      ? '$_totalKcal kcal · Lemak ${_totalFat}g · Kolesterol ${_totalCholesterol}mg · Asam urat ${_totalPurines}mg'
      : '$_totalKcal kcal · Fat ${_totalFat}g · Cholesterol ${_totalCholesterol}mg · Purines ${_totalPurines}mg';

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

  Future<void> _handleReinspect(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty || _reinspecting) return;
    setState(() => _reinspecting = true);
    try {
      if (widget.onReinspect != null) {
        await widget.onReinspect!(trimmed);
      }
    } finally {
      if (mounted) setState(() => _reinspecting = false);
    }
  }

  void _applyName(int index, String name) {
    if (index < 0 || index >= _items.length) return;
    setState(() {
      if (_isId) {
        _items[index].nameId = name;
      } else {
        _items[index].name = name;
      }
    });
  }

  String _itemOriginalLabel(int index) {
    if (index < 0 || index >= widget.card.items.length) return '';
    return widget.card.items[index].label(widget.locale);
  }

  Future<void> _editNameDialog(int index) async {
    if (index < 0 || index >= _items.length) return;
    final nameCtrl = TextEditingController(text: _items[index].label(widget.locale));

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final draft = nameCtrl.text.trim();
          final nameChanged = draft.isNotEmpty && draft != _itemOriginalLabel(index).trim();
          final canReinspect = nameChanged && widget.onReinspect != null;

          return AlertDialog(
            backgroundColor: const Color(0xFF18181B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF27272A)),
            ),
            title: Text(
              _isId ? 'Ubah Nama Makanan' : 'Edit Food Name',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFF4F4F5)),
            ),
            contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            content: SizedBox(
              width: 320,
              child: TextField(
                controller: nameCtrl,
                autofocus: true,
                style: const TextStyle(fontSize: 13, color: Color(0xFFF4F4F5)),
                decoration: UiInputDecoration.of(ctx, labelText: _isId ? 'Nama Makanan' : 'Food Name'),
                onChanged: (_) => setModalState(() {}),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(_isId ? 'Batal' : 'Cancel'),
              ),
              if (canReinspect)
                OutlinedButton.icon(
                  onPressed: _reinspecting
                      ? null
                      : () async {
                          _applyName(index, draft);
                          Navigator.pop(ctx);
                          await _handleReinspect(draft);
                        },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF3F3F46)),
                  ),
                  icon: _reinspecting
                      ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_fix_high_rounded, size: 14, color: Color(0xFF6EE7B7)),
                  label: Text(
                    _isId ? 'Periksa Ulang' : 'Check again',
                    style: const TextStyle(fontSize: 12, color: Color(0xFFE4E4E7)),
                  ),
                ),
              FilledButton(
                onPressed: draft.isEmpty || !nameChanged
                    ? null
                    : () {
                        _applyName(index, draft);
                        Navigator.pop(ctx);
                      },
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF059669)),
                child: Text(_isId ? 'Terapkan' : 'Apply'),
              ),
            ],
          );
        },
      ),
    );

    nameCtrl.dispose();
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

  Widget _buildEditButton(int index) => IconButton(
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        tooltip: _isId ? 'Ubah nama' : 'Edit name',
        icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF71717A)),
        onPressed: () => _editNameDialog(index),
      );

  Widget? _buildDeleteButton() {
    if (widget.onDelete == null) return null;
    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      icon: _deleting
          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFEF4444)))
          : const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
      tooltip: _isId ? 'Hapus' : 'Delete',
      hoverColor: const Color(0xFFEF4444).withValues(alpha: 0.15),
      onPressed: _deleting ? null : _handleDelete,
    );
  }

  Widget _buildQtyField(int index) => SizedBox(
        width: 78,
        height: 32,
        child: InFraction(
          value: _items[index].qty > 0 ? _items[index].qty : 1.0,
          labelText: null,
          compact: true,
          onChanged: (v) => _onPortionChanged(index, v),
        ),
      );

  Widget _buildItemRow(int index) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _items[index].label(widget.locale),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFFE4E4E7)),
              ),
            ),
            _buildEditButton(index),
            const SizedBox(width: 4),
            _buildQtyField(index),
          ],
        ),
      );

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
                      _headlineLabel,
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
            onExpansionChanged: (expanded) => widget.onCollapsedChanged?.call(!expanded),
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
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _primaryLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFF4F4F5)),
                ),
                const SizedBox(height: 2),
                Text(
                  _collapsedNutritionSummary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
            trailing: Builder(
              builder: (context) {
                final deleteBtn = _buildDeleteButton();
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (_items.length == 1) ...[
                      _buildEditButton(0),
                      const SizedBox(width: 4),
                      _buildQtyField(0),
                      const SizedBox(width: 4),
                    ],
                    if (deleteBtn != null) deleteBtn,
                    const SizedBox(width: 8),
                    const Icon(Icons.expand_more_rounded, size: 18, color: Color(0xFF71717A)),
                  ],
                );
              },
            ),
            children: [
              const Divider(color: Color(0xFF27272A), height: 12),
              if (_items.length > 1) ...[
                for (var i = 0; i < _items.length; i++) _buildItemRow(i),
                const SizedBox(height: 4),
              ],
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
    var protein = 0;
    var fat = 0;
    var carbs = 0;
    var fiber = 0;
    var sugar = 0;
    var sodium = 0;
    var potassium = 0;
    var iron = 0;
    var cholesterol = 0;
    var purines = 0;
    var kcal = 0;
    for (final item in _items) {
      final q = item.qty > 0 ? item.qty : 1.0;
      protein += (item.protein * q).round();
      fat += (item.fat * q).round();
      carbs += (item.carbs * q).round();
      fiber += (item.fiber * q).round();
      sugar += (item.sugar * q).round();
      sodium += (item.sodium * q).round();
      potassium += (item.potassium * q).round();
      iron += (item.iron * q).round();
      cholesterol += (item.cholesterol * q).round();
      purines += (item.purines * q).round();
      kcal += item.kcalScaled();
    }

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
                '$kcal kcal',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFF4F4F5)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _nutriChip('Protein', '${protein}g'),
              _nutriChip(_isId ? 'Lemak' : 'Fat', '${fat}g'),
              _nutriChip(_isId ? 'Karbo' : 'Carbs', '${carbs}g'),
              _nutriChip(_isId ? 'Serat' : 'Fiber', '${fiber}g'),
              _nutriChip(_isId ? 'Gula' : 'Sugar', '${sugar}g'),
              _nutriChip(_isId ? 'Natrium' : 'Sodium', '${sodium}mg'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isId ? 'Nutrisi Penting' : 'Key nutrients',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _nutriChip(_isId ? 'Besi' : 'Iron', '${iron}mg'),
              _nutriChip(_isId ? 'Kalium' : 'Potassium', '${potassium}mg'),
              _nutriChip(_isId ? 'Kolesterol' : 'Cholesterol', '${cholesterol}mg'),
              _nutriChip(_isId ? 'Asam urat' : 'Purines', '${purines}mg'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _nutriChip(String label, String value) => ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 88, maxWidth: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E22),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Color(0xFF71717A))),
              Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFFE4E4E7))),
            ],
          ),
        ),
      );
}
