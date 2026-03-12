import 'team.dart';

enum SportType { football, hockey }

class MatchSchedule {
  final SportType sport;
  final Team home;
  final Team away;
  final String league;
  final DateTime dateTime;
  final String screen;
  final List<GoalEvent> goals;

  const MatchSchedule({
    required this.sport,
    required this.home,
    required this.away,
    required this.league,
    required this.dateTime,
    required this.screen,
    this.goals = const [],
  });

  Map<String, dynamic> toMap() => {
        'sport': sport.name,
        'home': home.toMap(),
        'away': away.toMap(),
        'league': league,
        'dateTime': dateTime.toIso8601String(),
        'screen': screen,
        'goals': goals.map((g) => g.toMap()).toList(),
      };

  factory MatchSchedule.fromMap(Map<String, dynamic> map) {
    return MatchSchedule(
      sport: SportType.values.firstWhere(
        (s) => s.name == map['sport'],
        orElse: () => SportType.football,
      ),
      home: Team.fromMap(map['home'] as Map<String, dynamic>),
      away: Team.fromMap(map['away'] as Map<String, dynamic>),
      league: map['league'] as String? ?? '',
      dateTime: DateTime.parse(map['dateTime'] as String),
      screen: map['screen'] as String? ?? 'main',
      goals: (map['goals'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(GoalEvent.fromMap)
          .toList(),
    );
  }
}

class GoalEvent {
  final int minute;
  final String teamId;

  const GoalEvent({required this.minute, required this.teamId});

  Map<String, dynamic> toMap() => {'minute': minute, 'teamId': teamId};

  factory GoalEvent.fromMap(Map<String, dynamic> map) => GoalEvent(
        minute: (map['minute'] as num?)?.toInt() ?? 0,
        teamId: map['teamId'] as String? ?? '',
      );
}
