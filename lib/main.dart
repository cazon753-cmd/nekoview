import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/themes.dart';
import 'core/providers.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool isFirstTime = prefs.getBool('is_first_time') ?? true;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(create: (_) => SettingsProvider(prefs)),
        ChangeNotifierProvider(create: (_) => SelectionProvider()),
        ChangeNotifierProvider(create: (_) => UserDataProvider(prefs)),
      ],
      child: NekoViewApp(isFirstTime: isFirstTime),
    ),
  );
}

class NekoViewApp extends StatelessWidget {
  final bool isFirstTime;
  const NekoViewApp({super.key, required this.isFirstTime});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NekoView',
      debugShowCheckedModeBanner: false,
      theme: Provider.of<ThemeProvider>(context).getThemeData(),
      home: isFirstTime ? const OnboardingScreen() : const HomeScreen(),
    );
  }
}