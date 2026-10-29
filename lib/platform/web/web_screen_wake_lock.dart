import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:shuffle_alarm/platform/screen_wake_lock.dart';
import 'package:web/web.dart' as web;

/// Keeps the screen on with the browser's Screen Wake Lock API
/// (`navigator.wakeLock`): Chrome and Edge, Safari 16.4 and later, Firefox
/// 126 and later.
///
/// The browser lets go of the lock while the tab is hidden, so it asks again
/// each time the tab comes back into view. It needs no permission prompt.
class WebScreenWakeLock implements ScreenWakeLock {
  WebScreenWakeLock() {
    _visibility = web.document.onVisibilityChange.listen((_) {
      if (_wanted) unawaited(_request());
    });
  }

  late final StreamSubscription<web.Event> _visibility;
  final _changes = StreamController<bool>.broadcast();
  web.WakeLockSentinel? _sentinel;
  var _wanted = false;

  @override
  bool get supported => web.window.navigator.has('wakeLock');

  @override
  bool get held => _sentinel != null;

  @override
  Stream<bool> get heldChanges => _changes.stream;

  @override
  Future<void> hold() async {
    _wanted = true;
    await _request();
  }

  Future<void> _request() async {
    if (!supported || held || web.document.visibilityState != 'visible') {
      return;
    }
    try {
      final sentinel = await web.window.navigator.wakeLock
          .request('screen')
          .toDart;
      if (!_wanted) {
        await sentinel.release().toDart;
        return;
      }
      _sentinel = sentinel;
      sentinel.onrelease = ((web.Event _) {
        if (!identical(_sentinel, sentinel)) return;
        _sentinel = null;
        _changes.add(false);
      }).toJS;
      _changes.add(true);
    } on Object {
      // Refused, such as when the battery is low: the screen may turn off.
      _changes.add(false);
    }
  }

  @override
  Future<void> release() async {
    _wanted = false;
    final sentinel = _sentinel;
    _sentinel = null;
    if (sentinel == null) return;
    _changes.add(false);
    try {
      await sentinel.release().toDart;
    } on Object {
      // Released already.
    }
  }

  @override
  Future<void> dispose() async {
    await release();
    await _visibility.cancel();
    await _changes.close();
  }
}
