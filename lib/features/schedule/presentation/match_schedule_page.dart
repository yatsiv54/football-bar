import '../../../core/di/injection.dart';
import '../../../core/theme/colors.dart';
import '../../layout/custom_appbar.dart';
import '../../layout/side_nav.dart';
import '../data/schedule_repository.dart';
import '../domain/entities/match_schedule.dart';
import '../domain/entities/team.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MatchSchedulePage extends StatefulWidget {
  const MatchSchedulePage({super.key});

  @override
  State<MatchSchedulePage> createState() => _MatchSchedulePageState();
}

class _MatchSchedulePageState extends State<MatchSchedulePage> {
  final ScheduleRepository _repository = getIt<ScheduleRepository>();
  SportType _sport = SportType.football;
  String _league = '';
  Map<SportType, List<String>> _leagues = const {};
  DateTime _selectedDate = DateTime.now();
  Future<List<MatchSchedule>>? _future;
  bool _initDone = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final leaguesFootball = await _repository.getLeagues(SportType.football);
    final leaguesHockey = await _repository.getLeagues(SportType.hockey);
    setState(() {
      _leagues = {
        SportType.football: leaguesFootball,
        SportType.hockey: leaguesHockey,
      };
      _league = _leagues[_sport]!.first;
      _future = _repository.getMatchesForDate(_selectedDate, sport: _sport);
      _initDone = true;
    });
  }

  void _load() {
    _future = _repository.getMatchesForDate(_selectedDate, sport: _sport);
    setState(() {});
  }

  Future<void> _clearCache() async {
    await _repository.clearScheduleCache();
    _load();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Schedule cache cleared')));
    }
  }

  void _onSportChanged(SportType? sport) {
    if (sport == null) return;
    setState(() {
      _sport = sport;
      _league = _leagues[sport]!.first;
      _load();
    });
  }

  void _onLeagueChanged(String? league) {
    if (league == null) return;
    setState(() => _league = league);
  }

  void _onDateQuick(int days) {
    setState(() {
      _selectedDate = DateTime.now().add(Duration(days: days));
      _load();
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      initialDate: _selectedDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: MyColors.primaryBlue,
              surface: MyColors.bgSecondary,
              onSurface: Colors.white,
              onPrimary: Colors.white,
              secondary: MyColors.primaryBlue,
              onSecondary: Colors.white,
              error: Colors.red,
              onError: Colors.white,
            ),
          ),
          child: child ?? const SizedBox(),
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _load();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initDone) {
      return const Scaffold(
        backgroundColor: MyColors.bgPrimary,
        body: Center(
          child: CircularProgressIndicator(color: MyColors.primaryBlue),
        ),
      );
    }

    return Scaffold(
      backgroundColor: MyColors.bgPrimary,
      appBar: CustomAppbar(
        leading: const SideNavButton(active: SideNavSection.schedule),
        title: Text(
          'Match schedule',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 26,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: SizedBox(
                    child: _DropField<SportType>(
                      label: 'Sport',
                      value: _sport,
                      items: SportType.values,
                      display: (s) => s.name,
                      onChanged: _onSportChanged,
                    ),
                  ),
                ),

                Expanded(
                  child: SizedBox(
                    child: _DropField<String>(
                      label: 'League',
                      value: _league,
                      items: _leagues[_sport]!,
                      display: (s) => s,
                      onChanged: _onLeagueChanged,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: MediaQuery.of(context).size.width / 2 - 24,
              child: _DateDropdown(
                selected: _selectedDate,
                onToday: () => _onDateQuick(0),
                onTomorrow: () => _onDateQuick(1),
                onPickDate: _pickDate,
              ),
            ),
            const SizedBox(height: 60),
            Expanded(
              child: FutureBuilder<List<MatchSchedule>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: MyColors.primaryBlue,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Failed to load schedule',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    );
                  }
                  final matches = (snapshot.data ?? [])
                      .where((m) => m.league == _league)
                      .toList();
                  if (matches.isEmpty) {
                    return Center(
                      child: Text(
                        'No matches found for your filters.',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: MyColors.primaryGrey,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: matches.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _MatchCard(match: matches[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropField<T> extends StatefulWidget {
  const _DropField({
    required this.label,
    required this.value,
    required this.items,
    required this.display,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T) display;
  final ValueChanged<T?> onChanged;

  @override
  State<_DropField<T>> createState() => _DropFieldState<T>();
}

class _DropFieldState<T> extends State<_DropField<T>> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium!.copyWith(color: MyColors.primaryGrey),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: PopupMenuButton<T>(
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth,
                  maxWidth: constraints.maxWidth,
                ),
                color: Colors.white,
                onOpened: () => setState(() => _open = true),
                onCanceled: () => setState(() => _open = false),
                onSelected: (value) {
                  setState(() => _open = false);
                  widget.onChanged(value);
                },
                offset: const Offset(0, 30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
                itemBuilder: (context) => widget.items
                    .map(
                      (e) => PopupMenuItem<T>(
                        value: e,
                        child: SizedBox(
                          width: constraints.maxWidth - 16,
                          child: Text(
                            widget.display(e),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.display(widget.value),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.black, fontSize: 14),
                        ),
                      ),
                      Icon(
                        _open
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: MyColors.primaryBlue,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _DateDropdown extends StatelessWidget {
  const _DateDropdown({
    required this.selected,
    required this.onToday,
    required this.onTomorrow,
    required this.onPickDate,
  });

  final DateTime selected;
  final VoidCallback onToday;
  final VoidCallback onTomorrow;
  final Future<void> Function() onPickDate;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEE, dd MMM');
    final currentLabel = fmt.format(selected);
    final items = ['Today', 'Tomorrow', currentLabel, 'Pick date'];

    return _DropField<String>(
      label: 'Date',
      value: currentLabel,
      items: items,
      display: (s) => s,
      onChanged: (value) async {
        switch (value) {
          case 'Today':
            onToday();
            break;
          case 'Tomorrow':
            onTomorrow();
            break;
          case 'Pick date':
            await onPickDate();
            break;
          default:
            break;
        }
      },
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match});

  final MatchSchedule match;

  @override
  Widget build(BuildContext context) {
    final fmtDate = DateFormat('EEE dd MMM');
    final fmtTime = DateFormat('HH:mm');
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 30),
      decoration: BoxDecoration(
        color: MyColors.bgSecondary,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Stack(
        children: [
          Positioned(right: 0, child: _ScreenBadge(screen: match.screen)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _LogoPair(home: match.home, away: match.away),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      '${fmtDate.format(match.dateTime)} · ${fmtTime.format(match.dateTime)}',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: MyColors.primaryGrey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      overflow: TextOverflow.ellipsis,
                      '${match.home.name} vs ${match.away.name}',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 21,
                        color: MyColors.primaryLightBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LogoPair extends StatelessWidget {
  const _LogoPair({required this.home, required this.away});

  final Team home;
  final Team away;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _TeamLogo(team: home, size: 54),
          Positioned(left: 37, top: 25, child: _TeamLogo(team: away, size: 54)),
        ],
      ),
    );
  }
}

class _TeamLogo extends StatelessWidget {
  const _TeamLogo({required this.team, required this.size});

  final Team team;
  final double size;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: MyColors.bgElevated,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          team.name.characters.first,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );

    if (team.logoPath.isEmpty) return placeholder;

    return ClipOval(
      child: Image.asset(
        team.logoPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  }
}

class _ScreenBadge extends StatelessWidget {
  const _ScreenBadge({required this.screen});

  final String screen;

  @override
  Widget build(BuildContext context) {
    final isMain = screen.toLowerCase() == 'main';
    final color = MyColors.bgElevated;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: BoxBorder.all(
          width: 0.3,
          color: isMain ? MyColors.success : Color(0xFFFF9A3E),
        ),
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isMain ? 'Main' : 'Side',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
