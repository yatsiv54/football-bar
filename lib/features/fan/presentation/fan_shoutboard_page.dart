import 'dart:async';
import 'dart:math';

import '../../../core/di/injection.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/confirm_button.dart';
import '../../layout/custom_appbar.dart';
import '../../layout/side_nav.dart';
import '../../schedule/data/schedule_repository.dart';
import '../../schedule/domain/entities/match_schedule.dart';
import '../../schedule/domain/entities/team.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class FanShoutboardPage extends StatefulWidget {
  const FanShoutboardPage({super.key});

  @override
  State<FanShoutboardPage> createState() => _FanShoutboardPageState();
}

class _FanShoutboardPageState extends State<FanShoutboardPage> {
  final ScheduleRepository _repository = getIt<ScheduleRepository>();
  final Random _rand = Random();
  late final AudioPlayer _player;

  List<MatchSchedule> _matches = [];
  MatchSchedule? _selectedMatch;
  String? _selectedTeamId;
  int _homeScore = 50;
  int _awayScore = 50;
  final List<String> _feed = [];
  bool _globalCooldown = false;
  bool _loading = true;

  final List<_FanButton> _fanButtons = const [
    _FanButton(id: 'go', label: '⚡ GO!'),
    _FanButton(id: 'lets', label: '🔥 LET\'S GO!'),
    _FanButton(id: 'defense', label: '🛡 DEFENSE!'),
    _FanButton(id: 'noise', label: '📣 MAKE SOME NOISE!'),
    _FanButton(id: 'save', label: '😱 WHAT A SAVE!'),
    _FanButton(id: 'unbelievable', label: '🤯 UNBELIEVABLE!'),
  ];

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _loadMatches();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _loadMatches() async {
    setState(() => _loading = true);
    final today = DateTime.now();
    final football = await _repository.getMatchesForDate(
      today,
      sport: SportType.football,
    );
    final hockey = await _repository.getMatchesForDate(
      today,
      sport: SportType.hockey,
    );
    final all = [...football, ...hockey];
    setState(() {
      _matches = all;
      _selectedMatch = all.isNotEmpty ? all.first : null;
      _selectedTeamId = _selectedMatch?.home.id;
      _homeScore = 50;
      _awayScore = 50;
      _feed.clear();
      _loading = false;
    });
  }

  void _selectMatch(MatchSchedule match) {
    setState(() {
      _selectedMatch = match;
      _selectedTeamId = match.home.id;
      _homeScore = 50;
      _awayScore = 50;
      _feed.clear();
    });
  }

  void _selectTeam(String teamId) {
    setState(() {
      _selectedTeamId = teamId;
    });
  }

  void _onFanTap(_FanButton button) {
    if (_selectedMatch == null || _selectedTeamId == null) return;
    if (_globalCooldown) return;

    _playSound(button.id);

    _globalCooldown = true;
    Timer(const Duration(seconds: 3), () {
      setState(() {
        _globalCooldown = false;
      });
    });

    final home = _selectedMatch!.home;
    final away = _selectedMatch!.away;
    final cheeringHome = _selectedTeamId == home.id;
    final giveBoth = _rand.nextInt(100) < 30;

    setState(() {
      if (cheeringHome) {
        _homeScore += 10;
        _feed.insert(0, '${button.label} for ${home.name}');
      } else {
        _awayScore += 10;
        _feed.insert(0, '${button.label} for ${away.name}');
      }
      if (giveBoth) {
        final otherButton = () {
          _FanButton pick;
          do {
            pick = _fanButtons[_rand.nextInt(_fanButtons.length)];
          } while (pick.id == button.id && _fanButtons.length > 1);
          return pick;
        }();
        if (cheeringHome) {
          _awayScore += 10;
          _feed.insert(0, '${otherButton.label} for ${away.name}');
        } else {
          _homeScore += 10;
          _feed.insert(0, '${otherButton.label} for ${home.name}');
        }
      }
      if (_feed.length > 20) {
        _feed.removeRange(20, _feed.length);
      }
    });
  }

  void _playSound(String id) {
    final soundMap = <String, String>{
      'go': 'audio/reactions/go.mp3',
      'lets': 'audio/reactions/lets_go.mp3',
      'defense': 'audio/reactions/defense.mp3',
      'noise': 'audio/reactions/noise.mp3',
      'save': 'audio/reactions/save.mp3',
      'unbelievable': 'audio/reactions/unbelievable.mp3',
    };
    final asset = soundMap[id] ?? soundMap.values.first;
    _player.stop();
    _player.play(AssetSource(asset));
  }

