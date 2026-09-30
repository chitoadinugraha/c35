// ignore_for_file: constant_identifier_names

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/task.pb.dart';
import 'package:fixnum/fixnum.dart';

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

  Stream<TaskRunPush> get onTaskRunPush => conn?.onTaskRunPush ?? const Stream<TaskRunPush>.empty();

  ChatConn _requireConn() => conn ?? (throw StateError('not connected'));

  int _listDeviceIid(TaskScope scope, int deviceIid) =>
      scope == TaskScope.TASK_SCOPE_DEVICE ? deviceIid : 0;

  Future<List<Task>> list({
    required TaskScope scope,
    int deviceIid = 0,
    int botIid = 0,
    bool includeInactive = true,
  }) async {
    final res = await _requireConn().taskList(
      deviceIid: _listDeviceIid(scope, deviceIid),
      includeInactive: includeInactive,
    );
    final tasks = res.tasks;
    if (includeInactive) return tasks;
    return tasks.where((t) => t.isActive).toList();
  }

  Future<Task> put(Task task, {required TaskScope scope, int deviceIid = 0, int botIid = 0}) async {
    final draft = task.clone();
    if (scope == TaskScope.TASK_SCOPE_DEVICE && deviceIid > 0) {
      draft.deviceIid = Int64(deviceIid);
    }
    final res = await _requireConn().taskPut(draft);
    if (!res.hasTask()) throw 'task put failed';
    return res.task;
  }

  Future<void> delete(Int64 taskId, {required TaskScope scope, int deviceIid = 0, int botIid = 0}) async {
    throw UnsupportedError('task delete is not available on the server yet');
  }

  Future<TaskRun> runStart(ReqTaskRunStart req) async {
    final res = await _requireConn().taskRunStart(req);
    if (!res.hasRun()) throw 'task run start failed';
    return res.run;
  }

  Future<TaskRun> runCancel(int runId, {int taskId = 0}) async {
    final res = await _requireConn().taskRunCancel(runId);
    if (!res.hasRun()) throw 'task run cancel failed';
    return res.run;
  }

  Future<ResTaskRunCancelDevice> runCancelDevice(int deviceIid) =>
      _requireConn().taskRunCancelDevice(deviceIid);

  Future<List<TaskRun>> runList({required int taskId, int deviceIid = 0, int limit = 50}) async {
    final res = await _requireConn().taskRunList(taskId: taskId, deviceIid: deviceIid, limit: limit);
    return res.runs;
  }
}
