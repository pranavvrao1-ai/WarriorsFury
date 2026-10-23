import pygame

_cache = {}


def get_font(size, bold=False):
    key = (size, bold)
    if key not in _cache:
        _cache[key] = pygame.font.SysFont(
            "consolas,couriernew,dejavusansmono,monospace", size, bold=bold
        )
    return _cache[key]


def wrap_text(text, font, max_width):
    lines = []
    for paragraph in text.split("\n"):
        current = ""
        for word in paragraph.split(" "):
            test = word if not current else current + " " + word
            if font.size(test)[0] <= max_width:
                current = test
            else:
                if current:
                    lines.append(current)
                current = word
        lines.append(current)
    return lines


def draw_text(surface, text, font, color, pos, center=False, alpha=255):
    img = font.render(text, True, color)
    if alpha < 255:
        img.set_alpha(alpha)
    rect = img.get_rect(center=pos) if center else img.get_rect(topleft=pos)
    surface.blit(img, rect)
    return rect
