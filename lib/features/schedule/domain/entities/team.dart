class Team {
  final String id;
  final String name;
  final String logoPath;
  final String league;

  const Team({
    required this.id,
    required this.name,
    required this.logoPath,
    required this.league,
  });

  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      logoPath: map['logoPath'] as String? ?? '',
      league: map['league'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() =>
      {'id': id, 'name': name, 'logoPath': logoPath, 'league': league};
}
