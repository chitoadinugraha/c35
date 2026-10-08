import 'dart:async';

import 'package:alienai_c35/c/cas/cas_client.dart';
import 'package:alienai_c35/c/files/file_path.dart';
import 'package:alienai_c35/c/media/ask_media.dart';
import 'package:alienai_c35/c/media/media_types.dart';
import 'package:alienai_c35/c/pb/c35/identity.pb.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_info_sync.dart';
import 'package:alienai_c35/c/site/site_schedule.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/io/in_site_location.dart';
import 'package:alienai_c35/widgets/io/in_site_schedule.dart';
import 'package:alienai_c35/widgets/sites/editor/site_editor_save_scope.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'package:alienai_c35/guest_site/guest_site_pic.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);
const _taglineMax = 120;

class UiSiteInfoEditor extends StatefulWidget {
  const UiSiteInfoEditor({
    super.key,
    required this.row,
    required this.api,
    required this.siteIid,
    required this.onRowChanged,
    this.onDraftSaved,
  });

  final SiteRow row;
  final SiteApi api;
  final int siteIid;
  final ValueChanged<SiteRow> onRowChanged;
  final VoidCallback? onDraftSaved;

  @override
  State<UiSiteInfoEditor> createState() => _UiSiteInfoEditorState();
}

class _UiSiteInfoEditorState extends State<UiSiteInfoEditor> {
  late final _nameCtrl = TextEditingController(text: widget.row.name);
  late final _handleCtrl = TextEditingController(text: widget.row.alienId);
  late final _taglineCtrl = TextEditingController();
  late final _locationCtrl = TextEditingController();
  var _loading = true;
  var _taglinePick = 0;
  var _pic = '';
  double? _lat;
  double? _lng;
  List<SiteScheduleSlot> _hours = [];
  Timer? _saveTimer;
  var _suppressSave = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_scheduleSave);
    _handleCtrl.addListener(_scheduleSave);
    _taglineCtrl.addListener(_scheduleSave);
    _locationCtrl.addListener(_scheduleSave);
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant UiSiteInfoEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.row.siteIid != widget.row.siteIid) {
      _nameCtrl.text = widget.row.name;
      _handleCtrl.text = widget.row.alienId;
      _pic = widget.row.pic;
      unawaited(_load());
    } else if (oldWidget.row.name != widget.row.name || oldWidget.row.alienId != widget.row.alienId || oldWidget.row.pic != widget.row.pic) {
      _suppressSave = true;
      _nameCtrl.text = widget.row.name;
      _handleCtrl.text = widget.row.alienId;
      _pic = widget.row.pic;
      _suppressSave = false;
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _nameCtrl.dispose();
    _handleCtrl.dispose();
    _taglineCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final draft = await widget.api.draftGet(widget.siteIid);
      final meta = draft.doc.metaJson;
      _taglineCtrl.text = siteMetaTaglineRead(meta);
      _hours = siteScheduleSlotsFromMetaJson(meta);
      siteMetaLocationRead(meta, (label, href, lat, lng) {
        _locationCtrl.text = label;
        _lat = lat;
        _lng = lng;
      });
      _pic = widget.row.pic;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scheduleSave() {
    if (_loading || _suppressSave) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () => unawaited(_save()));
  }

  void _generateTagline() {
    _taglinePick++;
    _taglineCtrl.text = siteTaglineSuggest(name: _nameCtrl.text, locale: 'id', pick: _taglinePick);
    _scheduleSave();
  }

  SiteInfoSnapshot _snapshot() {
    final label = _locationCtrl.text.trim();
    return SiteInfoSnapshot(
      name: _nameCtrl.text.trim(),
      tagline: _taglineCtrl.text.trim(),
      pic: _pic,
      locationLabel: label,
      locationHref: siteLocationHrefBuild(label: label, lat: _lat, lng: _lng),
      latitude: _lat,
      longitude: _lng,
      openHours: _hours,
    );
  }

  Future<void> _save() async {
    await SiteEditorSaveScope.run(context, () async {
      final name = _nameCtrl.text.trim();
      final handle = siteAlienIdSlug(_handleCtrl.text);
      if (name.isNotEmpty && name != widget.row.name) {
        final res = await widget.api.conn.identityPut(ReqIdentityPut(
          iid: widget.row.siteIid,
          kind: 'site',
          name: name,
          pic: _pic,
          alienId: widget.row.alienId,
        ));
        if (res.hasRow()) {
          final next = widget.row.clone()..name = res.row.identity.name;
          widget.onRowChanged(next);
        }
      }
      if (handle.isNotEmpty && handle != widget.row.alienId) {
        final err = siteHandleFormatError(handle);
        if (err != null) throw err;
        final res = await widget.api.handlePut(widget.siteIid, handle);
        final next = widget.row.clone()..alienId = res.alienId;
        widget.onRowChanged(next);
      }
      final draft = await widget.api.draftGet(widget.siteIid);
      final next = draft.clone();
      next.doc = siteInfoApplyToDoc(draft.doc, _snapshot());
      await widget.api.draftPut(next);
      widget.onDraftSaved?.call();
    });
  }

  Future<void> _pickAvatar() async {
    final staged = await askMedia(context: context, types: const [MediaType.image], allowMultiple: false, maxCount: 1);
    if (staged == null || staged.isEmpty) return;
    final file = staged.first;
    final up = await casUpload(bytes: file.bytes, mime: file.mime, name: file.name);
    if (up == null || up.hash.isEmpty) return;
    if (!mounted) return;
    final pic = fileStoragePath(up.hash);
    await SiteEditorSaveScope.run(context, () async {
      final res = await widget.api.conn.identityPut(ReqIdentityPut(
        iid: widget.row.siteIid,
        kind: 'site',
        name: widget.row.name,
        pic: pic,
        alienId: widget.row.alienId,
      ));
      if (res.hasRow()) {
        setState(() => _pic = pic);
        widget.onRowChanged(widget.row.clone()..pic = pic);
        final draft = await widget.api.draftGet(widget.siteIid);
        final next = draft.clone();
        next.doc = siteInfoApplyToDoc(draft.doc, _snapshot());
        await widget.api.draftPut(next);
        widget.onDraftSaved?.call();
      }
    });
  }

  InputDecoration _fieldDecoration(String label, {Widget? suffixIcon}) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _muted, fontSize: 13),
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: _border)),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: _accent)),
        suffixIcon: suffixIcon,
      );

  Widget _skeletonField() => Container(
        height: 48,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: _border.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(8)),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return UiSiteEditorFormScroll(
        children: [
          const Text('Site info', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          for (var i = 0; i < 5; i++) _skeletonField(),
        ],
      );
    }
    final picUrl = _pic.isNotEmpty ? guestSitePicUrl(_pic) : '';
    return UiSiteEditorFormScroll(
      children: [
        const Text('Site info', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text('Page title uses site name and tagline automatically.', style: TextStyle(color: _muted, fontSize: 12)),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: _pickAvatar,
              customBorder: const CircleBorder(),
              child: CircleAvatar(
                radius: 32,
                backgroundColor: _border,
                backgroundImage: picUrl.isNotEmpty ? NetworkImage(picUrl) : null,
                child: picUrl.isEmpty ? const Icon(Icons.storefront_outlined, color: _muted) : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                children: [
                  TextField(controller: _nameCtrl, style: const TextStyle(color: _text, fontSize: 14), decoration: _fieldDecoration('Site name')),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _handleCtrl,
                    style: const TextStyle(color: _text, fontSize: 14),
                    decoration: _fieldDecoration('Alien ID', suffixIcon: const Padding(padding: EdgeInsets.only(top: 12), child: Text('@', style: TextStyle(color: _muted)))),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_-]')),
                      TextInputFormatter.withFunction((old, neu) => neu.copyWith(text: neu.text.toLowerCase())),
                    ],
                  ),
                  if (_handleCtrl.text.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('$siteUrlPrefix${siteAlienIdSlug(_handleCtrl.text)}', style: const TextStyle(color: _muted, fontSize: 11)),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _taglineCtrl,
          style: const TextStyle(color: _text, fontSize: 14),
          maxLength: _taglineMax,
          maxLines: 3,
          decoration: _fieldDecoration(
            'Tagline',
            suffixIcon: IconButton(
              tooltip: 'Generate tagline',
              onPressed: _generateTagline,
              icon: const Icon(Icons.auto_awesome, size: 20, color: _accent),
            ),
          ),
        ),
        const SizedBox(height: 12),
        InSiteLocation(
          controller: _locationCtrl,
          onChanged: _scheduleSave,
          onDevicePick: (lat, lng, label) {
            _lat = lat;
            _lng = lng;
            _scheduleSave();
          },
        ),
        const SizedBox(height: 16),
        InSiteSchedule(
          slots: _hours,
          onChanged: (v) {
            setState(() => _hours = v);
            _scheduleSave();
          },
        ),
      ],
    );
  }
}
