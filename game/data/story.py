"""All story text lives here as data. Edit freely - no engine code needed.

Line types:
  narr(text)                     narration
  say(who, text)                 dialogue
  system(text, title)            blue ALARM window. Colour words: {g:green} {r:red} {y:yellow} {c:cyan}
  fx(name, value)                'flash' | 'glitch' | 'overlay' | 'sound'
  wait(seconds)                  pause
  choice(prompt, options, auto)  button prompt (auto=True -> cursor clicks by itself)
Overlays: 'receipt', 'receipt_back', 'eyes', 'monitor', None
"""


def narr(text):
    return {"kind": "narr", "text": text}


def say(who, text):
    return {"kind": "say", "who": who, "text": text}


def system(text, title="ALARM"):
    return {"kind": "system", "text": text, "title": title}


def fx(name, value=None):
    return {"kind": "fx", "name": name, "value": value}


def wait(sec):
    return {"kind": "wait", "sec": sec}


def choice(prompt, options, auto=False):
    return {"kind": "choice", "prompt": prompt, "options": options, "auto": auto}


ACT1 = [
    narr("2026. 11:47 PM."),
    narr("An ordinary gamer walks into a small gaming cafe tucked away in a narrow city street. A flickering neon sign hangs above the door:"),
    narr("AFTERLIFE GAMING LOUNGE"),
    narr("Rows of high-end PCs. A humming air conditioner. The place feels strangely empty - except for a receptionist who seems to know your name before you say it."),
    fx("sound", "*the air conditioner hums*"),
    narr("You sit down and launch your favourite game: WARRIOR'S FURY."),
    fx("glitch", 0.4),
    say("UNKNOWN PLAYER", "Still trying to beat the final level?"),
    say("MC", "Who is this?"),
    say("UNKNOWN PLAYER", "Someone who's already beaten it."),
    say("MC", "Then tell me how."),
    say("UNKNOWN PLAYER", "Come back tomorrow. There's an event you won't want to miss."),
    say("MC", "What's the prize?"),
    say("UNKNOWN PLAYER", "Everything you've ever wanted."),
    fx("glitch", 0.8),
    narr("For a fraction of a second, the screen shows something that shouldn't be there:"),
    system("{r:PLAYER 07} IDENTIFIED."),
    narr("You ignore it and keep playing."),
    narr("Hours pass. The other PCs stay empty. The receptionist has disappeared."),
    narr("A new screen appears."),
    choice("WOULD YOU LIKE TO ENTER THE {y:FINAL LEVEL}?", ["YES"]),
    fx("flash"),
    narr("The monitor flashes white. And the world disappears."),
]

ACT2_INTRO = [
    narr("NEO-EDEN. YEAR 2189."),
    narr("A dystopian cyberpunk city, ruled by an artificial intelligence called NEXUS. Your body has been rebuilt as a cybernetic warrior."),
    system("{g:PLAYER 07}, CLEAR {y:THREE STAGES} TO ESCAPE."),
    system("IF YOU FAIL, THE SYSTEM WILL {r:RESET} YOU."),
    narr("CONTROLS:  WASD / arrows = move   |   mouse = aim   |   click or SPACE = shoot   |   SHIFT = dash"),
]

MEMORY1 = [
    fx("sound", "*a keyboard typing, far away*"),
    system("STAGE 1 {y:CLEARED}. {g:MEMORY FRAGMENT} ACQUIRED."),
    narr("A memory floods in - but it isn't yours. A kitchen. A birthday cake. A name you almost remember."),
]

MEMORY2 = [
    fx("sound", "*a chair rolls across a floor*"),
    system("STAGE 2 {y:CLEARED}. {g:MEMORY FRAGMENT} ACQUIRED."),
    narr("Another fragment: rain on a window. Someone laughing in the next room. Whose laugh is it?"),
    fx("sound", "*someone laughs*"),
]

