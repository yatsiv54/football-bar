import 'dart:convert';
import 'dart:math';

import '../domain/entities/match_schedule.dart';
import '../domain/entities/team.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScheduleRepository {
  ScheduleRepository({SharedPreferences? prefs, AssetBundle? bundle})
      : _prefs = prefs,
        _bundle = bundle;

  final SharedPreferences? _prefs;
  final AssetBundle? _bundle;

  static const _teamsAsset = 'assets/data/teams.json';
  static const _leaguesBySport = {
    SportType.football: ['Premier League', 'La Liga'],
    SportType.hockey: ['NHL', 'KHL'],
  };

  Map<SportType, List<Team>>? _teamsCache;
  Map<SportType, List<String>>? _leaguesCache;

  Future<void> clearScheduleCache() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final keysToRemove =
        prefs.getKeys().where((k) => k.startsWith('schedule_')).toList();
    for (final k in keysToRemove) {
      await prefs.remove(k);
    }
  }

  Future<Map<SportType, List<Team>>> _loadTeams() async {
    if (_teamsCache != null) return _teamsCache!;
    final bundle = _bundle ?? rootBundle;
    final raw = await bundle.loadString(_teamsAsset);
    final decoded = json.decode(raw) as Map<String, dynamic>;
    final football = (decoded['football'] as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(Team.fromMap)
        .toList();
    final hockey = (decoded['hockey'] as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(Team.fromMap)
        .toList();
    _teamsCache = {
      SportType.football: football,
      SportType.hockey: hockey,
    };
    _leaguesCache = {
      SportType.football:
          (decoded['footballLeagues'] as List<dynamic>?)?.cast<String>() ??
              _leaguesBySport[SportType.football]!,
      SportType.hockey:
          (decoded['hockeyLeagues'] as List<dynamic>?)?.cast<String>() ??
              _leaguesBySport[SportType.hockey]!,
    };
    return _teamsCache!;
  }

  Future<List<String>> getLeagues(SportType sport) async {
    if (_leaguesCache == null) {
      await _loadTeams();
    }
    return _leaguesCache?[sport] ?? _leaguesBySport[sport]!;
  }

  Future<List<MatchSchedule>> getMatchesForDate(
    DateTime date, {
    required SportType sport,
  }) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final key = _keyFor(sport, date);
    final now = DateTime.now();
    final isToday = now.year == date.year &&
        now.month == date.month &&
        now.day == date.day;
    final existing = prefs.getString(key);
    if (existing != null) {
      var list = (json.decode(existing) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(MatchSchedule.fromMap)
          .toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

      if (isToday) {
        list = list.where((m) => m.dateTime.isAfter(now)).toList();
      }

      if (list.isNotEmpty) return list;
    }

    final generated = await _generateMatches(
      date,
      sport: sport,
      minStart: isToday ? now.add(const Duration(minutes: 30)) : null,
    );
    _debugPrintMatches(sport, generated);
    await prefs.setString(
      key,
      json.encode(generated.map((e) => e.toMap()).toList()),
    );
    generated.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return isToday
        ? generated.where((m) => m.dateTime.isAfter(now)).toList()
        : generated;
  }

  String _keyFor(SportType sport, DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return 'schedule_${sport.name}_${day.toIso8601String()}';
  }

  Future<List<MatchSchedule>> _generateMatches(
    DateTime date, {
    required SportType sport,
    DateTime? minStart,
  }) async {
    final teamsBySport = await _loadTeams();
    final leagueList = _leaguesCache?[sport] ?? _leaguesBySport[sport]!;
    final rnd = Random();
    final matches = <MatchSchedule>[];
    final day = DateTime(date.year, date.month, date.day);
    const allowedMinutes = [0, 15, 30, 45];
    for (final league in leagueList) {
      final teamsForLeague = List<Team>.from(
        (teamsBySport[sport] ?? [])
            .where((team) => (team.league.isNotEmpty ? team.league : league) == league),
      )..shuffle(rnd);

      var generated = 0;
      while (teamsForLeague.length >= 2 && generated < 2) {
        final home = teamsForLeague.removeAt(0);
        final away = teamsForLeague.removeAt(0);

        DateTime generateTime() {
          if (minStart != null &&
              minStart.year == day.year &&
              minStart.month == day.month &&
              minStart.day == day.day) {
            final baseHour = (minStart.hour).clamp(8, 22);
            final maxHour = 22;
            final span = (maxHour - baseHour + 1).clamp(1, 8);
            final hour = baseHour + rnd.nextInt(span);
            final minute = allowedMinutes[rnd.nextInt(allowedMinutes.length)];
            return DateTime(day.year, day.month, day.day, hour, minute);
          } else {
            final hour = 12 + rnd.nextInt(10);
            final minute = allowedMinutes[rnd.nextInt(allowedMinutes.length)];
            return DateTime(day.year, day.month, day.day, hour, minute);
          }
        }

        DateTime matchTime = generateTime();
        if (minStart != null) {
          var safety = 0;
          while (!matchTime.isAfter(minStart) && safety < 10) {
            matchTime = matchTime.add(const Duration(minutes: 30));
            safety++;
          }
          if (!matchTime.isAfter(minStart)) {
            matchTime = minStart.add(const Duration(minutes: 30));
          }
        }

        matches.add(
          MatchSchedule(
            sport: sport,
            home: home,
            away: away,
            league: league,
            dateTime: matchTime,
            screen: rnd.nextBool() ? 'main' : 'side',
            goals: _generateGoals(rnd, matchTime, home.id, away.id),
          ),
        );
        generated++;
      }
    }
    return matches;
  }

  List<GoalEvent> _generateGoals(
    Random rnd,
    DateTime matchStart,
    String homeId,
    String awayId,
  ) {
    final goalCount = 1 + rnd.nextInt(5);
    final events = <GoalEvent>[];
    for (int i = 0; i < goalCount; i++) {
      final minute = 1 + rnd.nextInt(89);
      final teamId = rnd.nextBool() ? homeId : awayId;
      events.add(GoalEvent(minute: minute, teamId: teamId));
    }
    events.sort((a, b) => a.minute.compareTo(b.minute));
    return events;
  }

  void _debugPrintMatches(SportType sport, List<MatchSchedule> matches) {
    if (!kDebugMode) return;
    final buffer = StringBuffer();
    buffer.writeln('Generated matches for ${sport.name}: ${matches.length}');
    for (final m in matches) {
      buffer.writeln(
          '- ${m.league} | ${m.home.name} vs ${m.away.name} @ ${m.dateTime.toIso8601String()} screen:${m.screen}');
      if (m.goals.isEmpty) {
        buffer.writeln('  goals: none');
      } else {
        final goals = m.goals
            .map((g) => '${g.teamId} at ${g.minute}m')
            .join(', ');
        buffer.writeln('  goals: $goals');
      }
    }
    debugPrint(buffer.toString());
  }
}
