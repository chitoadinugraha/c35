import 'dart:typed_data';

import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/files/file_path.dart';
import 'package:alienai_c35/widgets/ai/ui_serve_image.dart';
import 'package:flutter/material.dart';

class UiPreviewImage {
  const UiPreviewImage({this.url = '', this.bytes});

  final String url;
  final Uint8List? bytes;

  bool get hasBytes => bytes != null && bytes!.isNotEmpty;
  bool get hasUrl => url.trim().isNotEmpty;
  bool get isValid => hasBytes || hasUrl;
}

class UiPreviewPage extends StatefulWidget {
  const UiPreviewPage({super.key, required this.images, this.initialIndex = 0});

  factory UiPreviewPage.urls(List<String> urls, {Key? key, int initialIndex = 0}) => UiPreviewPage(
        key: key,
        images: [for (final u in urls) UiPreviewImage(url: u)],
        initialIndex: initialIndex,
      );

  final List<UiPreviewImage> images;
  final int initialIndex;

  @override
  State<UiPreviewPage> createState() => _UiPreviewPageState();
}

class _UiPreviewPageState extends State<UiPreviewPage> {
  late final PageController _pageCtrl;
  late int _page;

  List<UiPreviewImage> get _images => widget.images.where((i) => i.isValid).toList();

  @override
  void initState() {
    super.initState();
    final max = _images.isNotEmpty ? _images.length - 1 : 0;
    _page = widget.initialIndex.clamp(0, max);
    _pageCtrl = PageController(initialPage: _page);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _images;
    final base = C35Config.authApiBase.replaceAll(RegExp(r'/+$'), '');
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: items.length > 1 ? Text('${_page + 1} / ${items.length}') : null,
      ),
      body: items.isEmpty
          ? const Center(child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48))
          : PageView.builder(
              controller: _pageCtrl,
              itemCount: items.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) {
                final item = items[i];
                if (item.hasBytes) {
                  return InteractiveViewer(child: Center(child: Image.memory(item.bytes!, fit: BoxFit.contain)));
                }
                final path = item.url.trim();
                final serve = path.startsWith('http') ? path : fileServeUrl(path, baseUrl: base);
                return InteractiveViewer(
                  child: Center(
                    child: UiServeImage(path: serve.startsWith('http') ? serve : path, fit: BoxFit.contain),
                  ),
                );
              },
            ),
    );
  }
}

Future<void> showMediaPreview(BuildContext context, List<String> paths, {int initialIndex = 0}) async {
  final urls = paths.where((p) => p.trim().isNotEmpty).toList();
  if (urls.isEmpty) return;
  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => UiPreviewPage.urls(urls, initialIndex: initialIndex),
      fullscreenDialog: true,
    ),
  );
}
