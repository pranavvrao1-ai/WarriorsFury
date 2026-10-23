import random

import pygame

from game.data.stages import STAGES, AMBIENT
from game.entities.enemy import Enemy
from game.entities.player import Player
from game.scenes.base import Scene
from game.settings import WIDTH, HEIGHT, THEMES, WHITE, GREY, RED
from game.ui.effects import get_background, draw_scanlines, draw_flash
from game.ui.system_window import draw_system_window
from game.ui.text import get_font, draw_text


class CombatScene(Scene):
    def __init__(self, game, stage_index, on_done):
        super().__init__(game)
        self.stage_index = stage_index
        self.stage = STAGES[stage_index]
        self.on_done = on_done
        self.player = Player(WIDTH / 2, HEIGHT / 2)
        self.enemies = []
        self.bullets = []
        self.wave_index = -1
        self.wave_timer = 2.6
        self.banner_t = 2.5
        self.banner_total = 2.5
        self.banner_text = f"{{y:{self.stage['name']}}} {{c:{self.stage['subtitle']}}}"
        self.state = "fight"  # fight | won | dead
        self.win_t = 0.0
        self.flash = 0.0
        self.t = 0.0
        self.ambient_t = random.uniform(8, 14)
        self.caption = None
        self.done_called = False

    # ---------- helpers ----------
    def _spawn(self, kind):
        side = random.choice("tblr")
        if side == "t":
            x, y = random.randint(0, WIDTH), -20
        elif side == "b":
            x, y = random.randint(0, WIDTH), HEIGHT + 20
        elif side == "l":
            x, y = -20, random.randint(0, HEIGHT)
        else:
            x, y = WIDTH + 20, random.randint(0, HEIGHT)
        if kind == "boss":
            x, y = WIDTH / 2, 90
        self.enemies.append(Enemy(kind, x, y))

    def _spawn_wave(self):
        self.wave_index += 1
        for kind, count in self.stage["waves"][self.wave_index].items():
            for _ in range(count):
                self._spawn(kind)
        waves = self.stage["waves"]
        if "boss" in waves[self.wave_index]:
            self.banner_text = "{r:NEXUS} HAS ENTERED THE ARENA."
        else:
            self.banner_text = f"{{c:WAVE {self.wave_index + 1} OF {len(waves)}}}"
        self.banner_t = self.banner_total = 1.5

    def _finish(self):
        if not self.done_called:
            self.done_called = True
            self.on_done()

    def _restart(self):
        self.game.set_scene(CombatScene(self.game, self.stage_index, self.on_done))

    # ---------- input ----------
    def handle_event(self, event):
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_ESCAPE:
                self.game.to_title()
            elif self.state == "dead" and event.key in (pygame.K_r, pygame.K_RETURN):
                self._restart()

    # ---------- update ----------
    def update(self, dt):
        self.t += dt
        self.flash = max(0.0, self.flash - dt * 1.2)
        self.banner_t = max(0.0, self.banner_t - dt)
        self._update_ambient(dt)

        if self.state == "dead":
            return
        if self.state == "won":
            self.win_t -= dt
            if self.win_t <= 0:
                self._finish()
            return

        keys = pygame.key.get_pressed()
        mouse = pygame.mouse.get_pressed()
        mpos = pygame.mouse.get_pos()
        self.player.update(dt, keys, mpos)
        if mouse[0] or keys[pygame.K_SPACE]:
            bullet = self.player.try_shoot(mpos)
            if bullet:
                self.bullets.append(bullet)

        for e in self.enemies:
            self.bullets.extend(e.update(dt, self.player.pos))
            if e.spawn_request:
                for _ in range(e.spawn_request):
                    self.enemies.append(Enemy("grunt", e.pos.x + random.randint(-60, 60), e.pos.y + 40))
                e.spawn_request = 0
        for b in self.bullets:
            b.update(dt)

        self._collisions()
        self.enemies = [e for e in self.enemies if e.alive]
        self.bullets = [b for b in self.bullets if b.alive]

        if not self.player.alive:
            self.state = "dead"
            return
        self._update_waves(dt)

    def _collisions(self):
        for b in self.bullets:
            if not b.alive:
                continue
            if b.friendly:
                for e in self.enemies:
                    if e.pos.distance_to(b.pos) < e.radius + b.radius:
                        e.hit(b.damage)
                        b.alive = False
                        break
            elif self.player.pos.distance_to(b.pos) < self.player.radius + b.radius:
                self.player.hit(b.damage)
                b.alive = False
        for e in self.enemies:
            if e.pos.distance_to(self.player.pos) < e.radius + self.player.radius:
                self.player.hit(e.contact)

    def _update_waves(self, dt):
        boss_dead = any(w.get("boss") for w in self.stage["waves"]) and self.wave_index >= 0 and not any(
            e.kind == "boss" for e in self.enemies
        )
        if boss_dead:
            self.enemies.clear()
            self.bullets.clear()
        if self.enemies:
            return
        if self.wave_index + 1 < len(self.stage["waves"]):
            self.wave_timer -= dt
            if self.wave_timer <= 0:
                self._spawn_wave()
                self.wave_timer = 1.5
        elif self.wave_index >= 0:
            self.state = "won"
            self.win_t = 1.8
            self.flash = 1.0

    def _update_ambient(self, dt):
        self.ambient_t -= dt
        if self.ambient_t <= 0:
            self.ambient_t = random.uniform(10, 18)
            self.caption = [random.choice(AMBIENT), 3.0]
        if self.caption:
            self.caption[1] -= dt
            if self.caption[1] <= 0:
                self.caption = None

    # ---------- draw ----------
    def draw(self, screen):
        accent = THEMES["sim"]["accent"]
        screen.blit(get_background("sim"), (0, 0))
        for x in range(0, WIDTH, 60):
            pygame.draw.line(screen, (0, 60, 80), (x, 0), (x, HEIGHT))
        for y in range(0, HEIGHT, 60):
            pygame.draw.line(screen, (0, 60, 80), (0, y), (WIDTH, y))

        for b in self.bullets:
            b.draw(screen)
        for e in self.enemies:
            e.draw(screen)
        if self.player.alive:
            self.player.draw(screen)
        self._draw_hud(screen, accent)

        if self.caption:
            text, left = self.caption
            draw_text(screen, text, get_font(18), GREY, (WIDTH // 2, HEIGHT - 24), center=True, alpha=int(180 * min(left, 1)))
        if self.banner_t > 0 and self.state == "fight":
            elapsed = self.banner_total - self.banner_t
            p = min(elapsed / 0.25, self.banner_t / 0.4, 1.0)
            draw_system_window(screen, self.banner_text, "NEXUS", (WIDTH // 2, HEIGHT // 2 - 70), progress=p)
        if self.state == "won":
            draw_system_window(screen, "STAGE {y:CLEARED}", "NEXUS", (WIDTH // 2, HEIGHT // 2 - 40))
        if self.state == "dead":
            veil = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
            veil.fill((0, 0, 0, 170))
            screen.blit(veil, (0, 0))
            draw_system_window(screen, "SIMULATION {r:FAILED}. PRESS {y:R} TO {g:RETRY}.", "WARNING", (WIDTH // 2, HEIGHT // 2))
        draw_scanlines(screen)
        draw_flash(screen, self.flash)

    def _draw_hud(self, screen, accent):
        bar = pygame.Rect(20, 20, 240, 18)
        pygame.draw.rect(screen, (50, 10, 20), bar, border_radius=4)
        fill = bar.copy()
        fill.width = int(bar.width * self.player.hp / self.player.max_hp)
        pygame.draw.rect(screen, (0, 230, 140), fill, border_radius=4)
        pygame.draw.rect(screen, WHITE, bar, 2, border_radius=4)
        draw_text(screen, f"UNIT 07   {self.stage['name']}", get_font(14), WHITE, (20, 44))
        boss = next((e for e in self.enemies if e.kind == "boss"), None)
        if boss:
            b = pygame.Rect(WIDTH // 2 - 250, HEIGHT - 60, 500, 16)
            pygame.draw.rect(screen, (60, 0, 40), b)
            pygame.draw.rect(screen, (255, 40, 200), (b.x, b.y, int(b.width * max(boss.hp, 0) / boss.max_hp), b.height))
            pygame.draw.rect(screen, WHITE, b, 2)
            draw_text(screen, "NEXUS", get_font(14, True), WHITE, (b.centerx, b.y - 14), center=True)
