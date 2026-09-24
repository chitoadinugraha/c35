import 'package:alienai_c35/c/pb/c35/task.pb.dart';

enum TaskRepeatPreset { hourly, daily, weekly, monthly, custom }

class TaskCronDecoded {
  TaskCronDecoded({
    required this.preset,
    required this.hour,
    required this.minute,
    this.weekday = 1,
    this.day = 1,
    this.rawExpr = '',
  });

  final TaskRepeatPreset preset;
  final int hour;
  final int minute;
  final int weekday;
  final int day;
  final String rawExpr;
}

String taskCronEncodeHourly({required int minute}) => '$minute * * * *';

String taskCronEncodeDaily({required int hour, required int minute}) => '$minute $hour * * *';

String taskCronEncodeWeekly({required int weekday, required int hour, required int minute}) => '$minute $hour * * $weekday';

String taskCronEncodeMonthly({required int day, required int hour, required int minute}) => '$minute $hour $day * *';

TaskCronDecoded? taskCronDecode(String expr) {
  final trimmed = expr.trim();
  if (trimmed.isEmpty) return null;
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length != 5) {
    return TaskCronDecoded(
      preset: TaskRepeatPreset.custom,
      hour: 0,
      minute: 0,
      rawExpr: trimmed,
    );
  }
  final min = int.tryParse(parts[0]);
  final hour = int.tryParse(parts[1]);

  // Hourly: "X * * * *"
  if (min != null && parts[1] == '*' && parts[2] == '*' && parts[3] == '*' && parts[4] == '*') {
    return TaskCronDecoded(preset: TaskRepeatPreset.hourly, hour: 0, minute: min, rawExpr: trimmed);
  }

  if (min == null || hour == null) {
    return TaskCronDecoded(
      preset: TaskRepeatPreset.custom,
      hour: 0,
      minute: 0,
      rawExpr: trimmed,
    );
  }

  // Daily: "X Y * * *"
  if (parts[2] == '*' && parts[3] == '*' && parts[4] == '*') {
    return TaskCronDecoded(preset: TaskRepeatPreset.daily, hour: hour, minute: min, rawExpr: trimmed);
  }

  // Weekly: "X Y * * Z"
  if (parts[2] == '*' && parts[3] == '*') {
    final wd = int.tryParse(parts[4]);
    if (wd != null) {
      return TaskCronDecoded(preset: TaskRepeatPreset.weekly, hour: hour, minute: min, weekday: wd, rawExpr: trimmed);
    }
  }

  // Monthly: "X Y D * *"
  if (parts[3] == '*' && parts[4] == '*') {
    final dom = int.tryParse(parts[2]);
    if (dom != null) {
      return TaskCronDecoded(preset: TaskRepeatPreset.monthly, hour: hour, minute: min, day: dom, rawExpr: trimmed);
    }
  }

  return TaskCronDecoded(
    preset: TaskRepeatPreset.custom,
    hour: hour,
    minute: min,
    rawExpr: trimmed,
  );
}

String taskTimezoneLocal() {
  final o = DateTime.now().timeZoneOffset;
  if (o.inMinutes == 0) return 'UTC';
  final hours = o.inHours;
  return 'Etc/GMT${hours > 0 ? '-' : '+'}${hours.abs()}';
}

const kCommonTimezones = <String>[
  'UTC',
  'Asia/Jakarta',
  'Asia/Singapore',
  'Asia/Tokyo',
  'Europe/London',
  'Europe/Berlin',
  'America/New_York',
  'America/Chicago',
  'America/Denver',
  'America/Los_Angeles',
  'Australia/Sydney',
];

String taskTriggerLabel({
  required TaskTriggerKind kind,
  String cronExpr = '',
  int runAtMs = 0,
  String timezone = 'UTC',
}) {
  if (kind == TaskTriggerKind.TASK_TRIGGER_KIND_WEBHOOK) {
    return 'Webhook';
  }
  if (kind == TaskTriggerKind.TASK_TRIGGER_KIND_ONCE) {
    if (runAtMs <= 0) return 'Once';
    final dt = DateTime.fromMillisecondsSinceEpoch(runAtMs).toLocal();
    final d = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
    final t = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return 'Once · $d $t';
  }
  if (kind == TaskTriggerKind.TASK_TRIGGER_KIND_CRON) {
    final d = taskCronDecode(cronExpr);
    if (d == null) return cronExpr.isEmpty ? 'Repeating' : cronExpr;
    final t = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    final tzSuffix = timezone.isNotEmpty && timezone != 'UTC' ? ' ($timezone)' : '';
    return switch (d.preset) {
      TaskRepeatPreset.hourly => 'Hourly :${d.minute.toString().padLeft(2, '0')}$tzSuffix',
      TaskRepeatPreset.daily => 'Daily · $t$tzSuffix',
      TaskRepeatPreset.weekly => 'Weekly · ${_weekdayShort(d.weekday)} · $t$tzSuffix',
      TaskRepeatPreset.monthly => 'Monthly · Day ${d.day} · $t$tzSuffix',
      TaskRepeatPreset.custom => 'Cron: ${d.rawExpr}$tzSuffix',
    };
  }
  return 'Manual';
}

String taskNextRunLabel(Task task) {
  final activeTriggers = task.triggers.where((t) => t.isActive).toList();
  if (activeTriggers.isEmpty) {
    return task.triggers.isEmpty ? 'Manual only' : 'Disabled';
  }
  return activeTriggers
      .map((t) => taskTriggerLabel(
            kind: t.kind,
            cronExpr: t.cronExpr,
            runAtMs: t.runAtMs.toInt(),
            timezone: t.timezone,
          ))
      .join(' · ');
}

String _weekdayShort(int w) => const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][w.clamp(0, 6)];
