import 'package:flutter/material.dart';

class IoSkillTeachResult {
  const IoSkillTeachResult({required this.title, required this.bodyMd, this.autoSubmit = false});
  final String title;
  final String bodyMd;
  final bool autoSubmit;
}

Future<IoSkillTeachResult?> ioSkillTeachShow(BuildContext context) => showDialog<IoSkillTeachResult>(
      context: context,
      builder: (_) => const _IoSkillTeachDialog(),
    );

class _IoSkillTeachDialog extends StatefulWidget {
  const _IoSkillTeachDialog();
  @override
  State<_IoSkillTeachDialog> createState() => _IoSkillTeachDialogState();
}

class _IoSkillTeachDialogState extends State<_IoSkillTeachDialog> {
  late final _title = TextEditingController();
  late final _body = TextEditingController(text: '# Skill instructions\n\nDescribe what this skill does…\n');
  bool _autoSubmit = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    Navigator.pop(context, IoSkillTeachResult(title: title, bodyMd: _body.text, autoSubmit: _autoSubmit));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('Teach skill', style: TextStyle(color: Color(0xFFF4F4F5), fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _title,
                autofocus: true,
                style: const TextStyle(color: Color(0xFFF4F4F5)),
                decoration: const InputDecoration(labelText: 'Title', labelStyle: TextStyle(color: Color(0xFF71717A))),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _body,
                maxLines: 8,
                style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 13, fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  labelText: 'Instructions (Markdown)',
                  alignLabelWithHint: true,
                  labelStyle: TextStyle(color: Color(0xFF71717A)),
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: _autoSubmit,
                onChanged: (v) => setState(() => _autoSubmit = v ?? false),
                title: const Text(
                  'Submit to Alien AI Public Skill Library',
                  style: TextStyle(color: Color(0xFFF4F4F5), fontSize: 13),
                ),
                subtitle: const Text(
                  'Share this skill with the community after 5 successful runs',
                  style: TextStyle(color: Color(0xFF71717A), fontSize: 11),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: const Color(0xFF34D399),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF34D399), foregroundColor: Colors.black),
            child: const Text('Save'),
          ),
        ],
      );
}
