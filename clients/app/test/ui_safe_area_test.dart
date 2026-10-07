import 'package:alienai_c35/widgets/ui/ui_safe_area.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('uiSafeBottomInset does not add keyboard height when IME is open', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          viewPadding: EdgeInsets.only(bottom: 336),
          viewInsets: EdgeInsets.only(bottom: 336),
        ),
        child: Builder(
          builder: (context) {
            expect(uiSafeBottomInset(context, 16), 16);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });

  testWidgets('uiSafeBottomInset keeps nav bar when keyboard is closed', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(viewPadding: EdgeInsets.only(bottom: 48)),
        child: Builder(
          builder: (context) {
            expect(uiSafeBottomInset(context, 16), 64);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });

  testWidgets('uiSafeBottomInset keeps nav bar above keyboard when both reported', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          viewPadding: EdgeInsets.only(bottom: 384),
          viewInsets: EdgeInsets.only(bottom: 336),
        ),
        child: Builder(
          builder: (context) {
            expect(uiSafeBottomInset(context, 16), 64);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });
}
