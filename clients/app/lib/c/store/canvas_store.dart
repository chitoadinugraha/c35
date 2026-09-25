import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

enum CanvasTab {
  editor,
  preview,
  diff,
}

class CanvasVersion {
  const CanvasVersion({
    required this.version,
    required this.content,
    required this.createdAtMs,
    this.description = '',
  });

  final int version;
  final String content;
  final int createdAtMs;
  final String description;

  Map<String, dynamic> toJson() => {
        'version': version,
        'content': content,
        'createdAtMs': createdAtMs,
        'description': description,
      };

  factory CanvasVersion.fromJson(Map<String, dynamic> j) => CanvasVersion(
        version: j['version'] as int? ?? 1,
        content: '${j['content'] ?? ''}',
        createdAtMs: j['createdAtMs'] as int? ?? 0,
        description: '${j['description'] ?? ''}',
      );
}

class CanvasArtifact {
  CanvasArtifact({
    required this.id,
    required this.title,
    required this.language,
    required this.type,
    required this.content,
    List<CanvasVersion>? versions,
    this.activeVersionIndex = 0,
  }) : versions = versions ??
            [
              CanvasVersion(
                version: 1,
                content: content,
                createdAtMs: DateTime.now().millisecondsSinceEpoch,
                description: 'Initial version',
              ),
            ];

  final String id;
  String title;
  String language;
  String type; // 'code' | 'markdown' | 'text'
  String content;
  final List<CanvasVersion> versions;
  int activeVersionIndex;

  CanvasVersion? get activeVersion =>
      activeVersionIndex >= 0 && activeVersionIndex < versions.length
          ? versions[activeVersionIndex]
          : versions.isNotEmpty
              ? versions.last
              : null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'language': language,
        'type': type,
        'content': content,
        'versions': versions.map((v) => v.toJson()).toList(),
        'activeVersionIndex': activeVersionIndex,
      };

  factory CanvasArtifact.fromJson(Map<String, dynamic> j) {
    final vList = (j['versions'] as List? ?? const [])
        .map((e) => CanvasVersion.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return CanvasArtifact(
      id: '${j['id'] ?? ''}',
      title: '${j['title'] ?? 'Document'}',
      language: '${j['language'] ?? 'text'}',
      type: '${j['type'] ?? 'code'}',
      content: '${j['content'] ?? ''}',
      versions: vList,
      activeVersionIndex: j['activeVersionIndex'] as int? ?? 0,
    );
  }
}

class CanvasStore extends ChangeNotifier {
  final List<CanvasArtifact> _artifacts = [];
  int _activeArtifactIndex = -1;
  bool _isOpen = false;
  CanvasTab _activeTab = CanvasTab.editor;

  List<CanvasArtifact> get artifacts => List.unmodifiable(_artifacts);
  CanvasArtifact? get artifact => _activeArtifactIndex >= 0 && _activeArtifactIndex < _artifacts.length
      ? _artifacts[_activeArtifactIndex]
      : null;
  int get activeArtifactIndex => _activeArtifactIndex;
  bool get isOpen => _isOpen;
  CanvasTab get activeTab => _activeTab;
  bool get hasArtifact => _artifacts.isNotEmpty;

  void openArtifact(CanvasArtifact artifact, {bool open = true}) {
    final existingIdx = _artifacts.indexWhere((a) => a.id == artifact.id || a.title == artifact.title);
    if (existingIdx >= 0) {
      _activeArtifactIndex = existingIdx;
      if (artifact.content.isNotEmpty && artifact.content != _artifacts[existingIdx].content) {
        _artifacts[existingIdx].content = artifact.content;
      }
    } else {
      _artifacts.add(artifact);
      _activeArtifactIndex = _artifacts.length - 1;
    }

    final artType = this.artifact?.type;
    final artLang = this.artifact?.language.toLowerCase();
    if (artType == 'markdown' || artType == 'slide' || artLang == 'slide' || artLang == 'slides' || artLang == 'marp') {
      _activeTab = CanvasTab.preview;
    } else {
      _activeTab = CanvasTab.editor;
    }
    if (open) {
      _isOpen = true;
    }
    notifyListeners();
  }

  void selectArtifact(int index) {
    if (index < 0 || index >= _artifacts.length) return;
    _activeArtifactIndex = index;
    final artType = _artifacts[index].type;
    final artLang = _artifacts[index].language.toLowerCase();
    if (artType == 'markdown' || artType == 'slide' || artLang == 'slide' || artLang == 'slides' || artLang == 'marp') {
      _activeTab = CanvasTab.preview;
    }
    notifyListeners();
  }

  void closeArtifact(int index) {
    if (index < 0 || index >= _artifacts.length) return;
    _artifacts.removeAt(index);
    if (_artifacts.isEmpty) {
      _activeArtifactIndex = -1;
      _isOpen = false;
    } else if (_activeArtifactIndex >= _artifacts.length) {
      _activeArtifactIndex = _artifacts.length - 1;
    }
    notifyListeners();
  }

  void openCode({
    required String title,
    required String code,
    required String language,
    bool open = true,
  }) {
    final langLower = language.toLowerCase();
    final isMarkdown = langLower == 'markdown' || langLower == 'md';
    final isSlide = langLower == 'slide' || langLower == 'slides' || langLower == 'marp';
    final art = CanvasArtifact(
      id: const Uuid().v4(),
      title: title.isNotEmpty ? title : 'Snippet',
      language: language.isNotEmpty ? language : 'text',
      type: isSlide ? 'slide' : (isMarkdown ? 'markdown' : 'code'),
      content: code,
    );
    openArtifact(art, open: open);
  }

  void setOpen(bool open) {
    if (_isOpen == open) return;
    _isOpen = open;
    notifyListeners();
  }

  void toggleOpen() {
    _isOpen = !_isOpen;
    notifyListeners();
  }

  void setActiveTab(CanvasTab tab) {
    if (_activeTab == tab) return;
    _activeTab = tab;
    notifyListeners();
  }

  void updateContent(
    String newContent, {
    bool createVersion = false,
    String description = 'User edit',
  }) {
    final active = artifact;
    if (active == null) return;
    if (active.content == newContent && !createVersion) return;

    active.content = newContent;

    if (createVersion) {
      final nextVer = active.versions.length + 1;
      final version = CanvasVersion(
        version: nextVer,
        content: newContent,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
        description: description,
      );
      active.versions.add(version);
      active.activeVersionIndex = active.versions.length - 1;
    }
    notifyListeners();
  }

  void restoreVersion(int versionIndex) {
    final active = artifact;
    if (active == null) return;
    if (versionIndex < 0 || versionIndex >= active.versions.length) return;
    final ver = active.versions[versionIndex];
    active.activeVersionIndex = versionIndex;
    active.content = ver.content;
    notifyListeners();
  }

  void close() {
    _isOpen = false;
    notifyListeners();
  }

  void clear() {
    _artifacts.clear();
    _activeArtifactIndex = -1;
    _isOpen = false;
    _activeTab = CanvasTab.editor;
    notifyListeners();
  }
}
