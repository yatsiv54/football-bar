import 'dart:async';

import '../../../core/theme/colors.dart';
import '../data/challenges_repository.dart';
import '../../layout/custom_appbar.dart';
import '../../layout/side_nav.dart';
import '../../schedule/domain/entities/match_schedule.dart';
import '../../schedule/domain/entities/team.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChallengesPage extends StatefulWidget {
  const ChallengesPage({super.key});

  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> {
  final ChallengesRepository _repo = ChallengesRepository();
  ChallengeState? _state;
  bool _loading = true;
  Timer? _refreshTimer;
  final Map<String, MatchSchedule?> _matchCandidates = {};
  final Map<String, String> _matchTempSelection = {};

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final state = await _repo.loadState();
    await _refreshMatchCandidates(state);
    if (!mounted) return;
    setState(() {
      _state = state;
      _loading = false;
    });
  }

  Future<void> _refreshMatchCandidates(ChallengeState state) async {
    final now = DateTime.now();

    bool hasActive(String id) => state.matchChallenges.any(
      (m) => m.id == id && m.status != MatchChallengeStatus.pending,
    );

    bool needsRefresh(MatchSchedule? candidate, String id) {
      if (candidate == null) return true;
      if (hasActive(id)) return false;
      return candidate.dateTime.isBefore(now);
    }

    final needClean = needsRefresh(
      _matchCandidates[ChallengesRepository.matchCleanSheetId],
      ChallengesRepository.matchCleanSheetId,
    );
    final needComeback = needsRefresh(
      _matchCandidates[ChallengesRepository.matchComebackId],
      ChallengesRepository.matchComebackId,
    );

    if (!needClean && !needComeback) return;

    final list = await _repo.fetchTodayMatchCandidates(2);
    final filtered = list.where((m) => m.dateTime.isAfter(now)).toList();

    if (!hasActive(ChallengesRepository.matchCleanSheetId)) {
      _matchCandidates[ChallengesRepository.matchCleanSheetId] =
          filtered.isNotEmpty ? filtered.first : null;
    }

    if (!hasActive(ChallengesRepository.matchComebackId)) {
      _matchCandidates[ChallengesRepository.matchComebackId] =
          filtered.length > 1 ? filtered[1] : null;
    }
  }

  Future<void> _selectTeam(String teamId) async {
    final updated = await _repo.selectTeam(teamId);
    if (!mounted) return;
    setState(() => _state = updated);
    await _load(silent: true);
  }

  Future<void> _acceptFood(_FoodChallenge c) async {
    ChallengeState? updated;
    switch (c.id) {
      case ChallengesRepository.comboChallengeId:
        updated = await _repo.acceptFoodCombo();
        break;
      case ChallengesRepository.mainsChallengeId:
        updated = await _repo.acceptFoodSpecials(c.points);
        break;
      case ChallengesRepository.dessertSecondHalfId:
        updated = await _repo.acceptDessertSecondHalf(c.points);
        break;
      default:
        break;
    }
    if (updated != null && mounted) {
      setState(() => _state = updated);
    }
  }

  Future<void> _onChooseMatchTeam(
    String teamId,
    MatchSchedule match,
    String challengeId,
  ) async {
    final updated = challengeId == ChallengesRepository.matchComebackId
        ? await _repo.acceptMatchComeback(match, teamId)
        : await _repo.acceptMatchCleanSheet(match, teamId);
    if (!mounted) return;
    setState(() {
      _matchTempSelection.remove(challengeId);
      _state = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    return Scaffold(
      backgroundColor: MyColors.bgPrimary,
      appBar: CustomAppbar(
        leading: const SideNavButton(active: SideNavSection.challenges),
        title: Text(
          'Fan Challenges',
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
          : RefreshIndicator(
              color: MyColors.primaryBlue,
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 23,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(
                      points: state?.totalPoints ?? 0,
                      completed: state?.completed ?? 0,
                    ),
                    const SizedBox(height: 27),
                    Text(
                      'Daily Challenge',
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge!.copyWith(fontSize: 21),
                    ),
                    const SizedBox(height: 12),
                    _DailyChallengeCard(
                      daily: state?.daily,
                      onPick: _selectTeam,
                    ),
                    const SizedBox(height: 22),
                    _SectionTitle(title: 'Food challenges'),
                    const SizedBox(height: 10),
                    ..._foodChallenges.map((c) {
                      final map = {for (final f in state?.food ?? []) f.id: f};
                      final foodState = map[c.id];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _FoodChallengeCard(
                          challenge: c,
                          state: foodState,
                          onAccept: () => _acceptFood(c),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    _SectionTitle(title: 'Match challenges'),
                    const SizedBox(height: 10),
                    _MatchChallengeCard(
                      challengeId: ChallengesRepository.matchCleanSheetId,
                      title:
                          'If your team finishes without conceding — you win.',
                      reward: 20,
                      state: state,
                      candidate:
                          _matchCandidates[ChallengesRepository
                              .matchCleanSheetId],
                      onChooseTeam: (team, match) => _onChooseMatchTeam(
                        team,
                        match,
                        ChallengesRepository.matchCleanSheetId,
                      ),
                      inlineSelect: false,
                    ),
                    const SizedBox(height: 12),
                    _MatchChallengeCard(
                      challengeId: ChallengesRepository.matchComebackId,
                      title:
                          'If your team scores after being behind — you win.',
                      reward: 20,
                      state: state,
                      candidate:
                          _matchCandidates[ChallengesRepository
                              .matchComebackId],
                      onChooseTeam: (team, match) => _onChooseMatchTeam(
                        team,
                        match,
                        ChallengesRepository.matchComebackId,
                      ),
                      inlineSelect: true,
                      tempSelection:
                          _matchTempSelection[ChallengesRepository
                              .matchComebackId],
                      onSelectTemp: (teamId) {
                        setState(() {
                          _matchTempSelection[ChallengesRepository
                                  .matchComebackId] =
                              teamId;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.points, required this.completed});

  final int points;
  final int completed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total fan points:',
              style: textTheme.displaySmall!.copyWith(
                color: MyColors.primaryGrey,
              ),
            ),
            Text(
              '$points',
              style: textTheme.titleLarge?.copyWith(fontSize: 32),
            ),
          ],
        ),
        const SizedBox(width: 50),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Completed:',
              style: textTheme.displaySmall!.copyWith(
                color: MyColors.primaryGrey,
              ),
            ),
            Text(
              '$completed',
              style: textTheme.titleLarge?.copyWith(fontSize: 32),
            ),
          ],
        ),
      ],
    );
  }
}

class _DailyChallengeCard extends StatelessWidget {
  const _DailyChallengeCard({required this.daily, required this.onPick});

  final DailyChallengeState? daily;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    if (daily == null) {
      return _PlaceholderCard(
        title: 'No daily challenge',
        subtitle: 'No upcoming matches left for today.',
      );
    }

    final resolved = daily!.resolved;
    final match = daily!.match;
    final rewardText = '+${daily!.reward} points';
    final winnerTeam = resolved
        ? (daily!.winnerTeamId == match.home.id
              ? match.home.name
              : match.away.name)
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF006BFF), Color(0xFF00FFC2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Next Goal Guess',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall!.copyWith(color: Colors.white),
              ),
              const Spacer(),
              Text(
                rewardText,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              text: 'Match: ',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
              children: [
                TextSpan(
                  text: '${match.home.name} vs ${match.away.name}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontSize: 16),
                ),
              ],
            ),
          ),
          SizedBox(height: 5),
          Text(
            resolved
                ? 'Result: $winnerTeam scored next.'
                : 'Pick who scores next.',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _TeamChip(
                team: match.home,
                selected: daily!.selectedTeamId == match.home.id,
                onTap: resolved ? null : () => onPick(match.home.id),
              ),
              const SizedBox(width: 27),
              _TeamChip(
                team: match.away,
                selected: daily!.selectedTeamId == match.away.id,
                onTap: resolved ? null : () => onPick(match.away.id),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeamChip extends StatelessWidget {
  const _TeamChip({required this.team, required this.selected, this.onTap});

  final Team team;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final border = Border.all(
      color: selected ? MyColors.primaryLightBlue : Colors.white,
      width: selected ? 1.6 : 0.5,
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(1.6),
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(1.6),
          border: border,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TeamLogo(team: team),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                team.name,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: selected ? Color(0xFF003A99) : Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchChallengeCard extends StatelessWidget {
  const _MatchChallengeCard({
    required this.state,
    required this.candidate,
    required this.onChooseTeam,
    required this.challengeId,
    required this.title,
    required this.reward,
    this.inlineSelect = false,
    this.tempSelection,
    this.onSelectTemp,
  });

  final ChallengeState? state;
  final MatchSchedule? candidate;
  final String challengeId;
  final String title;
  final int reward;
  final void Function(String teamId, MatchSchedule match) onChooseTeam;
  final bool inlineSelect;
  final String? tempSelection;
  final ValueChanged<String>? onSelectTemp;

  @override
  Widget build(BuildContext context) {
    final activeState = (state?.matchChallenges ?? [])
        .where((m) => m.id == challengeId)
        .toList();
    final MatchChallengeState? active = activeState.isNotEmpty
        ? activeState.first
        : null;
    final hasActive =
        active != null && active.status != MatchChallengeStatus.pending;
    final match = hasActive ? active.match : candidate;

    if (match == null) {
      return _PlaceholderCard(
        title: 'No match challenges',
        subtitle: 'No upcoming matches for today.',
      );
    }

    final selectedActive = hasActive ? active : null;
    final resultText =
        selectedActive != null &&
            selectedActive.status == MatchChallengeStatus.completed
        ? (selectedActive.userWon == true
              ? 'You won!'
              : 'You lost this challenge.')
        : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MyColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium!.copyWith(color: Colors.white),
                ),
              ),
              Text(
                '+$reward points',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: MyColors.primaryBlue),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text.rich(
            TextSpan(
              text: 'Match: ',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
              children: [
                TextSpan(
                  text: '${match.home.name} vs ${match.away.name}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (selectedActive != null &&
              selectedActive.status == MatchChallengeStatus.completed)
            Text(
              resultText ?? '',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: selectedActive.userWon == true
                    ? Colors.greenAccent
                    : Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            )
          else if (selectedActive != null &&
              selectedActive.status == MatchChallengeStatus.accepted)
            _AcceptButton(
              label: 'Chosen team: ${_chosenTeamName(selectedActive, match)}',
              onTap: null,
            )
          else if (inlineSelect)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _TeamSelectTile(
                      team: match.home,
                      selected: tempSelection == match.home.id,
                      onTap: () => onSelectTemp?.call(match.home.id),
                    ),
                    const SizedBox(width: 27),
                    _TeamSelectTile(
                      team: match.away,
                      selected: tempSelection == match.away.id,
                      onTap: () => onSelectTemp?.call(match.away.id),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                _AcceptButton(
                  label: 'Save',
                  onTap: tempSelection == null
                      ? null
                      : () => onChooseTeam(tempSelection!, match),
                ),
              ],
            )
          else
            _AcceptButton(
              label: 'Choose team',
              onTap: () => _showTeamDialog(context, match),
            ),
        ],
      ),
    );
  }

  String _chosenTeamName(MatchChallengeState active, MatchSchedule match) {
    if (active.selectedTeamId == match.home.id) return match.home.name;
    if (active.selectedTeamId == match.away.id) return match.away.name;
    return 'Team selected';
  }

  Future<void> _showTeamDialog(
    BuildContext context,
    MatchSchedule match,
  ) async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: MyColors.bgSecondary,
          title: Text(
            'Choose team',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _TeamSelectButton(
                team: match.home,
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  onChooseTeam(match.home.id, match);
                },
              ),
              _TeamSelectButton(
                team: match.away,
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  onChooseTeam(match.away.id, match);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TeamSelectButton extends StatelessWidget {
  const _TeamSelectButton({required this.team, required this.onTap});
  final Team team;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TeamLogo(team: team),
          const SizedBox(height: 8),
          SizedBox(
            width: 100,
            child: Text(
              team.name,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamSelectTile extends StatelessWidget {
  const _TeamSelectTile({
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
        width: 140,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? MyColors.primaryLightBlue : Colors.white,
            width: selected ? 1.6 : 0.5,
          ),
          borderRadius: BorderRadius.circular(2),
          color: selected ? Colors.white : Colors.transparent,
        ),
        child: Row(
          children: [
            _TeamLogo(team: team),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                team.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: selected ? Color(0xFF003A99) : Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamLogo extends StatelessWidget {
  const _TeamLogo({required this.team});

  final Team team;

  @override
  Widget build(BuildContext context) {
    if (team.logoPath.isEmpty) {
      return CircleAvatar(
        radius: 14,
        backgroundColor: Colors.white,
        child: Text(
          team.name.characters.first,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      );
    }
    return Image.asset(
      team.logoPath,
      width: 32,
      height: 32,
      fit: BoxFit.contain,
    );
  }
}

class _FoodChallengeCard extends StatelessWidget {
  const _FoodChallengeCard({
    required this.challenge,
    required this.state,
    required this.onAccept,
  });

  final _FoodChallenge challenge;
  final FoodChallengeState? state;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: MyColors.bgSecondary,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  challenge.title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium!.copyWith(color: Colors.white),
                ),
              ),
              SizedBox(width: 40),
              Text(
                '+${challenge.points} points',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: MyColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _FoodActionRow(
            state: state,
            onAccept: onAccept,
            deadline: state?.resolveAt,
          ),
        ],
      ),
    );
  }
}

class _FoodActionRow extends StatelessWidget {
  const _FoodActionRow({
    required this.state,
    required this.onAccept,
    this.deadline,
  });

  final FoodChallengeState? state;
  final VoidCallback onAccept;
  final DateTime? deadline;

  @override
  Widget build(BuildContext context) {
    final status = state?.status ?? FoodChallengeStatus.pending;
    final textTheme = Theme.of(context).textTheme;

    switch (status) {
      case FoodChallengeStatus.pending:
        return _AcceptButton(label: 'Accept challenge', onTap: onAccept);
      case FoodChallengeStatus.accepted:
        return Container(
          width: 180,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
          decoration: BoxDecoration(
            color: MyColors.success,
            borderRadius: BorderRadius.circular(122),
          ),
          child: Center(
            child: Text(
              'Accepted',
              style: textTheme.headlineMedium?.copyWith(color: Colors.black),
            ),
          ),
        );
      case FoodChallengeStatus.completed:
        return Text(
          'Completed',
          style: textTheme.headlineMedium?.copyWith(color: Colors.greenAccent),
        );
      case FoodChallengeStatus.expired:
        return Text(
          'Expired',
          style: textTheme.headlineMedium?.copyWith(color: Colors.redAccent),
        );
    }
  }
}

class _AcceptButton extends StatelessWidget {
  const _AcceptButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: AlignmentGeometry.topLeft,
            end: AlignmentGeometry.bottomRight,
            colors: [Color(0xFF006BFF), Color(0xFF00FFC2)],
          ),
          borderRadius: BorderRadius.circular(102),
        ),
        child: Center(
          child: Text(label, style: Theme.of(context).textTheme.headlineMedium),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: 21,
      ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MyColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _FoodChallenge {
  final String title;
  final int points;
  final String id;

  const _FoodChallenge({
    required this.title,
    required this.points,
    required this.id,
  });
}

const _foodChallenges = <_FoodChallenge>[
  _FoodChallenge(
    title: 'Order any drink + snack combo before the timer ends.',
    points: 7,
    id: ChallengesRepository.comboChallengeId,
  ),
  _FoodChallenge(
    title: 'Try any item from the "Mains" menu.',
    points: 6,
    id: ChallengesRepository.mainsChallengeId,
  ),
  _FoodChallenge(
    title: 'Order any dessert during the second half.',
    points: 8,
    id: ChallengesRepository.dessertSecondHalfId,
  ),
];
