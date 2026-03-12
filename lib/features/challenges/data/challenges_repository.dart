import 'dart:convert';
import 'dart:math';

import '../../menu/data/menu_repository.dart';
import '../../menu/domain/entities/cart_entry.dart';
import '../../schedule/data/schedule_repository.dart';
import '../../schedule/domain/entities/match_schedule.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChallengeState {
  final int totalPoints;
  final int completed;
  final DailyChallengeState? daily;
  final List<FoodChallengeState> food;
  final List<MatchChallengeState> matchChallenges;

  const ChallengeState({
    required this.totalPoints,
    required this.completed,
    this.daily,
    this.food = const [],
    this.matchChallenges = const [],
  });

  ChallengeState copyWith({
    int? totalPoints,
    int? completed,
    DailyChallengeState? daily,
    List<FoodChallengeState>? food,
    List<MatchChallengeState>? matchChallenges,
  }) {
    return ChallengeState(
      totalPoints: totalPoints ?? this.totalPoints,
      completed: completed ?? this.completed,
      daily: daily ?? this.daily,
      food: food ?? this.food,
      matchChallenges: matchChallenges ?? this.matchChallenges,
    );
  }
}

class DailyChallengeState {
  final MatchSchedule match;
  final String? selectedTeamId;
  final String? winnerTeamId;
  final DateTime expiresAt;
  final int reward;
  final DateTime? betPlacedAt;

  const DailyChallengeState({
    required this.match,
    required this.expiresAt,
    required this.reward,
    this.selectedTeamId,
    this.winnerTeamId,
    this.betPlacedAt,
  });

  bool get resolved => winnerTeamId != null;

  DailyChallengeState copyWith({
    MatchSchedule? match,
    String? selectedTeamId,
    String? winnerTeamId,
    DateTime? expiresAt,
    int? reward,
    DateTime? betPlacedAt,
  }) {
    return DailyChallengeState(
      match: match ?? this.match,
      selectedTeamId: selectedTeamId ?? this.selectedTeamId,
      winnerTeamId: winnerTeamId ?? this.winnerTeamId,
      expiresAt: expiresAt ?? this.expiresAt,
      reward: reward ?? this.reward,
      betPlacedAt: betPlacedAt ?? this.betPlacedAt,
    );
  }
}

enum FoodChallengeStatus { pending, accepted, completed, expired }

class FoodChallengeState {
  final String id;
  final FoodChallengeStatus status;
  final DateTime? acceptedAt;
  final DateTime resolveAt;
  final int reward;

  const FoodChallengeState({
    required this.id,
    required this.status,
    required this.resolveAt,
    required this.reward,
    this.acceptedAt,
  });

  FoodChallengeState copyWith({
    FoodChallengeStatus? status,
    DateTime? acceptedAt,
    DateTime? resolveAt,
    int? reward,
  }) {
    return FoodChallengeState(
      id: id,
      status: status ?? this.status,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      resolveAt: resolveAt ?? this.resolveAt,
      reward: reward ?? this.reward,
    );
  }

  static final empty = FoodChallengeState(
    id: '',
    status: FoodChallengeStatus.pending,
    resolveAt: DateTime.fromMillisecondsSinceEpoch(0),
    reward: 0,
  );
}

enum MatchChallengeStatus { pending, accepted, completed, expired }

class MatchChallengeState {
  final String id;
  final MatchSchedule match;
  final String? selectedTeamId;
  final bool? userWon;
  final MatchChallengeStatus status;
  final DateTime resolveAt;
  final int reward;

  const MatchChallengeState({
    required this.id,
    required this.match,
    required this.status,
    required this.resolveAt,
    required this.reward,
    this.selectedTeamId,
    this.userWon,
  });

  MatchChallengeState copyWith({
    MatchChallengeStatus? status,
    String? selectedTeamId,
    bool? userWon,
    DateTime? resolveAt,
    int? reward,
  }) {
    return MatchChallengeState(
      id: id,
      match: match,
      status: status ?? this.status,
      resolveAt: resolveAt ?? this.resolveAt,
      reward: reward ?? this.reward,
      selectedTeamId: selectedTeamId ?? this.selectedTeamId,
      userWon: userWon ?? this.userWon,
    );
  }

