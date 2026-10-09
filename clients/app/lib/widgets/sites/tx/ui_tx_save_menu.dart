import 'package:alienai_c35/widgets/sites/tx/dialog/transaksi_printer_settings_dialog.dart';
import 'package:flutter/material.dart';

const _accent = Color(0xFF34D399);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);

class UiTxSaveMenu extends StatelessWidget {
  const UiTxSaveMenu({
    super.key,
    required this.onSave,
    required this.onSaveNew,
    required this.onViewReceipt,
    required this.printReceipt,
    required this.onPrintReceiptChanged,
    required this.showTrackingQrOnReceipt,
    required this.onShowTrackingQrOnReceiptChanged,
    this.onPrinterSettings,
    this.onDelete,
    this.onHold,
    this.canHold = false,
    this.canSave = true,
    this.saveBlockReason,
    this.busy = false,
    this.posShell = false,
  });

  final VoidCallback onSave;
  final VoidCallback onSaveNew;
  final VoidCallback onViewReceipt;
  final bool printReceipt;
  final ValueChanged<bool> onPrintReceiptChanged;
  final bool showTrackingQrOnReceipt;
  final ValueChanged<bool> onShowTrackingQrOnReceiptChanged;
  final VoidCallback? onPrinterSettings;
  final VoidCallback? onDelete;
  final VoidCallback? onHold;
  final bool canHold;
  final bool canSave;
  final String? saveBlockReason;
  final bool busy;
  final bool posShell;

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
          if (!posShell) ...[
            MenuItemButton(
              onPressed: busy ? null : () => _saveTap(context, onSave),
              child: _menuRow(Icons.save_outlined, 'Save', enabled: _saveEnabled),
            ),
            MenuItemButton(
              onPressed: busy ? null : () => _saveTap(context, onSaveNew),
              child: _menuRow(Icons.post_add_outlined, 'Save & new', enabled: _saveEnabled),
            ),
          ],
          if (onHold != null) ...[
            MenuItemButton(
              onPressed: (busy || !canHold) ? null : onHold,
              child: _menuRow(Icons.pause_circle_outline, 'Hold order', enabled: canHold && !busy),
            ),
            const SizedBox(height: 6),
            const Divider(height: 1),
            const SizedBox(height: 6),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _menuSwitch(
              icon: Icons.print_outlined,
              label: 'Print Receipt',
              value: printReceipt,
              onChanged: onPrintReceiptChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _menuSwitch(
              icon: Icons.qr_code_2_outlined,
              label: 'Show Tracking QR on Receipt',
              value: showTrackingQrOnReceipt,
              onChanged: onShowTrackingQrOnReceiptChanged,
            ),
          ),
          if (!posShell)
            MenuItemButton(
              onPressed: busy ? null : onViewReceipt,
              child: _menuRow(Icons.receipt_long_outlined, 'View receipt', enabled: !busy),
            ),
          MenuItemButton(
            onPressed: busy
                ? null
                : (onPrinterSettings ?? () => showTransaksiPrinterSettingsDialog(context: context)),
            child: _menuRow(Icons.settings_outlined, 'Printer settings', enabled: !busy),
          ),
          if (onDelete != null) ...[
            const Divider(height: 1),
            MenuItemButton(
              onPressed: busy ? null : onDelete,
              child: _menuRow(Icons.delete_outline, 'Delete', enabled: !busy, danger: true),
            ),
          ],
        ],
        builder: (context, controller, child) => posShell
            ? IconButton(
                tooltip: 'More',
                onPressed: busy ? null : () => controller.isOpen ? controller.close() : controller.open(),
                icon: busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _muted))
                    : const Icon(Icons.more_vert, color: _text),
              )
            : FilledButton.icon(
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: _muted),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, height: 1.2))),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            onChanged: busy ? null : onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      );
}
