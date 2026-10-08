import 'package:alienai_c35/c/site/design/site_design_store.dart';
import 'package:alienai_c35/guest_site/guest_site_effect_stack.dart';
import 'package:alienai_c35/widgets/overlay_effect/ui_overlay_effect_stack.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('adding rain_shower persists presetId in theme json', () {
    final store = SiteDesignStore();
    store.overlayEffectAdd(presetId: 'rain_shower');
    expect(store.toThemeJson(), contains('"presetId":"rain_shower"'));
    expect(store.toThemeJson(), contains('"accent"'));
    expect(store.toThemeJson(), contains('"blocks"'));
  });

  testWidgets('GuestSiteEffectStack paints rain and skips unknown presets', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 240,
          height: 360,
          child: GuestSiteEffectStack(
            effects: [
              {'id': 'e1', 'presetId': 'rain_shower', 'params': <String, dynamic>{}, 'active': true},
            ],
            child: Text('page'),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(UiOverlayEffectStack), findsOneWidget);
    expect(find.text('page'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 240,
          height: 360,
          child: GuestSiteEffectStack(
            effects: [
              {'id': 'e2', 'presetId': 'not_a_preset', 'params': <String, dynamic>{}, 'active': true},
            ],
            child: Text('page'),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(UiOverlayEffectStack), findsNothing);
    expect(find.text('page'), findsOneWidget);
  });
}
