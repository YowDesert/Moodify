import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'pages/home_page.dart';
import 'services/app_theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MoodifyApp());
}

class MoodifyApp extends StatelessWidget {
  const MoodifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MoodifyThemeState>(
      valueListenable: MoodifyThemeController.instance.notifier,
      builder: (context, themeState, _) {
        final colors = moodifyColors(themeState);

        return MaterialApp(
          title: 'Moodify',
          debugShowCheckedModeBanner: false,
          themeMode: themeState.isDark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            fontFamily: 'Huninn',
            colorScheme: ColorScheme.fromSeed(
              seedColor: colors.primary,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: colors.background,
            cardColor: colors.card,
            switchTheme: SwitchThemeData(
              thumbColor: MaterialStatePropertyAll(colors.primary),
              trackColor: MaterialStatePropertyAll(colors.soft),
            ),
          ),
          darkTheme: ThemeData(
            fontFamily: 'Huninn',
            colorScheme: ColorScheme.fromSeed(
              seedColor: colors.primary,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: colors.background,
            cardColor: colors.card,
            switchTheme: SwitchThemeData(
              thumbColor: MaterialStatePropertyAll(colors.primary),
              trackColor: MaterialStatePropertyAll(colors.soft),
            ),
          ),
          home: const HomePage(),
        );
      },
    );
  }
}
