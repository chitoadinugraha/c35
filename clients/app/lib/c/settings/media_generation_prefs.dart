import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Client default for image / video / music generation provider.
/// Values: auto | gemini | grok | seedance | minimax | elevenlabs
class MediaGenerationPrefs extends ChangeNotifier {
  MediaGenerationPrefs._();

  static final MediaGenerationPrefs instance = MediaGenerationPrefs._();

  static const auto = 'auto';
  static const gemini = 'gemini';
  static const grok = 'grok';
  static const seedance = 'seedance';
  static const minimax = 'minimax';
  static const elevenlabs = 'elevenlabs';

  static const _keyImage = 'media_gen_image';
  static const _keyVideo = 'media_gen_video';
  static const _keyMusic = 'media_gen_music';

  static const imageProviders = [auto, gemini, grok];
  static const videoProviders = [auto, gemini, seedance];
  static const musicProviders = [auto, gemini, minimax, elevenlabs];

  SharedPreferences? _prefs;
  var _image = auto;
  var _video = auto;
  var _music = auto;

  String get image => _image;
  String get video => _video;
  String get music => _music;

  String get generationImageWire => _normalize(_image, imageProviders);
  String get generationVideoWire => _normalize(_video, videoProviders);
  String get generationMusicWire => _normalize(_music, musicProviders);

  static String _normalize(String value, List<String> allowed) {
    final v = value.trim().toLowerCase();
    return allowed.contains(v) ? v : auto;
  }

  static List<String> providersForKind(String kind) => switch (kind) {
        'video' => videoProviders,
        'music' => musicProviders,
        _ => imageProviders,
      };

  String defaultForKind(String kind) => switch (kind) {
        'video' => _normalize(_video, videoProviders),
        'music' => _normalize(_music, musicProviders),
        _ => _normalize(_image, imageProviders),
      };

  Future<void> load() async {
    _prefs ??= await SharedPreferences.getInstance();
    _image = _normalize(_prefs!.getString(_keyImage) ?? auto, imageProviders);
    _video = _normalize(_prefs!.getString(_keyVideo) ?? auto, videoProviders);
    _music = _normalize(_prefs!.getString(_keyMusic) ?? auto, musicProviders);
    notifyListeners();
  }

  Future<void> setImage(String value) => _put(kind: 'image', value: value);
  Future<void> setVideo(String value) => _put(kind: 'video', value: value);
  Future<void> setMusic(String value) => _put(kind: 'music', value: value);

  Future<void> setDefaultForKind(String kind, String provider) => _put(kind: kind, value: provider);

  Future<void> _put({required String kind, required String value}) async {
    final allowed = providersForKind(kind);
    final next = _normalize(value, allowed);
    final changed = switch (kind) {
      'video' => _video != next,
      'music' => _music != next,
      _ => _image != next,
    };
    if (!changed) return;
    switch (kind) {
      case 'video':
        _video = next;
      case 'music':
        _music = next;
      default:
        _image = next;
    }
    _prefs ??= await SharedPreferences.getInstance();
    final key = switch (kind) {
      'video' => _keyVideo,
      'music' => _keyMusic,
      _ => _keyImage,
    };
    await _prefs!.setString(key, next);
    notifyListeners();
  }

  Future<void> mergeFromProfileMeta(String metaJson) async {
    if (metaJson.trim().isEmpty) return;
    try {
      final root = jsonDecode(metaJson);
      if (root is! Map) return;
      final gen = root['generation'];
      if (gen is! Map) return;
      final img = gen['image']?.toString();
      final vid = gen['video']?.toString();
      final mus = gen['music']?.toString();
      _prefs ??= await SharedPreferences.getInstance();
      var changed = false;
      if (img != null && img.trim().isNotEmpty) {
        final n = _normalize(img, imageProviders);
        if (n != _image) {
          _image = n;
          await _prefs!.setString(_keyImage, n);
          changed = true;
        }
      }
      if (vid != null && vid.trim().isNotEmpty) {
        final n = _normalize(vid, videoProviders);
        if (n != _video) {
          _video = n;
          await _prefs!.setString(_keyVideo, n);
          changed = true;
        }
      }
      if (mus != null && mus.trim().isNotEmpty) {
        final n = _normalize(mus, musicProviders);
        if (n != _music) {
          _music = n;
          await _prefs!.setString(_keyMusic, n);
          changed = true;
        }
      }
      if (changed) notifyListeners();
    } catch (_) {}
  }

  void applyFromRegenerateResponse({String generationImage = '', String generationVideo = '', String generationMusic = ''}) {
    unawaited(mergeFromProfileMeta(jsonEncode({
      'generation': {
        if (generationImage.isNotEmpty) 'image': generationImage,
        if (generationVideo.isNotEmpty) 'video': generationVideo,
        if (generationMusic.isNotEmpty) 'music': generationMusic,
      },
    })));
  }
}
