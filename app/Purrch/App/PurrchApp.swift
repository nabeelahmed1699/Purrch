import SwiftUI

/// Entry point. Purrch is a menu bar app (LSUIElement): no Dock icon, no main window.
/// The only SwiftUI "scene" is the menu bar item; the notch window is created by AppDelegate.
@main
struct PurrchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Purrch", systemImage: "pawprint.fill") {
            PurrchMenu(pet: appDelegate.pet)
        }
    }
}
