import 'package:alienai_c35/c/store/canvas_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CanvasStore', () {
    test('initial state is closed with no artifact', () {
      final store = CanvasStore();
      expect(store.hasArtifact, isFalse);
      expect(store.isOpen, isFalse);
      expect(store.artifact, isNull);
      expect(store.activeTab, CanvasTab.editor);
    });

    test('openCode creates a code artifact and opens the canvas', () {
      final store = CanvasStore();
      store.openCode(title: 'main.dart', code: 'void main() {}', language: 'dart');

      expect(store.hasArtifact, isTrue);
      expect(store.isOpen, isTrue);
      expect(store.artifact?.title, 'main.dart');
      expect(store.artifact?.language, 'dart');
      expect(store.artifact?.type, 'code');
      expect(store.artifact?.content, 'void main() {}');
      expect(store.activeTab, CanvasTab.editor);
      expect(store.artifact?.versions.length, 1);
    });

    test('openCode with markdown language defaults to preview tab', () {
      final store = CanvasStore();
      store.openCode(title: 'README.md', code: '# Title', language: 'markdown');

      expect(store.hasArtifact, isTrue);
      expect(store.artifact?.type, 'markdown');
      expect(store.activeTab, CanvasTab.preview);
    });

    test('updateContent without createVersion updates active content', () {
      final store = CanvasStore();
      store.openCode(title: 'test.py', code: 'print("hi")', language: 'python');

      store.updateContent('print("hello world")');
      expect(store.artifact?.content, 'print("hello world")');
      expect(store.artifact?.versions.length, 1);
    });

    test('updateContent with createVersion adds a new version snapshot', () {
      final store = CanvasStore();
      store.openCode(title: 'test.py', code: 'print("v1")', language: 'python');

      store.updateContent('print("v2")', createVersion: true, description: 'added feature');
      expect(store.artifact?.content, 'print("v2")');
      expect(store.artifact?.versions.length, 2);
      expect(store.artifact?.versions[1].version, 2);
      expect(store.artifact?.versions[1].description, 'added feature');
      expect(store.artifact?.activeVersionIndex, 1);

      // Restore v1
      store.restoreVersion(0);
      expect(store.artifact?.content, 'print("v1")');
      expect(store.artifact?.activeVersionIndex, 0);
    });

    test('toggleOpen and close update isOpen flag', () {
      final store = CanvasStore();
      store.openCode(title: 'test.js', code: 'console.log(1)', language: 'javascript');
      expect(store.isOpen, isTrue);

      store.close();
      expect(store.isOpen, isFalse);

      store.toggleOpen();
      expect(store.isOpen, isTrue);
    });

    test('clear resets store', () {
      final store = CanvasStore();
      store.openCode(title: 'test.js', code: 'console.log(1)', language: 'javascript');
      store.clear();

      expect(store.hasArtifact, isFalse);
      expect(store.isOpen, isFalse);
      expect(store.artifact, isNull);
    });
  });
}
