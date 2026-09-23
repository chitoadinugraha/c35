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
const _treeWidth = 240.0;
const _listBreakpoint = 720.0;
const _previewBreakpoint = 1024.0;
const _previewMaxBytes = 256 * 1024;

enum _MobilePane { tree, list, preview }

class UiDeviceFiles extends StatefulWidget {
  const UiDeviceFiles({super.key, required this.session, this.searchQuery = ''});

  final RemoteSession session;
  final String searchQuery;

  @override
  State<UiDeviceFiles> createState() => _UiDeviceFilesState();
}

class _UiDeviceFilesState extends State<UiDeviceFiles> {
  static final _mockRoots = _buildMockRoots();
  static const _mockDefaultPath = r'C:\Users\CHITO\Documents';

  final _expanded = <String>{};
  final _dirCache = <String, List<_FsEntry>>{};
  List<_FsEntry>? _roots;
  var _selectedPath = '';
  String? _selectedFilePath;
  var _mobilePane = _MobilePane.tree;
  var _loadingRoots = false;
  var _loadingDir = false;
  String? _listError;
  var _connecting = false;

  var _previewLoading = false;
  String? _previewText;
  Uint8List? _previewImage;
  String? _previewError;

  bool get _useMock => widget.session.connected.value && widget.session.fs == null;

  @override
  void initState() {
    super.initState();
    widget.session.connected.addListener(_onConnectionChanged);
    if (widget.session.connected.value && widget.session.fs != null) _loadRoots();
  }

