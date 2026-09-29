import 'package:alienai_c35/c/pb/c35/remote.pb.dart';
import 'package:alienai_c35/c/skill/skill_md.dart';
import 'package:flutter/material.dart';

class IoSkillReviewResult {
  const IoSkillReviewResult({
    required this.title,
    required this.bodyMd,
    required this.steps,
    this.autoSubmit = false,
  });

  final String title;
  final String bodyMd;
  final List<RemoteTeachStep> steps;
  final bool autoSubmit;
}

Future<IoSkillReviewResult?> ioSkillReviewShow(
  BuildContext context, {
  required String title,
  required List<RemoteTeachStep> steps,
}) =>
    showDialog<IoSkillReviewResult>(
      context: context,
      builder: (_) => _IoSkillReviewDialog(title: title, steps: steps),
    );

class _IoSkillReviewDialog extends StatefulWidget {
  const _IoSkillReviewDialog({required this.title, required this.steps});

  final String title;
  final List<RemoteTeachStep> steps;

  @override
  State<_IoSkillReviewDialog> createState() => _IoSkillReviewDialogState();
}

class _IoSkillReviewDialogState extends State<_IoSkillReviewDialog> {
  late final _titleCtrl = TextEditingController(text: widget.title);
  late final _bodyCtrl = TextEditingController(
    text: skillBodyMdFromTeach(title: widget.title, steps: widget.steps),
  );
  var _autoSubmit = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    Navigator.pop(
      context,
      IoSkillReviewResult(
        title: title,
        bodyMd: _bodyCtrl.text,
        steps: widget.steps,
        autoSubmit: _autoSubmit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('Review skill', style: TextStyle(color: Color(0xFFF4F4F5), fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _titleCtrl,
                  style: const TextStyle(color: Color(0xFFF4F4F5)),
                  decoration: const InputDecoration(labelText: 'Title', labelStyle: TextStyle(color: Color(0xFF71717A))),
                ),
                const SizedBox(height: 12),
                if (widget.steps.isNotEmpty) ...[
                  Text('${widget.steps.length} recorded steps', style: const TextStyle(color: Color(0xFF71717A), fontSize: 12)),
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF27272A)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: widget.steps.length,
                      itemBuilder: (_, i) {
                        final s = widget.steps[i];
                        final label = s.label.trim().isNotEmpty ? s.label : s.kind;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Text('${s.ord}. $label', style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 12)),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _bodyCtrl,
                  maxLines: 10,
                  style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 13, fontFamily: 'monospace'),
                  decoration: const InputDecoration(
                    labelText: 'Instructions (Markdown)',
                    alignLabelWithHint: true,
                    labelStyle: TextStyle(color: Color(0xFF71717A)),
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: _autoSubmit,
                  onChanged: (v) => setState(() => _autoSubmit = v ?? false),
                  title: const Text('Submit to Alien AI Public Skill Library', style: TextStyle(color: Color(0xFFF4F4F5), fontSize: 13)),
                  subtitle: const Text('After 5 successful runs', style: TextStyle(color: Color(0xFF71717A), fontSize: 11)),
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: const Color(0xFF34D399),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Discard')),
          FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF34D399), foregroundColor: Colors.black),
            child: const Text('Save skill'),
          ),
        ],
      );
}
