import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/pb/c35/remote.pb.dart';
import 'package:alienai_c35/c/remote/remote_fs_transfer.dart';
import 'package:alienai_c35/c/remote/remote_session.dart';
import 'package:alienai_c35/widgets/ui/ui_alert.dart';
import 'package:alienai_c35/widgets/ui/ui_menu_position.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pasteboard/pasteboard.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _masterBg = Color(0xFF0C0C10);
const _panel = Color(0xFF111114);
const _selectedBg = Color(0xFF18181B);
const _accent = Color(0xFF34D399);
const _previewBreakpoint = 1024.0;
const _previewTextMaxBytes = 2 * 1024 * 1024;
const _previewImageMaxBytes = 512 * 1024;

enum _MobilePane { explorer, preview }

enum _FsSortColumn { name, size, type, modified }

class _CopyIntent extends Intent {
  const _CopyIntent();
}

class _CutIntent extends Intent {
  const _CutIntent();
}

class _PasteIntent extends Intent {
  const _PasteIntent();
}

class UiDeviceFiles extends StatefulWidget {
  const UiDeviceFiles({super.key, required this.session});

  final RemoteSession session;

  @override
  State<UiDeviceFiles> createState() => _UiDeviceFilesState();
}

class _UiDeviceFilesState extends State<UiDeviceFiles> {
  final _expanded = <String>{};
  final _dirCache = <String, List<_FsEntry>>{};
  final _searchCtrl = TextEditingController();
  List<_FsEntry>? _roots;
  var _selectedPath = '';
  String? _selectedFilePath;
  var _highlightPath = '';
  final _selectedPaths = <String>{};
  var _mobilePane = _MobilePane.explorer;
  var _isDragging = false;
  var _sortColumn = _FsSortColumn.name;
  var _sortAsc = true;
  final _focusNode = FocusNode();
  var _loadingRoots = false;
  var _loadingDir = false;
  String? _listError;
  var _connecting = false;

  var _previewLoading = false;
  String? _previewText;
  Uint8List? _previewImage;
  String? _previewError;
  var _previewTruncated = false;

