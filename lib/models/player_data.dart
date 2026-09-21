import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CharacterInfo {
  final String id;
  final String name;
  final String skillTitle;
  final String skillDescription;
  final String imageAsset;
  final int unlockCostGold;

  const CharacterInfo({
    required this.id,
    required this.name,
    required this.skillTitle,
    required this.skillDescription,
    required this.imageAsset,
    this.unlockCostGold = 0,
  });
}

class PlayerData extends ChangeNotifier {
  static final PlayerData _instance = PlayerData._internal();
  factory PlayerData() => _instance;
  PlayerData._internal();

  static const List<CharacterInfo> allCharacters = [
    CharacterInfo(
      id: 'haru',
      name: 'Haru',
      skillTitle: 'Purring Power',
      skillDescription: 'Clears the entire bottom row of blocks instantly.',
      imageAsset: 'assets/images/characters/newportrait_haru.png',
      unlockCostGold: 0,
    ),
    CharacterInfo(
      id: 'robinhood',
      name: 'Robinhood',
      skillTitle: 'Arrow Strike',
      skillDescription: 'Smashes 1 random block and its surrounding blocks.',
      imageAsset: 'assets/images/sprites/ui/Robinhood_Reward.png',
      unlockCostGold: 20,
    ),
    CharacterInfo(
      id: 'warrior',
      name: 'Warrior',
      skillTitle: 'Double Smash',
      skillDescription: 'Smashes 2 random blocks and clears nearby cats.',
      imageAsset: 'assets/images/sprites/ui/Haru_Warrior.png',
      unlockCostGold: 30,
    ),
    CharacterInfo(
      id: 'king',
      name: 'King',
      skillTitle: 'Thunderball Blitz',
      skillDescription: 'Throws 3 thunderballs that clear random rows and columns.',
      imageAsset: 'assets/images/sprites/ui/Haru_King_0.png',
      unlockCostGold: 50,
    ),
    CharacterInfo(
      id: 'magician',
      name: 'Magician',
      skillTitle: 'Frost Magic',
      skillDescription: 'Freezes upcoming rows for 2 turns so they do not push up.',
      imageAsset: 'assets/images/sprites/ui/Haru_Magician_0.png',
      unlockCostGold: 40,
    ),
  ];

  int _goldFish = 15;
  int _silverFish = 200;
  String _selectedCharacter = 'haru';
  Set<String> _unlockedCharacters = {'haru'};

  int _hammerCount = 3;
  int _magnetCount = 2;
  int _wandCount = 2;

  int _dailyRewardDay = 1;
  String _lastDailyRewardDate = '';
  int _lastFreeSpinTime = 0;

  int _bestScore = 0;
  int _lifetimeScore = 0;
  int _totalLinesCleared = 0;

  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _vibrationEnabled = true;

  // Getters
  int get goldFish => _goldFish;
  int get silverFish => _silverFish;
  String get selectedCharacter => _selectedCharacter;
  Set<String> get unlockedCharacters => _unlockedCharacters;

  int get hammerCount => _hammerCount;
  int get magnetCount => _magnetCount;
  int get wandCount => _wandCount;

  int get dailyRewardDay => _dailyRewardDay;
  int get lastFreeSpinTime => _lastFreeSpinTime;

  int get bestScore => _bestScore;
  int get lifetimeScore => _lifetimeScore;
  int get totalLinesCleared => _totalLinesCleared;

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  bool get vibrationEnabled => _vibrationEnabled;

  CharacterInfo get currentCharacter =>
      allCharacters.firstWhere((c) => c.id == _selectedCharacter, orElse: () => allCharacters.first);

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _goldFish = prefs.getInt('gold_fish') ?? 15;
      _silverFish = prefs.getInt('silver_fish') ?? 200;
      _selectedCharacter = prefs.getString('selected_character') ?? 'haru';
      _unlockedCharacters = (prefs.getStringList('unlocked_characters') ?? ['haru']).toSet();

      _hammerCount = prefs.getInt('booster_hammer') ?? 3;
      _magnetCount = prefs.getInt('booster_magnet') ?? 2;
      _wandCount = prefs.getInt('booster_wand') ?? 2;

      _dailyRewardDay = prefs.getInt('daily_reward_day') ?? 1;
      _lastDailyRewardDate = prefs.getString('last_daily_reward_date') ?? '';
      _lastFreeSpinTime = prefs.getInt('last_free_spin_time') ?? 0;

      _bestScore = prefs.getInt('best_score') ?? 0;
      _lifetimeScore = prefs.getInt('lifetime_score') ?? 0;
      _totalLinesCleared = prefs.getInt('total_lines_cleared') ?? 0;

