class Scene:
    """Every screen in the game (title, story, combat...) is a Scene."""

    def __init__(self, game):
        self.game = game

    def handle_event(self, event):
        pass

    def update(self, dt):
        pass

    def draw(self, screen):
        pass
