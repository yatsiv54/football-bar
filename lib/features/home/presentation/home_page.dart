import 'widgets/menu_card.dart';
import '../../layout/custom_appbar.dart';
import '../../layout/info_action_button.dart';
import '../../layout/qr_action_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning,';
    if (hour >= 12 && hour < 18) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _greeting();
    return Scaffold(
      backgroundColor: Color(0xFF0A0F1A),
      appBar: CustomAppbar(
        actions: [QrActionButton(), InfoActionButton()],
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 25),
            Text(greeting),
            Text('guest!', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            bottom: -20,
            left: -40,
            child: SizedBox(
              width: 200,
              child: Image.asset('assets/images/elipses/1.png'),
            ),
          ),
          Positioned(
            right: 0,
            top: -20,
            child: SizedBox(
              width: 70,
              child: Image.asset('assets/images/elipses/2.png'),
            ),
          ),

          Padding(
            padding: EdgeInsetsGeometry.symmetric(horizontal: 35, vertical: 33),
            child: GridView.count(
              childAspectRatio: .85,
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 20,
              children: [
                MenuCard(
                  onTap: () => context.push('/menu'),
                  title: 'View Menu',
                  iconPath: 'assets/images/icons/menu.png',
                  subtitle: 'Explore food & drinks',
                ),
                MenuCard(
                  onTap: () => context.push('/cart'),
                  title: 'Order From Table',
                  iconPath: 'assets/images/icons/order.png',
                  subtitle: 'Create your order and generate a QR code',
                ),
                MenuCard(
                  onTap: () => context.push('/reserve'),
                  title: 'Reserve Table',
                  iconPath: 'assets/images/icons/reserve.png',
                  subtitle: 'Pick a spot on the interactive hall map',
                ),
                MenuCard(
                  title: 'Match Schedule',
                  iconPath: 'assets/images/icons/schedule.png',
                  subtitle: 'Today\'s and upcoming sports broadcasts',
                  onTap: () => context.push('/schedule'),
                ),
                MenuCard(
                  title: 'Fan Challenges',
                  iconPath: 'assets/images/icons/challanges.png',
                  subtitle: 'Mini-games and interactive fan missions',
                  onTap: () => context.push('/challenges'),
                ),
                MenuCard(
                  title: 'Fan Shoutboard',
                  iconPath: 'assets/images/icons/fan.png',
                  subtitle: 'Cheer for your team in real time',
                  onTap: () => context.push('/fan'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
