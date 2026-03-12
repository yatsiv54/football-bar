import 'package:bar_app/core/services/bd.dart';

import 'core/router/router.dart';
import 'core/di/injection.dart';
import 'core/theme/theme.dart';
import 'package:flutter/material.dart';

void main() {
  setupDependencies();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: MaterialApp.router(
        theme: darkTheme,
        debugShowCheckedModeBanner: false,
        routerConfig: router,
      ),
    );
  }
}
