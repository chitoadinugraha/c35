import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../deploy_lib.dart';
import 'agent_version.dart';
import 'build_chrome_extension.dart';

const _idMap = 'abcdefghijklmnop';

String pemPath(String root) => p.join(root, '_', 'deployments', 'chrome_extension', 'extension.pem');

String manifestPublicKeyBase64(String root) {
  final pemFile = pemPath(root);
  if (!File(pemFile).existsSync()) {
    throw StateError('Missing $pemFile');
  }
  final tmpPub = p.join(Directory.systemTemp.path, 'c35_ext_pub_${DateTime.now().microsecondsSinceEpoch}.der');
  _runSync('openssl', ['rsa', '-in', pemFile, '-pubout', '-outform', 'DER', '-out', tmpPub]);
  final der = File(tmpPub).readAsBytesSync();
  File(tmpPub).deleteSync();
  return base64.encode(der);
}

String extensionIdFromManifestKey(String manifestKeyBase64) {
  final keyBytes = base64.decode(manifestKeyBase64);
  final hash = sha256.convert(keyBytes).bytes;
  final buf = StringBuffer();
  for (var i = 0; i < 16; i++) {
    final b = hash[i];
    buf.write(_idMap[(b >> 4) & 0xf]);
    buf.write(_idMap[b & 0xf]);
  }
  return buf.toString();
}

void _runSync(String exe, List<String> args) {
  final r = Process.runSync(exe, args, runInShell: true);
  if (r.exitCode != 0) {
    throw StateError('$exe ${args.join(' ')} failed (${r.exitCode}): ${r.stderr}');
  }
}

String? findChromeExe() {
  final candidates = [
    p.join(Platform.environment['PROGRAMFILES'] ?? '', 'Google', 'Chrome', 'Application', 'chrome.exe'),
    p.join(Platform.environment['PROGRAMFILES(X86)'] ?? '', 'Google', 'Chrome', 'Application', 'chrome.exe'),
    p.join(Platform.environment['LOCALAPPDATA'] ?? '', 'Google', 'Chrome', 'Application', 'chrome.exe'),
  ];
  for (final c in candidates) {
    if (File(c).existsSync()) return c;
  }
  return null;
}

Future<void> syncManifestKey(String root) async {
  final keyB64 = manifestPublicKeyBase64(root);
  final manifestPath = p.join(chromeExtensionPackageDir(root), 'manifest.json');
  final raw = File(manifestPath).readAsStringSync();
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  decoded['key'] = keyB64;
  final enc = const JsonEncoder.withIndent('  ').convert(decoded);
  File(manifestPath).writeAsStringSync('$enc\n');
  stdout.writeln('manifest key synced extension_id=${extensionIdFromManifestKey(keyB64)}');
}

Future<String> packCrx(String root) async {
  final chrome = findChromeExe();
  if (chrome == null) throw StateError('Google Chrome not found');
  final pkg = chromeExtensionPackageDir(root);
  final pem = pemPath(root);
  final cache = chromeExtensionCacheDir(root);
  Directory(cache).createSync(recursive: true);
  final crxOut = p.join(cache, 'alienai_remote.crx');
  if (File(crxOut).existsSync()) File(crxOut).deleteSync();
  final oldCrx = p.join(pkg, 'alienai_remote.crx');
  if (File(oldCrx).existsSync()) File(oldCrx).deleteSync();

  final r = await Process.run(chrome, [
    '--pack-extension=$pkg',
    '--pack-extension-key=$pem',
  ], runInShell: true);
  stdout.write(r.stdout);
  stderr.write(r.stderr);
  if (r.exitCode != 0) throw StateError('chrome --pack-extension failed (${r.exitCode})');

  final packedCandidates = [
    File(p.join(pkg, 'alienai_remote.crx')),
    File(p.join(p.dirname(pkg), 'alienai_remote.crx')),
  ];
  final packed = packedCandidates.firstWhere((f) => f.existsSync(), orElse: () => File(''));
  if (!packed.existsSync()) {
    throw StateError('chrome --pack-extension did not produce alienai_remote.crx');
  }
  packed.copySync(crxOut);
  stdout.writeln('packed CRX ${formatBytes(packed.lengthSync())} -> $crxOut');
  return crxOut;
}

