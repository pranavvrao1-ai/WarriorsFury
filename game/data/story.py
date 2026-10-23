"""All story text lives here as data. Edit freely - no engine code needed.

Line types:
  narr(text)                             narration
  say(who, text, voice=None)             dialogue with voice clip audio
  system(text, title)                    blue NEXUS window. Colour words: {g:green} {r:red} {y:yellow} {c:cyan}
  fx(name, value)                        'flash' | 'glitch' | 'overlay' | 'sound' | 'phone_ring' | 'typing'
  wait(seconds)                          pause
  choice(prompt, options, auto)          button prompt (auto=True -> cursor clicks by itself)
Overlays: 'receipt', 'receipt_back', 'eyes', 'monitor', None
"""


def narr(text):
    return {"kind": "narr", "text": text}


def say(who, text, voice=None):
    return {"kind": "say", "who": who, "text": text, "voice": voice}


def system(text, title="NEXUS"):
    return {"kind": "system", "text": text, "title": title}


def fx(name, value=None):
    return {"kind": "fx", "name": name, "value": value}


def wait(sec):
    return {"kind": "wait", "sec": sec}


def choice(prompt, options, auto=False):
    return {"kind": "choice", "prompt": prompt, "options": options, "auto": auto}


ACT1 = [
    narr("2026. 11:47 PM."),
    narr("An ordinary gamer walks into a small gaming café tucked away in a narrow city street. A flickering neon sign hangs above the door:"),
    narr("AFTERLIFE GAMING LOUNGE"),
    narr("Rows of high-end PCs. A humming air conditioner. The place feels strangely empty - except for a receptionist who seems to know your name before you say it."),
    fx("sound", "*the air conditioner hums*"),
    narr("You sit down and launch your favourite game: WARRIOR'S FURY."),
    fx("typing", 1.5),
    fx("glitch", 0.4),
    say("UNKNOWN PLAYER", "Still trying to beat the final level?", voice="unknown/d1.mp3"),
    say("MC", "Who is this?", voice="mc/d1.mp3"),
    say("UNKNOWN PLAYER", "Someone who's already beaten it.", voice="unknown/d2.mp3"),
    say("MC", "Then tell me how.", voice="mc/d2.mp3"),
    say("UNKNOWN PLAYER", "Come back tomorrow. There's an event you won't want to miss.", voice="unknown/d3.mp3"),
    say("MC", "What's the prize?", voice="mc/d3.mp3"),
    say("UNKNOWN PLAYER", "Everything you've ever wanted.", voice="unknown/d4.mp3"),
    fx("glitch", 0.8),
    narr("For a fraction of a second, the screen shows something that shouldn't be there:"),
    system("{r:PLAYER 07} IDENTIFIED."),
    narr("You ignore it and keep playing."),
    narr("Hours pass. The other PCs stay empty. The receptionist has disappeared."),
    narr("A new screen appears."),
    system("WOULD YOU LIKE TO ENTER {y:THE FINAL LEVEL}?"),
    fx("flash"),
    narr("The monitor flashes white. And the world disappears.")
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
    fx("typing", 2.0),
    system("STAGE 1 {y:CLEARED}. {g:MEMORY FRAGMENT} ACQUIRED."),
    narr("A memory floods in - but it isn't yours. A kitchen. A birthday cake. A name you almost remember."),
]

MEMORY2 = [
    fx("sound", "*a chair rolls across a floor*"),
    system("STAGE 2 {y:CLEARED}. {g:MEMORY FRAGMENT} ACQUIRED."),
    narr("Another fragment: rain on a window. Someone laughing in the next room. Whose laugh is it?"),
    fx("sound", "*someone laughs, far away*"),
]

NEXUS = [
    narr("The arena doors open. NEXUS speaks to you directly."),
    say("NEXUS", "You keep searching for the exit.", voice="nexus/d1.mp3"),
    say("MC", "Because this isn't real.", voice="mc/d4.mp3"),
    say("NEXUS", "Then why are you afraid to die?", voice="nexus/d2.mp3"),
    say("MC", "Because it feels real.", voice="mc/d5.mp3"),
    say("NEXUS", "Perhaps that is the only difference that matters.", voice="nexus/d3.mp3"),
]

