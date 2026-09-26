import 'dart:typed_data';

import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/pb/c35/remote.pb.dart';
import 'package:alienai_c35/c/remote/remote_session.dart';
import 'package:alienai_c35/widgets/ui/ui_alert.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _masterBg = Color(0xFF0C0C10);
const _panel = Color(0xFF111114);
const _selectedBg = Color(0xFF18181B);
const _accent = Color(0xFF34D399);
const _previewBreakpoint = 1024.0;
const _previewMaxBytes = 256 * 1024;

enum _MobilePane { explorer, preview }

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
  var _mobilePane = _MobilePane.explorer;
  var _loadingRoots = false;
  var _loadingDir = false;
  String? _listError;
  var _connecting = false;

  var _previewLoading = false;
  String? _previewText;
  Uint8List? _previewImage;
  String? _previewError;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    widget.session.connected.addListener(_onConnectionChanged);
    if (widget.session.connected.value && widget.session.fs != null) _loadRoots();
  }

  @override
  void dispose() {
    widget.session.connected.removeListener(_onConnectionChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onConnectionChanged() {
    if (!widget.session.connected.value) {
      setState(() {
        _roots = null;
        _dirCache.clear();
        _expanded.clear();
        _selectedPath = '';
        _selectedFilePath = null;
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
      final buf = BytesBuilder(copy: false);
      var offset = 0;
      var mime = '';
      while (buf.length < _previewMaxBytes) {
        final toRead = _previewMaxBytes - buf.length;
        final res = await fs.fsRead(path, offset: offset, len: toRead);
        if (res.error.isNotEmpty) throw res.error;
        if (mime.isEmpty && res.mime.isNotEmpty) mime = res.mime;
        buf.add(res.data);
        offset += res.data.length;
        if (res.eof || res.data.isEmpty) break;
      }
      final data = buf.takeBytes();
      if (!mounted) return;
      setState(() {
        _previewLoading = false;
        if (_isTextMime(mime, path)) {
          _previewText = String.fromCharCodes(data);
        } else if (_isImageMime(mime, path)) {
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
    if (_mobilePane == _MobilePane.preview) {
      return _previewPane(showBack: true, onBack: () => setState(() => _mobilePane = _MobilePane.explorer));
    }
    if (showPreviewPane) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 5, child: _explorerPane()),
          const VerticalDivider(width: 1, color: _border),
          Expanded(flex: 4, child: _previewPane(showBack: false)),
        ],
      );
    }
    return _explorerPane();
  }

  void _selectDir(_FsEntry node) {
    setState(() {
      _selectedPath = node.path;
      _selectedFilePath = null;
      _clearPreview();
      _expanded.add(node.path);
    });
    _loadDir(node.path);
  }

  void _selectFile(_FsEntry node) {
    if (!_canPreview(node)) return;
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

  Widget _explorerPane() => ColoredBox(
        color: _masterBg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _searchBar(),
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
                      : _explorerList(),
            ),
          ],
        ),
      );

  Widget _searchBar() => Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
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
      return SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: SelectableText(_previewText!, style: const TextStyle(color: _text, fontSize: 12, fontFamily: 'Consolas', height: 1.45)),
      );
    }
    if (_previewImage != null) {
      return Center(
        child: InteractiveViewer(
          child: Image.memory(_previewImage!, gaplessPlayback: true),
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _border))),
        child: Row(
          children: [
            Expanded(flex: 5, child: _colHeader('Name')),
            Expanded(flex: 2, child: _colHeader('Size')),
            Expanded(flex: 2, child: _colHeader('Type')),
            Expanded(flex: 3, child: _colHeader('Modified')),
          ],
        ),
      );

  Widget _colHeader(String label) => Text(label, style: const TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w500));

  Widget _explorerList() => ListView(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
        children: [for (final n in _rootsList) _explorerNode(n, 0)],
      );

  Widget _explorerNode(_FsEntry node, int depth) {
    final q = _searchQuery;
    if (q.isNotEmpty && !_nodeMatches(node, q)) return const SizedBox.shrink();
    final expanded = _expanded.contains(node.path) || (q.isNotEmpty && node.isDir);
    final children = node.isDir ? _dirEntries(node.path) : const <_FsEntry>[];
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
    final selectedDir = entry.isDir && entry.path == _selectedPath;
    final selectedFile = !entry.isDir && entry.path == _selectedFilePath;
    final previewable = _canPreview(entry);
    final indent = 8.0 + depth * 16.0;
    return Material(
      color: selectedDir || selectedFile ? _selectedBg : Colors.transparent,
      child: InkWell(
        onTap: entry.isDir ? () => _selectDir(entry) : previewable ? () => _selectFile(entry) : null,
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
  if (_isDriveRoot(entry.path)) return const Color(0xFF93C5FD);
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
    'txt' || 'md' || 'json' || 'yaml' || 'yml' || 'toml' || 'xml' || 'csv' || 'log' || 'ps1' || 'sh' || 'rs' || 'dart' || 'js' || 'ts' || 'html' || 'css' => true,
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
