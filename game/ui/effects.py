import random

import pygame

from game.settings import WIDTH, HEIGHT, THEMES

_backgrounds = {}
_scanlines = None


def get_background(theme):
    if theme not in _backgrounds:
        t = THEMES[theme]
        surf = pygame.Surface((WIDTH, HEIGHT))
        for y in range(HEIGHT):
            k = y / HEIGHT
            color = tuple(
                int(t["bg_top"][i] + (t["bg_bottom"][i] - t["bg_top"][i]) * k)
                for i in range(3)
            )
            pygame.draw.line(surf, color, (0, y), (WIDTH, y))
        _backgrounds[theme] = surf
    return _backgrounds[theme]


def draw_scanlines(screen):
    global _scanlines
    if _scanlines is None:
        _scanlines = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
        for y in range(0, HEIGHT, 3):
            pygame.draw.line(_scanlines, (0, 0, 0, 38), (0, y), (WIDTH, y))
    screen.blit(_scanlines, (0, 0))


def apply_glitch(screen, strength=10):
    snap = screen.copy()
    for _ in range(strength):
        y = random.randint(0, HEIGHT - 20)
        h = random.randint(4, 40)
        dx = random.randint(-40, 40)
        screen.blit(snap, (dx, y), pygame.Rect(0, y, WIDTH, h))


def draw_flash(screen, amount):
    if amount <= 0:
        return
    veil = pygame.Surface((WIDTH, HEIGHT))
    veil.fill((255, 255, 255))
    veil.set_alpha(int(255 * min(amount, 1)))
    screen.blit(veil, (0, 0))
