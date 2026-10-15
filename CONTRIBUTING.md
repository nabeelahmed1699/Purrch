# Contributing to Purrch

Thanks for helping out. Bug reports, ideas and pull requests are all welcome.

## Reporting a bug

Open an issue with:

- your Mac model and macOS version
- what the cat was doing and what you expected instead
- a screen recording if you can, since most bugs here are visual

## Pull requests

1. Fork the repo and create a branch from `main`.
2. Make your change. If you edited any of the JS art or animation files, run
   `node tools/export-sprites.mjs` and commit the updated `app/Resources/sprites.json` too.
3. Build and run the app in Xcode and check the change on a Mac with a notch.
4. Open a pull request describing what changed and why. Screenshots or recordings help a lot.

Keep to the two design rules in the [README](README.md#design-rules): nothing taller than the
notch unless it's hovered, and nothing meant to be seen drawn inside the notch.

## Sounds and art

New sounds must be CC0 or your own work. Add a row for each one to [SOUNDS.md](SOUNDS.md) with its
source, author and licence.

By contributing, you agree your contributions are released under the [MIT License](LICENSE).
