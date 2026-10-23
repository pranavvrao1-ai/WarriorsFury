import random
import pygame

from game.scenes.base import Scene
from game.settings import WIDTH, HEIGHT, THEMES, WHITE, GREY
from game.ui.effects import get_background, draw_scanlines, apply_glitch
from game.ui.text import get_font, draw_text
from game.audio import audio


class TitleScene(Scene):
    OPTIONS = ["START GAME", "QUIT"]

    def __init__(self, game, on_start):
        super().__init__(game)
        self.on_start = on_start
        self.sel = 0
        self.t = 0.0
        self.glitch_t = 0.0
        audio.play_music("suspense")

    def _activate(self):
        audio.play_sfx("click")
        if self.sel == 0:
            self.on_start()
        else:
            self.game.quit()

    def _rects(self):
        return [
            pygame.Rect(
                WIDTH // 2 - 130,
                330 + i * 60,
                260,
                46,
            )
            for i in range(len(self.OPTIONS))
        ]

    def handle_event(self, event):
        if event.type == pygame.KEYDOWN:
            if event.key in (pygame.K_UP, pygame.K_w):
                self.sel = (self.sel - 1) % len(self.OPTIONS)
                audio.play_sfx("click")
            elif event.key in (pygame.K_DOWN, pygame.K_s):
                self.sel = (self.sel + 1) % len(self.OPTIONS)
                audio.play_sfx("click")
            elif event.key in (pygame.K_RETURN, pygame.K_SPACE):
                self._activate()

        elif event.type == pygame.MOUSEMOTION:
            for i, rect in enumerate(self._rects()):
                if rect.collidepoint(event.pos):
                    if self.sel != i:
                        self.sel = i

        elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            for i, rect in enumerate(self._rects()):
                if rect.collidepoint(event.pos):
                    self.sel = i
                    self._activate()

    def update(self, dt):
        self.t += dt
        if random.random() < 0.01:
            self.glitch_t = 0.15
        self.glitch_t = max(0.0, self.glitch_t - dt)

    def draw(self, screen):
        accent = THEMES["sim"]["accent"]
        screen.blit(get_background("sim"), (0, 0))
        draw_text(
            screen, "WARRIOR'S FURY", get_font(64, True),
            accent, (WIDTH // 2, 160), center=True
        )
        draw_text(
            screen, "THE FINAL LEVEL", get_font(28),
            WHITE, (WIDTH // 2, 225), center=True
        )

        for i, (opt, rect) in enumerate(
            zip(self.OPTIONS, self._rects())
        ):
            selected = i == self.sel
            pygame.draw.rect(
                screen, accent if selected else GREY,
                rect, 2 if selected else 1, border_radius=6
            )
            draw_text(
                screen, opt, get_font(24, selected),
                WHITE if selected else GREY,
                rect.center, center=True
            )

        draw_text(
            screen, "Never explain the mystery completely.",
            get_font(14), GREY,
            (WIDTH // 2, HEIGHT - 30), center=True
        )

        if self.glitch_t > 0:
            apply_glitch(screen, 8)

        draw_scanlines(screen)