  RemoteFsTransfer get _transfer => RemoteFsTransfer.of(widget.session);

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    widget.session.connected.addListener(_onConnectionChanged);
    _transfer.addListener(_onTransferChanged);
    if (widget.session.connected.value && widget.session.fs != null) _loadRoots();
  }

  @override
  void dispose() {
    widget.session.connected.removeListener(_onConnectionChanged);
    _transfer.removeListener(_onTransferChanged);
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTransferChanged() {
    if (!mounted) return;
    final dir = _destDir();
    if (dir.isNotEmpty) {
      _dirCache.remove(dir);
      _loadDir(dir, force: true, silent: true);
    }
    setState(() {});
  }

  void _onConnectionChanged() {
    if (!widget.session.connected.value) {
      setState(() {
        _roots = null;
        _dirCache.clear();
        _expanded.clear();
        _selectedPath = '';
        _selectedFilePath = null;
        _highlightPath = '';
        _selectedPaths.clear();
        _clearPreview();
        _listError = null;
        _mobilePane = _MobilePane.explorer;
      });
      return;
    }
    if (widget.session.fs != null) _loadRoots();
  }

  void _clearPreview() {
    _previewLoading = false;
    _previewText = null;
    _previewImage = null;
    _previewError = null;
    _previewTruncated = false;
  }

  Future<void> _connect() async {
    if (_connecting) return;
    setState(() => _connecting = true);
    try {
      await widget.session.start();
    } catch (e) {
      lError('device files connect: $e');
      if (mounted) await uiAlertError(context, e, fallback: 'Could not connect to device.');
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _loadRoots() async {
    final fs = widget.session.fs;
    if (fs == null || _loadingRoots) return;
    setState(() {
      _loadingRoots = true;
      _listError = null;
    });
    try {
      final res = await fs.fsList('');
      if (res.error.isNotEmpty) throw res.error;
      final roots = res.entries.map(_FsEntry.fromPb).toList();
      l('device files roots: ${roots.length}');
      if (!mounted) return;
      setState(() {
        _roots = roots;
        if (_selectedPath.isEmpty && roots.isNotEmpty) {
          _selectedPath = roots.first.path;
          _expanded.add(roots.first.path);
        }
      });
      if (_selectedPath.isNotEmpty) await _loadDir(_selectedPath, silent: true);
    } catch (e) {
      lError('device files load roots: $e');
      if (mounted) setState(() => _listError = '$e');
    } finally {
      if (mounted) setState(() => _loadingRoots = false);
    }
  }

  Future<void> _loadDir(String path, {bool silent = false, bool force = false}) async {
    final fs = widget.session.fs;
    if (fs == null) return;
    if (!force && _dirCache.containsKey(path)) return;
    if (!silent) setState(() => _loadingDir = true);
    try {
      final res = await fs.fsList(path);
      if (res.error.isNotEmpty) throw res.error;
      if (!mounted) return;
      setState(() {
        _dirCache[path] = res.entries.map(_FsEntry.fromPb).toList();
        _listError = null;
      });
    } catch (e) {
      lError('device files list $path: $e');
      if (mounted) setState(() => _listError = '$e');
    } finally {
      if (mounted && !silent) setState(() => _loadingDir = false);
    }
  }

  Future<void> _loadPreview(String path) async {
    final fs = widget.session.fs;
    if (fs == null) return;
    setState(() {
      _previewLoading = true;
      _clearPreview();
      _previewLoading = true;
    });
    try {
      final isText = _isTextMime('', path);
      final isImage = _isImageMime('', path);
      final maxBytes = isText ? _previewTextMaxBytes : (isImage ? _previewImageMaxBytes : 0);
      if (maxBytes == 0) {
        if (!mounted) return;
        setState(() {
          _previewLoading = false;
          _previewError = 'Preview not available for this file type.\nDownload to open locally.';
        });
        return;
      }
      final buf = BytesBuilder(copy: false);
      var offset = 0;
      var mime = '';
      var eof = false;
      while (buf.length < maxBytes) {
        final toRead = maxBytes - buf.length;
        final res = await fs.fsRead(path, offset: offset, len: toRead);
        if (res.error.isNotEmpty) throw res.error;
        if (mime.isEmpty && res.mime.isNotEmpty) mime = res.mime;
        buf.add(res.data);
        offset += res.data.length;
        eof = res.eof || res.data.isEmpty;
        if (eof) break;
      }
      final truncated = !eof && buf.length >= maxBytes;
      final data = buf.takeBytes();
      if (!mounted) return;
      setState(() {
        _previewLoading = false;
        _previewTruncated = truncated;
        if (_isTextMime(mime, path) || isText) {
          _previewText = _decodeTextPreview(data);
        } else if (_isImageMime(mime, path) || isImage) {
          _previewImage = Uint8List.fromList(data);
        } else {
          _previewError = 'Preview not available for this file type.\nDownload to open locally.';
        }
      });
    } catch (e) {
      lError('device files preview $path: $e');
      if (mounted) {
        setState(() {
          _previewLoading = false;
          _previewError = '$e';
        });
      }
    }
  }

  List<_FsEntry> get _rootsList => _roots ?? const [];

  List<_FsEntry> _dirEntries(String path) => _dirCache[path] ?? const [];

  String get _searchQuery => _searchCtrl.text.trim().toLowerCase();

  void _toggleSort(_FsSortColumn column) => setState(() {
        if (_sortColumn == column) {
          _sortAsc = !_sortAsc;
        } else {
          _sortColumn = column;
          _sortAsc = true;
        }
      });

  List<_FsEntry> _sortedEntries(List<_FsEntry> entries) {
    final list = List<_FsEntry>.from(entries);
    list.sort((a, b) {
      if (_sortColumn == _FsSortColumn.name) {
        final dirCmp = (b.isDir ? 1 : 0).compareTo(a.isDir ? 1 : 0);
        if (dirCmp != 0) return dirCmp;
      }
      final cmp = switch (_sortColumn) {
        _FsSortColumn.name => _entryLabel(a).toLowerCase().compareTo(_entryLabel(b).toLowerCase()),
        _FsSortColumn.size => a.size.compareTo(b.size),
        _FsSortColumn.type => _typeLabel(a).toLowerCase().compareTo(_typeLabel(b).toLowerCase()),
        _FsSortColumn.modified => (a.modified?.millisecondsSinceEpoch ?? 0).compareTo(b.modified?.millisecondsSinceEpoch ?? 0),
      };
      if (cmp != 0) return _sortAsc ? cmp : -cmp;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.session.connected.value && widget.session.fs != null && _roots == null && !_loadingRoots) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadRoots();
      });
    }
    return ListenableBuilder(
      listenable: widget.session.connected,
      builder: (context, _) {
        if (!widget.session.connected.value) return _connectPrompt();
        if (widget.session.fs == null) return _loadingPane('Opening file channel…');
        if (_loadingRoots && _roots == null) return _loadingPane('Loading drives…');
        return _filesLayout(context);
      },
    );
  }

  Widget _connectPrompt() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: const Icon(Icons.folder_open_outlined, size: 28, color: _muted),
                ),
                const SizedBox(height: 16),
                const Text('Connect to browse files', textAlign: TextAlign.center, style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text('Files stream directly to your device over WebRTC — nothing passes through the server.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 13, height: 1.45)),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _connecting ? null : _connect,
                  icon: _connecting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _text))
                      : const Icon(Icons.link, size: 18),
                  label: Text(_connecting ? 'Connecting…' : 'Connect'),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _loadingPane(String message) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(color: _muted, fontSize: 13)),
          ],
        ),
      );

  Widget _filesLayout(BuildContext context) {
    final showPreviewPane = MediaQuery.sizeOf(context).width >= _previewBreakpoint;
    Widget body;
    if (_mobilePane == _MobilePane.preview) {
      body = _previewPane(showBack: true, onBack: () => setState(() => _mobilePane = _MobilePane.explorer));
    } else if (showPreviewPane) {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 5, child: _explorerPane()),
          const VerticalDivider(width: 1, color: _border),
          Expanded(flex: 4, child: _previewPane(showBack: false)),
        ],
      );
    } else {
      body = _explorerPane();
    }
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyC, control: true): _CopyIntent(),
        SingleActivator(LogicalKeyboardKey.keyX, control: true): _CutIntent(),
        SingleActivator(LogicalKeyboardKey.keyX, meta: true): _CutIntent(),
        SingleActivator(LogicalKeyboardKey.keyV, control: true): _PasteIntent(),
        SingleActivator(LogicalKeyboardKey.keyV, meta: true): _PasteIntent(),
      },
      child: Actions(
        actions: {
          _CopyIntent: CallbackAction<_CopyIntent>(onInvoke: (_) {
            _copySelection();
            return null;
          }),
          _CutIntent: CallbackAction<_CutIntent>(onInvoke: (_) {
            _cutSelection();
            return null;
          }),
          _PasteIntent: CallbackAction<_PasteIntent>(onInvoke: (_) {
            unawaited(_pasteClipboard());
            return null;
          }),
        },
        child: Focus(autofocus: true, focusNode: _focusNode, child: body),
      ),
    );
  }

  String _destDir() {
    if (_selectedPath.isNotEmpty) return _selectedPath;
    if (_rootsList.isNotEmpty) return _rootsList.first.path;
    return '';
  }

  List<String> _actionPaths() {
    if (_selectedPaths.isNotEmpty) return _selectedPaths.toList();
    final path = _highlightPath.isNotEmpty ? _highlightPath : _selectedFilePath;
    if (path != null && path.isNotEmpty) return [path];
    return const [];
  }

  bool get _hasActionSelection => _actionPaths().isNotEmpty;

  bool get _canRenameSelection {
    final paths = _actionPaths();
    return paths.length == 1 && _entryAt(paths.first) != null;
  }

  bool get _canDeleteSelection {
    final paths = _actionPaths();
    if (paths.isEmpty) return false;
    return paths.every((p) => !_isDriveRoot(p));
  }

  void _applyRowSelection(_FsEntry entry, {required bool toggle}) => setState(() {
        if (toggle) {
          if (_selectedPaths.contains(entry.path)) {
            _selectedPaths.remove(entry.path);
          } else {
            _selectedPaths.add(entry.path);
          }
        } else {
          _selectedPaths
            ..clear()
            ..add(entry.path);
        }
        _highlightPath = entry.path;
      });

  Future<void> _invalidateAfterMutate(String path) async {
    final parent = _parentDirPath(path);
    _dirCache.remove(parent);
    if (_selectedPath.isNotEmpty) _dirCache.remove(_selectedPath);
    await _loadDir(parent, force: true, silent: true);
    if (_selectedPath.isNotEmpty && _selectedPath != parent) {
      await _loadDir(_selectedPath, force: true, silent: true);
    }
    if (mounted) setState(() {});
  }

  Future<void> _downloadSelection() async {
    final paths = _actionPaths();
    if (paths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select files or folders to download.')));
      return;
    }
    try {
      await _transfer.downloadRemote(paths);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloading ${paths.length} item(s) to your computer…')),
      );
    } catch (e) {
      lError('device files download: $e');
      if (mounted) await uiAlertError(context, e, fallback: 'Could not start download.');
    }
  }

  Future<void> _showNewFolderDialog() async {
    final dest = _destDir();
    final fs = widget.session.fs;
    if (dest.isEmpty || fs == null) return;
    final nameCtrl = TextEditingController(text: 'New folder');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('New folder', style: TextStyle(color: _text, fontSize: 16)),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          style: const TextStyle(color: _text, fontSize: 14),
          decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: _muted)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final name = nameCtrl.text.trim();
    nameCtrl.dispose();
    if (name.isEmpty) return;
    final path = _joinPath(dest, name);
    try {
      final res = await fs.fsMkdir(path);
      if (res.error.isNotEmpty) throw res.error;
      await _invalidateAfterMutate(path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Created folder $name')));
    } catch (e) {
      lError('device files mkdir: $e');
      if (mounted) await uiAlertError(context, e, fallback: 'Could not create folder.');
    }
  }

  Future<void> _renameSelection() async {
    final fs = widget.session.fs;
    if (fs == null) return;
    final paths = _actionPaths();
    if (paths.length != 1) return;
    final entry = _entryAt(paths.first);
    if (entry == null || _isDriveRoot(entry.path)) return;
    final nameCtrl = TextEditingController(text: entry.name);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('Rename', style: TextStyle(color: _text, fontSize: 16)),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          style: const TextStyle(color: _text, fontSize: 14),
          decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: _muted)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Rename')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final newName = nameCtrl.text.trim();
    nameCtrl.dispose();
    if (newName.isEmpty || newName == entry.name) return;
    final newPath = _joinPath(_parentDirPath(entry.path), newName);
    try {
      final res = await fs.fsRename(entry.path, newPath);
      if (res.error.isNotEmpty) throw res.error;
      await _invalidateAfterMutate(entry.path);
      if (!mounted) return;
      setState(() {
        _highlightPath = newPath;
        _selectedPaths
          ..clear()
          ..add(newPath);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Renamed to $newName')));
    } catch (e) {
      lError('device files rename: $e');
      if (mounted) await uiAlertError(context, e, fallback: 'Could not rename.');
    }
  }

  Future<void> _deleteSelection() async {
    final fs = widget.session.fs;
    if (fs == null) return;
    final paths = _actionPaths().where((p) => !_isDriveRoot(p)).toList();
    if (paths.isEmpty) return;
    final labels = paths.map((p) => _entryAt(p)?.name ?? _basename(p)).take(3).join(', ');
    final extra = paths.length > 3 ? ' (+${paths.length - 3} more)' : '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('Delete?', style: TextStyle(color: _text, fontSize: 16)),
        content: Text(
          paths.length == 1 ? 'Delete "$labels" from the device?' : 'Delete $labels$extra from the device?',
          style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 13, height: 1.45),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      for (final path in paths) {
        final res = await fs.fsDelete(path);
        if (res.error.isNotEmpty) throw res.error;
      }
      if (_highlightPath.isNotEmpty && paths.contains(_highlightPath)) {
        setState(() {
          _highlightPath = '';
          _selectedFilePath = null;
          _selectedPaths.removeWhere(paths.contains);
          _clearPreview();
        });
      }
      await _invalidateAfterMutate(paths.first);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted ${paths.length} item(s)')));
    } catch (e) {
      lError('device files delete: $e');
      if (mounted) await uiAlertError(context, e, fallback: 'Could not delete.');
    }
  }

  Future<void> _pickAndUpload() async {
    if (widget.session.fs == null) {
      await uiAlertError(context, 'Connect to the device before uploading.');
      return;
    }
    final dest = _destDir();
    if (dest.isEmpty) return;
    final res = await FilePicker.platform.pickFiles(allowMultiple: true, withReadStream: false);
    if (res == null || res.files.isEmpty) return;
    final paths = res.files.map((f) => f.path).whereType<String>().where((p) => p.isNotEmpty).toList();
    if (paths.isEmpty) return;
    _transfer.uploadLocalFiles(dest, paths);
  }

  bool get _hasFileSelection {
    final path = _highlightPath.isNotEmpty ? _highlightPath : _selectedFilePath;
    if (path == null || path.isEmpty) return false;
    final entry = _entryAt(path);
    return entry != null && !entry.isDir;
  }

  void _copySelection() {
    final path = _highlightPath.isNotEmpty ? _highlightPath : _selectedFilePath;
    if (path == null || path.isEmpty) return;
    final entry = _entryAt(path);
    if (entry == null || entry.isDir) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a file to copy.')));
      return;
    }
    _transfer.copyRemote([path], cut: false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied ${entry.name}')));
  }

  void _cutSelection() {
    final path = _highlightPath.isNotEmpty ? _highlightPath : _selectedFilePath;
    if (path == null || path.isEmpty) return;
    final entry = _entryAt(path);
    if (entry == null || entry.isDir) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a file to cut.')));
      return;
    }
    _transfer.copyRemote([path], cut: true);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cut ${entry.name}')));
  }

  Future<void> _pasteClipboard() async {
    if (widget.session.fs == null) {
      await uiAlertError(context, 'Connect to the device before pasting.');
      return;
    }
    final dest = _destDir();
    if (dest.isEmpty) return;

    if (!kIsWeb) {
      try {
        final clipboard = await Pasteboard.files();
        final files = <String>[];
        final dirs = <String>[];
        for (final p in clipboard) {
          if (p.isEmpty) continue;
          final entity = FileSystemEntity.typeSync(p);
          if (entity == FileSystemEntityType.file) {
            files.add(p);
          } else if (entity == FileSystemEntityType.directory) {
            dirs.add(p);
          }
        }
        if (files.isNotEmpty || dirs.isNotEmpty) {
          for (final d in dirs) {
            _transfer.uploadLocalDirectory(dest, d);
          }
          if (files.isNotEmpty) _transfer.uploadLocalFiles(dest, files);
          if (!mounted) return;
          final parts = <String>[];
          if (files.isNotEmpty) parts.add('${files.length} file(s)');
          if (dirs.isNotEmpty) parts.add('${dirs.length} folder(s)');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Uploading ${parts.join(' and ')} from your computer')),
          );
          return;
        }
      } catch (e) {
        lError('device files pasteboard: $e');
      }
    }

    if (!_transfer.hasClipboard) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nothing to paste')));
      }
      return;
    }
    _transfer.pasteRemote(dest);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pasting on device…')));
    }
  }

  Future<void> _showNewFileDialog() async {
    final dest = _destDir();
    if (dest.isEmpty || widget.session.fs == null) return;
    final nameCtrl = TextEditingController(text: 'New file.txt');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('New file', style: TextStyle(color: _text, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              style: const TextStyle(color: _text, fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(color: _muted),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Type', style: TextStyle(color: _muted, fontSize: 12)),
            const SizedBox(height: 4),
            InputDecorator(
              decoration: InputDecoration(
                filled: true,
                fillColor: _panel,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
              ),
              child: const Text('Plain text (.txt)', style: TextStyle(color: _text, fontSize: 13)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    var name = nameCtrl.text.trim();
    nameCtrl.dispose();
    if (name.isEmpty) return;
    if (!name.contains('.')) name = '$name.txt';
    _transfer.createEmptyFile(dest, name);
  }

  Future<void> _onDropDone(DropDoneDetails detail) async {
    setState(() => _isDragging = false);
    if (widget.session.fs == null) return;
    final dest = _destDir();
    if (dest.isEmpty) return;
    final paths = <String>[];
    for (final f in detail.files) {
      final p = f.path;
      if (p.isNotEmpty) paths.add(p);
    }
    if (paths.isEmpty) return;
    _transfer.uploadLocalFiles(dest, paths);
  }

  void _showTransfersSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF18181B),
      builder: (ctx) => ListenableBuilder(
        listenable: _transfer,
        builder: (context, _) {
          final jobs = _transfer.jobs;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Expanded(child: Text('Transfers', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w600))),
                      if (jobs.any((j) => j.status == RemoteFsJobStatus.done))
                        TextButton(onPressed: _transfer.clearFinished, child: const Text('Clear done')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (jobs.isEmpty)
                    const Padding(padding: EdgeInsets.all(24), child: Text('No transfers', style: TextStyle(color: _muted)))
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: jobs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final j = jobs[i];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(j.label, style: TextStyle(color: j.status == RemoteFsJobStatus.failed ? const Color(0xFFFCA5A5) : _text, fontSize: 13)),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: j.status == RemoteFsJobStatus.failed ? null : j.progress,
                                minHeight: 4,
                                backgroundColor: const Color(0xFF27272A),
                                color: j.status == RemoteFsJobStatus.failed ? const Color(0xFFEF4444) : _accent,
                              ),
                              if (j.error != null) Text(j.error!, style: const TextStyle(color: _muted, fontSize: 11)),
                            ],
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showEntryMenu(_FsEntry entry, Offset pos) async {
    final action = await showMenu<String>(
      context: context,
      position: uiMenuPositionAt(context, pos),
      color: const Color(0xFF18181B),
      items: [
        _fsMenuItem('download', Icons.download_outlined, 'Download'),
        _fsMenuItem('new_folder', Icons.create_new_folder_outlined, 'New folder'),
        _fsMenuItem('new', Icons.note_add_outlined, 'New file'),
        if (!entry.isDir) _fsMenuItem('cut', Icons.content_cut_outlined, 'Cut'),
        if (!entry.isDir) _fsMenuItem('copy', Icons.copy_outlined, 'Copy'),
        if (widget.session.fs != null) _fsMenuItem('paste', Icons.content_paste_outlined, 'Paste'),
        if (!_isDriveRoot(entry.path)) _fsMenuItem('rename', Icons.drive_file_rename_outline, 'Rename'),
        if (!_isDriveRoot(entry.path)) _fsMenuItem('delete', Icons.delete_outline, 'Delete'),
      ],
    );
    if (action == null) return;
    _applyRowSelection(entry, toggle: false);
    switch (action) {
      case 'download':
        await _downloadSelection();
      case 'new_folder':
        await _showNewFolderDialog();
      case 'new':
        await _showNewFileDialog();
      case 'cut':
        if (!entry.isDir) _cutSelection();
      case 'copy':
        if (!entry.isDir) _copySelection();
      case 'paste':
        unawaited(_pasteClipboard());
      case 'rename':
        await _renameSelection();
      case 'delete':
        await _deleteSelection();
    }
  }

  PopupMenuItem<String> _fsMenuItem(String value, IconData icon, String label) => PopupMenuItem(
        value: value,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, size: 20, color: const Color(0xFFA1A1AA)),
          title: Text(label, style: const TextStyle(fontSize: 14, color: _text)),
          dense: true,
        ),
      );

  void _selectDir(_FsEntry node, {bool toggle = false}) {
    setState(() {
      _selectedPath = node.path;
      if (toggle) {
        if (_selectedPaths.contains(node.path)) {
          _selectedPaths.remove(node.path);
        } else {
          _selectedPaths.add(node.path);
        }
      } else {
        _selectedPaths
          ..clear()
          ..add(node.path);
      }
      _highlightPath = node.path;
      _selectedFilePath = null;
      _clearPreview();
      _expanded.add(node.path);
    });
    _loadDir(node.path);
  }

  void _selectFile(_FsEntry node, {bool toggle = false}) {
    if (toggle) {
      _applyRowSelection(node, toggle: true);
    } else {
      setState(() {
        _selectedPaths
          ..clear()
          ..add(node.path);
        _highlightPath = node.path;
      });
    }
    if (!_canPreview(node)) {
      setState(() {
        _selectedFilePath = null;
        _clearPreview();
      });
      return;
    }
    setState(() {
      _selectedFilePath = node.path;
      if (MediaQuery.sizeOf(context).width < _previewBreakpoint) _mobilePane = _MobilePane.preview;
    });
    _loadPreview(node.path);
  }

  void _toggleExpand(_FsEntry node) {
    setState(() {
      if (_expanded.contains(node.path)) {
        _expanded.remove(node.path);
      } else {
        _expanded.add(node.path);
      }
    });
    if (_expanded.contains(node.path)) _loadDir(node.path);
  }

  Widget _explorerPane() {
    final dropEnabled = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
    return ColoredBox(
      color: _masterBg,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _searchBar(),
              _fileOpsBar(),
              _fileListHeader(),
              if (_listError != null)
                _errorBanner(_listError!, onRetry: () {
                  _dirCache.remove(_selectedPath);
                  _loadDir(_selectedPath, force: true);
                }),
              Expanded(
                child: _loadingDir && _dirCache.isEmpty
                    ? _loadingPane('Loading folder…')
                    : _rootsList.isEmpty
                        ? const Center(child: Text('No drives found', style: TextStyle(color: _muted, fontSize: 13)))
                        : _explorerList(dropEnabled: dropEnabled),
              ),
            ],
          ),
          ListenableBuilder(
            listenable: _transfer,
            builder: (context, _) {
              final n = _transfer.activeCount;
              if (n == 0) return const SizedBox.shrink();
              return Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton.small(
                  heroTag: 'device-fs-transfers-${widget.session.deviceIid}',
                  backgroundColor: const Color(0xFF18181B),
                  foregroundColor: _accent,
                  onPressed: _showTransfersSheet,
                  child: Badge(
                    label: Text('$n'),
                    child: const Icon(Icons.upload_file_outlined),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _fileOpsBar() => Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
        child: Row(
          children: [
            _opsBtn(
              icon: Icons.download_outlined,
              tooltip: 'Download to your computer',
              onPressed: _hasActionSelection ? () => unawaited(_downloadSelection()) : null,
            ),
            _opsBtn(icon: Icons.create_new_folder_outlined, tooltip: 'New folder', onPressed: _showNewFolderDialog),
            _opsBtn(icon: Icons.note_add_outlined, tooltip: 'New file', onPressed: _showNewFileDialog),
            _opsBtn(icon: Icons.drive_file_rename_outline, tooltip: 'Rename', onPressed: _canRenameSelection ? () => unawaited(_renameSelection()) : null),
            _opsBtn(icon: Icons.delete_outline, tooltip: 'Delete', onPressed: _canDeleteSelection ? () => unawaited(_deleteSelection()) : null),
            _opsBtn(icon: Icons.content_cut_outlined, tooltip: 'Cut', onPressed: _hasFileSelection ? _cutSelection : null),
            _opsBtn(icon: Icons.copy_outlined, tooltip: 'Copy', onPressed: _hasFileSelection ? _copySelection : null),
            _opsBtn(
              icon: Icons.content_paste_outlined,
              tooltip: 'Paste: PC clipboard files/folders upload here; otherwise paste device copy/cut into this folder',
              onPressed: widget.session.fs != null ? () => unawaited(_pasteClipboard()) : null,
            ),
            const Spacer(),
            if (_isDragging)
              const Text('Drop to upload', style: TextStyle(color: _accent, fontSize: 11)),
          ],
        ),
      );

  Widget _opsBtn({required IconData icon, required String tooltip, VoidCallback? onPressed}) => uiIconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: onPressed == null ? const Color(0xFF3F3F46) : const Color(0xFFA1A1AA)),
        style: const ButtonStyle(
          visualDensity: VisualDensity.compact,
          padding: WidgetStatePropertyAll(EdgeInsets.all(6)),
          minimumSize: WidgetStatePropertyAll(Size(32, 32)),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );

  Widget _searchBar() => Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(fontSize: 13, color: _text),
                decoration: InputDecoration(
                  hintText: 'Search files',
                  hintStyle: const TextStyle(color: _muted, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 16, color: _muted),
                  prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 32),
                  suffixIcon: _searchCtrl.text.isEmpty
                      ? null
                      : uiIconButton(
                          tooltip: 'Clear',
                          onPressed: _searchCtrl.clear,
                          icon: const Icon(Icons.close, size: 16, color: Color(0xFFA1A1AA)),
                          style: const ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            padding: WidgetStatePropertyAll(EdgeInsets.zero),
                            minimumSize: WidgetStatePropertyAll(Size(28, 28)),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                  isDense: true,
                  filled: true,
                  fillColor: _panel,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
                ),
              ),
            ),
            const SizedBox(width: 4),
            uiIconButton(
              tooltip: 'Upload files',
              onPressed: _pickAndUpload,
              icon: const Icon(Icons.add, size: 22, color: _text),
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                padding: WidgetStatePropertyAll(EdgeInsets.all(8)),
                minimumSize: WidgetStatePropertyAll(Size(36, 36)),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      );

  Widget _previewPane({required bool showBack, VoidCallback? onBack}) {
    final file = _selectedFilePath == null ? null : _entryAt(_selectedFilePath!);
    return ColoredBox(
      color: _panel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _paneHeader(file?.name ?? 'Preview', showBack: showBack, onBack: onBack),
          Expanded(child: file == null ? _previewEmpty() : _previewBody(file)),
        ],
      ),
    );
  }

  Widget _errorBanner(String message, {VoidCallback? onRetry}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: const Color(0xFF450A0A),
        child: Row(
          children: [
            const Icon(Icons.error_outline, size: 16, color: Color(0xFFFCA5A5)),
            const SizedBox(width: 8),
            Expanded(child: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12))),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Retry', style: TextStyle(color: _accent, fontSize: 12))),
          ],
        ),
      );

  Widget _previewEmpty() => const Center(child: Text('Select a previewable file', style: TextStyle(color: _muted, fontSize: 13)));

  Widget _previewBody(_FsEntry file) {
    if (_previewLoading) return _loadingPane('Loading preview…');
    if (_previewError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_previewError!, textAlign: TextAlign.center, style: TextStyle(color: _muted.withValues(alpha: 0.9), fontSize: 13)),
        ),
      );
    }
    if (_previewText != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_previewTruncated)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: const Color(0xFF27272A),
              child: Text(
                'Showing first ${_formatSize(_previewTextMaxBytes)} — download for the full file.',
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: SelectableText(_previewText!, style: const TextStyle(color: _text, fontSize: 12, fontFamily: 'Consolas', height: 1.45)),
            ),
          ),
        ],
      );
    }
    if (_previewImage != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_previewTruncated)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: const Color(0xFF27272A),
              child: Text(
                'Image preview capped at ${_formatSize(_previewImageMaxBytes)} — download for full resolution.',
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ),
          Expanded(
            child: Center(
              child: InteractiveViewer(
                child: Image.memory(_previewImage!, gaplessPlayback: true),
              ),
            ),
          ),
        ],
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Preview not available for this file type.\nDownload to open locally.', textAlign: TextAlign.center, style: TextStyle(color: _muted.withValues(alpha: 0.9), fontSize: 13)),
      ),
    );
  }

  Widget _paneHeader(String title, {bool showBack = false, VoidCallback? onBack}) => Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _border))),
        child: Row(
          children: [
            if (showBack)
              uiIconButton(
                tooltip: 'Back',
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, size: 18, color: Color(0xFFA1A1AA)),
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  padding: WidgetStatePropertyAll(EdgeInsets.zero),
                  minimumSize: WidgetStatePropertyAll(Size(32, 32)),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            Expanded(
              child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );

  Widget _fileListHeader() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _border))),
        child: Row(
          children: [
            Expanded(flex: 5, child: _sortHeader(_FsSortColumn.name, 'Name')),
            Expanded(flex: 2, child: _sortHeader(_FsSortColumn.size, 'Size')),
            Expanded(flex: 2, child: _sortHeader(_FsSortColumn.type, 'Type')),
            Expanded(flex: 3, child: _sortHeader(_FsSortColumn.modified, 'Modified')),
          ],
        ),
      );

  Widget _sortHeader(_FsSortColumn column, String label) {
    final active = _sortColumn == column;
    return InkWell(
      onTap: () => _toggleSort(column),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: active ? _text : _muted, fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ),
            if (active) ...[
              const SizedBox(width: 2),
              Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward, size: 12, color: _muted),
            ],
          ],
        ),
      ),
    );
  }

  Widget _explorerList({required bool dropEnabled}) {
    final list = ListView(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 72),
      children: [for (final n in _sortedEntries(_rootsList)) _explorerNode(n, 0)],
    );
    if (!dropEnabled) return list;
    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: _onDropDone,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(border: Border.all(color: _isDragging ? _accent : Colors.transparent, width: 1.5)),
        child: list,
      ),
    );
  }

  Widget _explorerNode(_FsEntry node, int depth) {
    final q = _searchQuery;
    if (q.isNotEmpty && !_nodeMatches(node, q)) return const SizedBox.shrink();
    final expanded = _expanded.contains(node.path) || (q.isNotEmpty && node.isDir);
    final children = node.isDir ? _sortedEntries(_dirEntries(node.path)) : const <_FsEntry>[];
    final hasChildren = node.isDir && (children.isNotEmpty || !_dirCache.containsKey(node.path));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _explorerRow(node, depth: depth, expanded: expanded, hasChildren: hasChildren),
        if (expanded && node.isDir) for (final c in children) _explorerNode(c, depth + 1),
      ],
    );
  }

  Widget _explorerRow(_FsEntry entry, {required int depth, required bool expanded, required bool hasChildren}) {
    final selected = _selectedPaths.contains(entry.path) || entry.path == _highlightPath || (entry.isDir && entry.path == _selectedPath);
    final indent = 8.0 + depth * 16.0;
    return Material(
      color: selected ? _selectedBg : Colors.transparent,
      child: InkWell(
        onTap: () {
          final toggle = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;
          if (entry.isDir) {
            _selectDir(entry, toggle: toggle);
          } else {
            _selectFile(entry, toggle: toggle);
          }
        },
        onSecondaryTapDown: (d) => _showEntryMenu(entry, d.globalPosition),
        hoverColor: const Color(0xFF1C1C22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    SizedBox(
                      width: indent,
                    ),
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: entry.isDir && hasChildren
                          ? IconButton(
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              iconSize: 16,
                              splashRadius: 14,
                              onPressed: () => _toggleExpand(entry),
                              icon: Icon(expanded ? Icons.expand_more : Icons.chevron_right, size: 16, color: _muted),
                            )
                          : null,
                    ),
                    Icon(_entryIcon(entry), size: 16, color: _entryIconColor(entry)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _entryLabel(entry),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _text, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(flex: 2, child: Text(entry.isDir ? '' : _formatSize(entry.size), style: const TextStyle(color: _muted, fontSize: 12))),
              Expanded(flex: 2, child: Text(_typeLabel(entry), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 12))),
              Expanded(flex: 3, child: Text(entry.modified != null ? _formatDate(entry.modified!) : '', style: const TextStyle(color: _muted, fontSize: 12))),
            ],
          ),
        ),
      ),
    );
  }

  bool _canPreview(_FsEntry entry) {
    if (entry.isDir) return false;
    return _isTextMime('', entry.path) || _isImageMime('', entry.path);
  }

  bool _nodeMatches(_FsEntry node, String q) {
    if (_entryLabel(node).toLowerCase().contains(q) || node.name.toLowerCase().contains(q)) return true;
    return _dirEntries(node.path).any((c) => _nodeMatches(c, q));
  }

  _FsEntry? _entryAt(String path) {
    for (final root in _rootsList) {
      if (root.path == path) return root;
    }
    for (final entries in _dirCache.values) {
      for (final e in entries) {
        if (e.path == path) return e;
      }
    }
    return null;
  }
}

