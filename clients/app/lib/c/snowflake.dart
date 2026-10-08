import 'dart:math';

import 'package:alienai_c35/c/app_id.dart';

/// Matches server `SNOWFLAKE_EPOCH_MS` in `servers/crates/store/src/snowflake.rs`.
const snowflakeEpochMs = 1767225600000;

const _workerBits = 10;
const _seqBits = 12;
const _maxSeq = (1 << _seqBits) - 1;
const _workerMask = (1 << _workerBits) - 1;
const _shift = _workerBits + _seqBits;

int _fnv1a32(String s) {
  var h = 2166136261;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 16777619) & 0xFFFFFFFF;
  }
  return h;
}

/// Client workers use 512–1023 to reduce clashes with server pod workers.
int snowflakeWorkerFromInstall(String installId) {
  final n = _fnv1a32(installId) & _workerMask;
  final base = n == 0 ? 1 : n;
  return 512 + (base % 512);
}

class SnowflakeClient {
  SnowflakeClient._();

  static SnowflakeClient? _instance;
  static SnowflakeClient get instance => _instance ??= SnowflakeClient._();

  int? _worker;
  int _lastMs = 0;
  int _seq = 0;

  Future<void> ensureReady() async {
    if (_worker != null) return;
    final install = await deviceInstallId();
    _worker = snowflakeWorkerFromInstall(install);
  }

  Future<int> nextId() async {
    final worker = _worker;
    if (worker == null) {
      throw StateError('SnowflakeClient.ensureReady() must run before nextId()');
    }
    while (true) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final ms = max(0, now - snowflakeEpochMs);
      if (ms > _lastMs) {
        _lastMs = ms;
        _seq = 1;
        return ((ms << _shift) | (worker << _seqBits) | _seq);
      }
      if (ms == _lastMs) {
        _seq++;
        if (_seq > _maxSeq) {
          await Future<void>.delayed(const Duration(milliseconds: 1));
          continue;
        }
        return ((ms << _shift) | (worker << _seqBits) | _seq);
      }
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
  }
}

Future<int> snowflakeIdNext() async {
  await SnowflakeClient.instance.ensureReady();
  return SnowflakeClient.instance.nextId();
}
