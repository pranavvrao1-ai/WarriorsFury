import math
import random
import pygame

from game.entities.projectile import Projectile
from game.audio import audio

KINDS = {
    "grunt": dict(hp=30, speed=115, radius=14, color=(255, 80, 80), contact=10),
    "shooter": dict(hp=45, speed=70, radius=15, color=(255, 170, 40), contact=8),
    "boss": dict(hp=650, speed=45, radius=44, color=(255, 40, 200), contact=20),
}


class Enemy:
    def __init__(self, kind, x, y):
        cfg = KINDS[kind]
        self.kind = kind
        self.pos = pygame.Vector2(x, y)
        self.max_hp = self.hp = cfg["hp"]
        self.speed = cfg["speed"]
        self.radius = cfg["radius"]
        self.color = cfg["color"]
        self.contact = cfg["contact"]
        self.fire_t = random.uniform(0.5, 1.5)
        self.burst_t = 2.0
        self.spawn_t = 6.0
        self.spawn_request = 0
        self.flash = 0.0
        self.t = random.uniform(0, 10)
        self.aim = pygame.Vector2(0, 1)

    @property
    def alive(self):
        return self.hp > 0

    def hit(self, damage):
        self.hp -= damage
        self.flash = 0.08
        if self.hp <= 0:
            audio.play_sfx("explosion")
        else:
            audio.play_sfx("hit")

    def _toward(self, target):
        d = target - self.pos
        return d.normalize() if d.length_squared() > 1 else pygame.Vector2()

    def update(self, dt, target):
        """Moves, and returns a list of projectiles fired this frame."""
        shots = []
        self.t += dt
        self.flash = max(0.0, self.flash - dt)
        dist = self.pos.distance_to(target)
        direction = self._toward(target)
        if direction.length_squared() > 0:
            self.aim = direction

        if self.kind == "grunt":
            self.pos += direction * self.speed * dt

        elif self.kind == "shooter":
            if dist > 260:
                self.pos += direction * self.speed * dt
            elif dist < 180:
                self.pos -= direction * self.speed * dt
            self.fire_t -= dt
            if self.fire_t <= 0:
                self.fire_t = 1.6
                audio.play_sfx("shoot_enemy")
                shots.append(Projectile(self.pos, direction * 290, 8, False, 6, (255, 200, 60)))

        elif self.kind == "boss":
            phase2 = self.hp < self.max_hp / 2
            if dist > 220:
                self.pos += direction * self.speed * dt
            self.fire_t -= dt
            self.burst_t -= dt
            self.spawn_t -= dt
            if self.fire_t <= 0:  # aimed triple shot
                self.fire_t = 1.3 if phase2 else 1.8
                audio.play_sfx("shoot_boss")
                for spread in (-0.25, 0, 0.25):
                    v = direction.rotate_rad(spread) * 320
                    shots.append(Projectile(self.pos, v, 10, False, 7, (255, 90, 220)))
            if self.burst_t <= 0:  # radial burst
                self.burst_t = 2.6 if phase2 else 3.4
                audio.play_sfx("shoot_boss")
                n = 24 if phase2 else 16
                for i in range(n):
                    a = 2 * math.pi * i / n
                    v = pygame.Vector2(math.cos(a), math.sin(a)) * 210
                    shots.append(Projectile(self.pos, v, 8, False, 6, (255, 60, 90)))
            if phase2 and self.spawn_t <= 0:
                self.spawn_t = 7.0
                self.spawn_request = 3
        return shots

    def draw(self, screen):
        cx, cy = int(self.pos.x), int(self.pos.y)
        r = self.radius
        color = (255, 255, 255) if self.flash > 0 else self.color

        if self.kind == "boss":
            # NEXUS Boss Core: rotating mechanical shield pylons & pulsating red core
            phase2 = self.hp < self.max_hp / 2
            core_pulse = 0.85 + 0.15 * math.sin(self.t * (8 if phase2 else 4))
            c_rad = int(r * core_pulse)

            # Orbiting energy arcs
            arc_surf = pygame.Surface((r * 3, r * 3), pygame.SRCALPHA)
            n_segments = 6
            for i in range(n_segments):
                angle = self.t * 2.0 + (i * 2 * math.pi / n_segments)
                ax = r * 1.5 + math.cos(angle) * (r + 10)
                ay = r * 1.5 + math.sin(angle) * (r + 10)
                pygame.draw.circle(arc_surf, (255, 60, 180, 150), (int(ax), int(ay)), 5)
            screen.blit(arc_surf, (cx - r * 1.5, cy - r * 1.5))

            # Base chassis
            pygame.draw.circle(screen, (30, 5, 20), (cx, cy), r + 4)
            pygame.draw.circle(screen, color, (cx, cy), c_rad)
            pygame.draw.circle(screen, (80, 10, 40), (cx, cy), c_rad, 3)

            # Central AI iris
            pygame.draw.circle(screen, (255, 0, 50) if phase2 else (255, 80, 120), (cx, cy), 14)
            pygame.draw.circle(screen, (255, 255, 255), (cx, cy), 6)

            # Health bar above boss
            bw, bh = 200, 8
            bar_rect = pygame.Rect(cx - bw // 2, cy - r - 22, bw, bh)
            pygame.draw.rect(screen, (40, 10, 20), bar_rect, border_radius=3)
            fill_w = int(bw * max(0, self.hp) / self.max_hp)
            pygame.draw.rect(screen, (255, 40, 100), (bar_rect.x, bar_rect.y, fill_w, bh), border_radius=3)
            pygame.draw.rect(screen, (255, 100, 150), bar_rect, 1, border_radius=3)

        elif self.kind == "shooter":
            # Police Robot Unit
            pygame.draw.circle(screen, (20, 25, 35), (cx, cy), r + 2)
            pygame.draw.circle(screen, color, (cx, cy), r)
            # Flashing siren beacon (red / blue alternate)
            siren_color = (255, 40, 40) if int(self.t * 8) % 2 == 0 else (40, 140, 255)
            pygame.draw.circle(screen, siren_color, (cx, cy), 6)

            # Weapon barrel aiming at player
            barrel_end = self.pos + self.aim * (r + 8)
            pygame.draw.line(screen, (255, 220, 100), (cx, cy), (int(barrel_end.x), int(barrel_end.y)), 3)

            # HP bar
            w = 30
            hp_rect = pygame.Rect(cx - w // 2, cy - r - 10, w, 4)
            pygame.draw.rect(screen, (60, 0, 0), hp_rect)
            hp_rect.width = int(w * max(self.hp, 0) / self.max_hp)
            pygame.draw.rect(screen, (255, 180, 0), hp_rect)

        else:
            # Grunt drone: sharp angular patrol drone
            pygame.draw.circle(screen, color, (cx, cy), r)
            pygame.draw.circle(screen, (40, 0, 10), (cx, cy), r, 2)
            # Glowing optic eye
            eye_pos = self.pos + self.aim * (r // 2)
            pygame.draw.circle(screen, (255, 255, 255), (int(eye_pos.x), int(eye_pos.y)), 3)