  static MatchChallengeState empty(MatchSchedule match) => MatchChallengeState(
        id: '',
        match: match,
        status: MatchChallengeStatus.pending,
        resolveAt: DateTime.fromMillisecondsSinceEpoch(0),
        reward: 0,
      );
}

class ChallengesRepository {
  ChallengesRepository({
    SharedPreferences? prefs,
    ScheduleRepository? scheduleRepository,
    MenuRepository? menuRepository,
  })  : _prefs = prefs,
        _scheduleRepository = scheduleRepository ?? ScheduleRepository(),
        _menuRepository = menuRepository ?? AssetsMenuRepository();

  static const _pointsKey = 'challenges_points';
  static const _completedKey = 'challenges_completed';
  static const _dailyKey = 'challenges_daily';
  static const _foodKey = 'challenges_food';
  static const _matchKey = 'challenges_match';
  static const _dailyReward = 10;

  static const comboChallengeId = 'combo_drink_snack';
  static const mainsChallengeId = 'dessert_item'; 
  static const dessertSecondHalfId = 'dessert_second_half';
  static const matchCleanSheetId = 'match_clean_sheet';
  static const matchComebackId = 'match_comeback';
  static const _mainsCategoryId = 'mains';
  static const _drinksCategoryId = 'drinks';
  static const _snacksCategoryId = 'snacks';
  static const _dessertsCategoryId = 'desserts';

  final SharedPreferences? _prefs;
  final ScheduleRepository _scheduleRepository;
  final MenuRepository _menuRepository;

  Map<String, String>? _menuCategoryIndex;
  List<_FoodRule>? _rules;
  final Random _rnd = Random();

  Future<ChallengeState> loadState() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    var total = prefs.getInt(_pointsKey) ?? 0;
    var completed = prefs.getInt(_completedKey) ?? 0;
    final dailyRaw = prefs.getString(_dailyKey);
    final foodRaw = prefs.getString(_foodKey);
    final matchRaw = prefs.getString(_matchKey);
    DailyChallengeState? daily;
    var foodStates = <FoodChallengeState>[];
    var matchStates = <MatchChallengeState>[];

    if (dailyRaw != null) {
      try {
        final map = json.decode(dailyRaw) as Map<String, dynamic>;
        daily = _dailyFromMap(map);
      } catch (_) {
        daily = null;
      }
    }

    if (foodRaw != null) {
      try {
        foodStates = (json.decode(foodRaw) as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map(_foodFromMap)
            .toList();
      } catch (_) {
        foodStates = [];
      }
    }

    if (matchRaw != null) {
      try {
        matchStates = (json.decode(matchRaw) as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map(_matchFromMap)
            .toList();
      } catch (_) {
        matchStates = [];
      }
    }

    daily = _resolveDailyIfNeeded(daily, DateTime.now(), prefs);
    total = _lastTotal;
    completed = _lastCompleted;

    final now = DateTime.now();
    bool foodChanged = false;
    foodStates = foodStates.map((f) {
      if (f.status == FoodChallengeStatus.accepted && now.isAfter(f.resolveAt)) {
        foodChanged = true;
        return f.copyWith(status: FoodChallengeStatus.expired);
      }
      return f;
    }).toList();
    if (foodChanged) {
      await _saveFood(prefs, foodStates);
    }

    bool matchChanged = false;
    matchStates = matchStates.map((m) {
      if (m.status == MatchChallengeStatus.accepted &&
          now.isAfter(m.resolveAt)) {
        final userWon = _evaluateMatchChallenge(m);
        if (userWon) {
          total += m.reward;
          completed += 1;
        }
        matchChanged = true;
        return m.copyWith(
          status: MatchChallengeStatus.completed,
          userWon: userWon,
        );
      }
      return m;
    }).toList();

    if (matchChanged) {
      await _saveMatch(prefs, matchStates);
      await _save(prefs, total, completed, daily);
    }

    final today = DateTime.now();
    if (daily == null ||
        daily.match.dateTime.year != today.year ||
        daily.match.dateTime.month != today.month ||
        daily.match.dateTime.day != today.day) {
      daily = await _createDaily();
      await _save(prefs, total, completed, daily);
    }

    return ChallengeState(
      totalPoints: total,
      completed: completed,
      daily: daily,
      food: foodStates,
      matchChallenges: matchStates,
    );
  }

  Future<ChallengeState> selectTeam(String teamId) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final state = await loadState();
    final current = state.daily;
    if (current == null || current.resolved) return state;

    final updatedDaily =
        current.copyWith(selectedTeamId: teamId, betPlacedAt: DateTime.now());
    await _save(prefs, state.totalPoints, state.completed, updatedDaily);
    return state.copyWith(daily: updatedDaily);
  }

