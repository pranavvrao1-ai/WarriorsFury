import pygame

from game.scenes.base import Scene
from game.settings import WIDTH, HEIGHT, THEMES, WHITE, GREY
from game.ui.effects import get_background, draw_scanlines
from game.ui.text import get_font, draw_text
from game.audio import audio


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
        ok, message = self.progression.purchase(item_id)
        self.message = message
        self.message_timer = 2.5
        audio.play_sfx("flash" if ok else "hit")

    def handle_event(self, event):
        if event.type == pygame.KEYDOWN:
            if event.key in (pygame.K_UP, pygame.K_w):
                self.selected = (self.selected - 1) % len(self.ITEMS)
                audio.play_sfx("click")
            elif event.key in (pygame.K_DOWN, pygame.K_s):
                self.selected = (self.selected + 1) % len(self.ITEMS)
                audio.play_sfx("click")
            elif event.key in (pygame.K_RETURN, pygame.K_SPACE):
                self._buy_selected()
            elif event.key == pygame.K_ESCAPE:
                audio.play_sfx("click")
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
            get_font(20),
            WHITE,
            (WIDTH // 2, 125),
            center=True,
        )

        if self.message_timer > 0:
            draw_text(
                screen,
                self.message,
                get_font(18, True),
                accent,
                (WIDTH // 2, 165),
                center=True,
            )

        for i, (item_id, name, desc, cost) in enumerate(self.ITEMS):
            rect = self._rects()[i]
            selected = i == self.selected
            owned = False

            if item_id == "shield":
                owned = self.progression.shield_capacity > 0
            elif item_id == "armor":
                owned = self.progression.armor_owned
            elif item_id == "overclock":
                owned = self.progression.overclock_owned

            pygame.draw.rect(
                screen,
                accent if selected else (40, 50, 70),
                rect,
                2 if selected else 1,
                border_radius=8,
            )

            if selected:
                glow = pygame.Surface((rect.width, rect.height), pygame.SRCALPHA)
                pygame.draw.rect(glow, (*accent, 25), glow.get_rect(), border_radius=8)
                screen.blit(glow, rect.topleft)

            draw_text(
                screen,
                f"{name} (OWNED)" if owned else name,
                get_font(20, True),
                WHITE,
                (rect.x + 20, rect.y + 12),
            )

            draw_text(
                screen,
                desc,
                get_font(15),
                GREY,
                (rect.x + 20, rect.y + 36),
            )

            draw_text(
                screen,
                f"{cost} POINTS",
                get_font(18, True),
                accent,
                (rect.right - 130, rect.centery),
                center=True,
            )

        draw_text(
            screen,
            "PRESS ESC TO RETURN",
            get_font(15),
            GREY,
            (WIDTH // 2, HEIGHT - 35),
            center=True,
        )

        draw_scanlines(screen)
