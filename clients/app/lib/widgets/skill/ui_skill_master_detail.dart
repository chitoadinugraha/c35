import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/skill.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:alienai_c35/c/skill/skill_api.dart';
import 'package:alienai_c35/c/skill/skill_md.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/skill/io_skill_add_menu.dart';
import 'package:alienai_c35/widgets/skill/io_skill_catalog_pick.dart';
import 'package:alienai_c35/widgets/skill/io_skill_edit.dart';
import 'package:alienai_c35/widgets/skill/io_skill_teach.dart';
import 'package:alienai_c35/widgets/ui/ui_master_detail.dart';
import 'package:alienai_c35/widgets/ui/ui_page.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);
const _danger = Color(0xFFEF4444);

class UiSkillMasterDetail extends StatefulWidget {
  const UiSkillMasterDetail({
    super.key,
    required this.conn,
    required this.ownerIid,
    required this.scope,
    this.deviceIid = 0,
    this.showTeach = false,
    this.hideBarActions = false,
    this.onDrillBack,
    this.onTeachRemote,
    this.onDevicePrompt,
    this.title,
  });

  final ChatConn conn;
  final int ownerIid;
  final SkillScope scope;
  final int deviceIid;
  final bool showTeach;
  final bool hideBarActions;
  final VoidCallback? onDrillBack;
  final VoidCallback? onTeachRemote;
  final Future<void> Function(String prompt)? onDevicePrompt;
  final String? title;

  @override
  State<UiSkillMasterDetail> createState() => UiSkillMasterDetailState();
}

class UiSkillMasterDetailState extends State<UiSkillMasterDetail> {
  late final _api = SkillApi(widget.conn);
  var _loading = true;
  var _busy = false;
  var _skills = <Skill>[];
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _skills = await _api.list(scope: widget.scope, deviceIid: widget.deviceIid);
      if (_selectedId != null && !_skills.any((s) => '${s.id}' == _selectedId)) _selectedId = null;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Skill? _skillById(String? id) => id == null ? null : _skills.where((s) => '${s.id}' == id).firstOrNull;

