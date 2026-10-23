import pygame

from game.settings import WIDTH, HEIGHT, FPS, TITLE


class Game:
    """Owns the window and the currently active scene."""

    def __init__(self):
        pygame.init()
        pygame.display.set_caption(TITLE)
        self.screen = pygame.display.set_mode((WIDTH, HEIGHT))
        self.clock = pygame.time.Clock()
        self.scene = None
        self.running = True
        self.to_title = lambda: None  # set by flow.start_title

    def set_scene(self, scene):
        self.scene = scene

    def quit(self):
        self.running = False

    def tick(self, dt, events):
        """One frame. Split out from run() so tests can drive the game."""
        for event in events:
            if event.type == pygame.QUIT:
                self.quit()
            elif self.scene:
                self.scene.handle_event(event)
        if self.scene:
            self.scene.update(dt)
            self.scene.draw(self.screen)

    def run(self):
        while self.running:
            dt = min(self.clock.tick(FPS) / 1000.0, 0.05)
            self.tick(dt, pygame.event.get())
            pygame.display.flip()
        pygame.quit()
