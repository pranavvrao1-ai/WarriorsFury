import pygame

from game.settings import WIDTH, HEIGHT


class Projectile:
    def __init__(self, pos, vel, damage, friendly, radius=5, color=(255, 255, 255)):
        self.pos = pygame.Vector2(pos)
        self.vel = pygame.Vector2(vel)
        self.damage = damage
        self.friendly = friendly
        self.radius = radius
        self.color = color
        self.alive = True

    def update(self, dt):
        self.pos += self.vel * dt
        m = 30
        if not (-m < self.pos.x < WIDTH + m and -m < self.pos.y < HEIGHT + m):
            self.alive = False

    def draw(self, screen):
        pygame.draw.circle(screen, self.color, self.pos, self.radius)
