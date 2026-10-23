# WARRIOR'S FURY — The Final Level

A story-driven game with two builds kept in the same repository:
- **Godot 4 3D story build**: Afterlife Gaming Lounge → Neo-Eden → Awakening → Vanishing Café → Session 002.
- **Original Pygame prototype**: the existing 2D top-down action game, still available through `main.py`.

## Run the 3D Godot game (Windows)

1. Install **Godot 4.4.1 Standard** (not .NET).
2. Download this branch as a ZIP and extract the complete folder.
3. Open Godot Project Manager → **Import**.
4. Select `project.godot` in the extracted repository root (not the `after-life--session-zero` subfolder).
5. Open the project and wait for asset import to finish.
6. Press **F6** only for the current scene; press **F5** or **Play Project** to run the full story.

### 3D controls

- **WASD** — move; **Shift** — sprint; **Space** — jump
- **Click** — capture mouse; move mouse — look around; **Esc** — release mouse
- **E** — interact / advance story; **V** — switch first-person / third-person; **C** or **1–9** — CCTV; **0** — return to player camera

If the screen is black or a resource fails to import, open **Project → Tools → Orphan Resource Explorer** only after checking the Output panel; capture the first red error from **Debugger → Errors** for diagnosis.

## Run the original Pygame prototype (PyCharm)

1. Open this repository in PyCharm.
2. Install dependencies with `pip install -r requirements.txt`.
3. Run `main.py`.

## Repository layout

```
project.godot                 Godot 3D startup project
after-life--session-zero/     Godot world, controller and story director
characters/                   Existing GLB character assets
robot/                        Robot GLB and legacy OBJ
dialougues/, footsteps/       Existing dialogue and sound assets
game/                         Original Pygame implementation
main.py                       Pygame entry point
tests/                        Pygame and Godot smoke tests
```
