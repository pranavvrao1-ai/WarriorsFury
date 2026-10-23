import math
import os
from pathlib import Path
import pygame

from game.settings import BASE_DIR, ASSETS_DIR, SPEAKER_COLORS, WHITE, GREY
from game.ui.text import get_font, draw_text

PORTRAIT_SIZE = (120, 120)


class PortraitManager:
    """Renders authentic character portraits from the uploaded 3D assets with holographic tech frames."""

    def __init__(self):
        self._cache = {}
        self._portraits_dir = ASSETS_DIR / "portraits"

    def get_portrait(self, speaker, act_theme="cafe", t=0.0):
        """Returns a styled Surface for the character portrait."""
        key = (speaker, act_theme)
        base = self._cache.get(key)
        if base is None:
            base = self._render_base_portrait(speaker, act_theme)
            self._cache[key] = base

        surf = base.copy()
        w, h = surf.get_size()

        # Dynamic scanline sweep
        sweep_y = int((t * 50) % h)
        pygame.draw.line(surf, (255, 255, 255, 75), (4, sweep_y), (w - 4, sweep_y), 2)
        return surf

    def _render_base_portrait(self, speaker, act_theme):
        surf = pygame.Surface(PORTRAIT_SIZE, pygame.SRCALPHA)
        w, h = PORTRAIT_SIZE
        accent = SPEAKER_COLORS.get(speaker, (0, 230, 255))

        # Cybernetic background panel
        pygame.draw.rect(surf, (12, 16, 26, 240), (0, 0, w, h), border_radius=12)

        inner_rect = pygame.Rect(6, 6, w - 12, h - 12)
        pygame.draw.rect(surf, (6, 8, 14), inner_rect, border_radius=8)

        # Map speaker to uploaded character portrait file
        sp = speaker.upper()
        file_map = {
            "MC": "mc.png",
            "UNKNOWN PLAYER": "unknown.png",
            "UNKNOWN": "unknown.png",
            "RECEPTIONIST": "receptionist.png",
            "SHOPKEEPER": "shopkeeper.png",
            "NEXUS": "nexus.png",
        }
        portrait_file = self._portraits_dir / file_map.get(sp, "mc.png")

        if portrait_file.exists():
            try:
                raw_img = pygame.image.load(str(portrait_file))
                scaled = pygame.transform.smoothscale(raw_img, (inner_rect.w, inner_rect.h))
                surf.blit(scaled, inner_rect.topleft)
            except Exception as e:
                print(f"[Portrait] Error loading {portrait_file}: {e}")
                self._draw_fallback_graphics(surf, inner_rect, speaker, act_theme)
        else:
            self._draw_fallback_graphics(surf, inner_rect, speaker, act_theme)

        # Tech border and glowing accents
        pygame.draw.rect(surf, accent, (0, 0, w, h), 2, border_radius=12)
        # Corner brackets
        for c in [(2, 2), (w - 8, 2), (2, h - 8), (w - 8, h - 8)]:
            pygame.draw.rect(surf, accent, (*c, 6, 6))

        return surf

    def _draw_fallback_graphics(self, surf, r, speaker, act_theme):
        cx, cy = r.centerx, r.centery
        sp = speaker.upper()
        if "NEXUS" in sp:
            pygame.draw.circle(surf, (255, 40, 60), (cx, cy), 24)
            pygame.draw.circle(surf, (255, 255, 255), (cx, cy), 8)
        elif "UNKNOWN" in sp:
            pygame.draw.circle(surf, (30, 15, 35), (cx, cy), 26)
            pygame.draw.rect(surf, (255, 60, 180), (cx - 18, cy - 6, 36, 10))
        elif "RECEPTIONIST" in sp:
            pygame.draw.circle(surf, (216, 163, 148), (cx, cy), 22)
        elif "SHOPKEEPER" in sp:
            pygame.draw.circle(surf, (180, 140, 110), (cx, cy), 22)
        else:
            pygame.draw.circle(surf, (0, 220, 255), (cx, cy), 22)

    def draw_speaking_wave(self, screen, x, y, w, h, t, color, active=True):
        """Draws an audio-reactive waveform bar visualization."""
        n_bars = 10
        bar_w = 4
        gap = (w - n_bars * bar_w) // (n_bars - 1)
        for i in range(n_bars):
            if active:
                freq = 5.0 + i * 2.0
                val = 0.25 + 0.75 * abs(math.sin(t * freq + i * 0.7))
            else:
                val = 0.12
            bh = int(h * val)
            bx = x + i * (bar_w + gap)
            by = y + (h - bh) // 2
            pygame.draw.rect(screen, color, (bx, by, bar_w, bh), border_radius=2)


portraits = PortraitManager()
