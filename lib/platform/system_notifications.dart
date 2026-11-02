/// Whether the app may show a notification.
enum NotificationAccess {
  /// This platform cannot show one from the app: some browsers, and Android,
  /// iOS and the desktop until Phases 4 to 6.
  unavailable,

  /// Nobody answered yet, so [SystemNotifications.ask] can ask.
  notAsked,

  /// It may.
  allowed,

  /// The person said no. Only the settings of the browser or the system can
  /// change that now.
  blocked,
}

/// Shows notifications of the system, such as the bedtime reminder. Each
/// platform has its own way (`CLAUDE.md`), and the app reaches it only through
/// this interface.
abstract interface class SystemNotifications {
  /// What the platform says now. The person can change it at any time, in the
  /// settings of the browser or the system.
  NotificationAccess get access;

  /// Asks the person, and tells what is true after their answer:
  /// [NotificationAccess.notAsked] if they gave none, such as when they closed
  /// the question.
  ///
  /// Call it in a tap, after a short screen that explains it (`CLAUDE.md`): a
  /// browser may ask only then.
  Future<NotificationAccess> ask();

  /// Shows a notification now, in place of the one it showed before. Throws
  /// if it cannot.
  Future<void> show({required String title, required String body});
}

/// The notifications of a platform that cannot show them yet.
class NoSystemNotifications implements SystemNotifications {
  const NoSystemNotifications();

  @override
  NotificationAccess get access => NotificationAccess.unavailable;

  @override
  Future<NotificationAccess> ask() async => NotificationAccess.unavailable;

  @override
  Future<void> show({required String title, required String body}) async {}
}
