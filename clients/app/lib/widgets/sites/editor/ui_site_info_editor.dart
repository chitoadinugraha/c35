import 'dart:async';
import 'dart:typed_data';

import 'package:alienai_c35/c/cas/cas_client.dart';
import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/files/file_path.dart';
import 'package:alienai_c35/c/geo/geo_geocode.dart';
import 'package:alienai_c35/c/media/ask_media.dart';
import 'package:alienai_c35/c/media/image_generate_prompt.dart';
import 'package:alienai_c35/c/media/media_types.dart';
import 'package:alienai_c35/c/pb/c35/identity.pb.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/platform_site.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_info_sync.dart';
import 'package:alienai_c35/c/site/site_schedule.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/ai/ui_alien_icon.dart';
import 'package:alienai_c35/widgets/io/in_geo_point.dart';
import 'package:alienai_c35/widgets/io/in_site_schedule.dart';
import 'package:alienai_c35/widgets/media/ui_ask_image_generate.dart';
import 'package:alienai_c35/widgets/sites/editor/site_editor_save_scope.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'package:alienai_c35/widgets/sites/io_site_handle_claim_dialog.dart';
import 'package:alienai_c35/widgets/ui/ui_img.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);
const _taglineMax = 120;
const _sheetBg = Color(0xFF18181B);

