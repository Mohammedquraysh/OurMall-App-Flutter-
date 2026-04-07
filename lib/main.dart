// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/navigation/app_router.dart';
import 'presentation/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: OurMallApp()));
}

class OurMallApp extends StatelessWidget {
  const OurMallApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'OurMall',
    debugShowCheckedModeBanner: false,
    theme: buildLightTheme(),
    darkTheme: buildDarkTheme(),
    themeMode: ThemeMode.system,
    routerConfig: appRouter,
  );
}
