"""Combat stage definitions. Each wave is {enemy_kind: count}."""

STAGES = [
    {
        "name": "STAGE 1 - NEON STREETS",
        "subtitle": "Neo-Eden, 2189",
        "waves": [{"grunt": 4}, {"grunt": 7}],
    },
    {
        "name": "STAGE 2 - IRON BATTALION",
        "subtitle": "The robots remember you",
        "waves": [{"grunt": 4, "shooter": 2}, {"grunt": 5, "shooter": 4}],
    },
    {
        "name": "STAGE 3 - THE ARENA",
        "subtitle": "NEXUS awaits",
        "waves": [{"boss": 1}],
    },
]

# Faint captions from the real world that leak into the simulation.
AMBIENT = [
    "*keyboard clacking*",
    "*a chair rolls across a floor*",
    "*someone laughs, far away*",
    "*an air conditioner hums*",
]
