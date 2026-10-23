"""Blue 'system alert' windows (NEXUS popups) with colour-highlighted words.

Markup inside text:  {g:green}  {r:red}  {y:yellow}  {c:cyan}  {w:white}
Example: "{g:PLAYER 07} IDENTIFIED."  ->  [PLAYER 07 IDENTIFIED.]  (brackets added automatically)
"""
import re

import pygame

from game.ui.text import get_font

COLORS = {
    "w": (240, 245, 255),
    "g": (80, 235, 110),
    "r": (255, 60, 60),
    "y": (255, 205, 60),
    "c": (90, 225, 255),
}
_TAG = re.compile(r"\{([grycw]):([^}]*)\}")

PANEL_TOP = (38, 98, 210)
PANEL_BOTTOM = (20, 58, 150)
EDGE = (170, 210, 255)
EDGE_INNER = (95, 150, 235)
HEADER_H = 56
ROW_H = 32
PAD_BOTTOM = 30


def parse_markup(text):
    """Returns tokens [word, colour, space_before]."""
    segs, pos = [], 0
    for m in _TAG.finditer(text):
        if m.start() > pos:
            segs.append((text[pos:m.start()], "w"))
        segs.append((m.group(2), m.group(1)))
        pos = m.end()
    if pos < len(text):
        segs.append((text[pos:], "w"))
    tokens, space = [], False
    for chunk, c in segs:
        for part in re.findall(r"\s+|\S+", chunk):
            if part.isspace():
                space = True
            else:
                tokens.append([part, COLORS[c], space])
                space = False
    if tokens:
        tokens[0][2] = False
    return tokens


def wrap_tokens(tokens, font, max_w):
    rows, width = [[]], 0
    sp = font.size(" ")[0]
    for word, color, space in tokens:
        w = font.size(word)[0]
        gap = sp if (space and rows[-1]) else 0
        if rows[-1] and width + gap + w > max_w:
            rows.append([])
            width, gap = 0, 0
        rows[-1].append((word, color, gap > 0))
        width += gap + w
    return rows


def layout(text, width=700, extra_h=0, center=(480, 290), brackets=True):
    font = get_font(22, True)
    tokens = parse_markup(f"[{text}]" if brackets else text)
    rows = wrap_tokens(tokens, font, width - 80)
    rect = pygame.Rect(0, 0, width, HEADER_H + len(rows) * ROW_H + PAD_BOTTOM + extra_h)
    rect.center = center
    return rows, rect


def _diamond(surf, x, y, r, color):
    pygame.draw.polygon(surf, color, [(x, y - r), (x + r, y), (x, y + r), (x - r, y)])


def draw_panel(w, h, alpha=225):
    """The ornate blue panel, returned as a surface."""
    panel = pygame.Surface((w, h), pygame.SRCALPHA)
    for y in range(h):
        k = y / max(h - 1, 1)
        c = tuple(int(PANEL_TOP[i] + (PANEL_BOTTOM[i] - PANEL_TOP[i]) * k) for i in range(3))
        pygame.draw.line(panel, (*c, alpha), (0, y), (w, y))
    glow = pygame.Surface((w, h), pygame.SRCALPHA)
    pygame.draw.ellipse(glow, (130, 190, 255, 30), (int(w * 0.15), -int(h * 0.7), int(w * 0.7), int(h * 1.4)))
    panel.blit(glow, (0, 0))

    pygame.draw.rect(panel, EDGE, (0, 0, w, h), 2)
    pygame.draw.rect(panel, EDGE_INNER, (7, 7, w - 14, h - 14), 1)
    for cx, cy, sx, sy in ((7, 7, 1, 1), (w - 8, 7, -1, 1), (7, h - 8, 1, -1), (w - 8, h - 8, -1, -1)):
        pygame.draw.line(panel, EDGE, (cx, cy), (cx + sx * 28, cy), 3)
        pygame.draw.line(panel, EDGE, (cx, cy), (cx, cy + sy * 28), 3)
        _diamond(panel, cx + sx * 38, cy, 4, EDGE)
        _diamond(panel, cx, cy + sy * 38, 4, EDGE)
    _diamond(panel, w // 2, 7, 6, EDGE)
    _diamond(panel, w // 2 - 22, 7, 3, EDGE)
    _diamond(panel, w // 2 + 22, 7, 3, EDGE)
    font = get_font(13, True)
    img = font.render("-  X", True, (210, 230, 255))
    panel.blit(img, (w - img.get_width() - 14, 12))
    return panel


def draw_system_window(screen, text, title="NEXUS", center=(480, 290), width=700,
                       progress=1.0, extra_h=0, brackets=True):
    """Draws the window and returns its final rect. progress 0..1 = fade/slide in."""
    rows, rect = layout(text, width, extra_h, center, brackets)
    surf = draw_panel(rect.w, rect.h)

    # header: (!) icon + title
    tfont = get_font(22, True)
    title_img = tfont.render(title, True, (255, 255, 255))
    total = 26 + 10 + title_img.get_width()
    x0 = (rect.w - total) // 2
    pygame.draw.circle(surf, (255, 255, 255), (x0 + 12, 34), 12, 2)
    bang = get_font(16, True).render("!", True, (255, 255, 255))
    surf.blit(bang, bang.get_rect(center=(x0 + 12, 34)))
    surf.blit(title_img, (x0 + 36, 34 - title_img.get_height() // 2))

    # text rows, centred, per-word colours
    font = get_font(22, True)
    sp = font.size(" ")[0]
    for i, row in enumerate(rows):
        width_row = sum(font.size(w)[0] + (sp if s else 0) for w, _, s in row)
        x = (rect.w - width_row) // 2
        y = HEADER_H + i * ROW_H
        for word, color, space in row:
            if space:
                x += sp
            surf.blit(font.render(word, True, color), (x, y))
            x += font.size(word)[0]

    p = max(0.0, min(progress, 1.0))
    surf.set_alpha(int(255 * p))
    screen.blit(surf, (rect.x, rect.y + int((1 - p) * 16)))
    return rect


def draw_button(screen, rect, label, hot=False):
    panel = pygame.Surface(rect.size, pygame.SRCALPHA)
    panel.fill((22, 66, 170, 235) if not hot else (40, 100, 225, 245))
    screen.blit(panel, rect.topleft)
    pygame.draw.rect(screen, (255, 255, 255) if hot else EDGE_INNER, rect, 3 if hot else 1)
    img = get_font(24, True).render(label, True, (255, 255, 255))
    screen.blit(img, img.get_rect(center=rect.center))
