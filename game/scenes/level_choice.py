import pygame

from game.scenes.base import Scene
from game.settings import WIDTH, HEIGHT, THEMES, WHITE, GREY
from game.ui.effects import get_background, draw_scanlines
from game.ui.text import get_font, draw_text
from game.audio import audio


class LevelChoiceScene(Scene):
    def __init__(
        self,
        game,
        cleared_stage,
        on_replay,
        on_restart,
        on_shop,
        on_advance,
    ):
        super().__init__(game)

        self.cleared_stage = cleared_stage
        self.on_replay = on_replay
        self.on_restart = on_restart
        self.on_shop = on_shop
        self.on_advance = on_advance
        self.sel = 0

        # Primary advance option always first
        if cleared_stage == 0:
            self.options = ["ADVANCE TO LEVEL 2"]
        elif cleared_stage == 1:
            self.options = ["ADVANCE TO LEVEL 3"]
        else:
            self.options = ["CONTINUE STORY"]

        self.options.append("VISIT NEXUS SHOP")
        self.options.append("REPLAY LEVEL 1")

        if cleared_stage >= 1:
            self.options.append("RESTART LEVEL 2")

        if cleared_stage >= 2:
            self.options.append("RESTART LEVEL 3")

    def _rects(self):
        total = len(self.options)
        button_height = 46
        gap = 12

        total_height = total * button_height + (total - 1) * gap
        start_y = 190 + (HEIGHT - 190 - total_height) // 2

        return [
            pygame.Rect(
                WIDTH // 2 - 240,
                start_y + i * (button_height + gap),
                480,
                button_height,
            )
            for i in range(total)
        ]

    def _activate(self):
        audio.play_sfx("click")
        selected = self.options[self.sel]

        if "ADVANCE" in selected or "CONTINUE STORY" in selected:
            self.on_advance()
        elif selected == "VISIT NEXUS SHOP":
            self.on_shop()
        elif selected == "REPLAY LEVEL 1":
            self.on_replay()
        elif selected == "RESTART LEVEL 2":
            self.on_restart(1)
        elif selected == "RESTART LEVEL 3":
            self.on_restart(2)
        else:
            self.on_advance()

    def handle_event(self, event):
        if event.type == pygame.KEYDOWN:
            if event.key in (pygame.K_UP, pygame.K_w):
                self.sel = (self.sel - 1) % len(self.options)
                audio.play_sfx("click")
            elif event.key in (pygame.K_DOWN, pygame.K_s):
                self.sel = (self.sel + 1) % len(self.options)
                audio.play_sfx("click")
            elif event.key in (pygame.K_RETURN, pygame.K_SPACE):
                self._activate()

        elif event.type == pygame.MOUSEMOTION:
            for i, rect in enumerate(self._rects()):
                if rect.collidepoint(event.pos):
                    self.sel = i

        elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            for i, rect in enumerate(self._rects()):
                if rect.collidepoint(event.pos):
                    self.sel = i
                    self._activate()
                    break

    def update(self, dt):
        pass

    def draw(self, screen):
        accent = THEMES["sim"]["accent"]
        screen.blit(get_background("sim"), (0, 0))

        stage_num = self.cleared_stage + 1
        draw_text(
            screen,
            f"STAGE {stage_num} COMPLETED",
            get_font(38, True),
            accent,
            (WIDTH // 2, 60),
            center=True,
        )

        draw_text(
            screen,
            "NEXUS SUBSYSTEM READY. CHOOSE ACTION:",
            get_font(18),
            WHITE,
            (WIDTH // 2, 115),
            center=True,
        )

        for i, (opt, rect) in enumerate(zip(self.options, self._rects())):
            selected = i == self.sel

            pygame.draw.rect(
                screen,
                accent if selected else (40, 50, 70),
                rect,
                2 if selected else 1,
                border_radius=8,
            )

            if selected:
                glow = pygame.Surface((rect.width, rect.height), pygame.SRCALPHA)
                pygame.draw.rect(glow, (*accent, 35), glow.get_rect(), border_radius=8)
                screen.blit(glow, rect.topleft)

            draw_text(
                screen,
                opt,
                get_font(19, True),
                WHITE if selected else GREY,
                rect.center,
                center=True,
            )

        draw_scanlines(screen)
