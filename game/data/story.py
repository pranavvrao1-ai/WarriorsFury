"""All story text lives here as data. Edit freely - no engine code needed.

Line types:
  narr(text)                             narration
  say(who, text, voice=None)             dialogue with voice clip audio
  system(text, title)                    blue NEXUS window. Colour words: {g:green} {r:red} {y:yellow} {c:cyan}
  fx(name, value)                        'flash' | 'glitch' | 'overlay' | 'sound' | 'phone_ring' | 'typing' | 'shake' | 'heartbeat'
  wait(seconds)                          pause
  choice(prompt, options, auto)          button prompt (auto=True -> cursor clicks by itself)
Overlays: 'receipt', 'receipt_back', 'eyes', 'monitor', 'phone_screen', 'blackout', None
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
    fx("shake", 14),
    system("{r:NEXUS} DEFEATED. SIMULATION {r:COLLAPSING}."),
    narr("Neo-Eden begins tearing apart into blinding static."),
    fx("glitch", 1.2),
    say("UNKNOWN", "See you when you wake up.", voice="unknown/d5.mp3"),
    fx("flash"),
    wait(1.2),
]

ACT3 = [
    narr("You jolt awake!"),
    fx("shake", 8),
    narr("A gaming PC. The hum of the air conditioner. The neon sign outside. The same desk, the same game."),
    narr("Your heart is racing. Your hands tremble violently. You laugh at yourself - it must have been an extraordinarily vivid dream."),
    narr("Warrior's Fury is running on its normal title screen. No futuristic city. No NEXUS. No Unit 07."),
    say("MC", "Hey, how long was I asleep?", voice="mc/d6.mp3"),
    say("RECEPTIONIST", "You weren't asleep. You've been playing for six hours."),
    narr("You check your phone. It's 6:13 AM. You take a deep breath, trying to calm your racing pulse."),
    narr("Before leaving, you glance back at the screen. A notification flickers for a fraction of a second."),
    fx("glitch", 0.7),
    system("THANK YOU FOR PARTICIPATING, {g:PLAYER 07}."),
    narr("Then it vanishes into thin air. A glitch, you tell yourself. You walk home in the dawn light."),
]

ACT4 = [
    narr("The next afternoon, curiosity gnaws at your sanity. You return to the narrow city street."),
    narr("You want to confront the receptionist, inspect the computers, and find out what really happened."),
    fx("shake", 6),
    narr("You turn the corner. And your breath stops in your throat."),
    fx("glitch", 0.7),
    narr("There is NO café."),
    narr("No neon sign. No humming computers. No entrance doors. Just a cold, vacant commercial unit with dusty cracked windows and a faded FOR LEASE sign."),
    narr("You check the building number over and over. It's the exact same address. Trembling, you approach the shopkeeper next door."),
    say("MC", "Excuse me. What happened to the gaming café here?", voice="mc/d7.mp3"),
    say("SHOPKEEPER", "Gaming café?", voice="shopkeeper/d1.mp3"),
    say("MC", "AFTERLIFE. It was right here last night.", voice="mc/d8.mp3"),
    fx("shake", 8),
    say("SHOPKEEPER", "Son, this place has been empty for years.", voice="shopkeeper/d2.mp3"),
    say("MC", "No. I was literally there this morning.", voice="mc/d9.mp3"),
    say("SHOPKEEPER", "You've got the wrong place.", voice="shopkeeper/d3.mp3"),
    narr("The shopkeeper shakes his head and turns away."),
    fx("heartbeat"),
    fx("glitch", 0.9),
    narr("A cold wave of terror washes over you. You pull out your phone with shaking hands."),
    narr("Your GPS location history: EMPTY. You search online for 'AFTERLIFE GAMING LOUNGE': ZERO results. No website. No photos. No tax registration. Nothing."),
    narr("Your mind spins into complete disorientation. Was the café a hallucination? A psychotic break? Did you sleep on a bench? OR DID YOU ACTUALLY ENTER THE SIMULATION?!"),
    fx("heartbeat"),
    narr("Then... your fingers brush against your coat pocket."),
    narr("The printed receipt. The receptionist gave it to you when you checked in."),
    fx("shake", 10),
    narr("You frantically rip it out of your pocket. The paper is damp, crumpled, and unmistakably REAL."),
    fx("overlay", "receipt"),
    narr("Printed on the front: AFTERLIFE GAMING LOUNGE. 11:47 PM. And at the bottom: PLAYER 07 — SESSION STATUS: INCOMPLETE."),
    narr("Your hands shake as you slowly turn the paper over..."),
    fx("shake", 16),
    fx("glitch", 1.2),
    fx("heartbeat"),
    fx("overlay", "receipt_back"),
    narr("Scribbled in dark, jagged handwriting on the back:"),
    narr("'YOU WOKE UP TOO EARLY.'"),
    fx("heartbeat"),
    fx("sound", "*your phone vibrates violently in your palm*"),
    fx("phone_ring"),
    wait(1.5),
    narr("UNKNOWN CALLER. The screen glows in the gloom. Trembling, you hit ANSWER. Pure static. Then that familiar, chilling voice:"),
    say("UNKNOWN", "Did you enjoy the game?", voice="unknown/d6.mp3"),
    say("MC", "Who are you? What happened to that place?", voice="mc/d10.mp3"),
    say("UNKNOWN", "What place?", voice="unknown/d7.mp3"),
    say("MC", "The café!", voice="mc/d11.mp3"),
    fx("glitch", 0.8),
    say("UNKNOWN", "There was never a café.", voice="unknown/d8.mp3"),
    say("UNKNOWN", "Now get some sleep. Your next session begins tonight.", voice="unknown/d9.mp3"),
    fx("shake", 14),
    narr("CLICK. The call cuts dead."),
    fx("overlay", "phone_screen"),
    narr("Your phone screen goes pitch black. The world around you feels distant, warped, unreal."),
    fx("heartbeat"),
    narr("You stare into the black glass of the phone. In the dark reflection, you see your own terrified, pale face."),
    narr("You wonder if you're even awake. If you ever woke up at all."),
    fx("shake", 18),
    fx("glitch", 1.5),
    fx("heartbeat"),
    fx("overlay", "eyes"),
    narr("And then... right in the reflection... your eyes ignite into glowing electric blue."),
    fx("flash"),
    fx("shake", 22),
    wait(3.0),
    fx("overlay", "blackout"),
    narr("CUT TO BLACK."),
    wait(1.5),
    fx("overlay", None),
]

POST = [
    fx("overlay", "monitor"),
    narr("A pitch-black server room. A solitary computer monitor illuminates an empty leather chair."),
    system("WARRIOR'S FURY - {c:SESSION 002}"),
    narr("The camera slowly creeps closer to the glowing screen. A final classified log appears:"),
    system("{r:SUBJECT} IS BEGINNING TO QUESTION REALITY."),
    narr("A prompt blinks silently in the dark:"),
    choice("PROCEED TO {y:NEXT STAGE}?", ["YES"], auto=True),
    fx("flash"),
    fx("shake", 15),
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
