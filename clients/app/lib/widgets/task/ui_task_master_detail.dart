import 'dart:async';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/task.pb.dart';
import 'package:alienai_c35/c/task/task_api.dart';
import 'package:alienai_c35/c/task/task_trigger_cron.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/task/io_task_trigger.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:alienai_c35/widgets/ui/ui_master_detail.dart';
import 'package:alienai_c35/widgets/ui/ui_page.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);
const _danger = Color(0xFFEF4444);
const _cardBg = Color(0xFF141418);

class UiTaskMasterDetail extends StatefulWidget {
  const UiTaskMasterDetail({
    super.key,
    this.conn,
    required this.ownerIid,
    this.scope = TaskScope.TASK_SCOPE_USER,
    this.deviceIid = 0,
    this.botIid = 0,
    this.hideBarActions = false,
    this.onDrillBack,
    this.title,
    this.agentOnline = true,
  });

  final ChatConn? conn;
  final int ownerIid;
  final TaskScope scope;
  final int deviceIid;
  final int botIid;
  final bool hideBarActions;
  final VoidCallback? onDrillBack;
  final String? title;
  final bool agentOnline;

  @override
  State<UiTaskMasterDetail> createState() => UiTaskMasterDetailState();
}

class UiTaskMasterDetailState extends State<UiTaskMasterDetail> {
  late final _api = TaskApi(widget.conn);
  var _loading = true;
  var _busy = false;
  var _tasks = <Task>[];
  String? _selectedId;
  StreamSubscription<TaskRunPush>? _pushSub;

