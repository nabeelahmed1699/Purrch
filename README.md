# Purrch

A pixel-art cat that lives in your MacBook's notch.

The cat hides in the notch, comes out to chase a ball, gets hungry and meows until you feed it,
and naps in its bed. Hover over the notch to open a bigger view where it sits on its chair: you
can pet it, and it may hop down and wander around.

## Requirements

- macOS 14 or later
- A Mac with a notch (MacBook Pro 2021 or later, MacBook Air 2022 or later)
- Xcode 15 or later to build

## Build and run

```sh
git clone https://github.com/nabeelahmed1699/Purrch.git
cd Purrch
open app/Purrch.xcodeproj
```

Then press Run in Xcode. The app is ad-hoc signed, so no Apple developer account is needed.

## How it's put together

| Path | What it is |
|---|---|
| `app/Purrch/` | The Swift app: notch window, pet behaviour, rendering, menu bar |
| `app/Resources/sprites.json` | All sprite and animation data the app draws, generated from the JS files |
| `app/Resources/Sounds/` | Sound effects (sources and licences in [SOUNDS.md](SOUNDS.md)) |
| `*.js` (root) | Source of truth for the art and choreography: palettes, frames, routines |
| `vector/` | Vector cat art and the browser pages that rasterise it into `parts.js` and `play-frames.js` |
| `tools/export-sprites.mjs` | Builds `sprites.json` from the root JS files |

### Changing the art or animations

1. Edit the JS files in the project root (or the vector sources in `vector/`, then open
   `vector/build-parts.html` or `vector/build-play.html` in a browser and save the output into the
   project root).
2. Regenerate the app's data:

   ```sh
   node tools/export-sprites.mjs
   ```

3. Rebuild in Xcode.

The exporter needs Node 18 or later and has no npm dependencies.

### Design rules

- Unless the mouse is over the notch, nothing grows taller than the notch. The black shape may
  only widen sideways into the menu bar.
- The notch itself has no display pixels, so anything drawn inside it is invisible. The cat uses
  it as a hiding place, never to show content.

## Contributing

Issues and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Code and art: [MIT](LICENSE). Sound effects are CC0 or made for this project; see
[SOUNDS.md](SOUNDS.md).
