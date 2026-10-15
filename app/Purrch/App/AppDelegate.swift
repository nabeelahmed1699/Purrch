import AppKit

/// Owns the long-lived pieces of the app and wires them together at launch.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let sprites: SpriteLibrary
    let pet: PetController

    private var notchWindow: NotchWindowController?
    private var systemActivity: SystemActivityObserver?

    override init() {
        sprites = SpriteLibrary.loadFromBundle()
        pet = PetController(sprites: sprites)
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // The petting hand cursor needs this: Purrch is never the active app.
        BackgroundCursor.enable()
        notchWindow = NotchWindowController(pet: pet, sprites: sprites)
        notchWindow?.show()

        // Stop animating while the screen sleeps or the Mac is locked.
        systemActivity = SystemActivityObserver { [weak self] isIdle in
            self?.pet.setSystemPaused(isIdle)
        }

        pet.start()
    }
}