  Future<void> installFromCatalog() async {
    if (_busy) return;
    final catalog = await ioSkillCatalogPick(context, api: _api);
    if (catalog == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final skill = await _api.catalogInstall(catalog, scope: widget.scope, deviceIid: widget.deviceIid);
      setState(() {
        _skills = [skill, ..._skills.where((s) => s.id != skill.id)];
        _selectedId = '${skill.id}';
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Installed "${skill.title}"'), behavior: SnackBarBehavior.floating));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> showAddMenu(BuildContext context, {required Offset anchor}) async {
    final action = await ioSkillAddMenuShow(context, position: anchor, showTeach: widget.showTeach);
    if (action == SkillAddAction.teach) widget.onTeachRemote?.call();
    if (action == SkillAddAction.write) await writeSkill();
    if (action == SkillAddAction.install) await installFromCatalog();
  }


  void selectSkill(String id) => setState(() => _selectedId = id);

  void absorbSkill(Skill skill) => setState(() {
        _skills = [skill, ..._skills.where((s) => s.id != skill.id)];
        _selectedId = '${skill.id}';
      });

  Future<void> putSkill(Skill skill) async {
    setState(() => _busy = true);
    try {
      final saved = await _api.put(skill);
      setState(() {
        _skills = [saved, ..._skills.where((s) => s.id != saved.id)];
        _selectedId = '${saved.id}';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
      }
      rethrow;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
  Future<void> writeSkill() async {
    if (_busy) return;
    final draft = await ioSkillTeachShow(context);
    if (draft == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final skill = await _api.put(
        Skill(
          ownerIid: Int64(widget.ownerIid),
          scope: widget.scope,
          deviceIid: Int64(widget.deviceIid),
          title: draft.title,
          bodyMd: draft.bodyMd,
          source: SkillSource.SKILL_SOURCE_TAUGHT,
          autoSubmit: draft.autoSubmit,
        ),
      );
      setState(() {
        _skills = [skill, ..._skills];
        _selectedId = '${skill.id}';
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _masterBar() => Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
        child: Row(
          children: [
            if (widget.title != null)
              Expanded(child: Text(widget.title!, style: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w600))),
            if (widget.title == null) const Spacer(),
            if (!widget.hideBarActions)
              Builder(
                builder: (ctx) => uiIconButton(
                  tooltip: 'Add skill',
                  onPressed: _busy
                      ? null
                      : () {
                          final box = ctx.findRenderObject() as RenderBox?;
                          if (box == null) return;
                          final anchor = box.localToGlobal(Offset(box.size.width, box.size.height));
                          showAddMenu(ctx, anchor: anchor);
                        },
                  icon: const Icon(Icons.add, size: 18, color: _accent),
                  style: _barBtnStyle,
                ),
              ),
          ],
        ),
      );

  static final _barBtnStyle = IconButton.styleFrom(
    backgroundColor: const Color(0xFF111114),
    minimumSize: const Size(32, 32),
    padding: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: _border)),
  );

  Widget _masterEmpty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_fix_high_outlined, size: 32, color: Color(0xFF3F3F46)),
              const SizedBox(height: 12),
              const Text('No skills yet', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                widget.showTeach
                    ? 'Record on the Remote tab (Teach skill), write instructions manually, or install from the catalog.'
                    : 'Install from the catalog or write a skill from the + menu.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted, fontSize: 13, height: 1.45),
              ),
            ],
          ),
        ),
      );

  Widget _masterList() {
    if (_loading) return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _accent));
    if (_skills.isEmpty) return _masterEmpty();
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: _skills.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: _border, indent: 12, endIndent: 12),
      itemBuilder: (context, i) {
        final skill = _skills[i];
        final id = '${skill.id}';
        final selected = _selectedId == id;
        return Material(
          color: selected ? const Color(0xFF18181B) : Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _selectedId = id),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(
                children: [
                  Icon(_skillIcon(skill.source), size: 18, color: selected ? _accent : _muted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(skill.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: selected ? _text : const Color(0xFFE4E4E7), fontSize: 13, fontWeight: FontWeight.w600)),
                        if (skill.authorName.isNotEmpty) Text(skill.authorName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _skillIcon(SkillSource source) => switch (source) {
        SkillSource.SKILL_SOURCE_CATALOG => Icons.storefront_outlined,
        SkillSource.SKILL_SOURCE_TAUGHT => Icons.school_outlined,
        SkillSource.SKILL_SOURCE_IMPORT => Icons.upload_file_outlined,
        SkillSource.SKILL_SOURCE_AI_EXPLORE => Icons.psychology_outlined,
        _ => Icons.auto_awesome_outlined,
      };

  String _skillSourceLabel(SkillSource source) => switch (source) {
        SkillSource.SKILL_SOURCE_CATALOG => 'Catalog',
        SkillSource.SKILL_SOURCE_TAUGHT => 'Taught',
        SkillSource.SKILL_SOURCE_IMPORT => 'Imported',
        SkillSource.SKILL_SOURCE_AI_EXPLORE => 'AI Explored',
        _ => 'Custom',
      };

  Future<void> _editSkill(Skill skill) async {
    if (_busy) return;
    final edited = await ioSkillEditShow(context, skill);
    if (edited == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final next = skill.copyWith((s) {
        s.title = edited.title;
        s.bodyMd = edited.bodyMd;
        s.phrasesJson = edited.phrasesJson;
        s.autoRun = edited.autoRun;
        s.targetApp = edited.targetApp;
        s.urlPattern = edited.urlPattern;
      });
      final saved = await _api.put(next);
      setState(() {
        _skills = [saved, ..._skills.where((x) => x.id != saved.id)];
        _selectedId = '${saved.id}';
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteSkill(Skill skill) async {
    if (_busy) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('Delete skill?', style: TextStyle(color: _text, fontSize: 16)),
        content: Text('“${skill.title}” will be removed.', style: const TextStyle(color: _muted, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: _danger))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final tomb = skill.copyWith((s) => s.deletedTsMs = Int64(DateTime.now().millisecondsSinceEpoch));
      await _api.put(tomb);
      setState(() {
        _skills = _skills.where((s) => s.id != skill.id).toList();
        if (_selectedId == '${skill.id}') _selectedId = null;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runSkill(Skill skill) async {
    final prompt = skillRunPromptText(skill);
    if (widget.onDevicePrompt != null) {
      await widget.onDevicePrompt!(prompt);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sent run request to device chat.'), behavior: SnackBarBehavior.floating));
      }
      return;
    }
    await Clipboard.setData(ClipboardData(text: prompt));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Run prompt copied — paste in chat.'), behavior: SnackBarBehavior.floating));
  }

  Future<void> _submitToPublic(Skill skill) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final res = await _api.catalogSubmit(skillId: skill.id.toInt());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message.isNotEmpty ? res.message : 'Submitted! Status: ${res.status}'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _detail(String? id) {
    final skill = _skillById(id);
    if (skill == null) {
      return const Center(child: Text('Select a skill', style: TextStyle(color: _muted, fontSize: 13)));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.onDrillBack != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: uiIconButton(
                tooltip: 'Back',
                onPressed: widget.onDrillBack,
                icon: const Icon(Icons.arrow_back, size: 18, color: _muted),
              ),
            ),
          ),
        if (skillNeedsAttention(skill))
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF451A1A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF7F1D1D)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFF87171)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(skillAutoRepairPausedMessage, style: const TextStyle(color: Color(0xFFFECACA), fontSize: 12, height: 1.4)),
                  ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(skill.title, style: const TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF27272A), borderRadius: BorderRadius.circular(4)),
                child: Text(_skillSourceLabel(skill.source), style: const TextStyle(color: _muted, fontSize: 11)),
              ),
              if (skill.patchEpoch > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF27272A), borderRadius: BorderRadius.circular(4)),
                  child: Text('Epoch ${skill.patchEpoch}', style: const TextStyle(color: _muted, fontSize: 11)),
                ),
              if (skill.catalogId.toInt() == 0) ...[
                if (skill.autoSubmit)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF064E3B), borderRadius: BorderRadius.circular(4)),
                    child: Text('Auto-submit: ON (${skill.consecutiveOk}/5 runs)', style: const TextStyle(color: _accent, fontSize: 11)),
                  ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _submitToPublic(skill),
                  icon: const Icon(Icons.cloud_upload_outlined, size: 14),
                  label: const Text('Submit to Alien AI Public Skill Library', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: _accent,
                    side: const BorderSide(color: Color(0xFF27272A)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _editSkill(skill),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(foregroundColor: _text, side: const BorderSide(color: _border), visualDensity: VisualDensity.compact),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _runSkill(skill),
                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                label: const Text('Run', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(foregroundColor: _accent, side: const BorderSide(color: _border), visualDensity: VisualDensity.compact),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _deleteSkill(skill),
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text('Delete', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(foregroundColor: _danger, side: const BorderSide(color: _border), visualDensity: VisualDensity.compact),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: _border),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (skill.steps.where((s) => s.deletedTsMs == Int64.ZERO).isNotEmpty) ...[
                  const Text('Recorded steps', style: TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...skill.steps.where((s) => s.deletedTsMs == Int64.ZERO).map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 22,
                                child: Text('${s.ord}.', style: const TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              Expanded(child: Text(s.label.isNotEmpty ? s.label : s.kind, style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 13))),
                            ],
                          ),
                        ),
                      ),
                  const SizedBox(height: 16),
                ] else if (skill.source == SkillSource.SKILL_SOURCE_TAUGHT) ...[
                  const Text('No recorded steps yet — use Teach on Remote to capture a tape.', style: TextStyle(color: _muted, fontSize: 12)),
                  const SizedBox(height: 16),
                ],
                MarkdownBody(
                  data: skill.bodyMd.isNotEmpty ? skill.bodyMd : '_No content_',
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 14, height: 1.5),
                    h1: const TextStyle(color: _text, fontSize: 20, fontWeight: FontWeight.bold),
                    h2: const TextStyle(color: _text, fontSize: 17, fontWeight: FontWeight.bold),
                    code: const TextStyle(color: _accent, fontFamily: 'monospace', fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => UiMasterDetail(
        masterBar: _masterBar(),
        master: _masterList(),
        selectedId: _selectedId,
        onSelectedIdChanged: (id) => setState(() => _selectedId = id),
        onDrillBack: widget.onDrillBack != null ? () => setState(() => _selectedId = null) : null,
        detailBuilder: _detail,
        listEmpty: !_loading && _skills.isEmpty,
        collapseWhenEmpty: false,
        emptyDetail: const Center(child: Text('Select a skill', style: TextStyle(color: _muted, fontSize: 13))),
      );
}

class PageSkills extends StatelessWidget {
  const PageSkills({super.key, required this.conn, required this.ownerIid});

  final ChatConn conn;
  final int ownerIid;

  @override
  Widget build(BuildContext context) => UiPage(
        title: 'Skills',
        onBack: () => Navigator.pop(context),
        body: UiSkillMasterDetail(conn: conn, ownerIid: ownerIid, scope: SkillScope.SKILL_SCOPE_USER),
      );
}
