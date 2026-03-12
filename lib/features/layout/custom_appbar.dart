import '../../core/theme/colors.dart';
import 'package:flutter/material.dart';

class CustomAppbar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppbar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.color = MyColors.bgSecondary,
    this.needElevation = true,
  });
  final Color? color;
  final List<Widget>? actions;
  final Widget? title;
  final Widget? leading;
  final bool needElevation;

  List<Widget> _buildActions() {
    if (actions == null || actions!.isEmpty) return const [];

    final spaced = <Widget>[];
    for (var i = 0; i < actions!.length; i++) {
      if (i > 0) spaced.add(const SizedBox(width: 20));
      spaced.add(actions![i]);
    }
    spaced.add(const SizedBox(width: 20));
    return spaced;
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      iconTheme: IconThemeData(size: 50),
      elevation: needElevation ? 2 : 0,
      leading: leading == null
          ? null
          : Padding(padding: EdgeInsetsGeometry.only(left: 20), child: leading),
      leadingWidth: 70,
      titleSpacing: 20,
      actions: _buildActions(),
      toolbarHeight: 110,
      centerTitle: false,
      title: Align(alignment: Alignment.centerLeft, child: title),
      backgroundColor: color,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(110);
}
