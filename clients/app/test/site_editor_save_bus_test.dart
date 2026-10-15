import 'package:alienai_c35/c/site/site_editor_save_bus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('save bus stays saving until all in-flight saves finish', () async {
    final bus = SiteEditorSaveBus();
    bus.beginSave();
    bus.beginSave();
    expect(bus.saving, isTrue);

    bus.endSaveSuccess();
    expect(bus.saving, isTrue);

    bus.endSaveSuccess();
    expect(bus.saving, isFalse);
  });

  test('siteEditorSaveRun pairs begin and end on success and error', () async {
    final bus = SiteEditorSaveBus();
    await siteEditorSaveRun(bus, () async {});
    expect(bus.saving, isFalse);

    await expectLater(
      siteEditorSaveRun(bus, () async => throw StateError('fail')),
      throwsStateError,
    );
    expect(bus.saving, isFalse);
    expect(bus.error, contains('fail'));
  });
}
