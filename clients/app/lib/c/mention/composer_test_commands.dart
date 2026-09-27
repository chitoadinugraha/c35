/// Root-only composer slash / @mention QA hooks (see ai.mention test_multitask).
const composerTestMultitaskSlash = '/test-multitask';

class ComposerTestMultitaskPayload {
  const ComposerTestMultitaskPayload({
    required this.text,
    required this.displayContent,
    required this.mentionIds,
  });

  final String text;
  final String displayContent;
  final List<String> mentionIds;
}

bool composerSendIsTestMultitask(String text) {
  final t = text.trim().toLowerCase();
  final prefix = '$composerTestMultitaskSlash ';
  return t == composerTestMultitaskSlash || t.startsWith(prefix);
}

ComposerTestMultitaskPayload composerTestMultitaskPayload() {
  return const ComposerTestMultitaskPayload(
    displayContent: composerTestMultitaskSlash,
    mentionIds: ['catalog:research', 'research'],
    text:
        'Run a real multitask: call delegate.run exactly twice in parallel. '
        'Child A goal: compute 17 + 25 and return only the numeric result. '
        'Child B goal: compute 9 * 7 and return only the numeric result. '
        'Wait for both children, then reply with a one-line summary of both results.',
  );
}
