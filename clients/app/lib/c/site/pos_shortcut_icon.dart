import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:alienai_c35/c/media/media_disk_cache.dart';
import 'package:alienai_c35/guest_site/guest_site_pic.dart';
import 'package:alienai_c35/widgets/ui/ui_icon.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image/image.dart' as img;

const _iconSize = 192;
const _badgeFrac = 0.38;

/// Launcher / desktop shortcut: site picture with Alien AI badge (bottom-right).
Future<Uint8List> posShortcutCompositeIconPng({
  required String sitePic,
}) async {
  final badge = await _assetImage('assets/icons/app_icon.png');
  final fg = await _siteForeground(sitePic.trim());
  final canvas = img.Image(width: _iconSize, height: _iconSize);
  img.fill(canvas, color: img.ColorRgba8(24, 24, 27, 255));
  if (fg != null) {
    final cover = _coverSquare(fg, _iconSize);
    img.compositeImage(canvas, cover);
  } else {
    img.fill(canvas, color: img.ColorRgba8(39, 39, 42, 255));
  }
  _drawBadge(canvas, badge);
  return Uint8List.fromList(img.encodePng(canvas));
}

/// Windows `.lnk` [IconLocation] expects `.ico`.
Uint8List posShortcutCompositeIconIco(Uint8List pngBytes) {
  final decoded = img.decodeImage(pngBytes);
  if (decoded == null) return pngBytes;
  final s256 = img.copyResize(decoded, width: 256, height: 256);
  return Uint8List.fromList(img.encodeIco(s256));
}

Future<img.Image> _assetImage(String assetPath) async {
  final data = await rootBundle.load(assetPath);
  final decoded = img.decodeImage(data.buffer.asUint8List());
  if (decoded == null) throw StateError('asset image decode failed: $assetPath');
  return decoded;
}

Future<img.Image?> _siteForeground(String sitePic) async {
  final raw = await posShortcutSitePicBytes(sitePic);
  if (raw == null || raw.isEmpty) return null;
  return img.decodeImage(raw);
}

/// Loads site avatar bytes the same way [UiImg] / receipt logo loading does (API + public CDN).
Future<Uint8List?> posShortcutSitePicBytes(String sitePic) async {
  final trimmed = sitePic.trim();
  if (trimmed.isEmpty) return null;
  if (iconifyIdFromPic(trimmed) != null) {
    return _iconifyRasterPng(trimmed, _iconSize);
  }
  Future<Uint8List?> tryFetch(String src) async {
    final file = await mediaDiskCacheFetch(src);
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return bytes.isEmpty ? null : bytes;
  }
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return tryFetch(trimmed);
  }
  if (trimmed.startsWith('/fs/') || trimmed.startsWith('fs/')) {
    final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    final fromApi = await tryFetch(path);
    if (fromApi != null) return fromApi;
    final guest = guestSitePicUrl(path);
    if (guest.isNotEmpty) return tryFetch(guest);
    return null;
  }
  final fromResolve = await tryFetch(trimmed);
  if (fromResolve != null) return fromResolve;
  final guest = guestSitePicUrl(trimmed);
  if (guest.isNotEmpty) return tryFetch(guest);
  return null;
}

Future<Uint8List?> _iconifyRasterPng(String pic, int size) async {
  final svg = await iconSvgStringLoad(pic);
  if (svg == null) return null;
  final loader = SvgStringLoader(svg);
  final pictureInfo = await vg.loadPicture(loader, null);
  final w = pictureInfo.size.width;
  final h = pictureInfo.size.height;
  if (w <= 0 || h <= 0) {
    pictureInfo.picture.dispose();
    return null;
  }
  final scale = size / math.max(w, h);
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.scale(scale);
  canvas.drawPicture(pictureInfo.picture);
  pictureInfo.picture.dispose();
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data?.buffer.asUint8List();
}

img.Image _coverSquare(img.Image src, int size) {
  final scale = math.max(size / src.width, size / src.height);
  final resized = img.copyResize(
    src,
    width: math.max(1, (src.width * scale).round()),
    height: math.max(1, (src.height * scale).round()),
  );
  final x = math.max(0, (resized.width - size) ~/ 2);
  final y = math.max(0, (resized.height - size) ~/ 2);
  return img.copyCrop(resized, x: x, y: y, width: size, height: size);
}

void _drawBadge(img.Image canvas, img.Image badge) {
  final badgeSize = (canvas.width * _badgeFrac).round();
  final resized = img.copyResize(badge, width: badgeSize, height: badgeSize);
  final pad = (canvas.width * 0.04).round();
  final x = canvas.width - badgeSize - pad;
  final y = canvas.height - badgeSize - pad;
  final cx = x + badgeSize / 2;
  final cy = y + badgeSize / 2;
  final ring = badgeSize / 2 + 3;
  img.fillCircle(canvas, x: cx.round(), y: cy.round(), radius: ring.round(), color: img.ColorRgba8(255, 255, 255, 255));
  img.compositeImage(canvas, resized, dstX: x, dstY: y);
}