Future<void> _copyTree(String src, String dest) async {
  final d = Directory(dest);
  d.createSync(recursive: true);
  await for (final ent in Directory(src).list(recursive: true, followLinks: false)) {
    final rel = p.relative(ent.path, from: src);
    final target = p.join(dest, rel);
    if (ent is Directory) {
      Directory(target).createSync(recursive: true);
    } else if (ent is File) {
      if (p.basename(ent.path) == 'alienai_remote.crx') continue;
      File(target).parent.createSync(recursive: true);
      ent.copySync(target);
    }
  }
}

Future<void> _runCargoIfNeeded(String root, List<String> args) async {
  final agentExe = p.join(root, '.cache', 'c_remote', 'release', 'alienai_remote_browser.exe');
  if (!args.contains('--build-agent') && File(agentExe).existsSync()) {
    stdout.writeln('using existing $agentExe');
    return;
  }
  stdout.writeln('cargo build --release -p c_remote_browser');
  final proc = await Process.start('cargo', ['build', '--release', '-p', 'c_remote_browser'],
      workingDirectory: p.join(root, 'remotes'), runInShell: true);
  stdout.addStream(proc.stdout);
  stderr.addStream(proc.stderr);
  final code = await proc.exitCode;
  if (code != 0) throw StateError('cargo build failed ($code)');
}

void writeUtf8NoBom(String path, String content) {
  File(path).writeAsBytesSync(utf8.encode(content));
}

String installScriptFromTemplate(String root, String extId, String versionName) {
  final tpl = File(p.join(root, '_', 'deployments', 'chrome_extension', 'Install-AlienAI-Chrome-Remote.ps1.template'));
  if (!tpl.existsSync()) throw StateError('Missing install template: ${tpl.path}');
  return tpl.readAsStringSync().replaceAll('@EXT_ID@', extId).replaceAll('@VERSION@', versionName);
}

Future<void> buildChromeExtensionLocalInstall(List<String> args) async {
  final root = repoRoot();
  final (_, versionName) = agentVersionRead(root, RemoteAgentProduct.chromeExtension);
  final keyB64 = manifestPublicKeyBase64(root);
  final extId = extensionIdFromManifestKey(keyB64);
  await syncManifestKey(root);
  await _runCargoIfNeeded(root, args);

  final agentExe = p.join(root, '.cache', 'c_remote', 'release', 'alienai_remote_browser.exe');
  if (!File(agentExe).existsSync()) throw StateError('Missing $agentExe');

  final crxPath = await packCrx(root);
  final pkg = chromeExtensionPackageDir(root);
  final installRoot = p.join(chromeExtensionCacheDir(root), 'install');
  if (Directory(installRoot).existsSync()) Directory(installRoot).deleteSync(recursive: true);
  Directory(installRoot).createSync(recursive: true);

  await _copyTree(pkg, p.join(installRoot, 'alienai_remote'));
  File(crxPath).copySync(p.join(installRoot, 'alienai_remote.crx'));
  File(agentExe).copySync(p.join(installRoot, 'alienai_remote_browser.exe'));
  File(p.join(installRoot, 'extension_id.txt')).writeAsStringSync('$extId\n');

  final installPath = p.join(installRoot, 'Install-AlienAI-Chrome-Remote.ps1');
  writeUtf8NoBom(installPath, installScriptFromTemplate(root, extId, versionName));

  stdout.writeln('');
  stdout.writeln('Local install bundle: $installRoot');
  stdout.writeln('Extension ID: $extId');
  stdout.writeln('Run: $installPath');
}

void main(List<String> args) async {
  if (args.contains('--id-only')) {
    final root = repoRoot();
    stdout.writeln(extensionIdFromManifestKey(manifestPublicKeyBase64(root)));
    return;
  }
  await buildChromeExtensionLocalInstall(args);
}