  @override
  void dispose() {
    widget.session.connected.removeListener(_onConnectionChanged);
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
    if (_useMock) return;
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
    if (fs == null || _useMock) {
      final mock = _entryAt(path);
      if (mock == null) return;
      setState(() {
        _previewLoading = false;
        _previewError = null;
        _previewText = mock.previewText;
        _previewImage = mock.previewKind == _PreviewKind.image ? Uint8List(0) : null;
      });
      return;
    }
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

  List<_FsEntry> get _effectiveRoots => _useMock ? _mockRoots : (_roots ?? const []);

  List<_FsEntry> _dirEntries(String path) {
    if (_useMock) return _entryAt(path)?.children ?? const [];
    return _dirCache[path] ?? const [];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.session.connected.value && widget.session.fs != null && _roots == null && !_loadingRoots) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadRoots();
      });
    }
    if (_useMock && _selectedPath.isEmpty) {
      _selectedPath = _mockDefaultPath;
      _expanded.addAll(['C:', r'C:\Users', r'C:\Users\CHITO']);
    }
    return ListenableBuilder(
      listenable: widget.session.connected,
      builder: (context, _) {
        if (!widget.session.connected.value) return _connectPrompt();
        if (_useMock && _roots == null) return _loadingPane('Connecting file channel…');
        if (_loadingRoots && _roots == null && !_useMock) return _loadingPane('Loading drives…');
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
    final w = MediaQuery.sizeOf(context).width;
    final wide = w >= _listBreakpoint;
    final showPreviewPane = w >= _previewBreakpoint;
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: _treeWidth, child: _treePane(showBack: false)),
          const VerticalDivider(width: 1, color: _border),
          Expanded(flex: showPreviewPane ? 5 : 1, child: _listPane(compact: !showPreviewPane)),
          if (showPreviewPane) ...[
            const VerticalDivider(width: 1, color: _border),
            Expanded(flex: 4, child: _previewPane(showBack: false)),
          ],
        ],
      );
    }
    return switch (_mobilePane) {
      _MobilePane.tree => _treePane(showBack: false),
      _MobilePane.list => _listPane(compact: true, showBack: true, onBack: () => setState(() => _mobilePane = _MobilePane.tree)),
      _MobilePane.preview => _previewPane(showBack: true, onBack: () => setState(() => _mobilePane = _MobilePane.list)),
    };
  }

  void _selectDir(_FsEntry node) {
    setState(() {
      _selectedPath = node.path;
      _selectedFilePath = null;
      _clearPreview();
      if (MediaQuery.sizeOf(context).width < _listBreakpoint) _mobilePane = _MobilePane.list;
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

  Widget _treePane({required bool showBack, VoidCallback? onBack}) => ColoredBox(
        color: _masterBg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _paneHeader('Folders', showBack: showBack, onBack: onBack),
            Expanded(
              child: _effectiveRoots.isEmpty
                  ? const Center(child: Text('No drives found', style: TextStyle(color: _muted, fontSize: 13)))
                  : ListView(padding: const EdgeInsets.fromLTRB(4, 4, 4, 8), children: [for (final n in _effectiveRoots) _treeNode(n, 0)]),
            ),
          ],
        ),
      );

  Widget _listPane({required bool compact, bool showBack = false, VoidCallback? onBack}) => ColoredBox(
        color: const Color(0xFF08080A),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _paneHeader(_selectedPath.isEmpty ? 'Files' : _selectedPath, mono: true, showBack: showBack, onBack: onBack),
            if (!compact) _fileListHeader(),
            if (_listError != null) _errorBanner(_listError!, onRetry: () {
                  _dirCache.remove(_selectedPath);
                  _loadDir(_selectedPath, force: true);
                }),
            Expanded(child: _loadingDir ? _loadingPane('Loading folder…') : _fileList(compact: compact)),
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
      return SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: SelectableText(_previewText!, style: const TextStyle(color: _text, fontSize: 12, fontFamily: 'Consolas', height: 1.45)),
      );
    }
    if (_previewImage != null) {
      if (_previewImage!.isEmpty && _useMock) return _mockImagePreview(file.name);
      return Center(
        child: InteractiveViewer(
          child: Image.memory(_previewImage!, gaplessPlayback: true, errorBuilder: (_, __, ___) => _mockImagePreview(file.name)),
        ),
      );
    }
    if (_useMock && file.previewKind == _PreviewKind.text) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: SelectableText(file.previewText ?? '', style: const TextStyle(color: _text, fontSize: 12, fontFamily: 'Consolas', height: 1.45)),
      );
    }
    if (_useMock && file.previewKind == _PreviewKind.image) return _mockImagePreview(file.name);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Preview not available for this file type.\nDownload to open locally.', textAlign: TextAlign.center, style: TextStyle(color: _muted.withValues(alpha: 0.9), fontSize: 13)),
      ),
    );
  }

  Widget _mockImagePreview(String name) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 220,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(colors: [Color(0xFF1E3A5F), Color(0xFF34D399)]),
                border: Border.all(color: _border),
              ),
              child: const Icon(Icons.image_outlined, size: 48, color: _muted),
            ),
            const SizedBox(height: 12),
            Text(name, style: const TextStyle(color: _muted, fontSize: 12)),
          ],
        ),
      );

  Widget _paneHeader(String title, {bool mono = false, bool showBack = false, VoidCallback? onBack}) => Container(
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
              child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w500, fontFamily: mono ? 'Consolas' : null)),
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

  Widget _fileList({required bool compact}) {
    if (_selectedPath.isEmpty && !_useMock) {
      return const Center(child: Text('Select a folder', style: TextStyle(color: _muted, fontSize: 13)));
    }
    final q = widget.searchQuery.trim().toLowerCase();
    final entries = _dirEntries(_selectedPath).where((e) => q.isEmpty || e.name.toLowerCase().contains(q)).toList();
    if (entries.isEmpty) {
      return Center(child: Text(q.isEmpty ? 'This folder is empty' : 'No matches', style: const TextStyle(color: _muted, fontSize: 13)));
    }
    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: _border),
      itemBuilder: (context, i) => _fileRow(entries[i], compact: compact),
    );
  }

  Widget _fileRow(_FsEntry entry, {required bool compact}) {
    final selectedDir = entry.isDir && entry.path == _selectedPath;
    final selectedFile = !entry.isDir && entry.path == _selectedFilePath;
    final previewable = _canPreview(entry);
    return Material(
      color: selectedDir || selectedFile ? _selectedBg : Colors.transparent,
      child: InkWell(
        onTap: entry.isDir ? () => _selectDir(entry) : previewable ? () => _selectFile(entry) : null,
        hoverColor: const Color(0xFF1C1C22),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12, vertical: compact ? 9 : 7),
          child: compact
              ? Row(
                  children: [
                    Icon(entry.isDir ? Icons.folder_outlined : _fileIcon(entry.name), size: 18, color: entry.isDir ? const Color(0xFFFBBF24) : _muted),
                    const SizedBox(width: 10),
                    Expanded(child: Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _text, fontSize: 13))),
                    if (!entry.isDir) Text(_formatSize(entry.size), style: const TextStyle(color: _muted, fontSize: 11)),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Row(
                        children: [
                          Icon(entry.isDir ? Icons.folder_outlined : _fileIcon(entry.name), size: 16, color: entry.isDir ? const Color(0xFFFBBF24) : _muted),
                          const SizedBox(width: 8),
                          Expanded(child: Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _text, fontSize: 13))),
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

  Widget _treeNode(_FsEntry node, int depth) {
    final q = widget.searchQuery.trim().toLowerCase();
    if (q.isNotEmpty && !_nodeMatches(node, q)) return const SizedBox.shrink();
    final expanded = _expanded.contains(node.path);
    final selected = node.isDir && node.path == _selectedPath;
    final children = _useMock ? node.children : _dirEntries(node.path);
    final hasChildren = node.isDir && (children.isNotEmpty || (!_useMock && !_dirCache.containsKey(node.path)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: selected ? _selectedBg : Colors.transparent,
          child: InkWell(
            onTap: node.isDir ? () => _selectDir(node) : null,
            hoverColor: const Color(0xFF1C1C22),
            child: Padding(
              padding: EdgeInsets.fromLTRB(4.0 + depth * 14.0, 2, 4, 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 24,
                    child: hasChildren
                        ? IconButton(
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            iconSize: 16,
                            splashRadius: 14,
                            onPressed: () => _toggleExpand(node),
                            icon: Icon(expanded ? Icons.expand_more : Icons.chevron_right, size: 16, color: _muted),
                          )
                        : null,
                  ),
                  Icon(node.isDir ? Icons.folder_outlined : _fileIcon(node.name), size: 15, color: node.isDir ? const Color(0xFFFBBF24) : _muted),
                  const SizedBox(width: 6),
                  Expanded(child: Text(node.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: selected ? _text : const Color(0xFFA1A1AA), fontSize: 12))),
                ],
              ),
            ),
          ),
        ),
        if (expanded && node.isDir) for (final c in children) _treeNode(c, depth + 1),
      ],
    );
  }

  bool _canPreview(_FsEntry entry) {
    if (entry.isDir) return false;
    if (_useMock) return entry.previewKind != _PreviewKind.none;
    return _isTextMime('', entry.path) || _isImageMime('', entry.path);
  }

  bool _nodeMatches(_FsEntry node, String q) {
    if (node.name.toLowerCase().contains(q)) return true;
    final children = _useMock ? node.children : _dirEntries(node.path);
    return children.any((c) => _nodeMatches(c, q));
  }

  _FsEntry? _entryAt(String path) {
    for (final root in _effectiveRoots) {
      if (root.path == path) return root;
      final found = _findPath(root, path);
      if (found != null) return found;
    }
    for (final entries in _dirCache.values) {
      for (final e in entries) {
        if (e.path == path) return e;
      }
    }
    return null;
  }

  _FsEntry? _findPath(_FsEntry node, String path) {
    if (node.path == path) return node;
    for (final c in node.children) {
      final found = _findPath(c, path);
      if (found != null) return found;
    }
    return null;
  }
}

