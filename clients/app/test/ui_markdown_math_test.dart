import 'package:alienai_c35/widgets/ai/ui_markdown_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('UiMarkdownBody renders inline and display LaTeX', (tester) async {
    const md = '''
Inline: \$c = \\pm\\sqrt{a^2 + b^2}\$

Block:

\$\$
\\frac{89000}{124000} \\approx 0.718
\$\$
''';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: UiMarkdownBody(data: md)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Math), findsWidgets);
  });

  testWidgets('UiMarkdownBody shows fallback for invalid TeX', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: UiMarkdownBody(data: r'Bad: $\broken{'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('broken'), findsOneWidget);
  });
}