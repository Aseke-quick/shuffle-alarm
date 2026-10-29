/// Keeps the screen on, so the device does not sleep while alarms wait to
/// ring: in a browser, a hidden or sleeping tab rings late or not at all.
abstract interface class ScreenWakeLock {
  /// Whether this platform can keep the screen on.
  bool get supported;

  /// Whether the screen is kept on now. The platform can let go, such as a
  /// browser while the tab is hidden; [hold] takes it again when it can.
  bool get held;

  /// [held] each time it changes.
  Stream<bool> get heldChanges;

  /// Keeps the screen on until [release]: now if the platform lets it, and
  /// again each time it can after it let go.
  Future<void> hold();

  /// Lets the screen turn off again.
  Future<void> release();

  /// Lets go for good.
  Future<void> dispose();
}

/// The wake lock of a platform that cannot keep the screen on yet.
class NoScreenWakeLock implements ScreenWakeLock {
  const NoScreenWakeLock();

  @override
  bool get supported => false;

  @override
  bool get held => false;

  @override
  Stream<bool> get heldChanges => const Stream.empty();

  @override
  Future<void> hold() async {}

  @override
  Future<void> release() async {}

  @override
  Future<void> dispose() async {}
}
