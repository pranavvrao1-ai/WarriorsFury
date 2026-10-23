extends Node
## Shared audio routing for the Godot story build. Existing source assets remain in place.

const MUSIC := {
 "ambient": "res://gameathon music/atlasaudio-drone-ambient-518685.mp3",
 "awakening": "res://gameathon music/atlasaudio-spiritual-awakening-587611.mp3",
 "phone": "res://gameathon music/chrysalyn-corporate-minimalist-mobile-phone-ringtone-562423.mp3",
 "typing": "res://gameathon music/desastar-keyboard-typing-sound-effect-585931.mp3",
 "cyber": "res://gameathon music/leberch-cyber-crime-443113.mp3",
 "fear": "res://gameathon music/leberch-fear-525004.mp3",
 "suspense": "res://gameathon music/nastelbom-suspense-suspense-background-623748.mp3",
 "tension": "res://gameathon music/nastelbom-tension-tension-music-602460.mp3",
 "halloween": "res://gameathon music/prettyjohn1-halloween-620615.mp3",
 "countdown": "res://gameathon music/vanguardiacreate-the-final-countdown-250335.mp3"
}
const SFX := {
 "footsteps": "res://footsteps/foot steps on land.mp3",
 "gravel": "res://footsteps/footsteps on grovel.mp3",
 "typing": "res://gameathon music/soumages-keyboard-typing-579122.mp3"
}
const VOICE := {
 "mc": ["res://dialougues/mc/d1.mp3", "res://dialougues/mc/d2.mp3", "res://dialougues/mc/d3.mp3", "res://dialougues/mc/d4.mp3", "res://dialougues/mc/d5.mp3", "res://dialougues/mc/d6.mp3", "res://dialougues/mc/d7.mp3", "res://dialougues/mc/d8.mp3", "res://dialougues/mc/d9.mp3", "res://dialougues/mc/d10.mp3", "res://dialougues/mc/d11.mp3"],
 "nexus": ["res://dialougues/nexus/d1.mp3", "res://dialougues/nexus/d2.mp3", "res://dialougues/nexus/d3.mp3"],
 "unknown": ["res://dialougues/unknown/d1.mp3", "res://dialougues/unknown/d2.mp3", "res://dialougues/unknown/d3.mp3", "res://dialougues/unknown/d4.mp3", "res://dialougues/unknown/d5.mp3", "res://dialougues/unknown/d6.mp3", "res://dialougues/unknown/d7.mp3", "res://dialougues/unknown/d8.mp3", "res://dialougues/unknown/d9.mp3"],
 "shopkeeper": ["res://dialougues/shopkeeper/d1.mp3", "res://dialougues/shopkeeper/d2.mp3", "res://dialougues/shopkeeper/d3.mp3"]
}
var _music_player: AudioStreamPlayer
var _voice_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer
var _voice_index: Dictionary = {}
var _last_step_ms: int = 0

func _ready() -> void:
 _music_player = _make_player("Music", -12.0)
 _voice_player = _make_player("Dialogue", -3.0)
 _sfx_player = _make_player("SFX", -7.0)

func _make_player(player_name: String, volume_db: float) -> AudioStreamPlayer:
 var player := AudioStreamPlayer.new()
 player.name = player_name
 player.volume_db = volume_db
 add_child(player)
 return player

func play_music(key: String) -> void:
 var path: String = str(MUSIC.get(key, ""))
 if path.is_empty() or not ResourceLoader.exists(path):
  push_warning("Missing music asset key: " + key)
  return
 var stream := load(path) as AudioStream
 if stream == null:
  push_warning("Could not load music: " + path)
  return
 if _music_player.stream == stream and _music_player.playing:
  return
 _music_player.stream = stream
 _music_player.play()

func stop_music() -> void:
 if _music_player != null:
  _music_player.stop()

func play_sfx(key: String) -> void:
 var path: String = str(SFX.get(key, ""))
 if path.is_empty() or not ResourceLoader.exists(path):
  return
 var stream := load(path) as AudioStream
 if stream == null:
  return
 _sfx_player.stream = stream
 _sfx_player.play()

func play_voice_for_speaker(speaker: String) -> void:
 var normalized := speaker.to_lower()
 var voice_key := ""
 if "nexus" in normalized or "operator" in normalized:
  voice_key = "nexus"
 elif "unknown" in normalized or "static" in normalized:
  voice_key = "unknown"
 elif "hiro" in normalized or "shopkeeper" in normalized or "receptionist" in normalized:
  voice_key = "shopkeeper"
 elif "protagonist" in normalized or "mc" in normalized or "player" in normalized:
  voice_key = "mc"
 if voice_key.is_empty():
  return
 var clips: Array = VOICE[voice_key]
 var idx: int = int(_voice_index.get(voice_key, 0))
 var attempts := 0
 while attempts < clips.size():
  var path: String = clips[idx % clips.size()]
  idx += 1
  attempts += 1
  if ResourceLoader.exists(path):
   var stream := load(path) as AudioStream
   if stream != null:
    _voice_index[voice_key] = idx
    _voice_player.stream = stream
    _voice_player.play()
    return
 _voice_index[voice_key] = idx

func play_footstep() -> void:
 var now := Time.get_ticks_msec()
 if now - _last_step_ms < 420:
  return
 _last_step_ms = now
 play_sfx("footsteps")