COLLAPSE = [
    fx("flash"),
    system("{r:NEXUS} DEFEATED. SIMULATION {r:COLLAPSING}."),
    narr("Neo-Eden starts collapsing into static."),
    fx("glitch", 1.0),
    say("UNKNOWN", "See you when you wake up.", voice="unknown/d5.mp3"),
    fx("flash"),
    wait(1.2),
]

ACT3 = [
    narr("You jolt awake."),
    narr("A gaming PC. The hum of the air conditioner. The neon sign outside. The same desk, the same game."),
    narr("Your heart is racing. Your hands tremble. You laugh at yourself - it must have been an extraordinarily vivid dream."),
    narr("Warrior's Fury is running on its normal title screen. No futuristic city. No NEXUS. No Unit 07."),
    say("MC", "Hey, how long was I asleep?", voice="mc/d6.mp3"),
    say("RECEPTIONIST", "You weren't asleep. You've been playing for six hours."),
    narr("You check your phone. It's 6:13 AM. You feel relieved."),
    narr("Before leaving, you glance back at the screen. A notification flickers for a fraction of a second."),
    fx("glitch", 0.7),
    system("THANK YOU FOR PARTICIPATING, {g:PLAYER 07}."),
    narr("Then it vanishes. A glitch, you tell yourself. You walk home."),
]

ACT4 = [
    narr("The next afternoon, curiosity gets the better of you. You return to the same narrow street."),
    narr("You want to confront the receptionist, investigate the computers, and find out whether somebody tampered with your game."),
    narr("But when you reach the location, you stop walking."),
    narr("There is no café."),
    narr("No neon sign. No gaming PCs. No entrance. Just a vacant commercial unit with dusty windows and a faded FOR LEASE notice."),
    narr("You check the building number. It's the same one. You ask the shopkeeper next door."),
    say("MC", "Excuse me. What happened to the gaming café here?", voice="mc/d7.mp3"),
    say("SHOPKEEPER", "Gaming café?", voice="shopkeeper/d1.mp3"),
    say("MC", "AFTERLIFE. It was right here last night.", voice="mc/d8.mp3"),
    say("SHOPKEEPER", "Son, this place has been empty for years.", voice="shopkeeper/d2.mp3"),
    say("MC", "No. I was literally there this morning.", voice="mc/d9.mp3"),
    say("SHOPKEEPER", "You've got the wrong place.", voice="shopkeeper/d3.mp3"),
    narr("The shopkeeper turns away."),
    narr("Your location history: nothing. You search for AFTERLIFE GAMING LOUNGE online: nothing. No website, no reviews, no photographs, no business registration."),
    narr("It's as if the café never existed. Was it a dream? Did you fall asleep somewhere else? Were you hallucinating? Or did you really enter the simulation?"),
    narr("Then you remember something. The receipt. The café had given you a printed receipt when you sat down."),
    narr("You frantically search your pockets. You find it, damp and crumpled."),
    fx("overlay", "receipt"),
    narr("On it is the café's name, the time of entry, and a final line printed at the bottom: PLAYER 07 — SESSION STATUS: INCOMPLETE."),
    narr("You turn the receipt over."),
    fx("overlay", "receipt_back"),
    narr("Someone has handwritten a message on the back."),
    fx("overlay", None),
    fx("sound", "*phone vibrates*"),
    fx("phone_ring"),
    wait(1.5),
    narr("An unknown number is calling. You answer. Silence. Then a familiar voice."),
    say("UNKNOWN", "Did you enjoy the game?", voice="unknown/d6.mp3"),
    say("MC", "Who are you? What happened to that place?", voice="mc/d10.mp3"),
    say("UNKNOWN", "What place?", voice="unknown/d7.mp3"),
    say("MC", "The café!", voice="mc/d11.mp3"),
    say("UNKNOWN", "There was never a café.", voice="unknown/d8.mp3"),
    say("UNKNOWN", "Now get some sleep. Your next session begins tonight.", voice="unknown/d9.mp3"),
    narr("The call ends. Your phone screen goes black. For a moment, your reflection looks normal."),
    fx("overlay", "eyes"),
    fx("glitch", 0.6),
    narr("Then your eyes glow blue."),
    narr("CUT TO BLACK."),
    wait(2.0),
    fx("overlay", None),
]

POST = [
    fx("overlay", "monitor"),
    narr("A dark room. A computer monitor illuminates an empty chair. A game launches automatically."),
    system("WARRIOR'S FURY - {c:SESSION 002}"),
    narr("The camera slowly moves toward the screen. A final message appears:"),
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
