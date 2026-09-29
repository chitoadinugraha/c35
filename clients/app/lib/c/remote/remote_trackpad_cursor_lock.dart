import 'remote_trackpad_cursor_lock_stub.dart';
import 'remote_trackpad_cursor_lock_io.dart'
    if (dart.library.html) 'remote_trackpad_cursor_lock_stub.dart' as impl;

export 'remote_trackpad_cursor_lock_stub.dart';

RemoteTrackpadCursorLock createRemoteTrackpadCursorLock() =>
    impl.createRemoteTrackpadCursorLock();