enum _AvatarChoice { upload, generate }

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
  late final _taglineCtrl = TextEditingController();
  var _loading = true;
  var _taglinePick = 0;
  var _pic = '';
  Uint8List? _picPreviewBytes;
  var _picUploading = false;
  var _locationLabel = '';
  double? _lat;
  double? _lng;
  List<SiteScheduleSlot> _hours = [];
  Timer? _saveTimer;
  var _suppressSave = false;

  String get _geoBaseUrl => C35Config.authApiBase.replaceAll(RegExp(r'/+$'), '');

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_scheduleSave);
    _taglineCtrl.addListener(_scheduleSave);
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant UiSiteInfoEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.row.siteIid != widget.row.siteIid) {
      _nameCtrl.text = widget.row.name;
      _pic = widget.row.pic;
      _picPreviewBytes = null;
      _picUploading = false;
      unawaited(_load());
    } else if (oldWidget.row.name != widget.row.name || oldWidget.row.alienId != widget.row.alienId || oldWidget.row.pic != widget.row.pic) {
      _suppressSave = true;
      _nameCtrl.text = widget.row.name;
      _pic = widget.row.pic;
      _suppressSave = false;
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _nameCtrl.dispose();
    _taglineCtrl.dispose();
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
        _locationLabel = label;
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

  SiteInfoSnapshot _snapshot() => SiteInfoSnapshot(
        name: _nameCtrl.text.trim(),
        tagline: _taglineCtrl.text.trim(),
        pic: _pic,
        locationLabel: _locationLabel.trim(),
        locationHref: siteLocationHrefBuild(label: _locationLabel.trim(), lat: _lat, lng: _lng),
        latitude: _lat,
        longitude: _lng,
        openHours: _hours,
      );

  Future<void> _save() async {
    await SiteEditorSaveScope.run(context, () async {
      final name = _nameCtrl.text.trim();
      if (name.isNotEmpty && name != widget.row.name) {
        final res = await widget.api.conn.identityPut(ReqIdentityPut(
          iid: widget.row.siteIid,
          kind: 'site',
          name: name,
          pic: _pic,
          alienId: widget.row.alienId,
        ));
        if (res.hasRow()) {
          widget.onRowChanged(widget.row.clone()..name = res.row.identity.name);
        }
      }
      final draft = await widget.api.draftGet(widget.siteIid);
      final next = draft.clone();
      next.doc = siteInfoApplyToDoc(draft.doc, _snapshot());
      await widget.api.draftPut(next);
      widget.onDraftSaved?.call();
    });
  }

  Future<void> _changeHandle() async {
    if (isPlatformSiteAlienId(widget.row.alienId)) return;
    final hasHandle = widget.row.alienId.trim().isNotEmpty;
    final picked = await ioSiteHandleClaimDialogOpen(
      context,
      siteName: _nameCtrl.text.trim().isEmpty ? widget.row.name : _nameCtrl.text.trim(),
      initialHandle: hasHandle ? widget.row.alienId : siteAlienIdSlug(_nameCtrl.text),
      isChange: hasHandle,
    );
    if (picked == null || picked.isEmpty || picked == widget.row.alienId) return;
    await SiteEditorSaveScope.run(context, () async {
      final res = await widget.api.handlePut(widget.siteIid, picked);
      widget.onRowChanged(widget.row.clone()..alienId = res.alienId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Handle updated: @$siteUrlPrefix${res.alienId}'), behavior: SnackBarBehavior.floating),
      );
    });
  }

  Future<void> _chooseAvatar() async {
    final choice = await showModalBottomSheet<_AvatarChoice>(
      context: context,
      backgroundColor: _sheetBg,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.upload_outlined, color: _text),
              title: const Text('Upload', style: TextStyle(color: _text)),
              onTap: () => Navigator.pop(ctx, _AvatarChoice.upload),
            ),
            ListTile(
              leading: const UiAlienIcon(size: 24, color: _text),
              title: const Text('Generate', style: TextStyle(color: _text)),
              onTap: () => Navigator.pop(ctx, _AvatarChoice.generate),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case _AvatarChoice.upload:
        await _pickAvatar();
      case _AvatarChoice.generate:
        await _generateAvatar();
    }
  }

  Future<void> _commitPic(String pic) async {
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

  Future<void> _pickAvatar() async {
    try {
      final staged = await askMedia(context: context, types: const [MediaType.image], allowMultiple: false, maxCount: 1);
      if (staged == null || staged.isEmpty) return;
      final file = staged.first;
      if (file.bytes.isEmpty) return;
      setState(() {
        _picPreviewBytes = Uint8List.fromList(file.bytes);
        _picUploading = true;
      });
      final up = await casUpload(bytes: file.bytes, mime: file.mime, name: file.name);
      if (up == null || up.hash.isEmpty) {
        if (mounted) setState(() => _picUploading = false);
        return;
      }
      if (!mounted) return;
      await _commitPic(fileStoragePath(up.hash));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _picUploading = false);
    }
  }

  Future<void> _generateAvatar() async {
    final result = await askImageGenerate(
      context,
      conn: widget.api.conn,
      slot: ImageGenerateSlot.siteIcon,
      name: _nameCtrl.text,
      desc: _taglineCtrl.text,
    );
    if (result == null || result.hash.isEmpty || !mounted) return;
    setState(() => _picUploading = true);
    try {
      await _commitPic(fileStoragePath(result.hash));
    } finally {
      if (mounted) setState(() => _picUploading = false);
    }
  }

  static const _avatarRadius = 32.0;

  Widget _avatarPlaceholder() => const Icon(Icons.storefront_outlined, color: _muted, size: 28);

  Widget _avatarImage() {
    final side = _avatarRadius * 2;
    if (_picPreviewBytes != null && _picPreviewBytes!.isNotEmpty) {
      return Image.memory(_picPreviewBytes!, width: side, height: side, fit: BoxFit.cover);
    }
    if (_pic.isNotEmpty) {
      return UiImg(
        src: _pic,
        width: side,
        height: side,
        fit: BoxFit.cover,
        fallback: _avatarPlaceholder(),
      );
    }
    return ColoredBox(
      color: _border,
      child: Center(child: _avatarPlaceholder()),
    );
  }

  Widget _siteAvatar() {
    final side = _avatarRadius * 2;
    final ring = _picUploading ? 3.0 : 0.0;
    return InkWell(
      onTap: _picUploading ? null : () => unawaited(_chooseAvatar()),
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: side + ring * 2,
        height: side + ring * 2,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_picUploading)
              SizedBox(
                width: side + ring * 2,
                height: side + ring * 2,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: _accent),
              ),
            ClipOval(child: SizedBox(width: side, height: side, child: _avatarImage())),
          ],
        ),
      ),
    );
  }

  void _onLocationChanged(GeoPointValue v) {
    setState(() {
      _locationLabel = v.label;
      _lat = v.latitude;
      _lng = v.longitude;
    });
    _scheduleSave();
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
    final handle = widget.row.alienId.trim();
    final platformHome = isPlatformSiteAlienId(handle);
    final handlePreview = platformHome
        ? 'alienai.id/alienai is not the public home — the public home is https://alienai.id/.'
        : (handle.isNotEmpty ? '$siteUrlPrefix$handle' : 'Tap to claim your site link');
    return UiSiteEditorFormScroll(
      children: [
        const Text('Site info', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text('Page title uses site name and tagline automatically.', style: TextStyle(color: _muted, fontSize: 12)),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _siteAvatar(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                children: [
                  TextField(controller: _nameCtrl, style: const TextStyle(color: _text, fontSize: 14), decoration: _fieldDecoration('Site name')),
                  const SizedBox(height: 12),
                  platformHome
                      ? InputDecorator(
                          decoration: UiInputDecoration.of(context, labelText: 'Site link'),
                          child: Text(
                            handlePreview,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, color: _text),
                          ),
                        )
                      : InkWell(
                          onTap: () => unawaited(_changeHandle()),
                          borderRadius: BorderRadius.circular(UiInputDecoration.kRadius),
                          child: InputDecorator(
                            decoration: UiInputDecoration.of(context, labelText: 'Site link'),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    handlePreview,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: handle.isNotEmpty ? _text : _muted,
                                    ),
                                  ),
                                ),
                                Icon(Icons.chevron_right, size: 20, color: _muted.withValues(alpha: 0.7)),
                              ],
                            ),
                          ),
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
        InGeoPoint(
          baseUrl: _geoBaseUrl,
          locationLabel: _locationLabel,
          latitude: _lat,
          longitude: _lng,
          onChanged: _onLocationChanged,
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
