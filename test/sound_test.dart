import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quizquest/sound_effects.dart';

void main() {
  test('Mute and volume persist and mute suppresses all playback', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final heard = <SoundCue>[];
    final sound = SoundEffects(playback: (cue, volume) async {
      heard.add(cue);
      expect(volume, .4);
    });
    sound.initialize(prefs);
    expect(await sound.settings(prefs, on: true, level: .4), isTrue);
    await sound.play(SoundCue.correct);
    await sound.settings(prefs, on: false, level: .4);
    await sound.play(SoundCue.incorrect);
    expect(heard, [SoundCue.correct]);
    final restored = SoundEffects()..initialize(prefs);
    expect(restored.enabled, isFalse);
    expect(restored.volume, .4);
  });
  test('Queued stale sounds are discarded and audio failures stay nonfatal',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final heard = <SoundCue>[];
    final sound = SoundEffects(playback: (cue, volume) async {
      heard.add(cue);
      throw StateError('No audio device');
    })
      ..initialize(prefs);
    final first = sound.play(SoundCue.tap);
    final second = sound.play(SoundCue.correct);
    await Future.wait([first, second]);
    expect(heard, [SoundCue.correct]);
    await sound.play(SoundCue.complete);
    expect(heard.last, SoundCue.complete);
  });
  test('Zero volume suppresses playback even when enabled', () async {
    SharedPreferences.setMockInitialValues({'soundVolume': 0.0});
    final prefs = await SharedPreferences.getInstance();
    var calls = 0;
    final sound = SoundEffects(playback: (_, __) async {
      calls++;
    })
      ..initialize(prefs);
    await sound.play(SoundCue.achievement);
    expect(calls, 0);
  });
  test('Playback failure is visible and a successful retry clears it',
      () async {
    SharedPreferences.setMockInitialValues({});
    var fail = true;
    final sound = SoundEffects(playback: (_, __) async {
      if (fail) {
        throw StateError('Player failed');
      }
    })
      ..initialize(await SharedPreferences.getInstance());
    await sound.play(SoundCue.correct);
    expect(sound.lastError, isNotNull);
    fail = false;
    await sound.play(SoundCue.correct);
    expect(sound.lastError, isNull);
  });
  test('Background mode suppresses cues until the app resumes', () async {
    SharedPreferences.setMockInitialValues({});
    var calls = 0;
    final sound = SoundEffects(playback: (_, __) async {
      calls++;
    })
      ..initialize(await SharedPreferences.getInstance());
    sound.setActive(false);
    await sound.play(SoundCue.incorrect);
    expect(calls, 0);
    sound.setActive(true);
    await sound.play(SoundCue.correct);
    expect(calls, 1);
  });
}
