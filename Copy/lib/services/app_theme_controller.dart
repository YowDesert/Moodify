import 'package:flutter/material.dart';

enum MoodifyThemeMode { light, dark, weather }

enum WeatherThemeType { sunny, cloudy, rainy, night, calm }

class MoodifyThemeState {
  const MoodifyThemeState({
    required this.mode,
    required this.weatherTheme,
    this.weatherLabel = '尚未取得天氣',
    this.temperature,
  });

  final MoodifyThemeMode mode;
  final WeatherThemeType weatherTheme;
  final String weatherLabel;
  final double? temperature;

  bool get isDark =>
      mode == MoodifyThemeMode.dark ||
      (mode == MoodifyThemeMode.weather && weatherTheme == WeatherThemeType.night);

  MoodifyThemeState copyWith({
    MoodifyThemeMode? mode,
    WeatherThemeType? weatherTheme,
    String? weatherLabel,
    double? temperature,
  }) {
    return MoodifyThemeState(
      mode: mode ?? this.mode,
      weatherTheme: weatherTheme ?? this.weatherTheme,
      weatherLabel: weatherLabel ?? this.weatherLabel,
      temperature: temperature ?? this.temperature,
    );
  }
}

class MoodifyThemeController {
  MoodifyThemeController._();

  static final MoodifyThemeController instance = MoodifyThemeController._();

  final ValueNotifier<MoodifyThemeState> notifier = ValueNotifier(
    const MoodifyThemeState(
      mode: MoodifyThemeMode.light,
      weatherTheme: WeatherThemeType.calm,
    ),
  );

  MoodifyThemeState get state => notifier.value;

  void setMode(MoodifyThemeMode mode) {
    notifier.value = notifier.value.copyWith(mode: mode);
  }

  void applyWeatherTheme({
    required WeatherThemeType weatherTheme,
    required String weatherLabel,
    double? temperature,
  }) {
    notifier.value = notifier.value.copyWith(
      weatherTheme: weatherTheme,
      weatherLabel: weatherLabel,
      temperature: temperature,
    );
  }
}

class MoodifyThemeColors {
  const MoodifyThemeColors({
    required this.background,
    required this.background2,
    required this.card,
    required this.primary,
    required this.text,
    required this.subText,
    required this.line,
    required this.soft,
    required this.weatherIcon,
  });

  final Color background;
  final Color background2;
  final Color card;
  final Color primary;
  final Color text;
  final Color subText;
  final Color line;
  final Color soft;
  final IconData weatherIcon;
}

MoodifyThemeColors moodifyColors(MoodifyThemeState state) {
  if (state.mode == MoodifyThemeMode.dark) {
    return const MoodifyThemeColors(
      background: Color(0xFF101816),
      background2: Color(0xFF17231F),
      card: Color(0xFF1E2B27),
      primary: Color(0xFF8EE0BC),
      text: Color(0xFFF3FFF9),
      subText: Color(0xFFA8B9B1),
      line: Color(0xFF31413B),
      soft: Color(0xFF263B34),
      weatherIcon: Icons.dark_mode_rounded,
    );
  }

  if (state.mode == MoodifyThemeMode.weather) {
    switch (state.weatherTheme) {
      case WeatherThemeType.sunny:
        return const MoodifyThemeColors(
          background: Color(0xFFFFF8E9),
          background2: Color(0xFFFFF0C8),
          card: Color(0xFFFFFEFA),
          primary: Color(0xFFE4A72F),
          text: Color(0xFF352A16),
          subText: Color(0xFF8A7652),
          line: Color(0xFFF1DFAE),
          soft: Color(0xFFFFF3D1),
          weatherIcon: Icons.wb_sunny_rounded,
        );
      case WeatherThemeType.cloudy:
        return const MoodifyThemeColors(
          background: Color(0xFFF2F6F7),
          background2: Color(0xFFE4ECEF),
          card: Color(0xFFFFFFFF),
          primary: Color(0xFF5F8794),
          text: Color(0xFF243239),
          subText: Color(0xFF6E7F85),
          line: Color(0xFFD9E4E7),
          soft: Color(0xFFE9F2F4),
          weatherIcon: Icons.cloud_rounded,
        );
      case WeatherThemeType.rainy:
        return const MoodifyThemeColors(
          background: Color(0xFFEFF5FA),
          background2: Color(0xFFDDEBFA),
          card: Color(0xFFFFFFFF),
          primary: Color(0xFF4D79A8),
          text: Color(0xFF1D2C3A),
          subText: Color(0xFF62778A),
          line: Color(0xFFD2E0EC),
          soft: Color(0xFFE3EEF8),
          weatherIcon: Icons.water_drop_rounded,
        );
      case WeatherThemeType.night:
        return const MoodifyThemeColors(
          background: Color(0xFF111827),
          background2: Color(0xFF1D2A3A),
          card: Color(0xFF1F2937),
          primary: Color(0xFFB6C8FF),
          text: Color(0xFFF7FAFF),
          subText: Color(0xFFB8C2D3),
          line: Color(0xFF334155),
          soft: Color(0xFF273449),
          weatherIcon: Icons.nights_stay_rounded,
        );
      case WeatherThemeType.calm:
        break;
    }
  }

  return const MoodifyThemeColors(
    background: Color(0xFFF3FBF6),
    background2: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    primary: Color(0xFF2E7D62),
    text: Color(0xFF1D1D1F),
    subText: Color(0xFF6E6E73),
    line: Color(0xFFE5E5EA),
    soft: Color(0xFFEAF6EF),
    weatherIcon: Icons.eco_rounded,
  );
}