enum _PreviewKind { none, text, image }

class _FsEntry {
  _FsEntry({
    required this.name,
    required this.path,
    this.isDir = false,
    this.size = 0,
    this.modified,
    this.previewKind = _PreviewKind.none,
    this.previewText,
    List<_FsEntry>? children,
  }) : children = children ?? [];

  factory _FsEntry.fromPb(RemoteFsEntry e) => _FsEntry(
        name: e.name,
        path: e.path,
        isDir: e.isDir,
        size: e.size.toInt(),
        modified: e.modifiedMs.toInt() > 0 ? DateTime.fromMillisecondsSinceEpoch(e.modifiedMs.toInt()) : null,
      );

  final String name;
  final String path;
  final bool isDir;
  final int size;
  final DateTime? modified;
  final _PreviewKind previewKind;
  final String? previewText;
  final List<_FsEntry> children;
}

List<_FsEntry> _buildMockRoots() {
  final c = _FsEntry(name: 'C:', path: 'C:');
  final users = c.child('Users');
  final chito = users.child(r'C:\Users\CHITO');
  chito
      .child('Desktop')
      .file('Notes.txt', 2048, DateTime(2026, 9, 18), kind: _PreviewKind.text, text: 'TODO\n- finish device files UI\n- wire streaming preview')
      .file('Screenshot.png', 842000, DateTime(2026, 9, 19), kind: _PreviewKind.image);
  final docs = chito.child('Documents');
  docs
      .child('Work')
      .file('report.docx', 48000, DateTime(2026, 9, 15))
      .file('budget.xlsx', 22000, DateTime(2026, 9, 10));
  docs.child('Personal').file('resume.pdf', 310000, DateTime(2026, 8, 28));
  chito
      .child('Downloads')
      .file('setup.exe', 12400000, DateTime(2026, 9, 20))
      .file('archive.zip', 5600000, DateTime(2026, 9, 17));
  chito.child('Pictures').file('wallpaper.jpg', 1200000, DateTime(2026, 7, 4), kind: _PreviewKind.image);
  c.child('Program Files').child('Alien AI').file('agent.exe', 8900000, DateTime(2026, 9, 1));
  c.child('Windows');

  final d = _FsEntry(name: 'D:', path: 'D:');
  final projects = d.child('Projects');
  projects
      .child('alienai')
      .file('README.md', 1200, DateTime(2026, 9, 12), kind: _PreviewKind.text, text: '# alienai\n\nRemote agent runtime.')
      .file('Cargo.toml', 800, DateTime(2026, 9, 12), kind: _PreviewKind.text, text: '[package]\nname = "c_remote_core"\nversion = "0.1.0"');
  projects.child('c35').file('spec.md', 4500, DateTime(2026, 9, 20), kind: _PreviewKind.text, text: '# c35 spec\n\nDevice files stream over agent session.').file('dev.ps1', 3200, DateTime(2026, 9, 19));
  d.child('Backup').file('drive-image.wim', 48000000000, DateTime(2026, 6, 1));

  return [c, d];
}

extension on _FsEntry {
  _FsEntry child(String name) {
    final childPath = path.endsWith(r'\') || path.endsWith('/') ? '$path$name' : '$path\\$name';
    final n = _FsEntry(name: name, path: childPath, isDir: true);
    children.add(n);
    return n;
  }

  _FsEntry file(String name, int size, DateTime modified, {_PreviewKind kind = _PreviewKind.none, String? text}) {
    final filePath = path.endsWith(r'\') || path.endsWith('/') ? '$path$name' : '$path\\$name';
    final n = _FsEntry(name: name, path: filePath, size: size, modified: modified, previewKind: kind, previewText: text);
    children.add(n);
    return n;
  }
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
