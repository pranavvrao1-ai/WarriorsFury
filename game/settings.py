"""Global constants. Tweak numbers here instead of hunting through the code."""
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
ASSETS_DIR = BASE_DIR / "assets"
MUSIC_DIR = BASE_DIR / "gameathon music"
DIALOGUES_DIR = BASE_DIR / "dialougues"
FOOTSTEPS_DIR = BASE_DIR / "footsteps"
CHARACTERS_DIR = BASE_DIR / "characters"
ROBOT_DIR = BASE_DIR / "robot"

WIDTH, HEIGHT = 960, 540
FPS = 60
TITLE = "Warrior's Fury: The Final Level"

WHITE = (240, 240, 245)
GREY = (140, 145, 160)
RED = (255, 70, 90)

THEMES = {
    "cafe": {"bg_top": (12, 8, 26), "bg_bottom": (46, 10, 58), "accent": (255, 60, 160)},
    "sim": {"bg_top": (4, 10, 26), "bg_bottom": (0, 46, 66), "accent": (0, 230, 255)},
    "dark": {"bg_top": (0, 0, 0), "bg_bottom": (8, 8, 14), "accent": (90, 130, 255)},
}

SPEAKER_COLORS = {
    "MC": (255, 255, 255),
    "UNKNOWN PLAYER": (255, 80, 200),
    "UNKNOWN": (255, 80, 200),
    "NEXUS": (255, 70, 70),
    "RECEPTIONIST": (255, 200, 90),
    "SHOPKEEPER": (170, 220, 140),
}
