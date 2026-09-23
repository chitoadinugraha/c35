import 'package:flutter/material.dart';

const _accent = Color(0xFF34D399);
const _muted = Color(0xFF71717A);

class UiTxSaveMenu extends StatelessWidget {
  const UiTxSaveMenu({
    super.key,
    required this.onSave,
    required this.onSaveNew,
    required this.onViewReceipt,
    required this.printReceipt,
    required this.onPrintReceiptChanged,
    this.onDelete,
    this.canSave = true,
    this.saveBlockReason,
    this.busy = false,
  });

  final VoidCallback onSave;
  final VoidCallback onSaveNew;
  final VoidCallback onViewReceipt;
  final bool printReceipt;
  final ValueChanged<bool> onPrintReceiptChanged;
  final VoidCallback? onDelete;
  final bool canSave;
  final String? saveBlockReason;
  final bool busy;

  bool get _saveEnabled => canSave && !busy;

  void _saveTap(BuildContext context, VoidCallback save) {
    if (busy) return;
    if (_saveEnabled) {
      save();
      return;
    }
    final reason = saveBlockReason?.trim();
    if (reason == null || reason.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(reason), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) => MenuAnchor(
        alignmentOffset: const Offset(0, 4),
        style: MenuStyle(
          visualDensity: VisualDensity.standard,
          minimumSize: const WidgetStatePropertyAll(Size(248, 0)),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 8)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
        menuChildren: [
          MenuItemButton(
            onPressed: busy ? null : () => _saveTap(context, onSave),
            child: _menuRow(Icons.save_outlined, 'Save', enabled: _saveEnabled),
          ),
          MenuItemButton(
            onPressed: busy ? null : () => _saveTap(context, onSaveNew),
            child: _menuRow(Icons.post_add_outlined, 'Save & new', enabled: _saveEnabled),
          ),
          const SizedBox(height: 6),
          const Divider(height: 1),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            child: _menuSwitch(
              icon: Icons.print_outlined,
              label: 'Print receipt',
              value: printReceipt,
              onChanged: onPrintReceiptChanged,
            ),
          ),
          MenuItemButton(
            onPressed: busy ? null : onViewReceipt,
            child: _menuRow(Icons.receipt_long_outlined, 'View receipt', enabled: !busy),
          ),
          if (onDelete != null) ...[
            const Divider(height: 1),
            MenuItemButton(
              onPressed: busy ? null : onDelete,
              child: _menuRow(Icons.delete_outline, 'Delete', enabled: !busy, danger: true),
            ),
          ],
        ],
        builder: (context, controller, child) => FilledButton.icon(
          onPressed: busy ? null : () => controller.isOpen ? controller.close() : controller.open(),
          icon: busy
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save_outlined, size: 18),
          label: const Text('Save'),
          style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: const Color(0xFF052E1B)),
        ),
      );

  Widget _menuRow(IconData icon, String label, {required bool enabled, bool danger = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: enabled ? (danger ? Colors.redAccent : _muted) : _muted.withValues(alpha: 0.4)),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: enabled ? null : _muted.withValues(alpha: 0.4))),
          ],
        ),
      );

  Widget _menuSwitch({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      Row(
        children: [
          Icon(icon, size: 18, color: _muted),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Switch.adaptive(value: value, onChanged: busy ? null : onChanged),
        ],
      );
}
