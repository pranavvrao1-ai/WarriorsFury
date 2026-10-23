import math
import random

import pygame

from game.entities.projectile import Projectile

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

    @property
    def alive(self):
        return self.hp > 0

    def hit(self, damage):
        self.hp -= damage
        self.flash = 0.08

    def _toward(self, target):
        d = target - self.pos
        return d.normalize() if d.length_squared() > 1 else pygame.Vector2()

    def update(self, dt, target):
        """Moves, and returns a list of projectiles fired this frame."""
        shots = []
        self.flash = max(0.0, self.flash - dt)
        dist = self.pos.distance_to(target)
        direction = self._toward(target)

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
                for spread in (-0.25, 0, 0.25):
                    v = direction.rotate_rad(spread) * 320
                    shots.append(Projectile(self.pos, v, 10, False, 7, (255, 90, 220)))
            if self.burst_t <= 0:  # radial burst
                self.burst_t = 2.6 if phase2 else 3.4
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
        color = (255, 255, 255) if self.flash > 0 else self.color
        pygame.draw.circle(screen, color, self.pos, self.radius)
        pygame.draw.circle(screen, (30, 0, 20), self.pos, self.radius, 3)
        if self.kind != "grunt" and self.kind != "boss":
            w = 30
            r = pygame.Rect(self.pos.x - w / 2, self.pos.y - self.radius - 10, w, 4)
            pygame.draw.rect(screen, (60, 0, 0), r)
            r.width = int(w * max(self.hp, 0) / self.max_hp)
            pygame.draw.rect(screen, (0, 255, 120), r)
