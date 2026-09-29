import 'dart:convert';

import 'package:alienai_c35/c/pb/c35/skill.pb.dart';
import 'package:alienai_c35/c/skill/skill_md.dart';
import 'package:flutter/material.dart';

class IoSkillEditResult {
  const IoSkillEditResult({
    required this.title,
    required this.bodyMd,
    required this.phrasesJson,
    required this.autoRun,
    required this.targetApp,
    required this.urlPattern,
  });

  final String title;
  final String bodyMd;
  final String phrasesJson;
  final bool autoRun;
  final String targetApp;
  final String urlPattern;
}

Future<IoSkillEditResult?> ioSkillEditShow(BuildContext context, Skill skill) =>
    showDialog<IoSkillEditResult>(
      context: context,
      builder: (_) => _IoSkillEditDialog(skill: skill),
    );

String _phrasesToCommaField(String phrasesJson) {
  if (phrasesJson.trim().isEmpty) return '';
  try {
    final raw = jsonDecode(phrasesJson);
    if (raw is List) return raw.map((e) => '$e'.trim()).where((e) => e.isNotEmpty).join(', ');
  } catch (_) {}
  return phrasesJson;
}

String _commaFieldToPhrasesJson(String text) {
  final parts = text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return '[]';
  return jsonEncode(parts);
}

class _IoSkillEditDialog extends StatefulWidget {
  const _IoSkillEditDialog({required this.skill});

  final Skill skill;

  @override
  State<_IoSkillEditDialog> createState() => _IoSkillEditDialogState();
}

class _IoSkillEditDialogState extends State<_IoSkillEditDialog> {
  late final _titleCtrl = TextEditingController(text: widget.skill.title);
  late final _bodyCtrl = TextEditingController(text: widget.skill.bodyMd);
  late final _phrasesCtrl = TextEditingController(text: _phrasesToCommaField(widget.skill.phrasesJson));
  late final _targetAppCtrl = TextEditingController(text: widget.skill.targetApp);
  late final _urlPatternCtrl = TextEditingController(text: widget.skill.urlPattern);
  late var _autoRun = widget.skill.autoRun;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _phrasesCtrl.dispose();
    _targetAppCtrl.dispose();
    _urlPatternCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    Navigator.pop(
      context,
      IoSkillEditResult(
        title: title,
        bodyMd: _bodyCtrl.text,
        phrasesJson: _commaFieldToPhrasesJson(_phrasesCtrl.text).isNotEmpty
            ? _commaFieldToPhrasesJson(_phrasesCtrl.text)
            : skillPhrasesJsonFromTitle(title),
        autoRun: _autoRun,
        targetApp: _targetAppCtrl.text.trim(),
        urlPattern: _urlPatternCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('Edit skill', style: TextStyle(color: Color(0xFFF4F4F5), fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleCtrl,
                  autofocus: true,
                  style: const TextStyle(color: Color(0xFFF4F4F5)),
                  decoration: const InputDecoration(labelText: 'Title', labelStyle: TextStyle(color: Color(0xFF71717A))),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _phrasesCtrl,
                  style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Trigger phrases (comma-separated)',
                    labelStyle: TextStyle(color: Color(0xFF71717A)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _targetAppCtrl,
                  style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 13),
                  decoration: const InputDecoration(labelText: 'Target app', labelStyle: TextStyle(color: Color(0xFF71717A))),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _urlPatternCtrl,
                  style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 13),
                  decoration: const InputDecoration(labelText: 'URL pattern', labelStyle: TextStyle(color: Color(0xFF71717A))),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _bodyCtrl,
                  maxLines: 8,
                  style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 13, fontFamily: 'monospace'),
                  decoration: const InputDecoration(
                    labelText: 'Instructions (Markdown)',
                    alignLabelWithHint: true,
                    labelStyle: TextStyle(color: Color(0xFF71717A)),
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: _autoRun,
                  onChanged: (v) => setState(() => _autoRun = v ?? false),
                  title: const Text('Auto-run when matched', style: TextStyle(color: Color(0xFFF4F4F5), fontSize: 13)),
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: const Color(0xFF34D399),
                ),
              ],
            ),
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
