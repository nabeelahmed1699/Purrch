import CoreGraphics

/// Lets Purrch change the mouse pointer (the petting hand) even though it's never the active
/// app. macOS normally ignores cursor changes from background apps; this window-server
/// connection property lifts that. It's private API (fine outside the App Store), so if it
/// ever stops working the pointer simply stays the normal arrow.
enum BackgroundCursor {
    static func enable() {
        let connection = _CGSDefaultConnection()
        _ = CGSSetConnectionProperty(connection, connection, "SetsCursorInBackground" as CFString, kCFBooleanTrue)
    }
}

private typealias CGSConnectionID = Int32

@_silgen_name("_CGSDefaultConnection")
private func _CGSDefaultConnection() -> CGSConnectionID

@_silgen_name("CGSSetConnectionProperty")
private func CGSSetConnectionProperty(_ connection: CGSConnectionID, _ target: CGSConnectionID,
                                      _ key: CFString, _ value: CFTypeRef) -> CGError