class _FsEntry {
  _FsEntry({
    required this.name,
    required this.path,
    this.isDir = false,
    this.size = 0,
    this.modified,
    this.driveKind = RemoteFsDriveKind.REMOTE_FS_DRIVE_KIND_UNSPECIFIED,
  });

  factory _FsEntry.fromPb(RemoteFsEntry e) => _FsEntry(
        name: e.name,
        path: e.path,
        isDir: e.isDir,
        size: e.size.toInt(),
        modified: e.modifiedMs.toInt() > 0 ? DateTime.fromMillisecondsSinceEpoch(e.modifiedMs.toInt()) : null,
        driveKind: e.driveKind,
      );

  final String name;
  final String path;
  final bool isDir;
  final int size;
  final DateTime? modified;
  final RemoteFsDriveKind driveKind;
}

IconData _entryIcon(_FsEntry entry) {
  if (!entry.isDir) return _fileIcon(entry.name);
  if (!_isDriveRoot(entry.path)) return Icons.folder_outlined;
  return switch (entry.driveKind) {
    RemoteFsDriveKind.REMOTE_FS_DRIVE_KIND_REMOTE => Icons.folder_shared_outlined,
    RemoteFsDriveKind.REMOTE_FS_DRIVE_KIND_REMOVABLE => Icons.usb_outlined,
    RemoteFsDriveKind.REMOTE_FS_DRIVE_KIND_CDROM => Icons.album_outlined,
    RemoteFsDriveKind.REMOTE_FS_DRIVE_KIND_RAM => Icons.memory_outlined,
    _ => Icons.storage_outlined,
  };
}

