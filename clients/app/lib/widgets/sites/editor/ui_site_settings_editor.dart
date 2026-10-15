import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_table_rows.dart';
import 'package:alienai_c35/widgets/settings/ui_scope_instruction_editor.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

class UiSiteSettingsEditor extends StatefulWidget {
  const UiSiteSettingsEditor({
    super.key,
    required this.row,
    required this.api,
    required this.siteIid,
    this.onCapabilitiesSaved,
    this.onOpenPublish,
  });

  final SiteRow row;
  final SiteApi api;
  final int siteIid;
  final Future<void> Function()? onCapabilitiesSaved;
  final VoidCallback? onOpenPublish;

  @override
  State<UiSiteSettingsEditor> createState() => _UiSiteSettingsEditorState();
}

class _UiSiteSettingsEditorState extends State<UiSiteSettingsEditor> {
  var _loading = true;
  var _savingCaps = false;
  Map<String, bool> _caps = Map<String, bool>.from(siteCapabilityDefaults);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final config = await widget.api.configGet(widget.siteIid);
      _caps = siteCapabilitiesParse(config.capabilitiesJson);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveCapability(String key, bool value) async {
    if (_savingCaps) return;
    setState(() {
      _savingCaps = true;
      var next = {..._caps, key: value};
      if (key == 'commerce' && !value) {
        next['order_fulfillment'] = false;
      }
      _caps = next;
    });
    try {
      await widget.api.configPut(widget.siteIid, capabilitiesJson: siteCapabilitiesEncode(_caps));
      await widget.onCapabilitiesSaved?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating),
        );
      }
      await _load();
    } finally {
      if (mounted) setState(() => _savingCaps = false);
    }
  }

  Widget _capToggle(String key, String label) => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: const TextStyle(color: _text, fontSize: 14)),
        value: _caps[key] ?? siteCapabilityDefault(key),
        activeThumbColor: _accent,
        onChanged: _savingCaps ? null : (v) => _saveCapability(key, v),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)));
    }
    return Material(
      color: Colors.transparent,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Capabilities', style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('Enable backend features for this site.', style: TextStyle(color: _muted, fontSize: 12)),
          _capToggle('commerce', 'Commerce (Orders & Products)'),
          SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Member portal', style: TextStyle(color: _text, fontSize: 14)),
          subtitle: const Text(
            'Customer sign-in and order history on the guest site.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          value: _caps['member_portal'] ?? siteMemberPortalFromJson(Map<dynamic, dynamic>.from(_caps)),
          activeThumbColor: _accent,
          onChanged: (_savingCaps || !(_caps['commerce'] ?? true))
              ? null
              : (v) => _saveCapability('member_portal', v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Order processing (kitchen)', style: TextStyle(color: _text, fontSize: 14)),
          subtitle: const Text(
            'Kitchen queue and guest “being prepared” status. Cashier-only: leave off.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          value: siteOrderFulfillmentEnabled(_caps),
          activeThumbColor: _accent,
          onChanged: (_savingCaps || !(_caps['commerce'] ?? true))
              ? null
              : (v) => _saveCapability('order_fulfillment', v),
        ),
        _capToggle('booking', 'Booking (Objects tab)'),
        _capToggle('queue', 'Queue blocks'),
        _capToggle('attendance', 'Attendance (face enroll on Team)'),
        const SizedBox(height: 28),
        const Text('Assistant', style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        const Text(
          'Instructions for Home chat when this site is in scope (@mention or resolved context).',
          style: TextStyle(color: _muted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF0C0C0E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF27272A)),
          ),
          child: UiScopeInstructionEditor(
            conn: widget.api.conn,
            scopeKind: 'site',
            scopeIid: widget.siteIid,
            title: 'Site instructions',
            subtitle: null,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          ),
        ),
        if (widget.onOpenPublish != null) ...[
          const SizedBox(height: 28),
          Text('site.domain.sectionTitle'.tr(), style: const TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('site.domain.movedToPublish'.tr(), style: const TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: widget.onOpenPublish,
            child: Text('site.domain.openPublish'.tr()),
          ),
        ],
      ],
      ),
    );
  }
}
