"""The order of the whole game. Reorder / add steps here."""
from game.data.story import STORY
from game.scenes.combat import CombatScene
from game.scenes.endcard import EndCardScene
from game.scenes.story import StoryScene
from game.scenes.title import TitleScene

# (kind, argument, visual theme)
STEPS = [
    ("story", "act1", "cafe"),        # Act I   - the place that shouldn't exist
    ("story", "act2_intro", "sim"),   # Act II  - Neo-Eden
    ("combat", 0, "sim"),
    ("story", "memory1", "sim"),
    ("combat", 1, "sim"),
    ("story", "memory2", "sim"),
    ("story", "nexus", "sim"),
    ("combat", 2, "sim"),             # NEXUS boss
    ("story", "collapse", "sim"),
    ("story", "act3", "cafe"),        # Act III - the awakening
    ("story", "act4", "cafe"),        # Act IV  - the cafe that never existed
    ("story", "post", "dark"),        # post-credits
]


def start_title(game):
    game.to_title = lambda: start_title(game)
    game.set_scene(TitleScene(game, on_start=lambda: run_step(game, 0)))


def run_step(game, index):
    if index >= len(STEPS):
        game.set_scene(EndCardScene(game, on_done=game.to_title))
        return
    kind, arg, theme = STEPS[index]

    def done():
        run_step(game, index + 1)

    if kind == "story":
        game.set_scene(StoryScene(game, STORY[arg], theme, done))
    else:
        game.set_scene(CombatScene(game, arg, done))
