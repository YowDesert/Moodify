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

        ThemeData buildTheme(Brightness brightness) {
          final base = brightness == Brightness.dark ? ThemeData.dark() : ThemeData.light();
          return ThemeData(
            fontFamily: 'jf-openhuninn',
            colorScheme: ColorScheme.fromSeed(
              seedColor: colors.primary,
              brightness: brightness,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: colors.background,
            cardColor: colors.card,
            textTheme: base.textTheme.apply(
              bodyColor: colors.text,
              displayColor: colors.text,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: colors.background,
              foregroundColor: colors.text,
              elevation: 0,
              centerTitle: true,
            ),
            snackBarTheme: SnackBarThemeData(
              backgroundColor: colors.card,
              contentTextStyle: TextStyle(color: colors.text, fontWeight: FontWeight.w700),
              behavior: SnackBarBehavior.floating,
            ),
            switchTheme: SwitchThemeData(
              thumbColor: MaterialStateProperty.resolveWith((states) => colors.primary),
              trackColor: MaterialStateProperty.resolveWith((states) => colors.soft),
            ),
          );
        }

        return MaterialApp(
          title: 'Moodify',
          debugShowCheckedModeBanner: false,
          themeMode: themeState.isDark ? ThemeMode.dark : ThemeMode.light,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          home: const HomePage(),
        );
      },
    );
  }
}
