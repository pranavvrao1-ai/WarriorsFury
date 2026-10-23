"""Controls story progression, replays, and the NEXUS Shop."""

from game.data.story import STORY
from game.scenes.combat import CombatScene
from game.scenes.endcard import EndCardScene
from game.scenes.story import StoryScene
from game.scenes.title import TitleScene
from game.scenes.level_choice import LevelChoiceScene
from game.scenes.shop import NexusShopScene
from game.entities.progression import PlayerProgression
from game.audio import audio


STEPS = [
    ("story", "act1", "cafe"),
    ("story", "act2_intro", "sim"),
    ("combat", 0, "sim"),
    ("story", "memory1", "sim"),
    ("combat", 1, "sim"),
    ("story", "memory2", "sim"),
    ("story", "nexus", "sim"),
    ("combat", 2, "sim"),
    ("story", "collapse", "sim"),
    ("story", "act3", "cafe"),
    ("story", "act4", "cafe"),
    ("story", "post", "dark"),
]


def start_title(game):
    game.to_title = lambda: start_title(game)

    def start_new_run():
        game.progression = PlayerProgression()
        run_step(game, 0)

    game.set_scene(TitleScene(game, on_start=start_new_run))


def show_shop(game, next_index, cleared_stage):
    game.set_scene(
        NexusShopScene(
            game,
            on_done=lambda: show_level_choice(
                game, next_index, cleared_stage
            ),
        )
    )


def show_level_choice(game, next_index, cleared_stage):
    def replay_level_one():
        game.set_scene(
            CombatScene(
                game, 0,
                lambda: show_level_choice(game, 3, 0),
                show_intro=False,
            )
        )

    def restart_level_two():
        game.set_scene(
            CombatScene(
                game, 1,
                lambda: show_level_choice(game, 5, 1),
                show_intro=False,
            )
        )

    def advance():
        print("Advancing campaign to step:", next_index)
        run_step(game, next_index)

    game.set_scene(
        LevelChoiceScene(
            game,
            cleared_stage=cleared_stage,
            on_replay=replay_level_one,
            on_restart=restart_level_two,
            on_shop=lambda: show_shop(
                game, next_index, cleared_stage
            ),
            on_advance=advance,
        )
    )


def run_step(game, index):
    print("Running campaign step:", index)

    if index >= len(STEPS):
        game.set_scene(
            EndCardScene(game, on_done=game.to_title)
        )
        return

    kind, arg, theme = STEPS[index]

    if kind == "story":
        if arg == "act1":
            audio.play_music("cafe")
        elif arg == "act2_intro":
            audio.play_music("cyber")
        elif arg in ("nexus", "collapse"):
            audio.play_music("tension")
        elif arg == "act3":
            audio.play_music("awakening")
        elif arg == "act4":
            audio.play_music("fear")
        elif arg == "post":
            audio.play_music("drone")

    elif kind == "combat":
        audio.play_music("boss" if arg == 2 else "cyber")

    def done():
        print("Completed:", kind, arg)

        if kind == "combat":
            if arg == 2:
                # Stage 3 Boss (NEXUS) defeated!
                # Do NOT show a shop/replay menu — immediately trigger the simulation collapse & twist ending!
                run_step(game, index + 1)
            else:
                show_level_choice(game, index + 1, arg)
        else:
            run_step(game, index + 1)

    if kind == "story":
        game.set_scene(
            StoryScene(game, STORY[arg], theme, done)
        )
    elif kind == "combat":
        game.set_scene(
            CombatScene(game, arg, done)
        )