NEXUS = [
    narr("The arena doors open. NEXUS speaks to you directly."),
    say("NEXUS", "You keep searching for the exit."),
    say("MC", "Because this isn't real."),
    say("NEXUS", "Then why are you afraid to die?"),
    say("MC", "Because it feels real."),
    say("NEXUS", "Perhaps that is the only difference that matters."),
]

COLLAPSE = [
    fx("flash"),
    system("{r:NEXUS} DEFEATED. SIMULATION {r:COLLAPSING}."),
    narr("Neo-Eden starts collapsing into static."),
    fx("glitch", 1.0),
    say("UNKNOWN", "See you when you wake up."),
    fx("flash"),
    wait(1.2),
]

ACT3 = [
    narr("You jolt awake."),
    narr("A gaming PC. The hum of the air conditioner. The neon sign outside. The same desk, the same game."),
    narr("Your heart is racing. Your hands tremble. You laugh at yourself - it must have been an incredibly vivid dream."),
    narr("Warrior's Fury is running on its normal title screen. No futuristic city. No NEXUS. No Unit 07."),
    say("MC", "Hey... how long was I asleep?"),
    say("RECEPTIONIST", "You weren't asleep. You've been playing for six hours."),
    narr("You check your phone. 6:13 AM."),
    narr("Before leaving, you glance back at the screen. A notification flickers for a fraction of a second."),
    fx("glitch", 0.7),
    system("THANK YOU FOR PARTICIPATING, {g:PLAYER 07}."),
    narr("Then it vanishes. A glitch, you tell yourself. You walk home."),
]

ACT4 = [
    narr("The next afternoon, curiosity wins. You return to the same narrow street."),
    narr("You stop walking."),
    narr("No neon sign. No gaming PCs. No entrance. Just a vacant unit with dusty windows and a faded FOR LEASE notice."),
    narr("You check the building number. It's the same one. You ask the shopkeeper next door."),
    say("MC", "Excuse me. What happened to the gaming cafe here?"),
    say("SHOPKEEPER", "Gaming cafe?"),
    say("MC", "AFTERLIFE. It was right here last night."),
    say("SHOPKEEPER", "Son, this place has been empty for years."),
    say("MC", "No. I was literally there this morning."),
    say("SHOPKEEPER", "You've got the wrong place."),
    narr("Your location history: nothing. Search results: nothing. No website, no reviews, no photographs, no business registration."),
    narr("It's as if the cafe never existed. Was it a dream? Did you fall asleep somewhere else? Were you hallucinating? Or did you really enter the simulation?"),
    narr("Then you remember the receipt. You search your pockets and find it, damp and crumpled."),
    fx("overlay", "receipt"),
    narr("You turn it over."),
    fx("overlay", "receipt_back"),
    narr("Someone has handwritten a message on the back."),
    fx("overlay", None),
    narr("Your phone vibrates. Unknown number. You answer. Silence. Then a familiar voice."),
    say("UNKNOWN", "Did you enjoy the game?"),
    say("MC", "Who are you? What happened to that place?"),
    say("UNKNOWN", "What place?"),
    say("MC", "The cafe!"),
    say("UNKNOWN", "There was never a cafe."),
    say("UNKNOWN", "Now get some sleep. Your next session begins tonight."),
    narr("The call ends. Your phone screen goes black. For a moment, your reflection looks normal."),
    fx("overlay", "eyes"),
    fx("glitch", 0.6),
    wait(3.0),
    fx("overlay", None),
]

POST = [
    fx("overlay", "monitor"),
    narr("A dark room. A monitor lights an empty chair. A game launches by itself."),
    system("WARRIOR'S FURY - {c:SESSION 002}"),
    system("{r:SUBJECT} IS BEGINNING TO QUESTION REALITY."),
    choice("PROCEED TO {y:NEXT STAGE}?", ["YES"], auto=True),
    fx("flash"),
]

STORY = {
    "act1": ACT1,
    "act2_intro": ACT2_INTRO,
    "memory1": MEMORY1,
    "memory2": MEMORY2,
    "nexus": NEXUS,
    "collapse": COLLAPSE,
    "act3": ACT3,
    "act4": ACT4,
    "post": POST,
}
