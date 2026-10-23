import math
import os
from pathlib import Path
import pygame

from game.settings import BASE_DIR, ASSETS_DIR, SPEAKER_COLORS, WHITE, GREY
from game.ui.text import get_font, draw_text

PORTRAIT_SIZE = (110, 110)


class PortraitManager:
    """Renders high-tech cyberpunk character portrait badges with live waveform animations."""

    def __init__(self):
        self._cache = {}
        self._tex_dir = ASSETS_DIR / "textures"

    def get_portrait(self, speaker, act_theme="cafe", t=0.0):
        """Returns a stylized Surface for the character portrait."""
        key = (speaker, act_theme)
        base = self._cache.get(key)
        if base is None:
            base = self._render_base_portrait(speaker, act_theme)
            self._cache[key] = base

        # Copy to apply dynamic lighting/scanline effects
        surf = base.copy()
        w, h = surf.get_size()

        # Dynamic scanline sweep
        sweep_y = int((t * 60) % h)
        pygame.draw.line(surf, (255, 255, 255, 60), (4, sweep_y), (w - 4, sweep_y), 2)
        return surf

    def _render_base_portrait(self, speaker, act_theme):
        surf = pygame.Surface(PORTRAIT_SIZE, pygame.SRCALPHA)
        w, h = PORTRAIT_SIZE
        accent = SPEAKER_COLORS.get(speaker, (0, 230, 255))

        # Background badge base
        pygame.draw.rect(surf, (15, 18, 30, 230), (0, 0, w, h), border_radius=12)

        # Inner portrait region
        inner_rect = pygame.Rect(6, 6, w - 12, h - 12)
        pygame.draw.rect(surf, (8, 10, 18), inner_rect, border_radius=8)

        # Draw character face / graphic
        self._draw_character_graphics(surf, inner_rect, speaker, act_theme)

        # Glowing outer border
        pygame.draw.rect(surf, accent, (0, 0, w, h), 2, border_radius=12)
        # Corner tech notches
        for corner in [(2, 2), (w - 8, 2), (2, h - 8), (w - 8, h - 8)]:
            pygame.draw.rect(surf, accent, (*corner, 6, 6))

        return surf

    def _draw_character_graphics(self, surf, r, speaker, act_theme):
        cx, cy = r.centerx, r.centery
        sp = speaker.upper()

        if "NEXUS" in sp:
            # Malevolent AI Eye with rotating iris and circuit spikes
            pygame.draw.circle(surf, (20, 0, 5), (cx, cy), 36)
            for angle_deg in range(0, 360, 45):
                rad = math.radians(angle_deg)
                x1 = cx + math.cos(rad) * 22
                y1 = cy + math.sin(rad) * 22
                x2 = cx + math.cos(rad) * 34
                y2 = cy + math.sin(rad) * 34
                pygame.draw.line(surf, (255, 50, 70), (x1, y1), (x2, y2), 2)
            pygame.draw.circle(surf, (255, 40, 60), (cx, cy), 20)
            pygame.draw.circle(surf, (255, 180, 200), (cx, cy), 8)
            pygame.draw.circle(surf, (255, 255, 255), (cx - 3, cy - 3), 3)

        elif "UNKNOWN" in sp:
            # Mysterious hooded silhouette with glitch sunglasses / neon glow
            pygame.draw.circle(surf, (30, 15, 35), (cx, cy - 2), 26)  # Hood
            pygame.draw.polygon(surf, (20, 10, 25), [(cx - 28, r.bottom), (cx + 28, r.bottom), (cx, cy - 20)])
            # Dark visor / sunglasses
            pygame.draw.rect(surf, (255, 60, 180), (cx - 18, cy - 6, 36, 10), border_radius=3)
            pygame.draw.line(surf, (255, 220, 255), (cx - 16, cy - 2), (cx + 16, cy - 2), 2)

        elif "RECEPTIONIST" in sp:
            # Cyberpunk Receptionist with headset and amber glow
            pygame.draw.circle(surf, (50, 40, 30), (cx, cy - 4), 24)  # Hair
            pygame.draw.circle(surf, (216, 163, 148), (cx, cy - 2), 19)  # Face
            # Receptionist headset
            pygame.draw.arc(surf, (255, 200, 80), (cx - 24, cy - 26, 48, 48), 0.2, math.pi - 0.2, 3)
            pygame.draw.circle(surf, (255, 200, 80), (cx + 18, cy + 2), 5)
            pygame.draw.line(surf, (255, 200, 80), (cx + 18, cy + 2), (cx + 6, cy + 10), 2)

        elif "SHOPKEEPER" in sp:
            # Neighborhood Shopkeeper
            pygame.draw.circle(surf, (40, 45, 35), (cx, cy - 6), 25)
            pygame.draw.circle(surf, (180, 140, 110), (cx, cy - 2), 20)
            pygame.draw.rect(surf, (120, 160, 100), (cx - 22, cy + 12, 44, 26), border_radius=4)
            # Collar / apron
            pygame.draw.line(surf, (240, 240, 220), (cx - 10, cy + 12), (cx + 10, cy + 12), 2)

        else:
            # Protagonist / MC
            if act_theme == "sim":
                # Cybernetic Warrior Unit 07
                pygame.draw.circle(surf, (10, 35, 55), (cx, cy - 2), 26)  # Helmet
                pygame.draw.circle(surf, (0, 220, 255), (cx, cy - 2), 16)  # Visor
                pygame.draw.line(surf, (255, 255, 255), (cx - 12, cy - 2), (cx + 12, cy - 2), 2)
                # Cyber chestplate
                pygame.draw.polygon(surf, (0, 140, 180), [(cx - 24, r.bottom), (cx + 24, r.bottom), (cx, cy + 14)])
            else:
                # Ordinary gamer with headphones
                pygame.draw.circle(surf, (35, 30, 45), (cx, cy - 4), 24)  # Hair
                pygame.draw.circle(surf, (220, 175, 145), (cx, cy - 2), 18)  # Face
                # Gamer headphones
                pygame.draw.arc(surf, (0, 230, 255), (cx - 24, cy - 26, 48, 48), 0.2, math.pi - 0.2, 4)
                pygame.draw.rect(surf, (0, 180, 220), (cx - 24, cy - 8, 8, 16), border_radius=3)
                pygame.draw.rect(surf, (0, 180, 220), (cx + 16, cy - 8, 8, 16), border_radius=3)

    def draw_speaking_wave(self, screen, x, y, w, h, t, color, active=True):
        """Draws an audio-reactive waveform bar visualization."""
        n_bars = 9
        bar_w = 4
        gap = (w - n_bars * bar_w) // (n_bars - 1)
        for i in range(n_bars):
            if active:
                freq = 4.0 + i * 2.2
                val = 0.3 + 0.7 * abs(math.sin(t * freq + i * 0.8))
            else:
                val = 0.15
            bh = int(h * val)
            bx = x + i * (bar_w + gap)
            by = y + (h - bh) // 2
            pygame.draw.rect(screen, color, (bx, by, bar_w, bh), border_radius=2)


portraits = PortraitManager()