Color _entryIconColor(_FsEntry entry) {
  if (!entry.isDir) return _muted;
  return const Color(0xFFFBBF24);
}

String _entryLabel(_FsEntry entry) {
  if (!_isDriveRoot(entry.path)) return entry.name;
  if (entry.name.contains('(') && entry.name.contains(':')) return entry.name;
  final letter = entry.path.substring(0, 1).toUpperCase();
  return switch (entry.driveKind) {
    RemoteFsDriveKind.REMOTE_FS_DRIVE_KIND_REMOTE => 'Network ($letter:)',
    RemoteFsDriveKind.REMOTE_FS_DRIVE_KIND_REMOVABLE => 'USB Drive ($letter:)',
    RemoteFsDriveKind.REMOTE_FS_DRIVE_KIND_CDROM => 'DVD ($letter:)',
    RemoteFsDriveKind.REMOTE_FS_DRIVE_KIND_RAM => 'RAM Disk ($letter:)',
    _ => 'Local Disk ($letter:)',
  };
}

bool _isDriveRoot(String path) {
  final p = path.replaceAll('/', '\\');
  if (p.length == 2 && p[1] == ':') return true;
  return p.length == 3 && p[1] == ':' && p[2] == '\\';
}

bool _isTextMime(String mime, String path) {
  if (mime.startsWith('text/')) return true;
  final ext = _ext(path);
  return switch (ext) {
    'txt' || 'md' || 'json' || 'yaml' || 'yml' || 'toml' || 'xml' || 'csv' || 'log' || 'ini' || 'ps1' || 'sh' || 'rs' || 'dart' || 'js' || 'ts' || 'html' || 'css' => true,
    _ => false,
  };
}

