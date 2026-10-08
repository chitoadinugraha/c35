import 'package:alienai_c35/c/cas/cas_client.dart';
import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/media/ask_media.dart';
import 'package:alienai_c35/c/media/media_types.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/ui/ui_img.dart';
import 'package:flutter/material.dart';

/// Face enrollment gallery for one site member (attendance-gated).
///
/// Embeddings may be empty (photos-only fallback until attendance FaceNet ships).
class IoSiteMemberFacePhotos extends StatefulWidget {
  const IoSiteMemberFacePhotos({
    super.key,
    required this.api,
    required this.siteIid,
    required this.granteeIid,
    required this.attendanceEnabled,
  });

  final SiteApi api;
  final int siteIid;
  final int granteeIid;
  final bool attendanceEnabled;

  @override
  State<IoSiteMemberFacePhotos> createState() => _IoSiteMemberFacePhotosState();
}

class _IoSiteMemberFacePhotosState extends State<IoSiteMemberFacePhotos> {
  var _loading = true;
  var _busy = false;
  String _error = '';
  List<SiteMemberFacePhoto> _faces = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant IoSiteMemberFacePhotos oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.granteeIid != widget.granteeIid ||
        oldWidget.siteIid != widget.siteIid ||
        oldWidget.attendanceEnabled != widget.attendanceEnabled) {
      _load();
    }
  }

  Future<void> _load() async {
    if (!widget.attendanceEnabled || widget.granteeIid == 0) {
      setState(() {
        _loading = false;
        _faces = const [];
        _error = '';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final faces = await widget.api.memberFaceList(widget.siteIid, widget.granteeIid);
      if (!mounted) return;
      setState(() {
        _faces = faces;
        _loading = false;
      });
    } catch (e, st) {
      lError(e);
      l(st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = uiFriendlyError(e);
      });
    }
  }

  String _picSrc(SiteMemberFacePhoto face) {
    if (face.url.trim().isNotEmpty) return face.url.trim();
    final h = face.fileHash.trim();
    return h.isEmpty ? '' : '/fs/$h';
  }

  Future<void> _add() async {
    if (_busy || !widget.attendanceEnabled || _faces.length >= 8) return;
    setState(() {
      _busy = true;
      _error = '';
    });
    try {
      final staged = await askMedia(context: context, types: const [MediaType.image], allowMultiple: false, maxCount: 1);
      if (staged == null || staged.isEmpty || !mounted) {
        setState(() => _busy = false);
        return;
      }
      final file = staged.first;
      final up = await casUpload(bytes: file.bytes, mime: file.mime, name: file.name);
      if (up == null || up.hash.isEmpty) throw 'upload failed';
      final face = await widget.api.memberFacePut(widget.siteIid, widget.granteeIid, fileHash: up.hash);
      if (!mounted) return;
      setState(() {
        _faces = [..._faces, face];
        _busy = false;
      });
    } catch (e, st) {
      lError(e);
      l(st);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = uiFriendlyError(e);
      });
    }
  }

  Future<void> _del(SiteMemberFacePhoto face) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = '';
    });
    try {
      await widget.api.memberFaceDel(widget.siteIid, widget.granteeIid, face.id);
      if (!mounted) return;
      setState(() {
        _faces = _faces.where((f) => f.id != face.id).toList();
        _busy = false;
      });
    } catch (e, st) {
      lError(e);
      l(st);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = uiFriendlyError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.attendanceEnabled) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Face photos', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          'Add 2-3 clear photos for attendance face match (different angles / glasses).',
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in _faces)
                SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: UiImg(
                          src: _picSrc(f),
                          fit: BoxFit.cover,
                          fallback: ColoredBox(
                            color: cs.surfaceContainerHigh,
                            child: Icon(Icons.broken_image_outlined, color: cs.onSurfaceVariant),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Material(
                          color: cs.surface.withValues(alpha: 0.85),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _busy ? null : () => _del(f),
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Icon(Icons.close, size: 14, color: cs.error),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_faces.length < 8)
                SizedBox(
                  width: 72,
                  height: 72,
                  child: OutlinedButton(
                    onPressed: _busy ? null : _add,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _busy
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(Icons.add_a_photo_outlined, color: cs.primary),
                  ),
                ),
            ],
          ),
          if (_faces.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('No face photos yet.', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ),
        ],
        if (_error.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error, style: TextStyle(fontSize: 12, color: cs.error)),
          ),
      ],
    );
  }
}
