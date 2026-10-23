import math

import pygame

from game.scenes.base import Scene
from game.settings import WIDTH, HEIGHT, THEMES, SPEAKER_COLORS, WHITE, GREY
from game.ui.effects import get_background, draw_scanlines, apply_glitch, draw_flash
from game.ui.system_window import draw_system_window, draw_button, draw_panel, layout
from game.ui.text import get_font, wrap_text, draw_text

WINDOW_CENTER = (WIDTH // 2, 290)
CHOICE_EXTRA = 70


class StoryScene(Scene):
    """Plays a list of story lines (see game/data/story.py)."""

    CPS = 55  # typewriter characters per second

    def __init__(self, game, lines, theme="sim", on_done=None):
        super().__init__(game)
        self.lines = lines
        self.theme = theme
        self.on_done = on_done
        self.i = -1
        self.current = None
        self.chars = 0.0
        self.open_t = 0.0
        self.wait = 0.0
        self.flash = 0.0
        self.glitch = 0.0
        self.overlay = None
        self.caption = None  # (text, time_left)
        self.choice = None
        self.sel = 0
        self.auto_t = 0.0
        self.cursor = pygame.Vector2(WIDTH - 60, 40)
        self.t = 0.0
        self.finished = False
        self._next()

    # ---------- flow ----------
    def _next(self):
        while True:
            self.i += 1
            if self.i >= len(self.lines):
                self._finish()
                return
            line = self.lines[self.i]
            kind = line["kind"]
            self.open_t = 0.0
            if kind == "fx":
                self._apply_fx(line)
                continue
            if kind == "wait":
                self.wait = line["sec"]
                self.current = None
                return
            if kind == "choice":
                self.current = None
                self.choice = line
                self.sel = 0
                self.auto_t = 0.0
                self.cursor = pygame.Vector2(WIDTH - 60, 40)
                return
            self.current = line
            self.chars = float(len(line["text"])) if kind == "system" else 0.0
            return

    def _apply_fx(self, line):
        name, value = line["name"], line["value"]
        if name == "flash":
            self.flash = 1.0
        elif name == "glitch":
            self.glitch = value if value else 0.6
        elif name == "overlay":
            self.overlay = value
        elif name == "sound":
            self.caption = (value, 3.0)

    def _finish(self):
        if self.finished:
            return
        self.finished = True
        if self.on_done:
            self.on_done()
        else:
            self.game.to_title()

    def _full_text(self):
        return self.current["text"] if self.current else ""

    def _confirm_choice(self):
        self.choice = None
        self._next()

    # ---------- choice layout ----------
    def _choice_rects(self):
        _, rect = layout(self.choice["prompt"], 700, CHOICE_EXTRA, WINDOW_CENTER)
        opts = self.choice["options"]
        bw, bh, gap = 200, 44, 24
        total = len(opts) * bw + (len(opts) - 1) * gap
        x0 = rect.centerx - total // 2
        y = rect.bottom - 22 - bh
        return [pygame.Rect(x0 + i * (bw + gap), y, bw, bh) for i in range(len(opts))]

    # ---------- input ----------
    def handle_event(self, event):
        if event.type == pygame.KEYDOWN and event.key == pygame.K_ESCAPE:
            self.finished = True
            self.game.to_title()
            return
        if self.choice:
            if self.choice["auto"] or self.open_t < 0.3:
                return
            if event.type == pygame.KEYDOWN:
                if event.key in (pygame.K_LEFT, pygame.K_UP, pygame.K_a, pygame.K_w):
                    self.sel = (self.sel - 1) % len(self.choice["options"])
                elif event.key in (pygame.K_RIGHT, pygame.K_DOWN, pygame.K_d, pygame.K_s):
                    self.sel = (self.sel + 1) % len(self.choice["options"])
                elif event.key in (pygame.K_RETURN, pygame.K_SPACE):
                    self._confirm_choice()
            elif event.type == pygame.MOUSEMOTION:
                for i, r in enumerate(self._choice_rects()):
                    if r.collidepoint(event.pos):
                        self.sel = i
            elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
                for i, r in enumerate(self._choice_rects()):
                    if r.collidepoint(event.pos):
                        self.sel = i
                        self._confirm_choice()
            return

        advance = (event.type == pygame.KEYDOWN and event.key in (pygame.K_SPACE, pygame.K_RETURN)) or (
            event.type == pygame.MOUSEBUTTONDOWN and event.button == 1
        )
        if advance and self.current:
            if self.current["kind"] == "system":
                if self.open_t > 0.3:
                    self._next()
            elif self.chars < len(self._full_text()):
                self.chars = len(self._full_text())  # finish typing instantly
            else:
                self._next()

    # ---------- update ----------
    def update(self, dt):
        self.t += dt
        self.open_t += dt
        self.flash = max(0.0, self.flash - dt * 1.2)
        self.glitch = max(0.0, self.glitch - dt)
        if self.caption:
            text, left = self.caption
            left -= dt
            self.caption = (text, left) if left > 0 else None
        if self.current and self.chars < len(self._full_text()):
            self.chars += self.CPS * dt
        if self.wait > 0:
            self.wait -= dt
            if self.wait <= 0:
                self._next()
        if self.choice and self.choice["auto"]:
            self.auto_t += dt
            target = pygame.Vector2(self._choice_rects()[0].center)
            k = min(self.auto_t / 2.5, 1.0)
            k = k * k * (3 - 2 * k)  # smoothstep
            self.cursor = pygame.Vector2(WIDTH - 60, 40).lerp(target, k)
            if self.auto_t > 3.0:
                self._confirm_choice()

    # ---------- draw ----------
    def draw(self, screen):
        accent = THEMES[self.theme]["accent"]
        screen.blit(get_background(self.theme), (0, 0))
        self._draw_overlay(screen, accent)

        if self.caption:
            text, left = self.caption
            draw_text(screen, text, get_font(18), GREY, (WIDTH // 2, 40), center=True, alpha=int(255 * min(left, 1)))

        if self.current:
            if self.current["kind"] == "system":
                p = min(self.open_t / 0.3, 1.0)
                draw_system_window(screen, self.current["text"], self.current.get("title", "ALARM"),
                                   WINDOW_CENTER, 700, p)
            else:
                self._draw_textbox(screen, accent)
        if self.choice:
            self._draw_choice(screen)

        if self.glitch > 0:
            apply_glitch(screen, int(6 + 20 * self.glitch))
        draw_scanlines(screen)
        draw_flash(screen, self.flash)

    def _draw_textbox(self, screen, accent):
        line = self.current
        box = pygame.Rect(40, HEIGHT - 190, WIDTH - 80, 160)
        screen.blit(draw_panel(box.w, box.h, 232), box.topleft)

        y = box.y + 20
        if line["kind"] == "say":
            color = SPEAKER_COLORS.get(line["who"], WHITE)
            draw_text(screen, line["who"], get_font(22, True), color, (box.x + 28, y))
            y += 34
        font = get_font(22)
        remaining = int(self.chars)
        for row in wrap_text(line["text"], font, box.width - 56):
            if remaining <= 0:
                break
            draw_text(screen, row[:remaining], font, WHITE, (box.x + 28, y))
            remaining -= len(row) + 1
            y += 30
        if self.chars >= len(line["text"]) and int(self.t * 2) % 2 == 0:
            draw_text(screen, "v", get_font(20, True), WHITE, (box.right - 36, box.bottom - 36))

    def _draw_choice(self, screen):
        p = min(self.open_t / 0.3, 1.0)
        draw_system_window(screen, self.choice["prompt"], "ALARM", WINDOW_CENTER, 700, p, extra_h=CHOICE_EXTRA)
        if p >= 1.0:
            for i, (opt, r) in enumerate(zip(self.choice["options"], self._choice_rects())):
                draw_button(screen, r, opt, hot=(i == self.sel or self.choice["auto"]))
        if self.choice["auto"] and p >= 1.0:
            c = self.cursor
            pygame.draw.polygon(screen, WHITE, [c, c + (0, 22), c + (6, 17), c + (11, 27), c + (15, 25), c + (10, 15), c + (17, 15)])
            pygame.draw.polygon(screen, (0, 0, 0), [c, c + (0, 22), c + (6, 17), c + (11, 27), c + (15, 25), c + (10, 15), c + (17, 15)], 1)

    def _draw_overlay(self, screen, accent):
        o = self.overlay
        if o in ("receipt", "receipt_back"):
            paper = pygame.Rect(WIDTH // 2 - 160, 40, 320, 300)
            pygame.draw.rect(screen, (232, 226, 205), paper)
            pygame.draw.rect(screen, (150, 140, 110), paper, 3)
            f = get_font(16, True)
            if o == "receipt":
                rows = [("AFTERLIFE GAMING LOUNGE", 70), ("ENTRY: 11:47 PM", 120), ("STATION: 07", 150),
                        ("PLAYER 07 -", 240), ("SESSION STATUS: INCOMPLETE", 265)]
                for text, y in rows:
                    draw_text(screen, text, f, (40, 35, 30), (paper.centerx, paper.y + y - 40), center=True)
            else:
                draw_text(screen, "YOU WOKE UP", get_font(30, True), (170, 20, 30), (paper.centerx, paper.centery - 20), center=True)
                draw_text(screen, "TOO EARLY.", get_font(30, True), (170, 20, 30), (paper.centerx, paper.centery + 20), center=True)
        elif o == "eyes":
            pulse = 0.6 + 0.4 * math.sin(self.t * 4)
            for ex in (WIDTH // 2 - 60, WIDTH // 2 + 60):
                for r, a in ((46, 25), (32, 50), (20, 110)):
                    glow = pygame.Surface((r * 2, r * 2), pygame.SRCALPHA)
                    pygame.draw.circle(glow, (40, 140, 255, int(a * pulse)), (r, r), r)
                    screen.blit(glow, (ex - r, 190 - r))
                pygame.draw.circle(screen, (180, 230, 255), (ex, 190), 9)
        elif o == "monitor":
            m = pygame.Rect(WIDTH // 2 - 150, 22, 300, 140)
            pygame.draw.rect(screen, (10, 18, 40), m, border_radius=6)
            pygame.draw.rect(screen, accent, m, 3, border_radius=6)
            draw_text(screen, "WARRIOR'S FURY", get_font(22, True), accent, (m.centerx, m.centery - 12), center=True)
            draw_text(screen, "SESSION 002", get_font(18), WHITE, (m.centerx, m.centery + 16), center=True)
            pygame.draw.rect(screen, (30, 30, 40), (WIDTH // 2 - 40, 168, 80, 12))
