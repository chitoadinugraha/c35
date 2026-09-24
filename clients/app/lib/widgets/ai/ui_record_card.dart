import 'package:alienai_c35/widgets/io/ask_confirm.dart';
import 'package:alienai_c35/widgets/io/in_fraction.dart';
import 'package:alienai_c35/widgets/ui/ui_img.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:flutter/material.dart';

class RecordItemData {
  RecordItemData({
    required this.name,
    this.nameAlt = '',
    this.qty = 1.0,
    this.unitPrice = 0,
    this.totalPrice = 0,
    this.objId = 0,
  });

  String name;
  String nameAlt;
  double qty;
  int unitPrice;
  int totalPrice;
  int objId;

  int computedTotal() {
    if (totalPrice > 0) return totalPrice;
    return (unitPrice * (qty > 0 ? qty : 1)).round();
  }

  String displayLabel(String locale) {
    final isId = locale.toLowerCase().startsWith('id');
    if (isId && nameAlt.trim().isNotEmpty) return nameAlt.trim();
    if (!isId && name.trim().isNotEmpty) return name.trim();
    if (nameAlt.trim().isNotEmpty) return nameAlt.trim();
    if (name.trim().isNotEmpty) return name.trim();
    return isId ? 'Item' : 'Item';
  }

  RecordItemData clone() => RecordItemData(
        name: name,
        nameAlt: nameAlt,
        qty: qty,
        unitPrice: unitPrice,
        totalPrice: totalPrice,
        objId: objId,
      );
}

class RecordChipData {
  const RecordChipData({required this.label, required this.value});
  final String label;
  final String value;
}

typedef RecordItemsSave = Future<void> Function(List<RecordItemData> items);
typedef RecordDeleteCallback = Future<void> Function();

