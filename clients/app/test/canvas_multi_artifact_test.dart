import 'package:alienai_c35/c/store/canvas_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CanvasStore Multi-Artifact Tabs', () {
    test('can open multiple artifacts and switch between them', () {
      final store = CanvasStore();
      store.openCode(title: 'file1.dart', code: 'void main() {}', language: 'dart');
      store.openCode(title: 'file2.py', code: 'print(1)', language: 'python');
      store.openCode(title: 'file3.sql', code: 'SELECT 1;', language: 'sql');

      expect(store.artifacts.length, 3);
      expect(store.activeArtifactIndex, 2);
      expect(store.artifact?.title, 'file3.sql');

      // Select first artifact
      store.selectArtifact(0);
      expect(store.activeArtifactIndex, 0);
      expect(store.artifact?.title, 'file1.dart');
      expect(store.artifact?.content, 'void main() {}');

      // Select second artifact
      store.selectArtifact(1);
      expect(store.activeArtifactIndex, 1);
      expect(store.artifact?.title, 'file2.py');
    });

    test('reopening existing artifact selects it instead of duplicating', () {
      final store = CanvasStore();
      store.openCode(title: 'app.dart', code: 'class App {}', language: 'dart');
      store.openCode(title: 'test.dart', code: 'void test() {}', language: 'dart');

      expect(store.artifacts.length, 2);
      expect(store.activeArtifactIndex, 1);

      // Re-open app.dart
      store.openCode(title: 'app.dart', code: 'class App {}', language: 'dart');
      expect(store.artifacts.length, 2);
      expect(store.activeArtifactIndex, 0);
    });

    test('closing artifact removes it and maintains valid active index', () {
      final store = CanvasStore();
      store.openCode(title: 'A', code: 'A', language: 'text');
      store.openCode(title: 'B', code: 'B', language: 'text');
      store.openCode(title: 'C', code: 'C', language: 'text');

      expect(store.artifacts.length, 3);
      expect(store.activeArtifactIndex, 2);

      // Close C
      store.closeArtifact(2);
      expect(store.artifacts.length, 2);
      expect(store.activeArtifactIndex, 1);
      expect(store.artifact?.title, 'B');

      // Close all
      store.closeArtifact(0);
      store.closeArtifact(0);
      expect(store.artifacts.isEmpty, isTrue);
      expect(store.hasArtifact, isFalse);
      expect(store.isOpen, isFalse);
    });
  });
}