  String _dominanceText() {
    if (_homeScore == _awayScore) return 'It\'s neck and neck!';
    final leadingHome = _homeScore > _awayScore;
    final teamName = leadingHome
        ? _selectedMatch?.home.name
        : _selectedMatch?.away.name;
    return '$teamName fans are dominating!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.bgPrimary,
      appBar: CustomAppbar(
        leading: const SideNavButton(active: SideNavSection.shoutboard),
        title: Text(
          'Fan Shoutboard',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 26,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: MyColors.primaryBlue),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose a match:',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: MyColors.primaryGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _MatchDropdown(
                    matches: _matches,
                    selected: _selectedMatch,
                    onChanged: (m) {
                      if (m != null) _selectMatch(m);
                    },
                  ),
                  const SizedBox(height: 32),
                  if (_selectedMatch != null) ...[
                    Text(
                      'Choose your side',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        color: Colors.white,
                        fontSize: 21,
                      ),
                    ),
                    const SizedBox(height: 23),
                    Row(
                      children: [
                        Expanded(
                          child: _TeamSelectChip(
                            team: _selectedMatch!.home,
                            selected:
                                _selectedTeamId == _selectedMatch!.home.id,
                            onTap: () => _selectTeam(_selectedMatch!.home.id),
                          ),
                        ),
                        const SizedBox(width: 35),
                        Expanded(
                          child: _TeamSelectChip(
                            team: _selectedMatch!.away,
                            selected:
                                _selectedTeamId == _selectedMatch!.away.id,
                            onTap: () => _selectTeam(_selectedMatch!.away.id),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    _FanButtonsGrid(
                      buttons: _fanButtons,
                      cooldown: _globalCooldown,
                      onTap: _onFanTap,
                    ),
                    const SizedBox(height: 40),
                    Text(
                      _dominanceText(),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium!.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    _ScoreBar(
                      home: _selectedMatch!.home,
                      away: _selectedMatch!.away,
                      homeScore: _homeScore,
                      awayScore: _awayScore,
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'Reaction Feed:',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: _feed.isEmpty
                          ? Text(
                              'No reactions yet',
                              style: Theme.of(context).textTheme.bodySmall,
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final text in _feed)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: MyColors.bgSecondary,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        text,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),

                    const SizedBox(height: 45),
                    ConfirmButton(
                      onPressed: () {
                        setState(() {
                          _homeScore = 50;
                          _awayScore = 50;
                          _feed.clear();
                        });
                      },
                      title: 'Reset hype',
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
    );
  }
}

class _MatchDropdown extends StatefulWidget {
  const _MatchDropdown({
    required this.matches,
    required this.selected,
    required this.onChanged,
  });

  final List<MatchSchedule> matches;
  final MatchSchedule? selected;
  final ValueChanged<MatchSchedule?> onChanged;

  @override
  State<_MatchDropdown> createState() => _MatchDropdownState();
}

class _MatchDropdownState extends State<_MatchDropdown> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 38,
          decoration: BoxDecoration(color: Colors.white),
          child: PopupMenuButton<MatchSchedule>(
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
            offset: const Offset(0, 35),
            shape: RoundedRectangleBorder(),
            itemBuilder: (context) => widget.matches
                .map(
                  (m) => PopupMenuItem<MatchSchedule>(
                    value: m,
                    child: SizedBox(
                      width: constraints.maxWidth - 16,
                      child: Text(
                        '${m.home.name} vs ${m.away.name}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.black),
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
                      widget.selected == null
                          ? 'Select match'
                          : '${widget.selected!.home.name} vs ${widget.selected!.away.name}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.black),
                    ),
                  ),
                  Icon(
                    _open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: MyColors.primaryBlue,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TeamSelectChip extends StatelessWidget {
  const _TeamSelectChip({
    required this.team,
    required this.selected,
    required this.onTap,
  });

  final Team team;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          border: Border.all(
            color: selected ? Colors.transparent : Colors.grey.shade500,
          ),
        ),
        child: Row(
          children: [
            _TeamLogo(team: team, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                maxLines: 1,
                team.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: selected ? Color(0xFF003A99) : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FanButtonsGrid extends StatelessWidget {
  const _FanButtonsGrid({
    required this.buttons,
    required this.cooldown,
    required this.onTap,
  });

  final List<_FanButton> buttons;
  final bool cooldown;
  final void Function(_FanButton) onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: buttons.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.6,
      ),
      itemBuilder: (context, index) {
        final button = buttons[index];
        final disabled = cooldown;
        return Opacity(
          opacity: disabled ? 0.6 : 1,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(60),
              ),
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
            ),
            onPressed: disabled ? null : () => onTap(button),
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF003A99), Color(0xFF5F3AFF)],
                ),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                child: Text(
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  button.label,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({
    required this.home,
    required this.away,
    required this.homeScore,
    required this.awayScore,
  });

  final Team home;
  final Team away;
  final int homeScore;
  final int awayScore;

  @override
  Widget build(BuildContext context) {
    final total = (homeScore + awayScore) == 0 ? 1 : (homeScore + awayScore);
    final homeFlex = ((homeScore / total) * 100).round();
    final awayFlex = 100 - homeFlex;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: MyColors.bgSecondary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            flex: max(homeFlex, 1),
            child: Container(
              decoration: BoxDecoration(color: MyColors.success),
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Align(
                  alignment: AlignmentGeometry.centerLeft,
                  child: Text(
                    home.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: max(awayFlex, 1),
            child: Container(
              decoration: BoxDecoration(color: Colors.orangeAccent),
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Align(
                  alignment: AlignmentGeometry.centerRight,
                  child: Text(
                    away.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
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
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}

class _FanButton {
  final String id;
  final String label;
  const _FanButton({required this.id, required this.label});
}
