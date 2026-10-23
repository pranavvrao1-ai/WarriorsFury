"""Headless smoke tests: python -m pytest"""
import os

os.environ.setdefault("SDL_VIDEODRIVER", "dummy")
os.environ.setdefault("SDL_AUDIODRIVER", "dummy")

import pygame

from game.data.story import STORY
from game.data.stages import STAGES
from game.engine import Game
from game.flow import STEPS, start_title
from game.scenes.combat import CombatScene
from game.scenes.story import StoryScene


def key(k):
    return pygame.event.Event(pygame.KEYDOWN, key=k)


def test_every_story_scene_finishes():
    game = Game()
    for name, lines in STORY.items():
        done = []
        scene = StoryScene(game, lines, "sim", lambda: done.append(1))
        game.set_scene(scene)
        for _ in range(5000):
            if done:
                break
            events = [key(pygame.K_SPACE), key(pygame.K_RETURN)] if scene.choice is None else [key(pygame.K_RETURN)]
            game.tick(0.1, events)
        assert done, f"story '{name}' never finished"


def test_every_combat_stage_runs_and_can_be_won():
    game = Game()
    for idx in range(len(STAGES)):
        done = []
        scene = CombatScene(game, idx, lambda: done.append(1))
        game.set_scene(scene)
        for _ in range(300):
            game.tick(1 / 60, [])
        # cheat: kill everything each frame until the stage is won
        for _ in range(2000):
            for e in scene.enemies:
                e.hp = 0
            game.tick(1 / 30, [])
            if done:
                break
        assert done, f"stage {idx} could not be completed"


def test_steps_reference_valid_content():
    for kind, arg, _ in STEPS:
        assert (arg in STORY) if kind == "story" else (0 <= arg < len(STAGES))


def test_title_boots():
    game = Game()
    start_title(game)
    game.tick(0.016, [])
