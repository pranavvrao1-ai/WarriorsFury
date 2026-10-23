# Warrior's Fury: The Final Level

A 2D top-down action game with a story-driven, reality-bending twist (Pygame).
*Never explain the mystery completely.*

## Run it (PyCharm)
1. Open this folder in PyCharm (File > Open).
2. Create a virtual environment (PyCharm will offer one), then: `pip install -r requirements.txt`
3. Right-click `main.py` > Run.

## Controls
WASD / arrows move | mouse aims | click or SPACE shoots | SHIFT dashes | ESC back to title | R retry

## Project layout
```
main.py              entry point
game/
  settings.py        screen size, colours, themes, speaker colours
  engine.py          Game class: window + main loop
  flow.py            ORDER of the whole game (STEPS list)
  scenes/            title, story (dialogue/typewriter/effects), combat, endcard
  entities/          player, enemy (grunt/shooter/boss NEXUS), projectile
  data/story.py      ALL story text - edit the narrative here
  data/stages.py     enemy waves per stage
  ui/                text helpers + glitch/scanline/flash effects
assets/              put images / sounds / fonts here
tests/               headless smoke tests (python -m pytest)
```

## Ideas for next steps
- Add sprites to `assets/images` and replace the circle drawing in `entities/`
- Add music/SFX (`pygame.mixer`) - a keyboard-typing sound leaking into Act II would be creepy
- Save system, more stages, a Session 002 mode

## Push to GitHub
```bash
git init
git add .
git commit -m "Initial commit: Warrior's Fury prototype"
git branch -M main
git remote add origin https://github.com/<your-username>/warriors-fury.git
git push -u origin main
```
(Create the empty repo on github.com first.)
