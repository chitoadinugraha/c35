import 'dart:convert';

import 'package:alienai_c35/c/pb/c35/remote.pb.dart';
import 'package:alienai_c35/c/pb/c35/skill.pb.dart';
import 'package:fixnum/fixnum.dart';

String skillPhrasesJsonFromTitle(String title) {
  final t = title.trim();
  if (t.isEmpty) return '[]';
  return jsonEncode([t]);
}

String skillBodyMdFromTeach({required String title, required List<RemoteTeachStep> steps}) {
  final lines = <String>[
    '# $title',
    '',
    'Recorded automation on this device.',
    '',
  ];
  if (steps.isEmpty) {
    lines.add('_No steps were captured._');
  } else {
    lines.add('## Steps');
    for (final s in steps) {
      final label = s.label.trim().isNotEmpty ? s.label.trim() : s.kind;
      lines.add('${s.ord}. **$label** (${s.kind})');
    }
  }
  lines.add('');
  return lines.join('\n');
}

List<SkillStep> skillStepsFromRemoteTeach(List<RemoteTeachStep> wire, {int ownerIid = 0}) => [
      for (final s in wire)
        SkillStep(
          ownerIid: Int64(ownerIid),
          ord: s.ord,
          kind: s.kind,
          label: s.label,
          axTargetJson: s.axTargetJson,
        ),
    ];

Skill skillFromTeachReview({
  required int ownerIid,
  required SkillScope scope,
  required int deviceIid,
  required String title,
  required String bodyMd,
  required List<RemoteTeachStep> steps,
  bool autoSubmit = false,
  String phrasesJson = '',
}) =>
    Skill(
      ownerIid: Int64(ownerIid),
      scope: scope,
      deviceIid: Int64(deviceIid),
      title: title.trim(),
      bodyMd: bodyMd,
      source: SkillSource.SKILL_SOURCE_TAUGHT,
      phrasesJson: phrasesJson.isNotEmpty ? phrasesJson : skillPhrasesJsonFromTitle(title),
      autoSubmit: autoSubmit,
      steps: skillStepsFromRemoteTeach(steps, ownerIid: ownerIid),
    );

const skillAutoRepairPausedMessage = 'Auto-repair paused — this skill needs attention.';

const skillCircuitBreakerMaxPatchesPerDay = 3;

/// True when self-heal circuit breaker tripped or repeated patches without recovery.
bool skillNeedsAttention(Skill skill) {
  if (skill.patchCount >= skillCircuitBreakerMaxPatchesPerDay) return true;
  if (skill.patchCount >= 2 && skill.consecutiveOk == 0) return true;
  return false;
}

String skillRunPromptText(Skill skill) {
  final id = skill.id.toInt();
  final title = skill.title.trim();
  if (id > 0) {
    return 'Run the saved skill "$title" (skill_id=$id) on this device using its recorded steps.';
  }
  return 'Run the saved skill "$title" using its recorded steps.';
}
