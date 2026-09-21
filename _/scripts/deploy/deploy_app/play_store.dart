import 'dart:io';

import 'package:googleapis/androidpublisher/v3.dart';
import 'package:googleapis_auth/auth_io.dart';

import '../deploy_lib.dart';
import 'build_android.dart';
import 'deploy_app_lib.dart';
import 'update_version.dart';

String get _packageName => Platform.environment['PLAY_STORE_PACKAGE_NAME'] ?? playStorePackageName;

Future<AndroidPublisherApi> _playStoreApi() async {
  final json = await playStoreCredentialsJson();
  final creds = ServiceAccountCredentials.fromJson(json);
  final client = await clientViaServiceAccount(creds, [AndroidPublisherApi.androidpublisherScope]);
  return AndroidPublisherApi(client);
}

Future<int> uploadAabToPlayStore(String buildOutputDir, {required String track}) async {
  final api = await runStep('Load Play Store credentials', _playStoreApi);
  final aabPath = await runStep('Resolve AAB file path', () async => findAabFile(buildOutputDir));
  final bytes = await File(aabPath).readAsBytes();
  stdout.writeln('Uploading $aabPath (${formatBytes(bytes.length)}) to Play Store (track: $track)...');

  final edit = await runStep('Create Play Store edit session', () async {
    final res = await api.edits.insert(AppEdit(), _packageName);
    if (res.id == null) throw StateError('Failed to create edit');
    return res;
  });

  final editId = edit.id!;
  final bundle = await runStep('Upload AAB bundle', () async {
    final res = await api.edits.bundles.upload(
      _packageName,
      editId,
      uploadMedia: Media(Stream.value(bytes), bytes.length, contentType: 'application/octet-stream'),
    );
    if (res.versionCode == null) throw StateError('Upload did not return versionCode');
    return res;
  });

  final versionCode = bundle.versionCode!;
  await runStep('Assign versionCode $versionCode to $track track', () async {
    await api.edits.tracks.update(
      Track(releases: [TrackRelease(versionCodes: [versionCode.toString()], status: 'completed')]),
      _packageName,
      editId,
      track,
    );
  });

  await runStep('Commit Play Store edit', () async {
    await api.edits.commit(_packageName, editId);
  });

  stdout.writeln('✓ Play Store: $track track updated with versionCode $versionCode');
  return versionCode;
}

Future<void> promotePlayStoreReleaseToProduction(int versionCode) async {
  if (versionCode <= 0) throw StateError('Invalid versionCode for production promote: $versionCode');

  const track = 'production';
  final api = await runStep('Load Play Store credentials', _playStoreApi);

  final edit = await runStep('Create Play Store edit session (production promote)', () async {
    final res = await api.edits.insert(AppEdit(), _packageName);
    if (res.id == null) throw StateError('Failed to create edit');
    return res;
  });

  final editId = edit.id!;
  await runStep('Assign versionCode $versionCode to $track track', () async {
    await api.edits.tracks.update(
      Track(releases: [TrackRelease(versionCodes: [versionCode.toString()], status: 'completed')]),
      _packageName,
      editId,
      track,
    );
  });

  await runStep('Commit Play Store edit (production)', () async {
    await api.edits.commit(_packageName, editId);
  });

  stdout.writeln('✓ Play Store: $track track updated with versionCode $versionCode');
}

int _asInt(Object? n) {
  if (n is int) return n;
  if (n is String) return int.tryParse(n) ?? -1;
  return -1;
}

String? _formatDateMaybe(Object? value) {
  if (value == null) return null;
  if (value is String) {
    final d = DateTime.tryParse(value);
    if (d != null) return d.toLocal().toString();
  }
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true).toLocal().toString();
  return null;
}

class _ReleaseRow {
  _ReleaseRow({required this.release, required this.version, required this.track, required this.status, required this.lastUpdated});
  final String release;
  final String version;
  final String track;
  final String status;
  final String lastUpdated;
}

String _releaseName(TrackRelease release, String version) {
  final name = release.name?.trim() ?? '';
  return name.isNotEmpty ? name : 'v$version';
}

String _releaseLastUpdated(TrackRelease release) {
  final map = release.toJson();
  for (final key in ['lastUpdated', 'lastUpdatedTime', 'updateTime', 'releaseTime', 'releasedAt']) {
    final formatted = _formatDateMaybe(map[key]);
    if (formatted != null) return formatted;
  }
  return '-';
}

