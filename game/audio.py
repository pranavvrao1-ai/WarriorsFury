import os
import math
import array
from pathlib import Path
import pygame

from game.settings import BASE_DIR, MUSIC_DIR, DIALOGUES_DIR, FOOTSTEPS_DIR


class AudioManager:
    """Centralized sound, music, and dialogue voice playback system."""

    def __init__(self):
        self.initialized = False
        self.current_music = None
        self.voice_channel = None
        self.ambient_channel = None
        self.footstep_channel = None
        self._sound_cache = {}
        self._music_tracks = {}
        self._footstep_timer = 0.0
        self.muted = False
        self._init_mixer()

    def _init_mixer(self):
        if not pygame.mixer.get_init():
            try:
                pygame.mixer.init(frequency=44100, size=-16, channels=2, buffer=1024)
            except Exception as e:
                print(f"[Audio] Mixer init failed: {e}")
                return
        self.initialized = True
        try:
            pygame.mixer.set_num_channels(16)
            self.voice_channel = pygame.mixer.Channel(0)
            self.ambient_channel = pygame.mixer.Channel(1)
            self.footstep_channel = pygame.mixer.Channel(2)
        except Exception as e:
            print(f"[Audio] Channels init warning: {e}")

        self._index_music()
        self._generate_synth_sfx()

    def _index_music(self):
        if not MUSIC_DIR.exists():
            return
        for f in MUSIC_DIR.glob("*.mp3"):
            fname = f.name.lower()
            if "cyber-crime" in fname:
                self._music_tracks["cyber"] = f
                self._music_tracks["combat"] = f
            elif "drone-ambient" in fname:
                self._music_tracks["drone"] = f
                self._music_tracks["cafe"] = f
            elif "final-countdown" in fname:
                self._music_tracks["boss"] = f
                self._music_tracks["final"] = f
            elif "spiritual-awakening" in fname:
                self._music_tracks["awakening"] = f
            elif "fear" in fname:
                self._music_tracks["fear"] = f
            elif "suspense" in fname:
                self._music_tracks["suspense"] = f
                self._music_tracks["title"] = f
            elif "tension" in fname:
                self._music_tracks["tension"] = f
            elif "halloween" in fname and "Copy" not in f.name:
                self._music_tracks["horror"] = f
            elif "phone-ringtone" in fname:
                self._sound_cache["phone_ring"] = f
            elif "desastar-keyboard" in fname:
                self._sound_cache["typing_long"] = f
            elif "soumages-keyboard" in fname:
                self._sound_cache["typing_short"] = f

    def _generate_synth_sfx(self):
        """Procedural sci-fi and dramatic audio effects."""
        if not self.initialized:
            return
        try:
            self._sound_cache["shoot_player"] = self._create_synth(650, 180, 0.12, 0.25, wave="saw")
            self._sound_cache["shoot_enemy"] = self._create_synth(320, 90, 0.18, 0.22, wave="square")
            self._sound_cache["shoot_boss"] = self._create_synth(180, 45, 0.35, 0.35, wave="saw")
            self._sound_cache["dash"] = self._create_synth(250, 600, 0.15, 0.25, wave="sine")
            self._sound_cache["hit"] = self._create_synth(120, 40, 0.16, 0.3, wave="noise")
            self._sound_cache["explosion"] = self._create_synth(90, 20, 0.45, 0.4, wave="noise")
            self._sound_cache["glitch"] = self._create_synth(800, 120, 0.18, 0.2, wave="noise")
            self._sound_cache["flash"] = self._create_synth(1200, 300, 0.25, 0.25, wave="sine")
            self._sound_cache["click"] = self._create_synth(900, 1100, 0.05, 0.15, wave="sine")
            self._sound_cache["stage_clear"] = self._create_synth(440, 880, 0.4, 0.3, wave="sine")

            # Dramatic Heartbeat double-thump
            sample_rate = 44100
            duration = 0.5
            n_samples = int(sample_rate * duration)
            buf = array.array("h")
            for i in range(n_samples):
                t = i / sample_rate
                env1 = math.exp(-25 * t) if t < 0.16 else 0
                env2 = math.exp(-25 * (t - 0.18)) if t >= 0.18 else 0
                val = int(32767 * 0.75 * (env1 * math.sin(2 * math.pi * 55 * t) + env2 * math.sin(2 * math.pi * 65 * t)))
                val = max(-32768, min(32767, val))
                buf.append(val)
                buf.append(val)
            self._sound_cache["heartbeat"] = pygame.mixer.Sound(buf)

        except Exception as e:
            print(f"[Audio] Error creating synth sfx: {e}")

    def _create_synth(self, freq_start, freq_end, duration, volume=0.3, wave="sine"):
        sample_rate = 44100
        n_samples = int(sample_rate * duration)
        buf = array.array("h")
        for i in range(n_samples):
            t = i / sample_rate
            frac = i / n_samples
            freq = freq_start + (freq_end - freq_start) * frac
            envelope = math.sin(math.pi * frac) if frac < 0.2 else (1.0 - frac)
            if wave == "square":
                raw = 1.0 if math.sin(2 * math.pi * freq * t) >= 0 else -1.0
            elif wave == "saw":
                raw = 2.0 * (t * freq - math.floor(0.5 + t * freq))
            elif wave == "noise":
                import random
                raw = random.uniform(-1.0, 1.0)
            else:
                raw = math.sin(2 * math.pi * freq * t)
            val = int(32767 * volume * envelope * raw)
            val = max(-32768, min(32767, val))
            buf.append(val)
            buf.append(val)
        return pygame.mixer.Sound(buf)

    # ---------- Music ----------
    def play_music(self, track_name, loop=-1, fade_ms=400):
        if not self.initialized or self.muted:
            return
        if self.current_music == track_name and pygame.mixer.music.get_busy():
            return
        path = self._music_tracks.get(track_name)
        if not path or not path.exists():
            return
        try:
            pygame.mixer.music.set_volume(0.55)
            pygame.mixer.music.load(str(path))
            pygame.mixer.music.play(loops=loop, fade_ms=fade_ms)
            self.current_music = track_name
        except Exception as e:
            print(f"[Audio] play_music error: {e}")

    def ensure_music(self, track_name="cyber"):
        """Ensures background music is playing; starts it if silent."""
        if not self.initialized or self.muted:
            return
        if not pygame.mixer.music.get_busy():
            self.play_music(track_name)

    def stop_music(self, fade_ms=400):
        if not self.initialized:
            return
        try:
            pygame.mixer.music.fadeout(fade_ms)
            self.current_music = None
        except Exception:
            pass

    # ---------- Dialogue Voice ----------
    def play_dialogue(self, voice_rel_path):
        """Plays a character dialogue audio clip, stopping any currently speaking line."""
        if not self.initialized or self.muted or not voice_rel_path:
            return 0.0
        voice_file = DIALOGUES_DIR / voice_rel_path
        if not voice_file.exists():
            print(f"[Audio] Dialogue not found: {voice_file}")
            return 0.0
        try:
            sound = self._sound_cache.get(str(voice_file))
            if sound is None:
                sound = pygame.mixer.Sound(str(voice_file))
                sound.set_volume(0.95)
                self._sound_cache[str(voice_file)] = sound
            if self.voice_channel:
                self.voice_channel.stop()
                self.voice_channel.play(sound)
            else:
                sound.play()
            return sound.get_length()
        except Exception as e:
            print(f"[Audio] play_dialogue error: {e}")
            return 0.0

    def stop_voice(self):
        if self.voice_channel:
            self.voice_channel.stop()

    def is_voice_playing(self):
        return bool(self.voice_channel and self.voice_channel.get_busy())

    # ---------- SFX & Ambience ----------
    def play_sfx(self, name):
        if not self.initialized or self.muted:
            return
        try:
            s = self._sound_cache.get(name)
            if isinstance(s, Path) and s.exists():
                snd = pygame.mixer.Sound(str(s))
                snd.set_volume(0.65)
                self._sound_cache[name] = snd
                snd.play()
            elif isinstance(s, pygame.mixer.Sound):
                s.play()
        except Exception as e:
            print(f"[Audio] play_sfx error {name}: {e}")

    def play_ambient(self, name, loops=0):
        if not self.initialized or self.muted or not self.ambient_channel:
            return
        s = self._sound_cache.get(name)
        if not s:
            return
        try:
            if isinstance(s, Path):
                snd = pygame.mixer.Sound(str(s))
                snd.set_volume(0.35)
                self._sound_cache[name] = snd
                self.ambient_channel.play(snd, loops=loops)
            elif isinstance(s, pygame.mixer.Sound):
                self.ambient_channel.play(s, loops=loops)
        except Exception as e:
            print(f"[Audio] play_ambient error: {e}")

    def play_footstep(self, dt, gravel=False):
        """Rhythmically triggers footstep sound when moving."""
        if not self.initialized or self.muted or not self.footstep_channel:
            return
        self._footstep_timer += dt
        if self._footstep_timer >= 0.34:
            self._footstep_timer = 0.0
            clip_name = "footsteps on grovel.mp3" if gravel else "foot steps on land.mp3"
            clip_path = FOOTSTEPS_DIR / clip_name
            if clip_path.exists():
                try:
                    snd = self._sound_cache.get(str(clip_path))
                    if not snd:
                        snd = pygame.mixer.Sound(str(clip_path))
                        snd.set_volume(0.2)
                        self._sound_cache[str(clip_path)] = snd
                    self.footstep_channel.play(snd)
                except Exception:
                    pass


# Global singleton
audio = AudioManager()
