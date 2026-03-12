import '../../../core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class BarInformationPage extends StatelessWidget {
  const BarInformationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: MyColors.bgPrimary,
      body: Stack(
        children: [
          const _InfoBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                      const SizedBox(width: 30),
                      Column(
                        children: [
                          Text(
                            'Bar information',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 26,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 46),
                  _AboutCard(textTheme: textTheme),
                  const SizedBox(height: 21),
                  _RulesCard(textTheme: textTheme),
                  const SizedBox(height: 10),
                  _InfoTile(
                    icon: 'assets/images/info/wifi.png',
                    lines: const [
                      _InfoLine(label: 'Network:', value: ' 1W_Bar_WiFi'),
                      _InfoLine(label: 'Password:', value: ' 1234-5678'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _InfoTile(
                    icon: 'assets/images/info/phone.png',
                    lines: const [
                      _InfoLine(label: 'Phone:', value: ' +1 973 966 0252'),
                      _InfoLine(
                        label: 'Address:',
                        value: ' 54 Main Street, Madison',
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  _GradientButton(label: 'Open in maps', onTap: _launchMaps),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _launchMaps() async {
  const url = 'https://maps.app.goo.gl/A8qcmbHAW8DzzwsF8';
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About us',
                style: textTheme.displayLarge?.copyWith(
                  color: MyColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your go-to sports bar with big screens, cold drinks and a lively game-day atmosphere. Enjoy great food, fast service and the best match experience.',
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset(
            'assets/images/info/img.png',
            width: 190,
            height: 220,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }
}

class _RulesCard extends StatelessWidget {
  const _RulesCard({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    const rules = [
      'Please respect other guests.',
      'Outside food and drinks are not allowed.',
      'Smoking is permitted only in designated areas.',
      'Keep your belongings safe.',
      'Staff may refuse service to intoxicated guests.',
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 14),
      decoration: BoxDecoration(
        color: MyColors.bgSecondary,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'House rules',
            style: textTheme.displayLarge?.copyWith(
              color: MyColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 10),
          ...rules.map(
            (rule) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      '• $rule',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.lines});

  final String icon;
  final List<_InfoLine> lines;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: MyColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 28, child: Image.asset(icon)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: lines
                  .map(
                    (line) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: RichText(
                        text: TextSpan(
                          text: line.label,
                          style: textTheme.bodyMedium?.copyWith(
                            color: MyColors.primaryGrey,
                            fontWeight: FontWeight.w400,
                          ),
                          children: [
                            TextSpan(
                              text: line.value,
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine {
  final String label;
  final String value;
  const _InfoLine({required this.label, required this.value});
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 51,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(200),
          ),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        onPressed: onTap,
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF003A99), Color(0xFF5F3AFF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.all(Radius.circular(200)),
          ),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoBackground extends StatelessWidget {
  const _InfoBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: const [
          Positioned(
            right: -210,
            top: 30,
            child: _Bubble(
              width: 400,
              height: 400,
              colors: [Color(0xFF003A99), Color(0xFF006BFF), Color(0xFF00A5FF)],
            ),
          ),
          Positioned(
            left: -160,
            bottom: 110,
            child: _Bubble(
              width: 300,
              height: 300,
              colors: [Color(0xFF003A99), Color(0xFF006BFF), Color(0xFF00A5FF)],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.width,
    required this.height,
    required this.colors,
  });

  final double width;
  final double height;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}
