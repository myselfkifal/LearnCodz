import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SoundCue { tap, correct, incorrect, complete, achievement }

class SoundEffects extends ChangeNotifier {
  static final instance = SoundEffects();
  final Future<void> Function(SoundCue, double)? playback;
  SoundEffects({this.playback});
  bool enabled = true;
  double volume = .65;
  String? lastError;
  bool _live = false;
  bool _active = true;
  int _generation = 0;
  final _players = <SoundCue, AudioPlayer>{};
  Future<void> _queue = Future.value();
  void initialize(SharedPreferences prefs) {
    enabled = prefs.getBool('soundEnabled') ?? true;
    volume = (prefs.getDouble('soundVolume') ?? .65).clamp(0, 1);
    _live = true;
  }

  Future<bool> settings(SharedPreferences prefs,
      {required bool on, required double level}) async {
    try {
      final saved = await Future.wait([
        prefs.setBool('soundEnabled', on),
        prefs.setDouble('soundVolume', level.clamp(0, 1))
      ]);
      if (saved.any((v) => !v)) return false;
      enabled = on;
      volume = level.clamp(0, 1);
      if (!enabled || volume == 0) await stop();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> play(SoundCue cue) {
    if (!_live || !_active || !enabled || volume == 0) return Future.value();
    final generation = ++_generation;
    _queue = _queue.then((_) async {
      if (generation != _generation || !_active || !enabled) return;
      try {
        if (playback != null) {
          await playback!(cue, volume);
          lastError = null;
          notifyListeners();
          return;
        }
        for (final p in _players.values) {
          await p.stop();
        }
        var player = _players[cue];
        if (player == null) {
          player = AudioPlayer();
          _players[cue] = player;
          await player.setAudioContext(AudioContext(
            android: const AudioContextAndroid(
                contentType: AndroidContentType.music,
                usageType: AndroidUsageType.media,
                audioFocus: AndroidAudioFocus.none),
            iOS: AudioContextIOS(
                category: AVAudioSessionCategory.ambient,
                options: const {AVAudioSessionOptions.mixWithOthers}),
          ));
          await player.setReleaseMode(ReleaseMode.stop);
        }
        if (generation != _generation || !_active || !enabled) return;
        await player.play(AssetSource('sounds/${cue.name}.wav'),
            volume: volume, mode: PlayerMode.mediaPlayer);
        lastError = null;
      } catch (error) {
        lastError =
            'Audio could not start. Try Preview sound again, or restart the app.';
        debugPrint('LearnCodz audio: $error');
        final failed = _players.remove(cue);
        if (failed != null) {
          try {
            await failed.dispose();
          } catch (_) {}
        }
      }
      notifyListeners();
    });
    return _queue;
  }

  Future<void> stop() async {
    _generation++;
    for (final player in _players.values) {
      try {
        await player.stop();
      } catch (_) {}
    }
  }

  void setActive(bool active) {
    _active = active;
    if (!active) {
      unawaited(stop());
    }
  }
}

class SoundSettings extends StatefulWidget {
  final SharedPreferences prefs;
  const SoundSettings({super.key, required this.prefs});
  @override
  State<SoundSettings> createState() => _SoundSettingsState();
}

class _SoundSettingsState extends State<SoundSettings> {
  late bool enabled;
  late double volume;
  @override
  void initState() {
    super.initState();
    enabled = widget.prefs.getBool('soundEnabled') ?? true;
    volume = (widget.prefs.getDouble('soundVolume') ?? .65).clamp(0, 1);
  }

  Future<void> save() async {
    final ok = await SoundEffects.instance
        .settings(widget.prefs, on: enabled, level: volume);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sound settings could not be saved. Please retry.')));
    }
  }

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
          color: const Color(0xFFF7F5FC),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFECE6F7))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Sounds & feedback',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Play learning sounds'),
            subtitle:
                const Text('Soft taps, warm chimes and gentle retry cues.'),
            value: enabled,
            onChanged: (value) {
              setState(() => enabled = value);
              unawaited(save());
            }),
        Row(children: [
          const Icon(Icons.volume_down_outlined),
          Expanded(
              child: Slider(
                  label: '${(volume * 100).round()}%',
                  value: volume,
                  onChanged: enabled
                      ? (value) => setState(() => volume = value)
                      : null,
                  onChangeEnd: enabled ? (_) => unawaited(save()) : null)),
          Text('${(volume * 100).round()}%')
        ]),
        const Text('Sounds use your phone’s media volume.',
            style: TextStyle(fontSize: 12, color: Colors.black54)),
        AnimatedBuilder(
            animation: SoundEffects.instance,
            builder: (context, _) => SoundEffects.instance.lastError == null
                ? const SizedBox.shrink()
                : Text(SoundEffects.instance.lastError!,
                    style: const TextStyle(color: Colors.red))),
        TextButton.icon(
            onPressed: enabled
                ? () async {
                    await save();
                    await SoundEffects.instance.play(SoundCue.correct);
                  }
                : null,
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('Preview sound')),
        Wrap(spacing: 8, children: [
          for (final cue in SoundCue.values)
            OutlinedButton(
                onPressed: enabled
                    ? () async {
                        await save();
                        await SoundEffects.instance.play(cue);
                      }
                    : null,
                child: Text(const {
                  SoundCue.tap: 'Tap',
                  SoundCue.correct: 'Correct',
                  SoundCue.incorrect: 'Retry',
                  SoundCue.complete: 'Lesson done',
                  SoundCue.achievement: 'XP reward'
                }[cue]!))
        ]),
      ]));
}
