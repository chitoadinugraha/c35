import 'package:alienai_c35/c/pb/c35/task.pb.dart';
import 'package:alienai_c35/c/task/task_trigger_cron.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);
const _cardBg = Color(0xFF141418);

class IoTaskTrigger extends StatefulWidget {
  const IoTaskTrigger({
    super.key,
    required this.trigger,
    required this.onChanged,
    required this.onDelete,
    this.webhookHost = 'alienai.id',
  });

  final TaskTrigger trigger;
  final ValueChanged<TaskTrigger> onChanged;
  final VoidCallback onDelete;
  final String webhookHost;

  @override
  State<IoTaskTrigger> createState() => _IoTaskTriggerState();
}

class _IoTaskTriggerState extends State<IoTaskTrigger> {
  late TaskRepeatPreset _preset;
  late int _weekday;
  late int _day;
  late int _hour;
  late int _minute;
  late DateTime _onceAt;
  late String _timezone;
  late final TextEditingController _customCronCtrl;

  @override
  void initState() {
    super.initState();
    _customCronCtrl = TextEditingController();
    _loadFromTrigger(widget.trigger);
  }

  @override
  void didUpdateWidget(covariant IoTaskTrigger oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger.id != widget.trigger.id ||
        oldWidget.trigger.kind != widget.trigger.kind ||
        oldWidget.trigger.cronExpr != widget.trigger.cronExpr ||
        oldWidget.trigger.runAtMs != widget.trigger.runAtMs ||
        oldWidget.trigger.timezone != widget.trigger.timezone) {
      _loadFromTrigger(widget.trigger);
    }
  }

  @override
  void dispose() {
    _customCronCtrl.dispose();
    super.dispose();
  }

  void _loadFromTrigger(TaskTrigger t) {
    _onceAt = t.runAtMs > 0
        ? DateTime.fromMillisecondsSinceEpoch(t.runAtMs.toInt()).toLocal()
        : DateTime.now().add(const Duration(hours: 1));

    _timezone = t.timezone.isNotEmpty ? t.timezone : taskTimezoneLocal();

    final decoded = taskCronDecode(t.cronExpr);
    if (decoded != null) {
      _preset = decoded.preset;
      _weekday = decoded.weekday;
      _day = decoded.day;
      _hour = decoded.hour;
      _minute = decoded.minute;
      _customCronCtrl.text = decoded.preset == TaskRepeatPreset.custom ? decoded.rawExpr : t.cronExpr;
    } else {
      _preset = TaskRepeatPreset.daily;
      _weekday = 1;
      _day = 1;
      _hour = 9;
      _minute = 0;
      _customCronCtrl.text = '0 9 * * *';
    }
  }

  TaskTrigger _buildTrigger({
    TaskTriggerKind? kind,
    bool? isActive,
  }) {
    final targetKind = kind ?? widget.trigger.kind;
    final active = isActive ?? widget.trigger.isActive;
    final updated = widget.trigger.clone();
    updated.kind = targetKind;
    updated.isActive = active;
    updated.timezone = _timezone;

    if (targetKind == TaskTriggerKind.TASK_TRIGGER_KIND_ONCE) {
      final runAt = _onceAt.millisecondsSinceEpoch;
      updated.runAtMs = Int64(runAt);
      updated.label = taskTriggerLabel(
        kind: TaskTriggerKind.TASK_TRIGGER_KIND_ONCE,
        runAtMs: runAt,
        timezone: _timezone,
      );
    } else if (targetKind == TaskTriggerKind.TASK_TRIGGER_KIND_CRON) {
      final expr = switch (_preset) {
        TaskRepeatPreset.hourly => taskCronEncodeHourly(minute: _minute),
        TaskRepeatPreset.daily => taskCronEncodeDaily(hour: _hour, minute: _minute),
        TaskRepeatPreset.weekly => taskCronEncodeWeekly(weekday: _weekday, hour: _hour, minute: _minute),
        TaskRepeatPreset.monthly => taskCronEncodeMonthly(day: _day, hour: _hour, minute: _minute),
        TaskRepeatPreset.custom => _customCronCtrl.text.trim().isEmpty ? '0 9 * * *' : _customCronCtrl.text.trim(),
      };
      updated.cronExpr = expr;
      updated.label = taskTriggerLabel(
        kind: TaskTriggerKind.TASK_TRIGGER_KIND_CRON,
        cronExpr: expr,
        timezone: _timezone,
      );
    } else if (targetKind == TaskTriggerKind.TASK_TRIGGER_KIND_WEBHOOK) {
      if (updated.webhookSecret.isEmpty) {
        updated.webhookSecret = 'wh_${DateTime.now().millisecondsSinceEpoch}';
      }
      updated.label = 'Webhook';
    }

    return updated;
  }

  void _notifyUpdate({TaskTriggerKind? kind, bool? isActive}) {
    final t = _buildTrigger(kind: kind, isActive: isActive);
    widget.onChanged(t);
  }

  Future<void> _pickOnceDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _onceAt,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_onceAt),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _onceAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
    _notifyUpdate(kind: TaskTriggerKind.TASK_TRIGGER_KIND_ONCE);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
    );
    if (picked == null || !mounted) return;

    setState(() {
      _hour = picked.hour;
      _minute = picked.minute;
    });
    _notifyUpdate(kind: TaskTriggerKind.TASK_TRIGGER_KIND_CRON);
  }

  Future<void> _pickMinuteOnly() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 0, minute: _minute),
    );
    if (picked == null || !mounted) return;

    setState(() {
      _minute = picked.minute;
    });
    _notifyUpdate(kind: TaskTriggerKind.TASK_TRIGGER_KIND_CRON);
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.trigger.kind == TaskTriggerKind.TASK_TRIGGER_KIND_UNSPECIFIED
        ? TaskTriggerKind.TASK_TRIGGER_KIND_CRON
        : widget.trigger.kind;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 170,
                child: DropdownButtonFormField<TaskTriggerKind>(
                  key: ValueKey('kind_${widget.trigger.id}_${kind.value}'),
                  initialValue: kind,
                  dropdownColor: const Color(0xFF1E1E24),
                  style: const TextStyle(color: _text, fontSize: 13),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderSide: BorderSide(color: _border)),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _border)),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: TaskTriggerKind.TASK_TRIGGER_KIND_CRON,
                      child: Row(
                        children: [
                          Icon(Icons.update_outlined, size: 18, color: Color(0xFFA1A1AA)),
                          SizedBox(width: 10),
                          Text('Repeating (Cron)'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: TaskTriggerKind.TASK_TRIGGER_KIND_ONCE,
                      child: Row(
                        children: [
                          Icon(Icons.event_outlined, size: 18, color: Color(0xFFA1A1AA)),
                          SizedBox(width: 10),
                          Text('One Time'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: TaskTriggerKind.TASK_TRIGGER_KIND_WEBHOOK,
                      child: Row(
                        children: [
                          Icon(Icons.webhook_outlined, size: 18, color: Color(0xFFA1A1AA)),
                          SizedBox(width: 10),
                          Text('Webhook'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _notifyUpdate(kind: v);
                      });
                    }
                  },
                ),
              ),
              const Spacer(),
              Switch(
                value: widget.trigger.isActive,
                activeThumbColor: _accent,
                onChanged: (active) => _notifyUpdate(isActive: active),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: _muted),
                tooltip: 'Delete trigger',
                visualDensity: VisualDensity.compact,
                onPressed: widget.onDelete,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildTriggerBody(kind),
        ],
      ),
    );
  }

  Widget _buildTriggerBody(TaskTriggerKind kind) {
    return switch (kind) {
      TaskTriggerKind.TASK_TRIGGER_KIND_ONCE => _buildOnceBody(),
      TaskTriggerKind.TASK_TRIGGER_KIND_CRON => _buildCronBody(),
      TaskTriggerKind.TASK_TRIGGER_KIND_WEBHOOK => _buildWebhookBody(),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildOnceBody() {
    final dt = _onceAt;
    final label = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _pillButton(
          icon: Icons.calendar_month_outlined,
          label: label,
          onTap: _pickOnceDateTime,
        ),
        _pillButton(
          icon: Icons.add_alarm_outlined,
          label: '+1h',
          onTap: () {
            setState(() => _onceAt = DateTime.now().add(const Duration(hours: 1)));
            _notifyUpdate(kind: TaskTriggerKind.TASK_TRIGGER_KIND_ONCE);
          },
        ),
        _pillButton(
          icon: Icons.today_outlined,
          label: 'Tomorrow 9am',
          onTap: () {
            final now = DateTime.now();
            final tomorrow = now.add(const Duration(days: 1));
            setState(() => _onceAt = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0));
            _notifyUpdate(kind: TaskTriggerKind.TASK_TRIGGER_KIND_ONCE);
          },
        ),
      ],
    );
  }

  Widget _buildCronBody() {
    final tzList = List<String>.from(kCommonTimezones);
    if (!tzList.contains(_timezone)) {
      tzList.insert(0, _timezone);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 140,
              child: DropdownButtonFormField<TaskRepeatPreset>(
                key: ValueKey('preset_${widget.trigger.id}_${_preset.name}'),
                initialValue: _preset,
                dropdownColor: const Color(0xFF1E1E24),
                style: const TextStyle(color: _text, fontSize: 13),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(borderSide: BorderSide(color: _border)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _border)),
                ),
                items: const [
                  DropdownMenuItem(
                    value: TaskRepeatPreset.hourly,
                    child: Row(
                      children: [
                        Icon(Icons.hourglass_top_outlined, size: 18, color: Color(0xFFA1A1AA)),
                        SizedBox(width: 10),
                        Text('Hourly'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: TaskRepeatPreset.daily,
                    child: Row(
                      children: [
                        Icon(Icons.today_outlined, size: 18, color: Color(0xFFA1A1AA)),
                        SizedBox(width: 10),
                        Text('Daily'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: TaskRepeatPreset.weekly,
                    child: Row(
                      children: [
                        Icon(Icons.calendar_view_week_outlined, size: 18, color: Color(0xFFA1A1AA)),
                        SizedBox(width: 10),
                        Text('Weekly'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: TaskRepeatPreset.monthly,
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month_outlined, size: 18, color: Color(0xFFA1A1AA)),
                        SizedBox(width: 10),
                        Text('Monthly'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: TaskRepeatPreset.custom,
                    child: Row(
                      children: [
                        Icon(Icons.code_outlined, size: 18, color: Color(0xFFA1A1AA)),
                        SizedBox(width: 10),
                        Text('Custom'),
                      ],
                    ),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _preset = v);
                    _notifyUpdate(kind: TaskTriggerKind.TASK_TRIGGER_KIND_CRON);
                  }
                },
              ),
            ),
            if (_preset == TaskRepeatPreset.hourly)
              _pillButton(
                icon: Icons.access_time_outlined,
                label: 'At minute :${_minute.toString().padLeft(2, '0')}',
                onTap: _pickMinuteOnly,
              ),
            if (_preset == TaskRepeatPreset.weekly)
              SizedBox(
                width: 110,
                child: DropdownButtonFormField<int>(
                  key: ValueKey('weekday_${widget.trigger.id}_$_weekday'),
                  initialValue: _weekday,
                  dropdownColor: const Color(0xFF1E1E24),
                  style: const TextStyle(color: _text, fontSize: 13),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderSide: BorderSide(color: _border)),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _border)),
                  ),
                  items: List.generate(
                    7,
                    (i) => DropdownMenuItem(
                      value: i,
                      child: Row(
                        children: [
                          const Icon(Icons.date_range_outlined, size: 18, color: Color(0xFFA1A1AA)),
                          const SizedBox(width: 10),
                          Text(const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][i]),
                        ],
                      ),
                    ),
                  ),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _weekday = v);
                      _notifyUpdate(kind: TaskTriggerKind.TASK_TRIGGER_KIND_CRON);
                    }
                  },
                ),
              ),
            if (_preset == TaskRepeatPreset.monthly)
              SizedBox(
                width: 105,
                child: DropdownButtonFormField<int>(
                  key: ValueKey('day_${widget.trigger.id}_$_day'),
                  initialValue: _day,
                  dropdownColor: const Color(0xFF1E1E24),
                  style: const TextStyle(color: _text, fontSize: 13),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderSide: BorderSide(color: _border)),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _border)),
                  ),
                  items: List.generate(
                    28,
                    (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFFA1A1AA)),
                          const SizedBox(width: 10),
                          Text('Day ${i + 1}'),
                        ],
                      ),
                    ),
                  ),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _day = v);
                      _notifyUpdate(kind: TaskTriggerKind.TASK_TRIGGER_KIND_CRON);
                    }
                  },
                ),
              ),
            if (_preset == TaskRepeatPreset.daily ||
                _preset == TaskRepeatPreset.weekly ||
                _preset == TaskRepeatPreset.monthly)
              _pillButton(
                icon: Icons.access_time_outlined,
                label: '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}',
                onTap: _pickTime,
              ),
            SizedBox(
              width: 160,
              child: DropdownButtonFormField<String>(
                key: ValueKey('tz_${widget.trigger.id}_$_timezone'),
                initialValue: _timezone,
                dropdownColor: const Color(0xFF1E1E24),
                style: const TextStyle(color: _text, fontSize: 12),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(borderSide: BorderSide(color: _border)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _border)),
                ),
                items: tzList
                    .map(
                      (tz) => DropdownMenuItem(
                        value: tz,
                        child: Row(
                          children: [
                            const Icon(Icons.public_outlined, size: 18, color: Color(0xFFA1A1AA)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(tz, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _timezone = v);
                    _notifyUpdate(kind: TaskTriggerKind.TASK_TRIGGER_KIND_CRON);
                  }
                },
              ),
            ),
          ],
        ),
        if (_preset == TaskRepeatPreset.custom) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _customCronCtrl,
            style: const TextStyle(color: _text, fontSize: 13, fontFamily: 'monospace'),
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'Cron expression (min hour dom mon dow)',
              labelStyle: TextStyle(color: _muted, fontSize: 12),
              hintText: 'e.g. 0 9 * * 1-5',
              hintStyle: TextStyle(color: _muted, fontSize: 12),
              border: OutlineInputBorder(borderSide: BorderSide(color: _border)),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _border)),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
            onChanged: (_) => _notifyUpdate(kind: TaskTriggerKind.TASK_TRIGGER_KIND_CRON),
          ),
        ],
      ],
    );
  }

  Widget _buildWebhookBody() {
    final secret = widget.trigger.webhookSecret.isNotEmpty
        ? widget.trigger.webhookSecret
        : 'wh_${widget.trigger.id}';
    final url = 'https://${widget.webhookHost}/v1/task/webhook/$secret';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.webhook_outlined, size: 16, color: _accent),
              SizedBox(width: 6),
              Text('Webhook Endpoint URL', style: TextStyle(color: _text, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  url,
                  style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.content_copy_outlined, size: 16, color: _muted),
                tooltip: 'Copy URL',
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Webhook URL copied to clipboard'), behavior: SnackBarBehavior.floating),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'HTTP POST to this URL will trigger this task instantly.',
            style: TextStyle(color: _muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _pillButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E24),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: _accent),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: _text, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class IoTaskTriggerList extends StatelessWidget {
  const IoTaskTriggerList({
    super.key,
    required this.triggers,
    required this.onAdd,
    required this.onChanged,
    required this.onDelete,
    this.webhookHost = 'alienai.id',
  });

  final List<TaskTrigger> triggers;
  final VoidCallback onAdd;
  final void Function(int index, TaskTrigger trigger) onChanged;
  final void Function(int index) onDelete;
  final String webhookHost;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.schedule_outlined, size: 18, color: _accent),
            const SizedBox(width: 8),
            const Text(
              'Triggers & Schedules',
              style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 15),
              label: const Text('Add trigger', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: _accent,
                side: const BorderSide(color: _border),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (triggers.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _border),
            ),
            child: const Center(
              child: Text(
                'No triggers set. Task can only be run manually with the play button.',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
            ),
          ),
        ...List.generate(
          triggers.length,
          (i) => IoTaskTrigger(
            key: ValueKey('trigger_${triggers[i].id}_$i'),
            trigger: triggers[i],
            webhookHost: webhookHost,
            onChanged: (t) => onChanged(i, t),
            onDelete: () => onDelete(i),
          ),
        ),
      ],
    );
  }
}

Widget buildTaskTriggerBadge(TaskTrigger trigger) {
  final label = taskTriggerLabel(
    kind: trigger.kind,
    cronExpr: trigger.cronExpr,
    runAtMs: trigger.runAtMs.toInt(),
    timezone: trigger.timezone,
  );

  final icon = switch (trigger.kind) {
    TaskTriggerKind.TASK_TRIGGER_KIND_ONCE => Icons.event_outlined,
    TaskTriggerKind.TASK_TRIGGER_KIND_CRON => Icons.update_outlined,
    TaskTriggerKind.TASK_TRIGGER_KIND_WEBHOOK => Icons.webhook_outlined,
    _ => Icons.play_arrow_outlined,
  };

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: trigger.isActive ? const Color(0xFF064E3B).withValues(alpha: 0.5) : const Color(0xFF27272A),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: trigger.isActive ? const Color(0xFF047857) : _border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: trigger.isActive ? _accent : _muted),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: trigger.isActive ? _accent : _muted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}
