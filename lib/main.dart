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
          final base = brightness == Brightness.dark
              ? ThemeData.dark(useMaterial3: true)
              : ThemeData.light(useMaterial3: true);

          final colorScheme = ColorScheme.fromSeed(
            seedColor: colors.primary,
            brightness: brightness,
          );

          return base.copyWith(
            useMaterial3: true,
            colorScheme: colorScheme,

            // 這裡補回你的字體
            textTheme: base.textTheme
                .apply(
                  fontFamily: 'Huninn',
                  bodyColor: colors.text,
                  displayColor: colors.text,
                )
                .copyWith(
                  bodyLarge: base.textTheme.bodyLarge?.copyWith(
                    fontFamily: 'Huninn',
                    color: colors.text,
                  ),
                  bodyMedium: base.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'Huninn', 
                    color: colors.text,
                  ),
                  bodySmall: base.textTheme.bodySmall?.copyWith(
                    fontFamily: 'Huninn',
                    color: colors.text,
                  ),
                  titleLarge: base.textTheme.titleLarge?.copyWith(
                    fontFamily: 'Huninn',
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
                  titleMedium: base.textTheme.titleMedium?.copyWith(
                    fontFamily: 'Huninn',
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
                  titleSmall: base.textTheme.titleSmall?.copyWith(
                    fontFamily: 'Huninn',
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
                  labelLarge: base.textTheme.labelLarge?.copyWith(
                    fontFamily: 'Huninn',
                    color: colors.text,
                  ),
                  labelMedium: base.textTheme.labelMedium?.copyWith(
                    fontFamily: 'Huninn',
                    color: colors.text,
                  ),
                  labelSmall: base.textTheme.labelSmall?.copyWith(
                    fontFamily: 'Huninn',
                    color: colors.text,
                  ),
                ),

            primaryTextTheme: base.primaryTextTheme.apply(
              fontFamily: 'Huninn',
              bodyColor: colors.text,
              displayColor: colors.text,
            ),

            scaffoldBackgroundColor: colors.background,
            cardColor: colors.card,

            appBarTheme: AppBarTheme(
              backgroundColor: colors.background,
              foregroundColor: colors.text,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                fontFamily: 'Huninn',
                color: colors.text,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),

            snackBarTheme: SnackBarThemeData(
              backgroundColor: colors.card,
              contentTextStyle: TextStyle(
                fontFamily: 'Huninn',
                color: colors.text,
                fontWeight: FontWeight.w700,
              ),
              behavior: SnackBarBehavior.floating,
            ),

            switchTheme: SwitchThemeData(
              thumbColor: MaterialStateProperty.resolveWith(
                (states) => colors.primary,
              ),
              trackColor: MaterialStateProperty.resolveWith(
                (states) => colors.soft,
              ),
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
