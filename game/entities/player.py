import math
import pygame

from game.entities.projectile import Projectile
from game.settings import WIDTH, HEIGHT
from game.entities.progression import PlayerProgression
from game.audio import audio


class Player:
    def __init__(self, x, y, progression=None):
        self.pos = pygame.Vector2(x, y)
        self.radius = 16

        self.progression = progression or PlayerProgression()
        self.level = self.progression.level
        self.max_hp = self.progression.max_hp

        # Keep the same health when a new combat scene starts.
        if not hasattr(self.progression, "hp"):
            self.progression.hp = self.max_hp

        self.hp = min(self.progression.hp, self.max_hp)
        self.attack = self.progression.attack
        self.speed = self.progression.speed
        self.shoot_cooldown = self.progression.shoot_cooldown

        self.shield_hp = self.progression.shield_capacity

        self.shoot_cd = 0.0
        self.invuln = 0.0
        self.dash_t = 0.0
        self.dash_cd = 0.0
        self.dash_dir = pygame.Vector2(1, 0)
        self.aim = pygame.Vector2(1, 0)
        self.t = 0.0
        self.trail = []

    @property
    def alive(self):
        return self.hp > 0

    def sync_progression(self):
        """Synchronize permanent upgrades and current health."""
        old_max_hp = self.max_hp

        self.level = self.progression.level
        self.max_hp = self.progression.max_hp
        self.hp = min(
            self.max_hp,
            self.hp + self.max_hp - old_max_hp,
        )
        self.attack = self.progression.attack
        self.speed = self.progression.speed
        self.shoot_cooldown = self.progression.shoot_cooldown

        self.progression.hp = self.hp

    def update(self, dt, keys, mouse_pos):
        self.t += dt
        move = pygame.Vector2(
            int(keys[pygame.K_d] or keys[pygame.K_RIGHT])
            - int(keys[pygame.K_a] or keys[pygame.K_LEFT]),
            int(keys[pygame.K_s] or keys[pygame.K_DOWN])
            - int(keys[pygame.K_w] or keys[pygame.K_UP]),
        )

        if move.length_squared() > 0:
            move = move.normalize()
            audio.play_footstep(dt)

        if (
            keys[pygame.K_LSHIFT]
            and self.dash_cd <= 0
            and move.length_squared() > 0
        ):
            self.dash_t, self.dash_cd = 0.15, 0.8
            self.dash_dir = move
            self.invuln = max(self.invuln, 0.2)
            audio.play_sfx("dash")

        if self.dash_t > 0:
            self.pos += self.dash_dir * 700 * dt
            self.trail.append((pygame.Vector2(self.pos), 0.25))
        else:
            self.pos += move * self.speed * dt

        self.pos.x = max(
            self.radius, min(WIDTH - self.radius, self.pos.x)
        )
        self.pos.y = max(
            self.radius, min(HEIGHT - self.radius, self.pos.y)
        )

        self.shoot_cd = max(0.0, self.shoot_cd - dt)
        self.invuln = max(0.0, self.invuln - dt)
        self.dash_t = max(0.0, self.dash_t - dt)
        self.dash_cd = max(0.0, self.dash_cd - dt)

        # Decay dash trail
        new_trail = []
        for p, tl in self.trail:
            tl -= dt
            if tl > 0:
                new_trail.append((p, tl))
        self.trail = new_trail

        aim = pygame.Vector2(mouse_pos) - self.pos
        if aim.length_squared() > 1:
            self.aim = aim.normalize()

    def try_shoot(self, mouse_pos):
        if self.shoot_cd > 0:
            return None

        self.shoot_cd = self.shoot_cooldown
        audio.play_sfx("shoot_player")

        return Projectile(
            self.pos + self.aim * 20,
            self.aim * 640,
            self.attack,
            True,
            5,
            (0, 255, 255),
        )

    def hit(self, damage):
        if self.invuln > 0:
            return False

        damage = max(0, int(damage))

        if self.shield_hp > 0:
            absorbed = min(self.shield_hp, damage)
            self.shield_hp -= absorbed
            damage -= absorbed
            self.progression.shield_capacity = self.shield_hp

        if self.progression.armor_owned:
            damage = int(round(damage * 0.75))

        self.hp = max(0, self.hp - damage)
        self.progression.hp = self.hp
        self.invuln = 0.5
        audio.play_sfx("hit")
        return True

    def draw(self, screen):
        # Draw dash ghost trails
        for p, tl in self.trail:
            alpha = int(120 * (tl / 0.25))
            ghost = pygame.Surface((self.radius * 2 + 4, self.radius * 2 + 4), pygame.SRCALPHA)
            pygame.draw.circle(ghost, (0, 230, 255, alpha), (self.radius + 2, self.radius + 2), self.radius)
            screen.blit(ghost, (p.x - self.radius - 2, p.y - self.radius - 2))

        blink = (
            self.invuln > 0
            and int(self.invuln * 20) % 2 == 0
        )
        body_color = (255, 255, 255) if blink else (0, 220, 255)

        # Thruster jet glow (opposite to aim)
        thruster_pos = self.pos - self.aim * (self.radius + 4)
        flame_len = 6 + 4 * math.sin(self.t * 20)
        flame_tip = self.pos - self.aim * (self.radius + 4 + flame_len)
        pygame.draw.line(screen, (0, 255, 255), thruster_pos, flame_tip, 4)
        pygame.draw.circle(screen, (255, 255, 255), flame_tip, 2)

        # Outer energy shield aura if shield active
        if self.shield_hp > 0:
            shield_pulse = 0.85 + 0.15 * math.sin(self.t * 6)
            s_rad = int((self.radius + 6) * shield_pulse)
            shield_surf = pygame.Surface((s_rad * 2 + 6, s_rad * 2 + 6), pygame.SRCALPHA)
            pygame.draw.circle(shield_surf, (0, 200, 255, 80), (s_rad + 3, s_rad + 3), s_rad, 2)
            screen.blit(shield_surf, (self.pos.x - s_rad - 3, self.pos.y - s_rad - 3))

        # Main cybernetic chassis
        pygame.draw.circle(screen, body_color, self.pos, self.radius)
        pygame.draw.circle(
            screen, (0, 80, 140), self.pos, self.radius, 2
        )
        # Inner core
        pygame.draw.circle(screen, (10, 30, 60), self.pos, 7)
        pygame.draw.circle(screen, (255, 255, 255), self.pos, 3)

        # Aiming cannon barrel
        pygame.draw.line(
            screen,
            (255, 255, 255),
            self.pos,
            self.pos + self.aim * 24,
            3,
        )
        # Laser targeting pip
        laser_end = self.pos + self.aim * 55
        pygame.draw.line(screen, (0, 255, 255, 120), self.pos + self.aim * 24, laser_end, 1)
        pygame.draw.circle(screen, (0, 255, 255), laser_end, 2)