  bool _evaluateMatchChallenge(MatchChallengeState m) {
    if (m.selectedTeamId == null) return false;
    switch (m.id) {
      case matchCleanSheetId:
        return _isCleanSheetWin(m.match, m.selectedTeamId!);
      case matchComebackId:
        return _isComebackWin(m.match, m.selectedTeamId!);
      default:
        return false;
    }
  }

  bool _isCleanSheetWin(MatchSchedule match, String teamId) {
    final oppId =
        match.home.id == teamId ? match.away.id : match.home.id;
    final oppGoals =
        match.goals.where((g) => g.teamId == oppId).length;
    return oppGoals == 0;
  }

  bool _isComebackWin(MatchSchedule match, String teamId) {
    final goals = [...match.goals]..sort((a, b) => a.minute.compareTo(b.minute));
    int teamScore = 0;
    int oppScore = 0;
    for (final g in goals) {
      if (g.teamId == teamId) {
        if (teamScore < oppScore) {
          return true; 
        }
        teamScore++;
      } else {
        oppScore++;
      }
    }
    return false;
  }

  Future<ChallengeState> acceptFoodCombo() => _acceptChallenge(comboChallengeId, 7);

  Future<ChallengeState> acceptDessertSecondHalf(int reward) =>
      _acceptChallenge(dessertSecondHalfId, reward);

  Future<ChallengeState> acceptFoodSpecials(int reward) =>
      _acceptChallenge(mainsChallengeId, reward);

  Future<MatchSchedule?> fetchTodayMatchCandidate() async {
    final today = DateTime.now();
    final matchesFootball =
        await _scheduleRepository.getMatchesForDate(today, sport: SportType.football);
    final matchesHockey =
        await _scheduleRepository.getMatchesForDate(today, sport: SportType.hockey);
    final all = [...matchesFootball, ...matchesHockey];
    if (all.isEmpty) return null;
    return all[_rnd.nextInt(all.length)];
  }

  Future<List<MatchSchedule>> fetchTodayMatchCandidates(int count) async {
    final today = DateTime.now();
    final matchesFootball =
        await _scheduleRepository.getMatchesForDate(today, sport: SportType.football);
    final matchesHockey =
        await _scheduleRepository.getMatchesForDate(today, sport: SportType.hockey);
    final all = [...matchesFootball, ...matchesHockey];
    all.shuffle(_rnd);
    if (all.length <= count) return all;
    return all.take(count).toList();
  }

  Future<ChallengeState> acceptMatchCleanSheet(
    MatchSchedule match,
    String teamId,
  ) async {
    return _acceptMatch(matchCleanSheetId, match, teamId, 20);
  }

  Future<ChallengeState> acceptMatchComeback(
    MatchSchedule match,
    String teamId,
  ) async {
    return _acceptMatch(matchComebackId, match, teamId, 20);
  }