bool _isImageMime(String mime, String path) {
  if (mime.startsWith('image/')) return true;
  final ext = _ext(path);
  return switch (ext) {
    'png' || 'jpg' || 'jpeg' || 'gif' || 'webp' || 'bmp' => true,
    _ => false,
  };
}

String _ext(String path) => path.contains('.') ? path.split('.').last.toLowerCase() : '';

IconData _fileIcon(String name) {
  final ext = _ext(name);
  return switch (ext) {
    'png' || 'jpg' || 'jpeg' || 'gif' || 'webp' => Icons.image_outlined,
    'pdf' => Icons.picture_as_pdf_outlined,
    'doc' || 'docx' => Icons.description_outlined,
    'xls' || 'xlsx' => Icons.table_chart_outlined,
    'zip' || 'rar' || '7z' => Icons.folder_zip_outlined,
    'exe' || 'msi' => Icons.apps_outlined,
    'md' || 'txt' => Icons.text_snippet_outlined,
    'toml' || 'json' || 'yaml' => Icons.code_outlined,
    _ => Icons.insert_drive_file_outlined,
  };
}

String _typeLabel(_FsEntry entry) {
  if (entry.isDir && _isDriveRoot(entry.path)) {
    return switch (entry.driveKind) {
      RemoteFsDriveKind.REMOTE_FS_DRIVE_KIND_REMOTE => 'Network drive',
      RemoteFsDriveKind.REMOTE_FS_DRIVE_KIND_REMOVABLE => 'Removable disk',
      RemoteFsDriveKind.REMOTE_FS_DRIVE_KIND_CDROM => 'DVD drive',
      RemoteFsDriveKind.REMOTE_FS_DRIVE_KIND_RAM => 'RAM disk',
      _ => 'Local disk',
    };
  }
  if (entry.isDir) return 'File folder';
  final ext = _ext(entry.name);
  return ext.isEmpty ? 'File' : '${ext.toUpperCase()} File';
}

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(bytes < 10 * 1024 ? 1 : 0)} KB';
  if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(bytes < 10 * 1024 * 1024 ? 1 : 0)} MB';
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

String _formatDate(DateTime dt) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}

String _parentDirPath(String path) {
  final pth = path.replaceAll('/', '\\');
  final i = pth.lastIndexOf(r'\');
  if (i <= 0) return pth;
  if (i == 2 && pth[1] == ':') return pth.substring(0, 3);
  return pth.substring(0, i);
}

String _joinPath(String dir, String name) {
  if (dir.isEmpty) return name;
  final d = dir.replaceAll('/', '\\');
  if (d.endsWith(r'\') || d.endsWith(':')) return '$d$name';
  return '$d\\$name';
}

String _basename(String path) {
  final pth = path.replaceAll('/', '\\');
  final i = pth.lastIndexOf(r'\');
  return i < 0 ? pth : pth.substring(i + 1);
}

String _decodeTextPreview(Uint8List data) {
  if (data.isEmpty) return '';
  if (data.length >= 2 && data[0] == 0xFF && data[1] == 0xFE) {
    final codes = <int>[];
    for (var i = 2; i + 1 < data.length; i += 2) {
      final unit = data[i] | (data[i + 1] << 8);
      if (unit == 0) break;
      codes.add(unit);
    }
    return String.fromCharCodes(codes);
  }
  return utf8.decode(data, allowMalformed: true);
}
