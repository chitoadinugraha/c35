import 'app_update_install_stub.dart'
    if (dart.library.io) 'app_update_install_io.dart' as impl;

Future<bool> appUpdateInstallStaged(int version) => impl.appUpdateInstallStaged(version);