_ReleaseRow? _latestReleaseForTrack(Track track) {
  final releases = track.releases ?? [];
  if (releases.isEmpty) return null;

  TrackRelease? best;
  var maxCode = -1;
  for (final r in releases) {
    final codes = r.versionCodes ?? [];
    for (final c in codes) {
      final code = _asInt(c);
      if (code > maxCode) {
        maxCode = code;
        best = r;
      }
    }
  }
  if (best == null || maxCode < 0) return null;

  final version = maxCode.toString();
  return _ReleaseRow(
    release: _releaseName(best, version),
    version: version,
    track: track.track ?? '-',
    status: best.status ?? '-',
    lastUpdated: _releaseLastUpdated(best),
  );
}

String _padRight(String text, int width) => text.length >= width ? text : text + ' ' * (width - text.length);

String _renderTable(List<_ReleaseRow> rows) {
  final headers = _ReleaseRow(release: 'release', version: 'version', track: 'track', status: 'status', lastUpdated: 'last updated');
  final widths = {
    'release': [headers.release.length, ...rows.map((r) => r.release.length)].reduce((a, b) => a > b ? a : b),
    'version': [headers.version.length, ...rows.map((r) => r.version.length)].reduce((a, b) => a > b ? a : b),
    'track': [headers.track.length, ...rows.map((r) => r.track.length)].reduce((a, b) => a > b ? a : b),
    'status': [headers.status.length, ...rows.map((r) => r.status.length)].reduce((a, b) => a > b ? a : b),
    'lastUpdated': [headers.lastUpdated.length, ...rows.map((r) => r.lastUpdated.length)].reduce((a, b) => a > b ? a : b),
  };

  String line(_ReleaseRow r) => [
    _padRight(r.release, widths['release']!),
    _padRight(r.version, widths['version']!),
    _padRight(r.track, widths['track']!),
    _padRight(r.status, widths['status']!),
    _padRight(r.lastUpdated, widths['lastUpdated']!),
  ].join('  ');

  final sep = [
    '-' * widths['release']!,
    '-' * widths['version']!,
    '-' * widths['track']!,
    '-' * widths['status']!,
    '-' * widths['lastUpdated']!,
  ].join('  ');

  return [line(headers), sep, ...rows.map(line)].join('\n');
}

Future<String?> playStoreShowDeployedStatus() async {
  stdout.writeln('\n--- Deployed status ---');
  return playStoreCheckRelease();
}

Future<String?> playStoreCheckRelease() async {
  final api = await runStep('Load Play Store credentials', _playStoreApi);

  final edit = await runStep('Create Play Store edit session', () async {
    final res = await api.edits.insert(AppEdit(), _packageName);
    if (res.id == null) throw StateError('Failed to create edit');
    return res;
  });

  final tracks = await runStep('Fetch tracks', () async {
    final res = await api.edits.tracks.list(_packageName, edit.id!);
    return res.tracks ?? [];
  });

  final rows = <_ReleaseRow>[];
  for (final track in tracks) {
    final row = _latestReleaseForTrack(track);
    if (row != null) rows.add(row);
  }
  rows.sort((a, b) => _asInt(b.version).compareTo(_asInt(a.version)));

  if (rows.isEmpty) {
    stdout.writeln('No releases found.');
    return null;
  }
  stdout.writeln(_renderTable(rows));
  return rows.first.release;
}

Future<int> uploadAabToPlayStoreProduction(String buildOutputDir) async {
  final track = Platform.environment['PLAY_STORE_TRACK'] ?? 'production';
  return uploadAabToPlayStore(buildOutputDir, track: track);
}

Future<int> uploadAabToPlayStoreInternal(String buildOutputDir) => uploadAabToPlayStore(buildOutputDir, track: 'internal');

bool isPlayStoreVersionCodeAlreadyUsedError(Object e) {
  final msg = e.toString();
  return msg.contains('Version code') && msg.contains('has already been used');
}

Future<int> playStoreLatestVersionCode() async {
  final api = await runStep('Load Play Store credentials', _playStoreApi);

  final edit = await runStep('Create Play Store edit session (read all tracks)', () async {
    final res = await api.edits.insert(AppEdit(), _packageName);
    if (res.id == null) throw StateError('Failed to create edit');
    return res;
  });

  final tracks = await runStep('Fetch tracks', () async {
    final res = await api.edits.tracks.list(_packageName, edit.id!);
    return res.tracks ?? [];
  });

  var maxCode = 0;
  for (final track in tracks) {
    final row = _latestReleaseForTrack(track);
    if (row == null) continue;
    final code = _asInt(row.version);
    if (code > maxCode) maxCode = code;
  }
  if (maxCode <= 0) throw StateError('No versionCode found on Play Store');
  stdout.writeln('Latest Play Store versionCode (all tracks): $maxCode');
  return maxCode;
}

