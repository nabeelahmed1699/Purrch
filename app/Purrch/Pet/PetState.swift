/// What the pet is doing. Each state gets its own animation in PetController.
/// Future states (annoyed, held, happy) are added here as new cases.
enum PetState {
    /// Hidden inside the notch. Nothing is drawn and nothing runs.
    case resting
    /// The ball game (play.js).
    case playing
    /// Out of the notch, sitting and meowing until it's fed (hungry.js).
    case hungry
    /// Eating from the bowl, then heading back into the notch (hungry.js).
    case eating
    /// Out of the notch just for attention: sitting facing you, pawing at the screen.
    case attention
    /// Napping in its bed (sleep.js). Hidden in the notch; asleep in the bed while hovered.
    case sleeping
}
