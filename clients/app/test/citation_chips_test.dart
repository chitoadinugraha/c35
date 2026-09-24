import 'dart:convert';

import 'package:alienai_c35/c/trace/trace_log.dart';
import 'package:alienai_c35/c/trace/trace_view.dart';
import 'package:alienai_c35/widgets/ai/ui_citation_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Citation helper functions', () {
    test('citationHost extracts and strips www', () {
      expect(citationHost('https://www.google.com/search?q=test'), 'google.com');
      expect(citationHost('http://indonesia.go.id/news/123'), 'indonesia.go.id');
      expect(citationHost('https://en.wikipedia.org/wiki/Jakarta'), 'en.wikipedia.org');
      expect(citationHost('invalid-url'), '');
    });

    test('citationFaviconUrl builds correct Google S2 URL', () {
      expect(
        citationFaviconUrl('https://www.google.com/search'),
        'https://www.google.com/s2/favicons?domain=google.com&sz=32',
      );
    });
  });

  group('citationsFromTraceLogs extraction', () {
    test('extracts and dedupes from web.search and web.visit logs', () {
      final logs = <TraceLogDoc>[
        TraceLogDoc(
          topic: 'tool_result',
          text: jsonEncode({
            'ok': true,
            'tool': 'web.search',
            'results': [
              {
                'title': 'Google Search',
                'url': 'https://www.google.com/search',
                'snippet': 'Google snippet',
              },
              {
                'title': 'Indonesia Portal',
                'url': 'https://indonesia.go.id',
                'snippet': 'Official government portal',
              },
              {
                'title': 'Google Duplicate Host',
                'url': 'https://google.com/about',
                'snippet': 'Another google page',
              },
            ],
          }),
          metaJson: jsonEncode({'tool': 'web.search'}),
        ),
        TraceLogDoc(
          topic: 'tool_result',
          text: jsonEncode({
            'ok': true,
            'tool': 'web.visit',
            'url': 'https://en.wikipedia.org/wiki/Indonesia',
            'title': 'Indonesia - Wikipedia',
            'description': 'Wikipedia article on Indonesia',
          }),
          metaJson: jsonEncode({'tool': 'web.visit'}),
        ),
      ];

      final citations = citationsFromTraceLogs(logs);
      expect(citations.length, 3);
      expect(citations[0].url, 'https://www.google.com/search');
      expect(citations[0].title, 'Google Search');
      expect(citations[1].url, 'https://indonesia.go.id');
      expect(citations[2].url, 'https://en.wikipedia.org/wiki/Indonesia');
    });

    test('extracts from web.research dossier', () {
      final logs = <TraceLogDoc>[
        TraceLogDoc(
          topic: 'tool_result',
          text: jsonEncode({
            'ok': true,
            'tool': 'web.research',
            'dossier': [
              {
                'title': 'Deep Research 1',
                'url': 'https://research.org/report',
                'summary': 'Summary text',
              },
            ],
          }),
          metaJson: jsonEncode({'tool': 'web.research'}),
        ),
      ];

      final citations = citationsFromTraceLogs(logs);
      expect(citations.length, 1);
      expect(citations[0].title, 'Deep Research 1');
      expect(citations[0].url, 'https://research.org/report');
    });
  });

  group('UiCitationChips widget', () {
    testWidgets('renders citation chips with hosts', (tester) async {
      final citations = [
        const Citation(
          url: 'https://indonesia.go.id/portal',
          title: 'Indonesia Portal',
        ),
        const Citation(
          url: 'https://en.wikipedia.org/wiki/Indonesia',
          title: 'Wikipedia Indonesia',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UiCitationChips(citations: citations),
          ),
        ),
      );

      expect(find.text('indonesia.go.id'), findsOneWidget);
      expect(find.text('en.wikipedia.org'), findsOneWidget);
    });

    testWidgets('renders nothing when citations list is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UiCitationChips(citations: []),
          ),
        ),
      );

      expect(find.byType(Wrap), findsNothing);
    });
  });
}
