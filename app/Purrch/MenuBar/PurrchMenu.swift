import SwiftUI

/// The menu that opens from the paw icon in the menu bar.
struct PurrchMenu: View {
    @Bindable var pet: PetController

    private var catName: String {
        pet.cats.first { $0.id == pet.catID }?.name ?? "cat"
    }

    var body: some View {
        Picker("Cat", selection: $pet.catID) {
            ForEach(pet.cats) { cat in
                Text(cat.name).tag(cat.id)
            }
        }

        Button(pet.state == .hungry ? "Feed \(catName) (hungry!)" : "Feed \(catName)") {
            pet.feed()
        }
        .disabled(pet.state == .playing || pet.state == .eating)

        Button("Play with the ball now") {
            pet.playNow()
        }
        .disabled(pet.state != .resting && pet.state != .sleeping)

        Button(pet.state == .sleeping ? "Wake \(catName) up" : "Send \(catName) to bed") {
            pet.toggleNap()
        }
        .disabled(pet.state != .resting && pet.state != .sleeping)

        Button(pet.isPausedByUser ? "Resume animation" : "Pause animation") {
            pet.togglePause()
        }

        Divider()

        Toggle("Sound effects", isOn: $pet.soundEnabled)
        Picker("Volume", selection: $pet.soundVolume) {
            ForEach(PetController.SoundVolume.allCases) { level in
                Text(level.rawValue.capitalized).tag(level)
            }
        }
        .disabled(!pet.soundEnabled)

        Divider()

        Button("Quit Purrch") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
