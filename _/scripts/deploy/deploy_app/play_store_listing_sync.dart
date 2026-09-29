import 'dart:io';

import 'play_store.dart';

Future<void> main(List<String> args) async {
  try {
    await runPlayStoreListingSyncCli(args);
  } catch (e, s) {
    stderr.writeln(e);
    stderr.writeln(s);
    exitCode = 1;
  }
}