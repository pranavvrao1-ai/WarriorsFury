
import pygame

from game.scenes.base import Scene
from game.settings import WIDTH, HEIGHT, THEMES, WHITE, GREY
from game.ui.effects import get_background, draw_scanlines
from game.ui.text import get_font, draw_text


class NexusShopScene(Scene):
    ITEMS = [
        ("shield", "SHIELD", "Absorbs 60 damage", 150),
        ("armor", "ARMOR", "Reduces health damage by 25%", 200),
        ("health_core", "HEALTH CORE", "Maximum health +25", 100),
        (
            "overclock",
            "WEAPON OVERCLOCK",
            "Damage +50%, firing speed +25%",
            250,
        ),
    ]

    def __init__(self, game, on_done):
        super().__init__(game)
        self.on_done = on_done
        self.progression = game.progression
        self.selected = 0
        self.message = "SELECT AN UPGRADE"
        self.message_timer = 0.0

    def _rects(self):
        return [
            pygame.Rect(
                WIDTH // 2 - 350,
                205 + i * 75,
                700,
                60,
            )
            for i in range(len(self.ITEMS))
        ]

    def _buy_selected(self):
        item_id = self.ITEMS[self.selected][0]
        _, message = self.progression.purchase(item_id)
        self.message = message
        self.message_timer = 2.5

    def handle_event(self, event):
        if event.type == pygame.KEYDOWN:
            if event.key in (pygame.K_UP, pygame.K_w):
                self.selected = (self.selected - 1) % len(self.ITEMS)
            elif event.key in (pygame.K_DOWN, pygame.K_s):
                self.selected = (self.selected + 1) % len(self.ITEMS)
            elif event.key in (pygame.K_RETURN, pygame.K_SPACE):
                self._buy_selected()
            elif event.key == pygame.K_ESCAPE:
                self.on_done()

        elif event.type == pygame.MOUSEMOTION:
            for i, rect in enumerate(self._rects()):
                if rect.collidepoint(event.pos):
                    self.selected = i

        elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            for i, rect in enumerate(self._rects()):
                if rect.collidepoint(event.pos):
                    self.selected = i
                    self._buy_selected()
                    break

    def update(self, dt):
        self.message_timer = max(0.0, self.message_timer - dt)

    def draw(self, screen):
        accent = THEMES["sim"]["accent"]
        screen.blit(get_background("sim"), (0, 0))

        draw_text(
            screen,
            "NEXUS SHOP",
            get_font(42, True),
            accent,
            (WIDTH // 2, 75),
            center=True,
        )

        draw_text(
            screen,
            f"AVAILABLE POINTS: {self.progression.points}",
            get_font(23, True),
            WHITE,
            (WIDTH // 2, 135),
            center=True,
        )

        for i, (item_id, name, description, cost) in enumerate(self.ITEMS):
            rect = self._rects()[i]
            selected = i == self.selected
            owned = item_id in self.progression.purchased_upgrades

            pygame.draw.rect(
                screen,
                accent if selected else GREY,
                rect,
                2 if selected else 1,
                border_radius=6,
            )

            status = "OWNED" if owned else f"{cost} PTS"

            draw_text(
                screen,
                name,
                get_font(21, selected),
                WHITE,
                (rect.x + 18, rect.y + 12),
            )

            draw_text(
                screen,
                description,
                get_font(15),
                GREY,
                (rect.x + 18, rect.y + 39),
            )

            draw_text(
                screen,
                status,
                get_font(17, True),
                accent if owned else WHITE,
                (rect.right - 18, rect.centery),
                center=True,
            )

        if self.message_timer > 0:
            draw_text(
                screen,
                self.message,
                get_font(19, True),
                accent,
                (WIDTH // 2, HEIGHT - 65),
                center=True,
            )

        draw_text(
            screen,
            "UP/DOWN: SELECT  |  ENTER: BUY  |  ESC: EXIT",
            get_font(14),
            GREY,
            (WIDTH // 2, HEIGHT - 25),
            center=True,
        )

        draw_scanlines(screen)
