# Purrch sound effects

All sounds in `app/Resources/Sounds/` are CC0 (public domain) or made for this project, so
they can ship in the app with no attribution required. Credit is given here anyway.

Every file was trimmed to the sound, given short fades, levelled, and converted to
44.1 kHz mono 16-bit WAV. The purr is kept whole so it loops.

| File | Use | Source | Author | Licence |
|---|---|---|---|---|
| meow1.wav | hungry meow | [Meow](https://opengameart.org/content/meow) (Meow.ogg) | IgnasD | CC0 |
| meow2.wav | hungry meow | [Cat Purr & Meow](https://opengameart.org/content/cat-purr-meow) (cat_mewfood.wav) | Kerzoven | CC0 |
| meow3.wav | hungry meow (soft, long) | [Cat Purr & Meow](https://opengameart.org/content/cat-purr-meow) (cat_softmew.wav) | Kerzoven | CC0 |
| chirp.wav | when petting starts | [Cat Purr & Meow](https://opengameart.org/content/cat-purr-meow) (cat_mewpurr.wav) | Kerzoven | CC0 |
| purr.wav | petting (loop) | [Cat Purr & Meow](https://opengameart.org/content/cat-purr-meow) (cat_purrsleepy_loop.wav) | Kerzoven | CC0 |
| bounce1–3.wav | ball bounces | [Impact Sounds](https://kenney.nl/assets/impact-sounds) (impactGeneric_light_001/003/004) | Kenney | CC0 |
| swat.wav | cat bats the ball | [Impact Sounds](https://kenney.nl/assets/impact-sounds) (impactSoft_medium_001) | Kenney | CC0 |
| land.wav | hopping off the chair | [Impact Sounds](https://kenney.nl/assets/impact-sounds) (footstep_carpet_001) | Kenney | CC0 |
| bowl.wav | bowl set down | [Impact Sounds](https://kenney.nl/assets/impact-sounds) (impactPlate_light_002) | Kenney | CC0 |
| throw.wav | ball thrown | [Interface Sounds](https://kenney.nl/assets/interface-sounds) (drop_003) | Kenney | CC0 |
| open.wav | hover view opens | [Interface Sounds](https://kenney.nl/assets/interface-sounds) (maximize_003) | Kenney | CC0 |
| close.wav | hover view closes | [Interface Sounds](https://kenney.nl/assets/interface-sounds) (minimize_003) | Kenney | CC0 |
| scratch1–2.wav | ear scratching | [RPG Audio](https://kenney.nl/assets/rpg-audio) (cloth2, cloth3) | Kenney | CC0 |
| crunch1–3.wav | eating | synthesised for Purrch (filtered noise bursts) | — | ours |

Kenney's packs include a `License.txt` stating CC0 1.0
(<http://creativecommons.org/publicdomain/zero/1.0/>).

To audition them all:

```sh
for f in app/Resources/Sounds/*.wav; do echo "$f"; afplay "$f"; done
```