class UiRecordCard extends StatefulWidget {
  const UiRecordCard({
    super.key,
    required this.id,
    required this.title,
    this.subtitle = '',
    this.headline = '',
    this.coach = '',
    this.photoHash = '',
    this.leadingIcon = Icons.receipt_long_rounded,
    this.primaryMetric = '',
    this.contextLabel = '',
    this.contextValue = '',
    required this.items,
    this.chips = const [],
    this.footerNote = '',
    this.collapsed = true,
    this.locale = 'en-US',
    this.qtyMode = 'stepper',
    this.canEditName = true,
    this.canEditQty = true,
    this.canEditPrice = true,
    this.formatPrice,
    this.onSave,
    this.onDelete,
    this.saved = true,
    this.duplicate = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final String headline;
  final String coach;
  final String photoHash;
  final IconData leadingIcon;
  final String primaryMetric;
  final String contextLabel;
  final String contextValue;
  final List<RecordItemData> items;
  final List<RecordChipData> chips;
  final String footerNote;
  final bool collapsed;
  final String locale;
  final String qtyMode;
  final bool canEditName;
  final bool canEditQty;
  final bool canEditPrice;
  final String Function(int value)? formatPrice;
  final RecordItemsSave? onSave;
  final RecordDeleteCallback? onDelete;
  final bool saved;
  final bool duplicate;

  @override
  State<UiRecordCard> createState() => _UiRecordCardState();
}

class _UiRecordCardState extends State<UiRecordCard> {
  late final ExpansibleController _ctrl;
  late List<RecordItemData> _items;
  var _saving = false;
  var _deleting = false;
  var _deleted = false;

  bool get _isId => widget.locale.toLowerCase().startsWith('id');

  @override
  void initState() {
    super.initState();
    _ctrl = ExpansibleController();
    _items = widget.items.map((e) => e.clone()).toList();
    if (!widget.collapsed) _ctrl.expand();
  }

  @override
  void didUpdateWidget(covariant UiRecordCard old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id || old.items.length != widget.items.length) {
      _items = widget.items.map((e) => e.clone()).toList();
    }
  }

  bool get _isDirty {
    if (_items.length != widget.items.length) return true;
    for (var i = 0; i < _items.length; i++) {
      final orig = widget.items[i];
      final curr = _items[i];
      if ((curr.qty - orig.qty).abs() > 0.001) return true;
      if (curr.name.trim() != orig.name.trim()) return true;
      if (curr.nameAlt.trim() != orig.nameAlt.trim()) return true;
      if (curr.unitPrice != orig.unitPrice) return true;
      if (curr.totalPrice != orig.totalPrice) return true;
    }
    return false;
  }

  int get _computedGrandTotal => _items.fold(0, (sum, i) => sum + i.computedTotal());

  String _fmt(int val) {
    if (widget.formatPrice != null) return widget.formatPrice!(val);
    return val.toString();
  }

  String _photoSrc() {
    final h = widget.photoHash.trim();
    if (h.isEmpty) return '';
    if (h.startsWith('http://') || h.startsWith('https://') || h.startsWith('/fs/')) return h;
    return '/fs/$h';
  }

  void _onQtyChanged(int index, double newQty) {
    setState(() {
      final item = _items[index];
      item.qty = newQty > 0 ? newQty : 1.0;
      if (item.unitPrice > 0) {
        item.totalPrice = (item.unitPrice * item.qty).round();
      }
    });
  }

  Future<void> _handleDelete() async {
    if (_deleting || _deleted) return;
    final confirmed = await askConfirm(
      context,
      title: _isId ? 'Hapus Catatan' : 'Delete Record',
      message: _isId
          ? 'Apakah Anda yakin ingin menghapus catatan "${widget.title}" ini?'
          : 'Are you sure you want to delete "${widget.title}"?',
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

  Future<void> _save() async {
    if (widget.onSave == null || _saving) return;
    setState(() => _saving = true);
    try {
      await widget.onSave!(_items);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editItemModal(int index) async {
    final item = _items[index];
    final nameCtrl = TextEditingController(text: item.displayLabel(widget.locale));
    final priceCtrl = TextEditingController(text: item.unitPrice > 0 ? item.unitPrice.toString() : '');
    double localQty = item.qty;

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final unitPrice = int.tryParse(priceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          final lineTot = (unitPrice * (localQty > 0 ? localQty : 1)).round();

          return AlertDialog(
            backgroundColor: const Color(0xFF18181B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF27272A)),
            ),
            title: Text(
              _isId ? 'Ubah Item' : 'Edit Item',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFF4F4F5)),
            ),
            contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.canEditName) ...[
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(fontSize: 13, color: Color(0xFFF4F4F5)),
                      decoration: UiInputDecoration.of(ctx, labelText: _isId ? 'Nama Item' : 'Item Name'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (widget.canEditQty) ...[
                    Row(
                      children: [
                        Text(_isId ? 'Jumlah (Qty)' : 'Quantity', style: const TextStyle(fontSize: 12.5, color: Color(0xFFA1A1AA))),
                        const Spacer(),
                        _QtyMiniStepper(
                          qty: localQty,
                          onChanged: (q) => setModalState(() => localQty = q),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (widget.canEditPrice) ...[
                    TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 13, color: Color(0xFFF4F4F5)),
                      decoration: UiInputDecoration.of(ctx, labelText: _isId ? 'Harga Satuan' : 'Unit Price'),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF27272A),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_isId ? 'Total Baris:' : 'Line Total:', style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                        Text(_fmt(lineTot), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF6EE7B7))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(_isId ? 'Batal' : 'Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final newName = nameCtrl.text.trim();
                  if (newName.isNotEmpty) {
                    if (_isId) {
                      item.nameAlt = newName;
                    } else {
                      item.name = newName;
                    }
                  }
                  item.qty = localQty;
                  if (widget.canEditPrice) {
                    item.unitPrice = unitPrice;
                    item.totalPrice = lineTot;
                  }
                  Navigator.pop(ctx, true);
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
    priceCtrl.dispose();

    if (updated == true) {
      setState(() {});
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
                  _isId ? 'Catatan telah dihapus.' : 'Record deleted.',
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
    final displayedMetric = _isDirty ? _fmt(_computedGrandTotal) : (widget.primaryMetric.isNotEmpty ? widget.primaryMetric : _fmt(_computedGrandTotal));

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
          // Optional Header Headline Banner
          if (widget.headline.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: const BoxDecoration(
                color: Color(0xFF202024),
                border: Border(bottom: BorderSide(color: Color(0xFF27272A))),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.saved ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
                    size: 14,
                    color: widget.saved ? const Color(0xFF6EE7B7) : const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.headline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFFD4D4D8)),
                    ),
                  ),
                ],
              ),
            ),

          // Main ExpansionTile
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
                      color: const Color(0xFF1E3A5F),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(widget.leadingIcon, size: 18, color: const Color(0xFF60A5FA)),
                  ),
            title: Text(
              widget.title.isNotEmpty ? widget.title : (_isId ? 'Catatan' : 'Record'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFF4F4F5)),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.subtitle.isNotEmpty)
                  Text(
                    widget.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF)),
                  ),
                if (widget.coach.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    widget.coach,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF6EE7B7), height: 1.2),
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayedMetric,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFF4F4F5)),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.expand_more_rounded, size: 18, color: Color(0xFF71717A)),
              ],
            ),
            children: [
              const Divider(color: Color(0xFF27272A), height: 12),

              // Context Row (e.g. Today's total)
              if (widget.contextLabel.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.contextLabel,
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF)),
                      ),
                      Text(
                        widget.contextValue,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFFE4E4E7)),
                      ),
                    ],
                  ),
                ),

              // Line Items
              if (_items.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isId ? 'Rincian Item' : 'Line Items',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF60A5FA)),
                    ),
                    if (widget.canEditName || widget.canEditPrice)
                      Text(
                        _isId ? 'Ketuk untuk ubah' : 'Tap to edit',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF71717A)),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                for (var idx = 0; idx < _items.length; idx++)
                  _buildItemRow(idx),
              ],

              // Metadata Chips
              if (widget.chips.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final chip in widget.chips)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF202024),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF27272A)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${chip.label}: ', style: const TextStyle(fontSize: 10.5, color: Color(0xFF71717A))),
                            Text(chip.value, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: Color(0xFFD4D4D8))),
                          ],
                        ),
                      ),
                  ],
                ),
              ],

              // Duplicate reason note
              if (widget.footerNote.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    widget.footerNote,
                    style: const TextStyle(fontSize: 11, color: Color(0xFFF59E0B)),
                  ),
                ),

              // Bottom Action Row (Save / Delete)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    if (widget.onDelete != null)
                      SizedBox(
                        height: 32,
                        child: TextButton.icon(
                          onPressed: _deleting ? null : _handleDelete,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: _deleting
                              ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFEF4444)))
                              : const Icon(Icons.delete_outline_rounded, size: 15),
                          label: Text(_isId ? 'Hapus' : 'Delete', style: const TextStyle(fontSize: 11.5)),
                        ),
                      ),
                    const Spacer(),
                    if (_isDirty && widget.onSave != null)
                      FilledButton.icon(
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
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(int idx) {
    final item = _items[idx];
    final isFraction = widget.qtyMode == 'fraction';

    return InkWell(
      onTap: (widget.canEditName || widget.canEditPrice) ? () => _editItemModal(idx) : null,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayLabel(widget.locale),
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFFF4F4F5), fontWeight: FontWeight.w500),
                  ),
                  if (item.unitPrice > 0)
                    Text(
                      _fmt(item.unitPrice),
                      style: const TextStyle(fontSize: 11, color: Color(0xFF71717A)),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Quantity Modifier
            if (widget.canEditQty) ...[
              if (isFraction)
                InkWell(
                  onTap: () async {
                    final picked = await askFraction(context: context, value: item.qty);
                    if (picked != null) _onQtyChanged(idx, picked);
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF27272A),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${item.qty} porsi',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF6EE7B7)),
                    ),
                  ),
                )
              else
                _QtyMiniStepper(
                  qty: item.qty,
                  onChanged: (q) => _onQtyChanged(idx, q),
                ),
              const SizedBox(width: 10),
            ],

            // Line Total
            Text(
              _fmt(item.computedTotal()),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFA1A1AA)),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyMiniStepper extends StatelessWidget {
  const _QtyMiniStepper({required this.qty, required this.onChanged});

  final double qty;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final intDisplay = (qty == qty.roundToDouble());
    final text = intDisplay ? qty.round().toString() : qty.toStringAsFixed(1);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF202024),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _miniBtn(
            icon: Icons.remove,
            onTap: qty > 1 ? () => onChanged(qty - 1) : (qty > 0.5 ? () => onChanged(0.5) : null),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              text,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFFF4F4F5)),
            ),
          ),
          _miniBtn(
            icon: Icons.add,
            onTap: () => onChanged(qty + 1),
          ),
        ],
      ),
    );
  }

  Widget _miniBtn({required IconData icon, VoidCallback? onTap}) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 13, color: onTap == null ? const Color(0xFF52525B) : const Color(0xFFD4D4D8)),
        ),
      );
}