  Future<ChallengeState> _acceptMatch(
    String id,
    MatchSchedule match,
    String teamId,
    int reward,
  ) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    var state = await loadState();
    final resolveAt = match.dateTime.add(const Duration(minutes: 90));
    final newState = MatchChallengeState(
      id: id,
      match: match,
      status: MatchChallengeStatus.accepted,
      selectedTeamId: teamId,
      resolveAt: resolveAt,
      reward: reward,
      userWon: null,
    );
    final list = _replaceMatch(state.matchChallenges, newState);
    await _saveMatch(prefs, list);
    return state.copyWith(matchChallenges: list);
  }

  Future<ChallengeState> evaluateOrder(
    List<CartEntry> entries,
    DateTime orderTime,
  ) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    var state = await loadState();
    await _ensureMenuIndex();
    _ensureRules();

    var total = state.totalPoints;
    var completed = state.completed;
    var foodStates = [...state.food];

    for (final rule in _rules!) {
      final current = foodStates.firstWhere(
        (f) => f.id == rule.id,
        orElse: () => FoodChallengeState.empty,
      );
      if (current.id.isEmpty || current.status != FoodChallengeStatus.accepted) continue;
      if (rule.requiresDaily && state.daily == null) continue;

      final ctx = _FoodContext(
        entries: entries,
        orderTime: orderTime,
        daily: state.daily,
        menuCategories: _menuCategoryIndex ?? {},
        acceptedState: current,
      );

      if (rule.isExpired(ctx)) {
        final updated = current.copyWith(status: FoodChallengeStatus.expired);
        foodStates = _replaceFood(foodStates, updated);
        continue;
      }

      if (rule.isCompleted(ctx)) {
        final updated = current.copyWith(status: FoodChallengeStatus.completed);
        foodStates = _replaceFood(foodStates, updated);
        total += current.reward;
        completed += 1;
      }
    }

    await _save(prefs, total, completed, state.daily);
    await _saveFood(prefs, foodStates);

    return state.copyWith(
      totalPoints: total,
      completed: completed,
      food: foodStates,
    );
  }

  Future<DailyChallengeState?> _createDaily() async {
    final now = DateTime.now();
    final matchesFootball =
        await _scheduleRepository.getMatchesForDate(now, sport: SportType.football);
    final matchesHockey =
        await _scheduleRepository.getMatchesForDate(now, sport: SportType.hockey);

    final all = [...matchesFootball, ...matchesHockey];
    if (all.isEmpty) return null;

    all.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final match = all.first;
    final expires = match.dateTime.add(const Duration(minutes: 45));

    return DailyChallengeState(
      match: match,
      expiresAt: expires,
      reward: _dailyReward,
    );
  }

  Future<void> _save(
    SharedPreferences prefs,
    int total,
    int completed,
    DailyChallengeState? daily,
  ) async {
    await prefs.setInt(_pointsKey, total);
    await prefs.setInt(_completedKey, completed);
    if (daily == null) {
      await prefs.remove(_dailyKey);
    } else {
      await prefs.setString(_dailyKey, json.encode(_dailyToMap(daily)));
    }
  }

  Map<String, dynamic> _dailyToMap(DailyChallengeState daily) => {
        'match': daily.match.toMap(),
        'selectedTeamId': daily.selectedTeamId,
        'winnerTeamId': daily.winnerTeamId,
        'expiresAt': daily.expiresAt.toIso8601String(),
        'resolveAt': daily.expiresAt.toIso8601String(),
        'reward': daily.reward,
        'betPlacedAt': daily.betPlacedAt?.toIso8601String(),
      };

  DailyChallengeState _dailyFromMap(Map<String, dynamic> map) {
    final match = MatchSchedule.fromMap(map['match'] as Map<String, dynamic>);
    final resolveRaw =
        map['resolveAt'] as String? ?? map['expiresAt'] as String? ?? '';
    final expires = DateTime.tryParse(resolveRaw) ??
        DateTime.tryParse(map['expiresAt'] as String? ?? '') ??
        match.dateTime.add(const Duration(minutes: 45));
    return DailyChallengeState(
      match: match,
      selectedTeamId: map['selectedTeamId'] as String?,
      winnerTeamId: map['winnerTeamId'] as String?,
      expiresAt: expires,
      reward: (map['reward'] as num?)?.toInt() ?? _dailyReward,
      betPlacedAt: DateTime.tryParse(map['betPlacedAt'] as String? ?? ''),
    );
  }

  int _lastTotal = 0;
  int _lastCompleted = 0;

  DailyChallengeState? _resolveDailyIfNeeded(
    DailyChallengeState? daily,
    DateTime now,
    SharedPreferences prefs,
  ) {
    _lastTotal = prefs.getInt(_pointsKey) ?? 0;
    _lastCompleted = prefs.getInt(_completedKey) ?? 0;
    if (daily == null || daily.resolved || daily.selectedTeamId == null) {
      return daily;
    }
    final betTime = daily.betPlacedAt ?? daily.match.dateTime;
    final goals = daily.match.goals;

    DateTime matchEnd = daily.match.dateTime.add(const Duration(minutes: 95));

    if (goals.isEmpty) {
      if (now.isAfter(matchEnd)) {
        final updated = daily.copyWith(winnerTeamId: '');
        _updateScores(updated, prefs);
        return updated;
      }
      return daily;
    }

    GoalEvent? nextGoal;
    for (final g in goals) {
      final goalTime = daily.match.dateTime.add(Duration(minutes: g.minute));
      if (goalTime.isAfter(betTime)) {
        nextGoal = g;
        break;
      }
    }

    if (nextGoal == null) {
      if (now.isAfter(matchEnd)) {
        final updated = daily.copyWith(winnerTeamId: '');
        _updateScores(updated, prefs);
        return updated;
      }
      return daily;
    }

    final goalDate = daily.match.dateTime.add(Duration(minutes: nextGoal.minute));
    if (now.isAfter(goalDate)) {
      final updated = daily.copyWith(winnerTeamId: nextGoal.teamId);
      _updateScores(updated, prefs);
      return updated;
    }

    return daily;
  }

  Future<void> _updateScores(
    DailyChallengeState daily,
    SharedPreferences prefs,
  ) async {
    if (daily.selectedTeamId != null && daily.selectedTeamId == daily.winnerTeamId) {
      _lastTotal += _dailyReward;
      _lastCompleted += 1;
    }
    await _save(prefs, _lastTotal, _lastCompleted, daily);
  }
  Future<void> clearAll() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.remove(_pointsKey);
    await prefs.remove(_completedKey);
    await prefs.remove(_dailyKey);
    await prefs.remove(_foodKey);
    await prefs.remove(_matchKey);
  }

  Future<void> _saveFood(SharedPreferences prefs, List<FoodChallengeState> list) async {
    await prefs.setString(
      _foodKey,
      json.encode(list.map(_foodToMap).toList()),
    );
  }

  Future<void> _saveMatch(SharedPreferences prefs, List<MatchChallengeState> list) async {
    await prefs.setString(
      _matchKey,
      json.encode(list.map(_matchToMap).toList()),
    );
  }

  Map<String, dynamic> _foodToMap(FoodChallengeState state) => {
        'id': state.id,
        'status': state.status.name,
        'acceptedAt': state.acceptedAt?.toIso8601String(),
        'resolveAt': state.resolveAt.toIso8601String(),
        'reward': state.reward,
      };

  FoodChallengeState _foodFromMap(Map<String, dynamic> map) {
    final rawId = map['id'] as String? ?? '';
    final normalizedId = rawId == 'specials_item' ? mainsChallengeId : rawId;
    return FoodChallengeState(
      id: normalizedId,
      status: FoodChallengeStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => FoodChallengeStatus.pending,
      ),
      acceptedAt: DateTime.tryParse(map['acceptedAt'] as String? ?? ''),
      resolveAt: DateTime.tryParse(map['resolveAt'] as String? ?? '') ??
          DateTime.now().add(const Duration(minutes: 30)),
      reward: (map['reward'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> _matchToMap(MatchChallengeState state) => {
        'id': state.id,
        'match': state.match.toMap(),
        'selectedTeamId': state.selectedTeamId,
        'userWon': state.userWon,
        'status': state.status.name,
        'resolveAt': state.resolveAt.toIso8601String(),
        'reward': state.reward,
      };

  MatchChallengeState _matchFromMap(Map<String, dynamic> map) {
    final match = MatchSchedule.fromMap(map['match'] as Map<String, dynamic>);
    return MatchChallengeState(
      id: map['id'] as String? ?? '',
      match: match,
      selectedTeamId: map['selectedTeamId'] as String?,
      userWon: map['userWon'] as bool?,
      status: MatchChallengeStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => MatchChallengeStatus.pending,
      ),
      resolveAt: DateTime.tryParse(map['resolveAt'] as String? ?? '') ??
          match.dateTime.add(const Duration(minutes: 90)),
      reward: (map['reward'] as num?)?.toInt() ?? 20,
    );
  }

  Future<void> _ensureMenuIndex() async {
    if (_menuCategoryIndex != null) return;
    final categories = await _menuRepository.fetchMenu();
    final map = <String, String>{};
    for (final cat in categories) {
      for (final item in cat.items) {
        map[item.id] = cat.id;
      }
    }
    _menuCategoryIndex = map;
  }

  List<FoodChallengeState> _replaceFood(
    List<FoodChallengeState> list,
    FoodChallengeState updated,
  ) {
    final copy = [...list];
    final idx = copy.indexWhere((f) => f.id == updated.id);
    if (idx >= 0) {
      copy[idx] = updated;
    } else {
      copy.add(updated);
    }
    return copy;
  }

  List<MatchChallengeState> _replaceMatch(
    List<MatchChallengeState> list,
    MatchChallengeState updated,
  ) {
    final copy = [...list];
    final idx = copy.indexWhere((m) => m.id == updated.id);
    if (idx >= 0) {
      copy[idx] = updated;
    } else {
      copy.add(updated);
    }
    return copy;
  }

  Future<ChallengeState> _acceptChallenge(String id, int reward) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    var state = await loadState();
    await _ensureMenuIndex();
    _ensureRules();

    final rule = _rules!.firstWhere((r) => r.id == id);
    if (rule.requiresDaily && state.daily == null) return state;

    final resolve = rule.resolveAt(
      _FoodContext(
        entries: const [],
        orderTime: DateTime.now(),
        daily: state.daily,
        menuCategories: _menuCategoryIndex ?? {},
        acceptedState: FoodChallengeState.empty,
      ),
    );

    final newState = FoodChallengeState(
      id: id,
      status: FoodChallengeStatus.accepted,
      reward: reward,
      acceptedAt: DateTime.now(),
      resolveAt: resolve,
    );

    state = state.copyWith(food: _replaceFood(state.food, newState));
    await _saveFood(prefs, state.food);
    return state;
  }

  void _ensureRules() {
    if (_rules != null) return;
    _rules = [
      _FoodRule(
        id: comboChallengeId,
        requiresDaily: true,
        resolveAt: (ctx) {
          final match = ctx.daily!.match;
          return match.dateTime.add(const Duration(minutes: 90));
        },
        isExpired: (ctx) =>
            ctx.orderTime.isAfter(ctx.daily!.match.dateTime.add(const Duration(minutes: 90))),
        isCompleted: (ctx) {
          final hasDrink = ctx.entries
              .any((e) => ctx.menuCategories[e.item.id] == _drinksCategoryId && e.quantity > 0);
          final hasSnack = ctx.entries
              .any((e) => ctx.menuCategories[e.item.id] == _snacksCategoryId && e.quantity > 0);
          return hasDrink && hasSnack;
        },
      ),
      _FoodRule(
        id: mainsChallengeId,
        requiresDaily: false,
        resolveAt: (ctx) => ctx.orderTime.add(const Duration(days: 1)),
        isExpired: (ctx) => ctx.orderTime.isAfter(ctx.acceptedState.resolveAt),
        isCompleted: (ctx) => ctx.entries
            .any((e) => ctx.menuCategories[e.item.id] == _mainsCategoryId && e.quantity > 0),
      ),
      _FoodRule(
        id: dessertSecondHalfId,
        requiresDaily: true,
        resolveAt: (ctx) {
          final match = ctx.daily!.match;
          return match.dateTime.add(const Duration(minutes: 90));
        },
        isExpired: (ctx) =>
            ctx.orderTime.isAfter(ctx.daily!.match.dateTime.add(const Duration(minutes: 90))),
        isCompleted: (ctx) {
          final match = ctx.daily!.match;
          final secondHalf = match.dateTime.add(const Duration(minutes: 45));
          final matchEnd = match.dateTime.add(const Duration(minutes: 90));
          final t = ctx.orderTime;
          final inWindow = t.isAfter(secondHalf) && !t.isAfter(matchEnd);
          final hasDessert = ctx.entries.any(
            (e) => ctx.menuCategories[e.item.id] == _dessertsCategoryId && e.quantity > 0,
          );
          return inWindow && hasDessert;
        },
      ),
    ];
  }
}

class _FoodRule {
  final String id;
  final bool requiresDaily;
  final DateTime Function(_FoodContext ctx) resolveAt;
  final bool Function(_FoodContext ctx) isCompleted;
  final bool Function(_FoodContext ctx) isExpired;

  _FoodRule({
    required this.id,
    required this.resolveAt,
    required this.isCompleted,
    required this.isExpired,
    this.requiresDaily = false,
  });
}

class _FoodContext {
  final List<CartEntry> entries;
  final DateTime orderTime;
  final DailyChallengeState? daily;
  final Map<String, String> menuCategories;
  final FoodChallengeState acceptedState;

  _FoodContext({
    required this.entries,
    required this.orderTime,
    required this.daily,
    required this.menuCategories,
    required this.acceptedState,
  });
}
