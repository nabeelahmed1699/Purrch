import AppKit

/// Tells you when nobody can see the screen: display asleep, Mac locked, or the user
/// switched to another account. Calls `onChange(true)` when hidden, `false` when back.
@MainActor
final class SystemActivityObserver {
    private let onChange: (Bool) -> Void
    private var screensAsleep = false
    private var locked = false
    private var sessionInactive = false
    // Observers live as long as the app, so they are never removed.
    private var tokens: [NSObjectProtocol] = []

    init(onChange: @escaping (Bool) -> Void) {
        self.onChange = onChange

        let workspace = NSWorkspace.shared.notificationCenter
        listen(workspace, NSWorkspace.screensDidSleepNotification) { $0.screensAsleep = true }
        listen(workspace, NSWorkspace.screensDidWakeNotification) { $0.screensAsleep = false }
        listen(workspace, NSWorkspace.sessionDidResignActiveNotification) { $0.sessionInactive = true }
        listen(workspace, NSWorkspace.sessionDidBecomeActiveNotification) { $0.sessionInactive = false }

        // Lock / unlock are only announced as system-wide distributed notifications.
        let distributed = DistributedNotificationCenter.default()
        listen(distributed, Notification.Name("com.apple.screenIsLocked")) { $0.locked = true }
        listen(distributed, Notification.Name("com.apple.screenIsUnlocked")) { $0.locked = false }
    }

    private func listen(_ center: NotificationCenter, _ name: Notification.Name,
                        update: @escaping (SystemActivityObserver) -> Void) {
        let token = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                update(self)
                self.onChange(self.screensAsleep || self.locked || self.sessionInactive)
            }
        }
        tokens.append(token)
    }
}