      _soundEnabled = prefs.getBool('sfx_enabled') ?? true;
      _musicEnabled = prefs.getBool('bgm_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('gold_fish', _goldFish);
      await prefs.setInt('silver_fish', _silverFish);
      await prefs.setString('selected_character', _selectedCharacter);
      await prefs.setStringList('unlocked_characters', _unlockedCharacters.toList());

      await prefs.setInt('booster_hammer', _hammerCount);
      await prefs.setInt('booster_magnet', _magnetCount);
      await prefs.setInt('booster_wand', _wandCount);

      await prefs.setInt('daily_reward_day', _dailyRewardDay);
      await prefs.setString('last_daily_reward_date', _lastDailyRewardDate);
      await prefs.setInt('last_free_spin_time', _lastFreeSpinTime);

      await prefs.setInt('best_score', _bestScore);
      await prefs.setInt('lifetime_score', _lifetimeScore);
      await prefs.setInt('total_lines_cleared', _totalLinesCleared);

      await prefs.setBool('sfx_enabled', _soundEnabled);
      await prefs.setBool('bgm_enabled', _musicEnabled);
      await prefs.setBool('vibration_enabled', _vibrationEnabled);
    } catch (_) {}
  }

  // Currency Operations
  void addGoldFish(int amount) {
    _goldFish += amount;
    _save();
    notifyListeners();
  }

  bool spendGoldFish(int amount) {
    if (_goldFish < amount) return false;
    _goldFish -= amount;
    _save();
    notifyListeners();
    return true;
  }

  void addSilverFish(int amount) {
    _silverFish += amount;
    _save();
    notifyListeners();
  }

  bool spendSilverFish(int amount) {
    if (_silverFish < amount) return false;
    _silverFish -= amount;
    _save();
    notifyListeners();
    return true;
  }

  // Booster Operations
  int getBoosterCount(String boosterType) {
    switch (boosterType) {
      case 'hammer':
        return _hammerCount;
      case 'magnet':
        return _magnetCount;
      case 'wand':
        return _wandCount;
      default:
        return 0;
    }
  }

  void addBooster(String boosterType, int count) {
    switch (boosterType) {
      case 'hammer':
        _hammerCount += count;
        break;
      case 'magnet':
        _magnetCount += count;
        break;
      case 'wand':
        _wandCount += count;
        break;
    }
    _save();
    notifyListeners();
  }

  bool useBooster(String boosterType) {
    switch (boosterType) {
      case 'hammer':
        if (_hammerCount <= 0) return false;
        _hammerCount--;
        break;
      case 'magnet':
        if (_magnetCount <= 0) return false;
        _magnetCount--;
        break;
      case 'wand':
        if (_wandCount <= 0) return false;
        _wandCount--;
        break;
      default:
        return false;
    }
    _save();
    notifyListeners();
    return true;
  }

  // Character Operations
  bool unlockCharacter(String id) {
    final char = allCharacters.firstWhere((c) => c.id == id, orElse: () => allCharacters.first);
    if (_unlockedCharacters.contains(id)) return true;
    if (spendGoldFish(char.unlockCostGold)) {
      _unlockedCharacters.add(id);
      _selectedCharacter = id;
      _save();
      notifyListeners();
      return true;
    }
    return false;
  }

  void selectCharacter(String id) {
    if (_unlockedCharacters.contains(id)) {
      _selectedCharacter = id;
      _save();
      notifyListeners();
    }
  }

  // Daily Reward Operations
  bool canClaimDailyReward() {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return _lastDailyRewardDate != todayStr;
  }

  Map<String, int> claimDailyReward() {
    if (!canClaimDailyReward()) return {};

    final now = DateTime.now();
    _lastDailyRewardDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final dayRewards = [
      {'silver': 100, 'gold': 0},
      {'silver': 150, 'gold': 2},
      {'silver': 200, 'gold': 0, 'hammer': 1},
      {'silver': 250, 'gold': 5},
      {'silver': 300, 'gold': 0, 'magnet': 1},
      {'silver': 350, 'gold': 5, 'wand': 1},
      {'silver': 500, 'gold': 15, 'hammer': 2, 'magnet': 2, 'wand': 2},
    ];

    final reward = dayRewards[(_dailyRewardDay - 1).clamp(0, 6)];

    if (reward.containsKey('silver')) addSilverFish(reward['silver']!);
    if (reward.containsKey('gold')) addGoldFish(reward['gold']!);
    if (reward.containsKey('hammer')) addBooster('hammer', reward['hammer']!);
    if (reward.containsKey('magnet')) addBooster('magnet', reward['magnet']!);
    if (reward.containsKey('wand')) addBooster('wand', reward['wand']!);

    _dailyRewardDay = (_dailyRewardDay % 7) + 1;
    _save();
    notifyListeners();
    return reward;
  }

  // Lucky Spin Operations
  bool canFreeSpin() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - _lastFreeSpinTime) > (2 * 60 * 60 * 1000);
  }

  Duration getSpinCooldownRemaining() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = now - _lastFreeSpinTime;
    final remainingMs = (2 * 60 * 60 * 1000) - elapsed;
    if (remainingMs <= 0) return Duration.zero;
    return Duration(milliseconds: remainingMs);
  }

  void recordSpin() {
    _lastFreeSpinTime = DateTime.now().millisecondsSinceEpoch;
    _save();
    notifyListeners();
  }

  // Stats
  void recordGameEnd({required int score, required int linesCleared, required int silverEarned}) {
    if (score > _bestScore) {
      _bestScore = score;
    }
    _lifetimeScore += score;
    _totalLinesCleared += linesCleared;
    addSilverFish(silverEarned);
    _save();
    notifyListeners();
  }

  // Settings
  void toggleSound() {
    _soundEnabled = !_soundEnabled;
    _save();
    notifyListeners();
  }

  void toggleMusic() {
    _musicEnabled = !_musicEnabled;
    _save();
    notifyListeners();
  }

  void toggleVibration() {
    _vibrationEnabled = !_vibrationEnabled;
    _save();
    notifyListeners();
  }
}
