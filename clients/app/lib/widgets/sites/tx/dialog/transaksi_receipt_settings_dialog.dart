import 'package:alienai_c35/c/hardware/thermal_printer_manager.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_config_of.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

Future<bool?> showTransaksiReceiptSettingsDialog({
  required BuildContext context,
  required SiteApi siteApi,
  required int siteIid,
  SiteRow? site,
  required String capabilitiesJson,
}) =>
    showDialog<bool>(
      context: context,
      builder: (ctx) => TransaksiReceiptSettingsDialog(
        siteApi: siteApi,
        siteIid: siteIid,
        site: site,
        capabilitiesJson: capabilitiesJson,
      ),
    );

class TransaksiReceiptSettingsDialog extends StatefulWidget {
  const TransaksiReceiptSettingsDialog({
    super.key,
    required this.siteApi,
    required this.siteIid,
    this.site,
    required this.capabilitiesJson,
  });

  final SiteApi siteApi;
  final int siteIid;
  final SiteRow? site;
  final String capabilitiesJson;

  @override
  State<TransaksiReceiptSettingsDialog> createState() => _TransaksiReceiptSettingsDialogState();
}

class _TransaksiReceiptSettingsDialogState extends State<TransaksiReceiptSettingsDialog> {
  late final TextEditingController _headerCtrl;
  late final TextEditingController _footerCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _contactCtrl;
  late int _marginMm;
  late int _paperWidthMm;
  late int _logoSizePx;
  late bool _progressTrackingQr;
  late bool _showSiteName;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final fromCaps = receiptConfigOf(
      widget.site,
      config: SiteConfig(capabilitiesJson: widget.capabilitiesJson),
    );
    _headerCtrl = TextEditingController(text: fromCaps.receiptHeader);
    _footerCtrl = TextEditingController(text: fromCaps.receiptFooter);
    _addressCtrl = TextEditingController(text: fromCaps.projectAddress);
    _contactCtrl = TextEditingController(text: fromCaps.projectContact);
    _marginMm = fromCaps.marginMm;
    _paperWidthMm = fromCaps.paperWidthMm;
    _logoSizePx = fromCaps.logoSizePx;
    _progressTrackingQr = fromCaps.showQrLink;
    _showSiteName = fromCaps.showSiteName;
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _footerCtrl.dispose();
    _addressCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final nextJson = capabilitiesJsonSetReceipt(
        capabilitiesJson: widget.capabilitiesJson,
        header: _headerCtrl.text.trim(),
        footer: _footerCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        contact: _contactCtrl.text.trim(),
        showQrLink: _progressTrackingQr,
        showSiteName: _showSiteName,
        marginMm: _marginMm,
        paperWidthMm: _paperWidthMm,
        logoSizePx: _logoSizePx,
      );
      await widget.siteApi.configPut(widget.siteIid, capabilitiesJson: nextJson);

      final mgr = ThermalPrinterManager.instance;
      mgr.paperWidth = _paperWidthMm == 58 ? 32 : 48;
      await mgr.save();

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('Receipt settings', style: TextStyle(color: _text)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 0, 0),
        content: SizedBox(
          width: 420,
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(right: 24, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _toggle(
                    title: 'Show Progress Tracking QR',
                    subtitle: 'Order tracking QR on printed receipt',
                    value: _progressTrackingQr,
                    onChanged: (v) => setState(() => _progressTrackingQr = v),
                  ),
                  const SizedBox(height: 4),
                  _toggle(
                    title: 'Show Site Name',
                    subtitle: 'Store name on printed receipt',
                    value: _showSiteName,
                    onChanged: (v) => setState(() => _showSiteName = v),
                  ),
                  const SizedBox(height: 16),
                  _field('Header', _headerCtrl, maxLines: 2, hint: 'Text above store name'),
                  const SizedBox(height: 12),
                  _field('Footer', _footerCtrl, maxLines: 2, hint: 'Thank-you line at bottom'),
                  const SizedBox(height: 12),
                  _field('Address', _addressCtrl, maxLines: 2),
                  const SizedBox(height: 12),
                  _field('Contact', _contactCtrl, hint: 'Phone or WhatsApp'),
                  const SizedBox(height: 16),
                  Text('Paper width', style: const TextStyle(color: _muted, fontSize: 12)),
                  const SizedBox(height: 8),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 58, label: Text('58 mm')),
                      ButtonSegment(value: 80, label: Text('80 mm')),
                    ],
                    selected: {_paperWidthMm},
                    onSelectionChanged: (s) => setState(() => _paperWidthMm = s.first),
                    style: ButtonStyle(
                      foregroundColor: WidgetStateProperty.resolveWith(
                        (s) => s.contains(WidgetState.selected) ? const Color(0xFF052E1B) : _text,
                      ),
                      backgroundColor: WidgetStateProperty.resolveWith(
                        (s) => s.contains(WidgetState.selected) ? _accent : _border,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: Text('Margin ($_marginMm mm)', style: const TextStyle(color: _text, fontSize: 14))),
                    ],
                  ),
                  Slider(
                    value: _marginMm.toDouble(),
                    min: 0,
                    max: 20,
                    divisions: 20,
                    label: '$_marginMm mm',
                    activeColor: _accent,
                    onChanged: (v) => setState(() => _marginMm = v.round()),
                  ),
                  Row(
                    children: [
                      Expanded(child: Text('Logo size (${_logoSizePx}px)', style: const TextStyle(color: _text, fontSize: 14))),
                    ],
                  ),
                  Slider(
                    value: _logoSizePx.toDouble(),
                    min: 40,
                    max: 96,
                    divisions: 14,
                    label: '${_logoSizePx}px',
                    activeColor: _accent,
                    onChanged: (v) => setState(() => _logoSizePx = v.round()),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: _saving ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: const Color(0xFF052E1B)),
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      );

  Widget _toggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: const TextStyle(color: _text, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)),
        value: value,
        activeThumbColor: _accent,
        onChanged: _saving ? null : onChanged,
      );

  Widget _field(String label, TextEditingController ctrl, {int maxLines = 1, String? hint}) => TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: _text),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: _muted),
          hintStyle: TextStyle(color: _muted.withValues(alpha: 0.7)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _accent)),
        ),
      );
}
