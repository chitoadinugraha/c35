import 'dart:async';
import 'dart:io';

import 'package:alienai_c35/c/media/media_disk_cache.dart';
import 'package:flutter/material.dart';

class UiImgCached extends StatefulWidget {
  const UiImgCached({
    super.key,
    required this.src,
    required this.networkUrl,
    this.headers,
    this.fallback,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  final String src;
  final String networkUrl;
  final Map<String, String>? headers;
  final Widget? fallback;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  State<UiImgCached> createState() => _UiImgCachedState();
}

class _UiImgCachedState extends State<UiImgCached> {
  File? _file;
  var _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_resolve());
  }

  @override
  void didUpdateWidget(covariant UiImgCached oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.networkUrl != widget.networkUrl) {
      _file = null;
      _failed = false;
      unawaited(_resolve());
    }
  }

  Future<void> _resolve() async {
    final file = await mediaDiskCacheFetch(widget.src, headers: widget.headers);
    if (!mounted) return;
    setState(() {
      _file = file;
      _failed = file == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fb = widget.fallback ?? const SizedBox.shrink();
    final file = _file;
    if (file != null) {
      return Image.file(
        file,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        errorBuilder: (_, __, ___) => _networkFallback(fb),
      );
    }
    if (_failed) return _networkFallback(fb);
    return SizedBox(width: widget.width, height: widget.height, child: fb);
  }

  Widget _networkFallback(Widget fb) => Image.network(
        widget.networkUrl,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        headers: widget.headers,
        loadingBuilder: (_, child, progress) => progress == null ? child : fb,
        errorBuilder: (_, __, ___) => fb,
      );
}
