"""Entry point. Run this file from PyCharm (right-click -> Run 'main')."""
from game.engine import Game
from game.flow import start_title


def main():
    game = Game()
    start_title(game)
    game.run()


if __name__ == "__main__":
    main()
