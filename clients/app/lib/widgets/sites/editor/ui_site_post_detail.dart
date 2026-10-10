import 'dart:async';

import 'package:alienai_c35/c/cas/cas_client.dart';
import 'package:alienai_c35/c/files/file_path.dart';
import 'package:alienai_c35/c/media/ask_media.dart';
import 'package:alienai_c35/c/media/media_types.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_post_media.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/io/in_media_list.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_detail_header.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_form.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _postTitleMax = 200;

class UiSitePostDetail extends StatefulWidget {
  const UiSitePostDetail({
    super.key,
    required this.api,
    required this.siteIid,
    required this.post,
    required this.busy,
    required this.onBusy,
    required this.onPostUpdated,
    required this.onDeleted,
  });

  final SiteApi api;
  final int siteIid;
  final SitePost post;
  final bool busy;
  final ValueChanged<bool> onBusy;
  final ValueChanged<SitePost> onPostUpdated;
  final VoidCallback onDeleted;

  @override
  State<UiSitePostDetail> createState() => _UiSitePostDetailState();
}

class _UiSitePostDetailState extends State<UiSitePostDetail> {
  late final _titleCtrl = TextEditingController();
  late final _captionCtrl = TextEditingController();
  late final _bodyCtrl = TextEditingController();
  Timer? _persistTimer;
  var _mediaUploading = false;
  String _localError = '';

  @override
  void initState() {
    super.initState();
    _syncFromPost();
  }

  @override
  void didUpdateWidget(covariant UiSitePostDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ('${oldWidget.post.postId}' != '${widget.post.postId}') {
      _syncFromPost();
    }
  }

  @override
  void dispose() {
    _persistTimer?.cancel();
    _titleCtrl.dispose();
    _captionCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  void _syncFromPost() {
    final p = widget.post;
    _titleCtrl.text = p.title;
    _captionCtrl.text = p.caption;
    _bodyCtrl.text = p.body;
  }

  void _schedulePersist() {
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(milliseconds: 500), () => unawaited(_persistNow()));
  }

  Future<void> _persistNow() async {
    if (_mediaUploading) return;
    widget.onBusy(true);
    try {
      final saved = await widget.api.sitePostPut(widget.siteIid, widget.post);
      widget.onPostUpdated(saved);
      if (mounted) setState(() => _localError = '');
    } catch (e) {
      if (mounted) setState(() => _localError = uiFriendlyError(e));
    } finally {
      widget.onBusy(false);
    }
  }

  void _patch(void Function(SitePost p) fn, {bool debounce = true}) {
    final next = widget.post.clone();
    fn(next);
    if (next.title.length > _postTitleMax) {
      next.title = next.title.substring(0, _postTitleMax);
      _titleCtrl.text = next.title;
    }
    widget.onPostUpdated(next);
    if (debounce) {
      _schedulePersist();
    } else {
      unawaited(_persistNow());
    }
  }

  Future<void> _addImage() async {
    if (_mediaUploading || widget.busy) return;
    final paths = sitePostMediaPaths(widget.post);
    if (paths.length >= sitePostMediaMaxCount) {
      setState(() => _localError = 'Max $sitePostMediaMaxCount images per post');
      return;
    }
    final staged = await askMedia(context: context, types: const [MediaType.image], allowMultiple: false, maxCount: 1);
    if (staged == null || staged.isEmpty) return;
    final file = staged.first;
    if (file.bytes.isEmpty) return;
    setState(() {
      _mediaUploading = true;
      _localError = '';
    });
    widget.onBusy(true);
    try {
      final up = await casUpload(bytes: file.bytes, mime: file.mime, name: file.name);
      if (up == null || up.hash.isEmpty) throw 'Upload failed';
      final path = fileStoragePath(up.hash);
      final withMedia = sitePostWithMedia(widget.post, [...paths, path]);
      final saved = await widget.api.sitePostPut(widget.siteIid, withMedia);
      widget.onPostUpdated(saved);
    } catch (e) {
      if (mounted) setState(() => _localError = uiFriendlyError(e));
    } finally {
      if (mounted) setState(() => _mediaUploading = false);
      widget.onBusy(false);
    }
  }

  void _removeImage(int index) {
    final paths = [...sitePostMediaPaths(widget.post)];
    if (index < 0 || index >= paths.length) return;
    paths.removeAt(index);
    final withMedia = sitePostWithMedia(widget.post, paths);
    widget.onPostUpdated(withMedia);
    unawaited(_persistNow());
  }

  Future<void> _delete() async {
    final postId = widget.post.postId.toInt();
    if (postId <= 0) {
      widget.onDeleted();
      return;
    }
    widget.onBusy(true);
    try {
      await widget.api.sitePostDelete(widget.siteIid, postId);
      widget.onDeleted();
    } catch (e) {
      if (mounted) setState(() => _localError = uiFriendlyError(e));
    } finally {
      widget.onBusy(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final paths = sitePostMediaPaths(post);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        UiSiteCatalogDetailHeader(
          icon: Icons.photo_library_outlined,
          title: 'site.posts.title'.tr(),
          subtitle: 'site.posts.subtitle'.tr(),
          active: post.onStorefront,
          onActiveChanged: (v) => _patch((p) => p.onStorefront = v, debounce: false),
          onDelete: () => unawaited(_delete()),
          deleteConfirmTitle: 'Delete post?',
          deleteConfirmBody: 'This post will be removed from your site hub.',
        ),
        if (_localError.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(_localError, style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
        ],
        const SizedBox(height: 16),
        Text('site.posts.photos'.tr(), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InMediaList(
          paths: paths,
          enabled: !widget.busy && !_mediaUploading,
          maxCount: sitePostMediaMaxCount,
          thumbSize: 56,
          onAdd: () => unawaited(_addImage()),
          onRemove: _removeImage,
        ),
        const SizedBox(height: 4),
        Text('site.posts.imagesOnlyHint'.tr(), style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        UiSiteEditorLabeledField(
          label: 'Title',
          child: TextField(
            controller: _titleCtrl,
            maxLength: _postTitleMax,
            enabled: !widget.busy,
            onChanged: (v) => _patch((p) => p.title = v),
            style: const TextStyle(fontSize: 13, color: siteEditorFormText),
            decoration: siteEditorInputDecoration(hintText: 'Headline'),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('200 characters max', style: TextStyle(color: _muted, fontSize: 11)),
        ),
        UiSiteEditorLabeledField(
          label: 'Caption',
          child: TextField(
            controller: _captionCtrl,
            maxLines: 3,
            enabled: !widget.busy,
            onChanged: (v) => _patch((p) => p.caption = v),
            style: const TextStyle(fontSize: 13, color: siteEditorFormText),
            decoration: siteEditorInputDecoration(hintText: 'Short summary for the hub'),
          ),
        ),
        UiSiteEditorLabeledField(
          label: 'Body',
          child: TextField(
            controller: _bodyCtrl,
            maxLines: 8,
            enabled: !widget.busy,
            onChanged: (v) => _patch((p) => p.body = v),
            style: const TextStyle(fontSize: 13, color: siteEditorFormText),
            decoration: siteEditorInputDecoration(hintText: 'Full story'),
          ),
        ),
      ],
    );
  }
}
