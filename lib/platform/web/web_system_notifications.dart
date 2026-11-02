import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:shuffle_alarm/platform/system_notifications.dart';
import 'package:web/web.dart' as web;

/// Notifications from the page, with the browser's Notifications API: Chrome,
/// Edge, Firefox and Safari on a computer.
///
/// Chrome and Samsung Internet on Android throw when a page makes one, and
/// Safari on an iPhone has no `Notification`, so it is unavailable there
/// (docs/DECISIONS.md, 2.4a). It asks nobody for a permission it cannot use.
class WebSystemNotifications implements SystemNotifications {
  /// A second notification with this tag replaces the first, also when two
  /// tabs of the app are open.
  static const _tag = 'wakemix';

  /// Whether the page can make a notification, once it has tried.
  bool? _canMake;

  @override
  NotificationAccess get access {
    if (_canMake == false || !web.window.has('Notification')) {
      return NotificationAccess.unavailable;
    }
    final permission = web.Notification.permission;
    if (permission == 'granted') return NotificationAccess.allowed;
    if (!(_canMake ??= _tryMaking())) return NotificationAccess.unavailable;
    return permission == 'denied'
        ? NotificationAccess.blocked
        : NotificationAccess.notAsked;
  }

  /// Without the permission, a notification that a page makes shows nothing
  /// and only fires an error event, so this is safe before the question.
  bool _tryMaking() {
    try {
      web.Notification('');
      return true;
    } on Object {
      return false;
    }
  }

  @override
  Future<NotificationAccess> ask() async {
    if (access == NotificationAccess.unavailable) return access;
    try {
      await web.Notification.requestPermission().toDart;
    } on Object catch (error) {
      debugPrint('Could not ask for notifications: $error');
    }
    return access;
  }

  @override
  Future<void> show({required String title, required String body}) async {
    final web.Notification notification;
    try {
      notification = web.Notification(
        title,
        // Renotify, or it would replace one still in the system's list
        // without showing.
        web.NotificationOptions(body: body, tag: _tag, renotify: true),
      );
    } on Object {
      // Such as Chrome on Android, after someone allowed it in the settings.
      _canMake = false;
      rethrow;
    }
    // A click on it brings the tab back.
    notification.onclick = ((web.Event _) {
      web.window.focus();
      notification.close();
    }).toJS;
  }
}
