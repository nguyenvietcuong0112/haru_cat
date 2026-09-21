import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  AudioPlayer? _bgmPlayer;

  bool _isBgmEnabled = true;
  bool _isSfxEnabled = true;

  bool get isBgmEnabled => _isBgmEnabled;
  bool get isSfxEnabled => _isSfxEnabled;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isBgmEnabled = prefs.getBool('bgm_enabled') ?? true;
      _isSfxEnabled = prefs.getBool('sfx_enabled') ?? true;

      _bgmPlayer = AudioPlayer();
      await _bgmPlayer?.setReleaseMode(ReleaseMode.loop);
    } catch (_) {
      // Platform channels not available in headless tests
    }
  }

  Future<void> playBgm({String assetPath = 'audio/bgm/bg_music.ogg'}) async {
    if (!_isBgmEnabled) return;
    try {
      _bgmPlayer ??= AudioPlayer();
      await _bgmPlayer?.stop();
      await _bgmPlayer?.play(AssetSource(assetPath), volume: 0.5);
    } catch (_) {}
  }

  Future<void> pauseBgm() async {
    try {
      await _bgmPlayer?.pause();
    } catch (_) {}
  }

  Future<void> resumeBgm() async {
    if (!_isBgmEnabled) return;
    try {
      await _bgmPlayer?.resume();
    } catch (_) {}
  }

  Future<void> stopBgm() async {
    try {
      await _bgmPlayer?.stop();
    } catch (_) {}
  }

  Future<void> toggleBgm() async {
    _isBgmEnabled = !_isBgmEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bgm_enabled', _isBgmEnabled);

    if (_isBgmEnabled) {
      await playBgm();
    } else {
      await stopBgm();
    }
  }

  Future<void> toggleSfx() async {
    _isSfxEnabled = !_isSfxEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sfx_enabled', _isSfxEnabled);
  }

  Future<void> playSfx(String soundFile) async {
    if (!_isSfxEnabled) return;
    try {
      // Create separate player instance or reuse for rapid SFX
      final sfxPlayer = AudioPlayer();
      await sfxPlayer.play(AssetSource('audio/sfx/$soundFile'), volume: 0.8);
      sfxPlayer.onPlayerComplete.listen((_) => sfxPlayer.dispose());
    } catch (_) {}
  }

  // Predefined sound triggers
  void playClick() => playSfx('button_click_1.wav');
  void playDrop() => playSfx('block_drop.wav');
  void playMeow() => playSfx('meow_1.wav');
  void playMeowCombo() => playSfx('meow_2.wav');
  void playClear() => playSfx('combos_clear.wav');
  void playLightning() => playSfx('lightning.wav');
  void playIceBreak() => playSfx('ice_break.wav');
  void playBooster() => playSfx('booster_added.wav');
  void playWin() => playSfx('star_3.ogg');
  void playGameOver() => playSfx('challenge_game_over.ogg');
}
