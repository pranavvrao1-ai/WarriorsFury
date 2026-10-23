import pygame

from game.scenes.base import Scene
from game.settings import WIDTH, HEIGHT, WHITE, GREY
from game.ui.effects import get_background, draw_scanlines
from game.ui.text import get_font, draw_text
from game.audio import audio


class EndCardScene(Scene):
    def __init__(self, game, on_done):
        super().__init__(game)
        self.on_done = on_done
        self.t = 0.0
        audio.play_music("fear")

    def handle_event(self, event):
        if self.t > 1.5 and event.type in (pygame.KEYDOWN, pygame.MOUSEBUTTONDOWN):
            audio.play_sfx("click")
            self.on_done()

    def update(self, dt):
        self.t += dt

    def draw(self, screen):
        screen.blit(get_background("dark"), (0, 0))
        alpha = int(255 * min(self.t / 2.0, 1))
        draw_text(screen, "Did he wake up from the simulation,", get_font(26), WHITE, (WIDTH // 2, 200), center=True, alpha=alpha)
        draw_text(screen, "or did he just enter another one?", get_font(26), WHITE, (WIDTH // 2, 240), center=True, alpha=alpha)
        draw_text(screen, "TO BE CONTINUED...", get_font(40, True), (90, 130, 255), (WIDTH // 2, 340), center=True, alpha=alpha)
        if self.t > 1.5:
            draw_text(screen, "press any key", get_font(16), GREY, (WIDTH // 2, HEIGHT - 40), center=True)
        draw_scanlines(screen)