  // Detail editing controllers & draft
  final _nameCtrl = TextEditingController();
  final _promptCtrl = TextEditingController();
  var _isActive = true;
  var _triggers = <TaskTrigger>[];
  var _runs = <TaskRun>[];
  var _runsLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
    _pushSub = _api.onTaskRunPush.listen(_onTaskRunPush);
  }

  @override
  void dispose() {
    _pushSub?.cancel();
    _nameCtrl.dispose();
    _promptCtrl.dispose();
    super.dispose();
  }

  void _onTaskRunPush(TaskRunPush push) {
    if (!mounted) return;
    final run = push.run;
    if (_selectedId != null && run.taskId.toString() == _selectedId) {
      setState(() {
        final idx = _runs.indexWhere((r) => r.id == run.id);
        if (idx >= 0) {
          _runs[idx] = run;
        } else {
          _runs.insert(0, run);
        }
      });
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _tasks = await _api.list(
        scope: widget.scope,
        deviceIid: widget.deviceIid,
        botIid: widget.botIid,
      );
      if (_selectedId != null) {
        final existing = _taskById(_selectedId);
        if (existing == null) {
          _selectTask(null);
        } else {
          _selectTask(existing);
        }
      } else if (_tasks.isNotEmpty) {
        _selectTask(_tasks.first);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Task? _taskById(String? id) =>
      id == null ? null : _tasks.where((t) => '${t.id}' == id).firstOrNull;

  void _selectTask(Task? task) {
    if (task == null) {
      _selectedId = null;
      _nameCtrl.clear();
      _promptCtrl.clear();
      _isActive = true;
      _triggers = [];
      _runs = [];
      return;
    }

    _selectedId = '${task.id}';
    _nameCtrl.text = task.name;
    _promptCtrl.text = task.prompt;
    _isActive = task.isActive;
    _triggers = task.triggers.map((t) => t.clone()).toList();
    _loadRuns(task.id.toInt());
  }

  Future<void> _loadRuns(int taskId) async {
    setState(() => _runsLoading = true);
    try {
      final runs = await _api.runList(taskId: taskId);
      if (mounted && _selectedId == '$taskId') {
        setState(() => _runs = runs);
      }
    } catch (_) {
      // Non-fatal
    } finally {
      if (mounted) setState(() => _runsLoading = false);
    }
  }

  Future<void> _createTask() async {
    if (_busy) return;
    final newId = DateTime.now().millisecondsSinceEpoch;
    final draft = Task(
      id: Int64(newId),
      ownerIid: Int64(widget.ownerIid),
      deviceIid: Int64(widget.deviceIid),
      name: 'New Scheduled Task',
      prompt: '',
      isActive: true,
      triggers: [
        TaskTrigger(
          id: Int64(newId + 1),
          taskId: Int64(newId),
          kind: TaskTriggerKind.TASK_TRIGGER_KIND_CRON,
          cronExpr: '0 9 * * *',
          timezone: taskTimezoneLocal(),
          label: 'Daily · 09:00',
          isActive: true,
        ),
      ],
    );

    setState(() => _busy = true);
    try {
      final saved = await _api.put(
        draft,
        scope: widget.scope,
        deviceIid: widget.deviceIid,
        botIid: widget.botIid,
      );
      setState(() {
        _tasks.insert(0, saved);
        _selectTask(saved);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Created new task draft'), behavior: SnackBarBehavior.floating),
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

  Future<void> _saveCurrentTask() async {
    final current = _taskById(_selectedId);
    if (current == null || _busy) return;

    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task name cannot be empty'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final updated = current.clone();
      updated.name = name;
      updated.prompt = _promptCtrl.text.trim();
      updated.isActive = _isActive;
      updated.triggers.clear();
      updated.triggers.addAll(_triggers);

      final saved = await _api.put(
        updated,
        scope: widget.scope,
        deviceIid: widget.deviceIid,
        botIid: widget.botIid,
      );

      setState(() {
        final idx = _tasks.indexWhere((t) => t.id == saved.id);
        if (idx >= 0) {
          _tasks[idx] = saved;
        }
        _selectTask(saved);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task saved successfully'), behavior: SnackBarBehavior.floating),
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

  Future<void> _deleteCurrentTask() async {
    final current = _taskById(_selectedId);
    if (current == null || _busy) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('Delete Task', style: TextStyle(color: _text)),
        content: Text('Are you sure you want to delete "${current.name}"?', style: const TextStyle(color: _muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: _muted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: _danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await _api.delete(
        current.id,
        scope: widget.scope,
        deviceIid: widget.deviceIid,
        botIid: widget.botIid,
      );
      setState(() {
        _tasks.removeWhere((t) => t.id == current.id);
        _selectTask(_tasks.isNotEmpty ? _tasks.first : null);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted'), behavior: SnackBarBehavior.floating),
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

  Future<void> _runTask(Task task) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final req = ReqTaskRunStart(
        taskId: task.id,
        deviceIid: Int64(widget.deviceIid),
        prompt: task.prompt,
        skillId: task.skillId,
        model: task.model,
      );
      final run = await _api.runStart(req);
      if (mounted) {
        if (_selectedId == '${task.id}') {
          setState(() {
            _runs.insert(0, run);
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Run initiated: ${task.name}'),
            behavior: SnackBarBehavior.floating,
          ),
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

  Future<void> _cancelRun(TaskRun run) async {
    try {
      await _api.runCancel(run.id.toInt(), taskId: run.taskId.toInt());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Run cancelled'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _toggleTaskActive(Task task, bool active) async {
    final updated = task.clone()..isActive = active;
    try {
      await _api.put(
        updated,
        scope: widget.scope,
        deviceIid: widget.deviceIid,
        botIid: widget.botIid,
      );
      setState(() {
        final idx = _tasks.indexWhere((t) => t.id == task.id);
        if (idx >= 0) _tasks[idx] = updated;
        if (_selectedId == '${task.id}') _isActive = active;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Widget _masterBar() => Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.title ?? 'Tasks',
                style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            if (!widget.hideBarActions) ...[
              uiIconButton(
                tooltip: 'Refresh tasks',
                onPressed: _busy ? null : _load,
                icon: const Icon(Icons.refresh, size: 18, color: _muted),
                style: _barBtnStyle,
              ),
              const SizedBox(width: 6),
              uiIconButton(
                tooltip: 'Add task',
                onPressed: _busy ? null : _createTask,
                icon: const Icon(Icons.add, size: 18, color: _accent),
                style: _barBtnStyle,
              ),
            ],
          ],
        ),
      );

  static final _barBtnStyle = IconButton.styleFrom(
    backgroundColor: const Color(0xFF111114),
    minimumSize: const Size(32, 32),
    padding: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: _border)),
  );

  Widget _masterList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _accent));
    }
    if (_tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.schedule_outlined, size: 36, color: _muted),
              const SizedBox(height: 12),
              const Text('No tasks yet', style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('Create automations and scheduled triggers.', style: TextStyle(color: _muted, fontSize: 12), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _busy ? null : _createTask,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create task'),
                style: OutlinedButton.styleFrom(foregroundColor: _accent, side: const BorderSide(color: _border)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: _tasks.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: _border, indent: 12, endIndent: 12),
      itemBuilder: (context, i) {
        final task = _tasks[i];
        final id = '${task.id}';
        final selected = _selectedId == id;
        final nextRun = taskNextRunLabel(task);

        return Material(
          color: selected ? const Color(0xFF18181B) : Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() => _selectTask(task));
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(
                children: [
                  Icon(
                    task.isActive ? Icons.task_alt_outlined : Icons.pause_circle_outline,
                    size: 20,
                    color: task.isActive ? (selected ? _accent : const Color(0xFFA1A1AA)) : _muted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                task.name.isNotEmpty ? task.name : 'Untitled task',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: selected ? _text : const Color(0xFFE4E4E7),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (task.prompt.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            task.prompt,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: _muted, fontSize: 11),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: task.isActive ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFF27272A),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                nextRun,
                                style: TextStyle(
                                  color: task.isActive ? _accent : _muted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.play_arrow_rounded, size: 20, color: _accent),
                    tooltip: 'Run task now',
                    visualDensity: VisualDensity.compact,
                    onPressed: _busy ? null : () => _runTask(task),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detail(String? id) {
    final task = _taskById(id);
    if (task == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined, size: 40, color: _muted),
            SizedBox(height: 12),
            Text('Select a task', style: TextStyle(color: _muted, fontSize: 13)),
          ],
        ),
      );
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
                tooltip: 'Back to tasks',
                onPressed: widget.onDrillBack,
                icon: const Icon(Icons.arrow_back, size: 18, color: _muted),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.name.isNotEmpty ? task.name : 'Untitled task',
                      style: const TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFF27272A), borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            switch (widget.scope) {
                              TaskScope.TASK_SCOPE_DEVICE => 'Device Scope',
                              TaskScope.TASK_SCOPE_BOT => 'Bot Scope',
                              _ => 'User Scope',
                            },
                            style: const TextStyle(color: _muted, fontSize: 11),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _isActive ? const Color(0xFF064E3B) : const Color(0xFF27272A),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _isActive ? 'Active' : 'Paused',
                            style: TextStyle(color: _isActive ? _accent : _muted, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _runTask(task),
                icon: const Icon(Icons.play_arrow, size: 16),
                label: const Text('Run now', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _accent,
                  side: const BorderSide(color: _border),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _busy ? null : _saveCurrentTask,
                icon: _busy
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Icon(Icons.check, size: 16),
                label: const Text('Save', style: TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: _muted),
                tooltip: 'Delete task',
                onPressed: _busy ? null : _deleteCurrentTask,
              ),
            ],
          ),
        ),
        if (widget.scope == TaskScope.TASK_SCOPE_DEVICE && !widget.agentOnline)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF78350F).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD97706)),
            ),
            child: const Row(
              children: [
                Icon(Icons.wifi_off, size: 16, color: Color(0xFFFBBF24)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Device is currently offline. Triggered runs will be queued until the agent connects.',
                    style: TextStyle(color: Color(0xFFFDE68A), fontSize: 12),
                  ),
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
                TextField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: _text, fontSize: 14),
                  decoration: UiInputDecoration.of(
                    context,
                    labelText: 'Task Name',
                    hintText: 'e.g. Daily Data Backup',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _promptCtrl,
                  minLines: 3,
                  maxLines: 7,
                  style: const TextStyle(color: _text, fontSize: 13),
                  decoration: UiInputDecoration.of(
                    context,
                    labelText: 'Prompt / Instruction',
                    hintText: 'Enter AI prompt or automated instruction to execute...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _border),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable Task Scheduling', style: TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text('When disabled, scheduled and webhook triggers will not execute.', style: TextStyle(color: _muted, fontSize: 11)),
                    value: _isActive,
                    activeThumbColor: _accent,
                    onChanged: (v) {
                      setState(() => _isActive = v);
                      _toggleTaskActive(task, v);
                    },
                  ),
                ),
                const SizedBox(height: 20),
                IoTaskTriggerList(
                  triggers: _triggers,
                  onAdd: () {
                    final newTrigId = DateTime.now().millisecondsSinceEpoch;
                    setState(() {
                      _triggers.add(
                        TaskTrigger(
                          id: Int64(newTrigId),
                          taskId: task.id,
                          kind: TaskTriggerKind.TASK_TRIGGER_KIND_CRON,
                          cronExpr: '0 9 * * *',
                          timezone: taskTimezoneLocal(),
                          label: 'Daily · 09:00',
                          isActive: true,
                        ),
                      );
                    });
                  },
                  onChanged: (idx, trig) {
                    setState(() {
                      _triggers[idx] = trig;
                    });
                  },
                  onDelete: (idx) {
                    setState(() {
                      _triggers.removeAt(idx);
                    });
                  },
                ),
                const SizedBox(height: 24),
                _buildRunHistorySection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRunHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.history_outlined, size: 18, color: _accent),
            const SizedBox(width: 8),
            const Text(
              'Run History',
              style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            if (_runsLoading)
              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: _accent)),
          ],
        ),
        const SizedBox(height: 8),
        if (_runs.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _border),
            ),
            child: const Center(
              child: Text(
                'No runs recorded yet. Use the "Run now" button to execute this task.',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
            ),
          ),
        ..._runs.take(10).map(_buildRunRow),
      ],
    );
  }

  Widget _buildRunRow(TaskRun run) {
    final status = run.status;
    final isRunning = status == TaskRunStatus.TASK_RUN_STATUS_RUNNING ||
        status == TaskRunStatus.TASK_RUN_STATUS_LEASED ||
        status == TaskRunStatus.TASK_RUN_STATUS_QUEUED;

    final statusIcon = switch (status) {
      TaskRunStatus.TASK_RUN_STATUS_DONE => const Icon(Icons.check_circle_outline, size: 16, color: _accent),
      TaskRunStatus.TASK_RUN_STATUS_RUNNING => const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF60A5FA)),
        ),
      TaskRunStatus.TASK_RUN_STATUS_QUEUED => const Icon(Icons.schedule, size: 16, color: Color(0xFFFBBF24)),
      TaskRunStatus.TASK_RUN_STATUS_FAILED => const Icon(Icons.error_outline, size: 16, color: _danger),
      TaskRunStatus.TASK_RUN_STATUS_CANCELLED => const Icon(Icons.cancel_outlined, size: 16, color: _muted),
      _ => const Icon(Icons.help_outline, size: 16, color: _muted),
    };

    final statusLabel = switch (status) {
      TaskRunStatus.TASK_RUN_STATUS_DONE => 'Completed',
      TaskRunStatus.TASK_RUN_STATUS_RUNNING => 'Running',
      TaskRunStatus.TASK_RUN_STATUS_QUEUED => 'Queued',
      TaskRunStatus.TASK_RUN_STATUS_FAILED => 'Failed',
      TaskRunStatus.TASK_RUN_STATUS_CANCELLED => 'Cancelled',
      _ => 'Unknown',
    };

    final started = run.startedTsMs > 0
        ? DateTime.fromMillisecondsSinceEpoch(run.startedTsMs.toInt()).toLocal()
        : null;

    final timeStr = started != null
        ? '${started.day.toString().padLeft(2, '0')}/${started.month.toString().padLeft(2, '0')} ${started.hour.toString().padLeft(2, '0')}:${started.minute.toString().padLeft(2, '0')}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: statusIcon,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: status == TaskRunStatus.TASK_RUN_STATUS_DONE
                            ? _accent
                            : status == TaskRunStatus.TASK_RUN_STATUS_FAILED
                                ? _danger
                                : _text,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (timeStr.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(timeStr, style: const TextStyle(color: _muted, fontSize: 11)),
                    ],
                  ],
                ),
                if (run.summary.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(run.summary, style: const TextStyle(color: Color(0xFFD4D4D8), fontSize: 12)),
                ],
                if (run.error.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(run.error, style: const TextStyle(color: _danger, fontSize: 11)),
                ],
              ],
            ),
          ),
          if (isRunning)
            TextButton(
              onPressed: () => _cancelRun(run),
              style: TextButton.styleFrom(
                foregroundColor: _danger,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: const Text('Cancel', style: TextStyle(fontSize: 11)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => UiMasterDetail(
        masterBar: _masterBar(),
        master: _masterList(),
        selectedId: _selectedId,
        onSelectedIdChanged: (id) {
          setState(() {
            _selectTask(_taskById(id));
          });
        },
        onDrillBack: widget.onDrillBack != null ? () => setState(() => _selectedId = null) : null,
        detailBuilder: _detail,
        listEmpty: !_loading && _tasks.isEmpty,
        collapseWhenEmpty: false,
        emptyDetail: const Center(
          child: Text('Select a task', style: TextStyle(color: _muted, fontSize: 13)),
        ),
      );
}

class PageTasks extends StatelessWidget {
  const PageTasks({
    super.key,
    this.conn,
    required this.ownerIid,
    this.scope = TaskScope.TASK_SCOPE_USER,
    this.deviceIid = 0,
    this.botIid = 0,
    this.title = 'Tasks',
  });

  final ChatConn? conn;
  final int ownerIid;
  final TaskScope scope;
  final int deviceIid;
  final int botIid;
  final String title;

  @override
  Widget build(BuildContext context) => UiPage(
        title: title,
        onBack: () => Navigator.pop(context),
        body: UiTaskMasterDetail(
          conn: conn,
          ownerIid: ownerIid,
          scope: scope,
          deviceIid: deviceIid,
          botIid: botIid,
        ),
      );
}