Future<int> playStoreNextVersionCode() async {
  try {
    final latest = await playStoreLatestVersionCode();
    return latest + 1;
  } catch (e) {
    final (_, build) = versionReadPubspec(repoRoot());
    final next = build + 1;
    stdout.writeln('[warn] Could not read Play Store latest ($e) — using local build+1 = $next');
    return next;
  }
}

Future<int> playStoreAlignVersionToNext() async {
  final next = await playStoreNextVersionCode();
  final (_, current) = versionReadPubspec(repoRoot());
  final target = current > next ? current : next;
  if (current == target) {
    stdout.writeln('Version already at Play latest + 1 ($target)');
    versionStampSync(repoRoot());
    return target;
  }
  stdout.writeln('Aligning version: local $current → $target (Play latest + 1)');
  versionSetPubspecBuild(repoRoot(), target);
  return target;
}

Future<int> playStoreBuildAndUpload(Future<int> Function(String buildDir) upload) async {
  await playStoreAlignVersionToNext();
  var buildDir = buildAndroidAab();
  try {
    return await upload(buildDir);
  } catch (e) {
    if (!isPlayStoreVersionCodeAlreadyUsedError(e)) rethrow;
    final (_, build) = versionReadPubspec(repoRoot());
    final next = build + 1;
    stdout.writeln('[retry] Version code already used on Play Store. Rebuilding with versionCode $next...');
    versionSetPubspecBuild(repoRoot(), next);
    buildDir = buildAndroidAab();
    return await upload(buildDir);
  }
}

Future<int> playStoreLatestVersionCodeForTrack(String track) async {
  final api = await runStep('Load Play Store credentials', _playStoreApi);

  final edit = await runStep('Create Play Store edit session (read $track)', () async {
    final res = await api.edits.insert(AppEdit(), _packageName);
    if (res.id == null) throw StateError('Failed to create edit');
    return res;
  });

  final tracks = await runStep('Fetch tracks', () async {
    final res = await api.edits.tracks.list(_packageName, edit.id!);
    return res.tracks ?? [];
  });

  final target = tracks.cast<Track?>().firstWhere((t) => t?.track == track, orElse: () => null);
  final row = target == null ? null : _latestReleaseForTrack(target);
  if (row == null) throw StateError('No release found on Play Store track: $track');

  final versionCode = _asInt(row.version);
  if (versionCode <= 0) throw StateError('Invalid versionCode on $track track: ${row.version}');
  stdout.writeln('Latest $track release: versionCode $versionCode (${row.release})');
  return versionCode;
}

Future<void> playStoreClearTrack(String track) async {
  final api = await runStep('Load Play Store credentials', _playStoreApi);

  final edit = await runStep('Create Play Store edit session (clear $track)', () async {
    final res = await api.edits.insert(AppEdit(), _packageName);
    if (res.id == null) throw StateError('Failed to create edit');
    return res;
  });

  final editId = edit.id!;
  final tracks = await runStep('Fetch $track track', () async {
    final res = await api.edits.tracks.list(_packageName, editId);
    return res.tracks ?? [];
  });

  final target = tracks.cast<Track?>().firstWhere((t) => t?.track == track, orElse: () => null);
  final releases = target?.releases ?? [];
  if (releases.isEmpty) {
    stdout.writeln('✓ Play Store: $track track already has no releases');
    await api.edits.delete(_packageName, editId);
    return;
  }

  await runStep('Deactivate $track track releases', () async {
    try {
      await api.edits.tracks.update(
        Track(
          track: track,
          releases: [
            TrackRelease(
              name: 'Cleared',
              status: 'completed',
              releaseNotes: [LocalizedText(language: 'id', text: 'Track cleared')],
            ),
          ],
        ),
        _packageName,
        editId,
        track,
      );
    } on Object catch (_) {}
  });

  await runStep('Commit Play Store edit (clear $track)', () async {
    await api.edits.commit(_packageName, editId);
  });

  stdout.writeln('✓ Play Store: $track track cleared');
}
