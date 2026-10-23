import os
from pathlib import Path
import pytest
import pygame

from game.settings import BASE_DIR, DIALOGUES_DIR, MUSIC_DIR, FOOTSTEPS_DIR
from game.data.story import STORY
from game.audio import audio
from game.ui.portraits import portraits


def test_all_story_dialogues_exist_on_disk():
    """Verify that every single voice clip referenced in the story data exists on disk and is valid."""
    missing = []
    found_count = 0
    for act_name, lines in STORY.items():
        for line in lines:
            if line["kind"] == "say" and line.get("voice"):
                voice_rel = line["voice"]
                full_path = DIALOGUES_DIR / voice_rel
                if not full_path.exists():
                    missing.append((act_name, line["who"], voice_rel))
                else:
                    found_count += 1
    assert not missing, f"Missing dialogue audio files: {missing}"
    assert found_count >= 25, f"Expected at least 25 dialogue voice lines, found {found_count}"


def test_music_files_exist_on_disk():
    """Verify that the key music tracks exist in gameathon music."""
    assert MUSIC_DIR.exists(), f"Music directory {MUSIC_DIR} does not exist"
    music_files = list(MUSIC_DIR.glob("*.mp3"))
    assert len(music_files) >= 8, f"Expected music tracks, found {len(music_files)}"
    assert "drone" in audio._music_tracks
    assert "cyber" in audio._music_tracks
    assert "boss" in audio._music_tracks
    assert "awakening" in audio._music_tracks
    assert "fear" in audio._music_tracks
    assert "suspense" in audio._music_tracks


def test_character_portraits_render():
    """Verify that character portraits generate valid Surfaces for all game speakers."""
    speakers = ["MC", "UNKNOWN PLAYER", "UNKNOWN", "NEXUS", "RECEPTIONIST", "SHOPKEEPER"]
    themes = ["cafe", "sim", "dark"]

    for speaker in speakers:
        for theme in themes:
            surf = portraits.get_portrait(speaker, theme, t=0.5)
            assert isinstance(surf, pygame.Surface)
            assert surf.get_width() > 0 and surf.get_height() > 0


def test_audio_playback_methods_headless_safe():
    """Verify audio methods execute safely without crashing in headless / dummy environments."""
    audio.play_music("cyber")
    audio.play_dialogue("unknown/d1.mp3")
    audio.play_sfx("flash")
    audio.play_sfx("shoot_player")
    audio.play_sfx("phone_ring")
    audio.play_footstep(0.4)
    audio.stop_voice()
    audio.stop_music()
