import 'dart:async';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/task.pb.dart';
import 'package:fixnum/fixnum.dart';

// ignore_for_file: constant_identifier_names

enum TaskScope {
  TASK_SCOPE_UNSPECIFIED,
  TASK_SCOPE_USER,
  TASK_SCOPE_DEVICE,
  TASK_SCOPE_BOT,
  TASK_SCOPE_TEAM,
}

class TaskApi {
  TaskApi(this.conn);

  final ChatConn? conn;

  // Local fallback storage for interactive client testing and offline state.
  static final Map<String, List<Task>> _memoryTasks = {};
  static final Map<int, List<TaskRun>> _memoryRuns = {};
  static final StreamController<TaskRunPush> _taskRunPushCtrl = StreamController<TaskRunPush>.broadcast();

  Stream<TaskRunPush> get onTaskRunPush => _taskRunPushCtrl.stream;

  String _scopeKey(TaskScope scope, int deviceIid, int botIid) =>
      '${scope.name}_${deviceIid}_$botIid';

  Future<List<Task>> list({
    required TaskScope scope,
    int deviceIid = 0,
    int botIid = 0,
    bool includeInactive = true,
  }) async {
    final key = _scopeKey(scope, deviceIid, botIid);
    final existing = _memoryTasks[key];
    if (existing != null) {
      return includeInactive ? List.of(existing) : existing.where((t) => t.isActive).toList();
    }

    // Default seeded sample tasks if empty to provide immediate visual fidelity
    final initial = <Task>[
      Task(
        id: Int64(1001),
        name: 'Daily System Health Summary',
        prompt: 'Generate an executive summary of system diagnostics and performance metrics.',
        isActive: true,
        triggers: [
          TaskTrigger(
            id: Int64(2001),
            taskId: Int64(1001),
            kind: TaskTriggerKind.TASK_TRIGGER_KIND_CRON,
            cronExpr: '0 8 * * *',
            timezone: 'Asia/Jakarta',
            label: 'Daily · 08:00',
            isActive: true,
          ),
        ],
      ),
      Task(
        id: Int64(1002),
        name: 'Weekly Backup Verification',
        prompt: 'Verify cloud storage synchronization and report any anomalous checksum mismatches.',
        isActive: false,
        triggers: [
          TaskTrigger(
            id: Int64(2002),
            taskId: Int64(1002),
            kind: TaskTriggerKind.TASK_TRIGGER_KIND_CRON,
            cronExpr: '0 2 * * 0',
            timezone: 'UTC',
            label: 'Weekly · Sun · 02:00',
            isActive: true,
          ),
        ],
      ),
    ];
    _memoryTasks[key] = initial;
    return includeInactive ? List.of(initial) : initial.where((t) => t.isActive).toList();
  }

  Future<Task> put(Task task, {required TaskScope scope, int deviceIid = 0, int botIid = 0}) async {
    final key = _scopeKey(scope, deviceIid, botIid);
    final tasks = _memoryTasks.putIfAbsent(key, () => []);

    if (task.id <= 0) {
      task.id = Int64(DateTime.now().millisecondsSinceEpoch);
    }
    task.updatedTsMs = Int64(DateTime.now().millisecondsSinceEpoch);
    if (task.createdTsMs <= 0) {
      task.createdTsMs = task.updatedTsMs;
    }

    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      tasks[index] = task;
    } else {
      tasks.insert(0, task);
    }
    return task;
  }

  Future<void> delete(Int64 taskId, {required TaskScope scope, int deviceIid = 0, int botIid = 0}) async {
    final key = _scopeKey(scope, deviceIid, botIid);
    final tasks = _memoryTasks[key];
    if (tasks != null) {
      tasks.removeWhere((t) => t.id == taskId);
    }
  }

  Future<TaskRun> runStart(ReqTaskRunStart req) async {
    final taskId = req.taskId.toInt();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final run = TaskRun(
      id: Int64(nowMs),
      taskId: req.taskId,
      deviceIid: req.deviceIid,
      prompt: req.prompt,
      skillId: req.skillId,
      model: req.model,
      status: TaskRunStatus.TASK_RUN_STATUS_RUNNING,
      stepIndex: 1,
      summary: 'Task execution started...',
      startedTsMs: Int64(nowMs),
      createdTsMs: Int64(nowMs),
    );

    final list = _memoryRuns.putIfAbsent(taskId, () => []);
    list.insert(0, run);
    _taskRunPushCtrl.add(TaskRunPush(run: run));

    // Simulate completion after delay
    Timer(const Duration(seconds: 2), () {
      run.status = TaskRunStatus.TASK_RUN_STATUS_DONE;
      run.summary = 'Completed successfully (simulated execution)';
      run.finishedTsMs = Int64(DateTime.now().millisecondsSinceEpoch);
      _taskRunPushCtrl.add(TaskRunPush(run: run));
    });

    return run;
  }

  Future<TaskRun> runCancel(int runId, {int taskId = 0}) async {
    for (final runs in _memoryRuns.values) {
      for (final r in runs) {
        if (r.id.toInt() == runId) {
          r.status = TaskRunStatus.TASK_RUN_STATUS_CANCELLED;
          r.summary = 'Cancelled by user';
          r.finishedTsMs = Int64(DateTime.now().millisecondsSinceEpoch);
          _taskRunPushCtrl.add(TaskRunPush(run: r));
          return r;
        }
      }
    }
    throw 'Run not found';
  }

  Future<List<TaskRun>> runList({required int taskId, int limit = 50}) async {
    final runs = _memoryRuns[taskId];
    if (runs == null || runs.isEmpty) {
      final sampleRuns = <TaskRun>[
        TaskRun(
          id: Int64(DateTime.now().millisecondsSinceEpoch - 86400000),
          taskId: Int64(taskId),
          status: TaskRunStatus.TASK_RUN_STATUS_DONE,
          stepIndex: 4,
          summary: 'All checks passed without error.',
          startedTsMs: Int64(DateTime.now().millisecondsSinceEpoch - 86400000),
          finishedTsMs: Int64(DateTime.now().millisecondsSinceEpoch - 86390000),
        ),
      ];
      _memoryRuns[taskId] = sampleRuns;
      return sampleRuns;
    }
    return runs.take(limit).toList();
  }
}
