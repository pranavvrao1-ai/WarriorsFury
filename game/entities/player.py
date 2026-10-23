import pygame

from game.entities.projectile import Projectile
from game.settings import WIDTH, HEIGHT


class Player:
    def __init__(self, x, y):
        self.pos = pygame.Vector2(x, y)
        self.radius = 14
        self.max_hp = 100
        self.hp = self.max_hp
        self.speed = 270
        self.shoot_cd = 0.0
        self.invuln = 0.0
        self.dash_t = 0.0
        self.dash_cd = 0.0
        self.dash_dir = pygame.Vector2(1, 0)
        self.aim = pygame.Vector2(1, 0)

    @property
    def alive(self):
        return self.hp > 0

    def update(self, dt, keys, mouse_pos):
        move = pygame.Vector2(
            int(keys[pygame.K_d] or keys[pygame.K_RIGHT]) - int(keys[pygame.K_a] or keys[pygame.K_LEFT]),
            int(keys[pygame.K_s] or keys[pygame.K_DOWN]) - int(keys[pygame.K_w] or keys[pygame.K_UP]),
        )
        if move.length_squared() > 0:
            move = move.normalize()
        if keys[pygame.K_LSHIFT] and self.dash_cd <= 0 and move.length_squared() > 0:
            self.dash_t, self.dash_cd = 0.15, 0.8
            self.dash_dir = move
            self.invuln = max(self.invuln, 0.2)
        if self.dash_t > 0:
            self.pos += self.dash_dir * 700 * dt
        else:
            self.pos += move * self.speed * dt
        self.pos.x = max(self.radius, min(WIDTH - self.radius, self.pos.x))
        self.pos.y = max(self.radius, min(HEIGHT - self.radius, self.pos.y))

        self.shoot_cd = max(0.0, self.shoot_cd - dt)
        self.invuln = max(0.0, self.invuln - dt)
        self.dash_t = max(0.0, self.dash_t - dt)
        self.dash_cd = max(0.0, self.dash_cd - dt)

        aim = pygame.Vector2(mouse_pos) - self.pos
        if aim.length_squared() > 1:
            self.aim = aim.normalize()

    def try_shoot(self, mouse_pos):
        if self.shoot_cd > 0:
            return None
        self.shoot_cd = 0.18
        return Projectile(self.pos + self.aim * 20, self.aim * 640, 15, True, 5, (0, 255, 255))

    def hit(self, damage):
        if self.invuln > 0:
            return False
        self.hp = max(0, self.hp - damage)
        self.invuln = 0.5
        return True

    def draw(self, screen):
        blink = self.invuln > 0 and int(self.invuln * 20) % 2 == 0
        color = (255, 255, 255) if blink else (0, 220, 255)
        pygame.draw.circle(screen, color, self.pos, self.radius)
        pygame.draw.circle(screen, (0, 80, 120), self.pos, self.radius, 2)
        pygame.draw.line(screen, (255, 255, 255), self.pos, self.pos + self.aim * 24, 3)
