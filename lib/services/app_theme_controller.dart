import 'package:flutter/material.dart';

enum MoodifyThemeMode { light, dark, weather, custom }

enum WeatherThemeType { sunny, cloudy, rainy, thunder, foggy, snowy, calm }

enum MoodifyCustomTheme { mint, sunny, rainy, cloudy, lavender, sakura, ocean, night }

class MoodifyThemeState {
  MoodifyThemeState({
    required this.mode,
    required this.weatherTheme,
    required this.customTheme,
    this.weatherLabel = '尚未取得天氣',
    this.temperature,
  });

  final MoodifyThemeMode mode;
  final WeatherThemeType weatherTheme;
  final MoodifyCustomTheme customTheme;
  final String weatherLabel;
  final double? temperature;

  bool get isDark =>
      mode == MoodifyThemeMode.dark ||
      (mode == MoodifyThemeMode.custom && customTheme == MoodifyCustomTheme.night);

  MoodifyThemeState copyWith({
    MoodifyThemeMode? mode,
    WeatherThemeType? weatherTheme,
    MoodifyCustomTheme? customTheme,
    String? weatherLabel,
    double? temperature,
  }) {
    return MoodifyThemeState(
      mode: mode ?? this.mode,
      weatherTheme: weatherTheme ?? this.weatherTheme,
      customTheme: customTheme ?? this.customTheme,
      weatherLabel: weatherLabel ?? this.weatherLabel,
      temperature: temperature ?? this.temperature,
    );
  }
}

class MoodifyThemeController {
  MoodifyThemeController._();

  static final MoodifyThemeController instance = MoodifyThemeController._();

  final ValueNotifier<MoodifyThemeState> notifier = ValueNotifier(
    MoodifyThemeState(
      mode: MoodifyThemeMode.light,
      weatherTheme: WeatherThemeType.calm,
      customTheme: MoodifyCustomTheme.mint,
    ),
  );

  MoodifyThemeState get state => notifier.value;

  void setMode(MoodifyThemeMode mode) {
    notifier.value = notifier.value.copyWith(mode: mode);
  }

  void setCustomTheme(MoodifyCustomTheme customTheme) {
    notifier.value = notifier.value.copyWith(
      mode: MoodifyThemeMode.custom,
      customTheme: customTheme,
    );
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
  MoodifyThemeColors({
    required this.background,
    required this.background2,
    required this.card,
    required this.primary,
    required this.text,
    required this.subText,
    required this.line,
    required this.soft,
    required this.weatherIcon,
    required this.name,
    required this.description,
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
  final String name;
  final String description;
}

MoodifyThemeColors moodifyColors(MoodifyThemeState state) {
  switch (state.mode) {
    case MoodifyThemeMode.dark:
      return _darkColors;
    case MoodifyThemeMode.weather:
      return _weatherColors(state.weatherTheme);
    case MoodifyThemeMode.custom:
      return _customColors(state.customTheme);
    case MoodifyThemeMode.light:
      return _mintColors;
  }
}

MoodifyThemeColors moodifyPreviewColors(MoodifyCustomTheme theme) => _customColors(theme);

String moodifyCustomThemeName(MoodifyCustomTheme theme) => _customColors(theme).name;
String moodifyCustomThemeDescription(MoodifyCustomTheme theme) => _customColors(theme).description;

MoodifyThemeColors _mintColors = MoodifyThemeColors(
  background: Color(0xFFF4FBF7),
  background2: Color(0xFFEAF6EF),
  card: Color(0xFFFFFFFF),
  primary: Color(0xFF2E7D62),
  text: Color(0xFF1E2A24),
  subText: Color(0xFF6F7F77),
  line: Color(0xFFE0EAE4),
  soft: Color(0xFFE7F5EE),
  weatherIcon: Icons.eco_rounded,
  name: '清新綠',
  description: '乾淨、療癒、日常預設',
);

MoodifyThemeColors _darkColors = MoodifyThemeColors(
  background: Color(0xFF071411),
  background2: Color(0xFF0D211C),
  card: Color(0xFF132A23),
  primary: Color(0xFF7DDDB0),
  text: Color(0xFFF0FAF6),
  subText: Color(0xFFA8BFB5),
  line: Color(0xFF28443A),
  soft: Color(0xFF1C3A31),
  weatherIcon: Icons.dark_mode_rounded,
  name: '深色模式',
  description: '墨綠夜色、低亮度、卡片層次更柔和',
);

MoodifyThemeColors _customColors(MoodifyCustomTheme theme) {
  switch (theme) {
    case MoodifyCustomTheme.mint:
      return _mintColors;
    case MoodifyCustomTheme.sunny:
      return MoodifyThemeColors(
        background: Color(0xFFFFF9EA),
        background2: Color(0xFFFFEFCB),
        card: Color(0xFFFFFEFA),
        primary: Color(0xFFE3A72F),
        text: Color(0xFF362A16),
        subText: Color(0xFF8A7652),
        line: Color(0xFFF1DFAE),
        soft: Color(0xFFFFF3D1),
        weatherIcon: Icons.wb_sunny_rounded,
        name: '晴天暖光',
        description: '晴天、明亮、暖黃色',
      );
    case MoodifyCustomTheme.rainy:
      return MoodifyThemeColors(
        background: Color(0xFFEFF6FC),
        background2: Color(0xFFDDECF8),
        card: Color(0xFFFFFFFF),
        primary: Color(0xFF4C7FAA),
        text: Color(0xFF1D2D3A),
        subText: Color(0xFF61788A),
        line: Color(0xFFD2E3EF),
        soft: Color(0xFFE4F0FA),
        weatherIcon: Icons.water_drop_rounded,
        name: '雨天藍',
        description: '下雨、安靜、藍色系',
      );
    case MoodifyCustomTheme.cloudy:
      return MoodifyThemeColors(
        background: Color(0xFFF2F6F7),
        background2: Color(0xFFE5ECEF),
        card: Color(0xFFFFFFFF),
        primary: Color(0xFF5F8794),
        text: Color(0xFF243239),
        subText: Color(0xFF6E7F85),
        line: Color(0xFFD9E4E7),
        soft: Color(0xFFE9F2F4),
        weatherIcon: Icons.cloud_rounded,
        name: '多雲灰藍',
        description: '柔和、低飽和、舒服',
      );
    case MoodifyCustomTheme.lavender:
      return MoodifyThemeColors(
        background: Color(0xFFF8F5FF),
        background2: Color(0xFFEFE9FF),
        card: Color(0xFFFFFFFF),
        primary: Color(0xFF7C6BC7),
        text: Color(0xFF2F2A44),
        subText: Color(0xFF77708F),
        line: Color(0xFFE2DCF5),
        soft: Color(0xFFF0EAFF),
        weatherIcon: Icons.auto_awesome_rounded,
        name: '薰衣草紫',
        description: '柔軟、放鬆、夢幻感',
      );
    case MoodifyCustomTheme.sakura:
      return MoodifyThemeColors(
        background: Color(0xFFFFF5F7),
        background2: Color(0xFFFFE8EE),
        card: Color(0xFFFFFFFF),
        primary: Color(0xFFD96C86),
        text: Color(0xFF3A2229),
        subText: Color(0xFF8B6871),
        line: Color(0xFFF2D7DE),
        soft: Color(0xFFFFEAF0),
        weatherIcon: Icons.favorite_rounded,
        name: '櫻花粉',
        description: '可愛、溫柔、少女感',
      );
    case MoodifyCustomTheme.ocean:
      return MoodifyThemeColors(
        background: Color(0xFFEFFBFA),
        background2: Color(0xFFDDF2F1),
        card: Color(0xFFFFFFFF),
        primary: Color(0xFF278A8E),
        text: Color(0xFF173738),
        subText: Color(0xFF5F7E80),
        line: Color(0xFFD0E7E6),
        soft: Color(0xFFE0F4F2),
        weatherIcon: Icons.waves_rounded,
        name: '海鹽藍綠',
        description: '清爽、平靜、有空氣感',
      );
    case MoodifyCustomTheme.night:
      return MoodifyThemeColors(
        background: Color(0xFF0D1324),
        background2: Color(0xFF121B30),
        card: Color(0xFF1A2438),
        primary: Color(0xFF8FB3FF),
        text: Color(0xFFF6F8FF),
        subText: Color(0xFFA9B7D0),
        line: Color(0xFF2D3A53),
        soft: Color(0xFF22304A),
        weatherIcon: Icons.nights_stay_rounded,
        name: '星夜藍',
        description: '深藍、安靜、比黑色模式更有氛圍',
      );
  }
}

MoodifyThemeColors _weatherColors(WeatherThemeType theme) {
  switch (theme) {
    case WeatherThemeType.sunny:
      return _customColors(MoodifyCustomTheme.sunny);
    case WeatherThemeType.cloudy:
      return _customColors(MoodifyCustomTheme.cloudy);
    case WeatherThemeType.rainy:
      return _customColors(MoodifyCustomTheme.rainy);
    case WeatherThemeType.thunder:
      return MoodifyThemeColors(
        background: Color(0xFFF3F1FB),
        background2: Color(0xFFE1DDF4),
        card: Color(0xFFFFFFFF),
        primary: Color(0xFF6263AA),
        text: Color(0xFF272846),
        subText: Color(0xFF6B6B8A),
        line: Color(0xFFDAD8EE),
        soft: Color(0xFFECEAF8),
        weatherIcon: Icons.thunderstorm_rounded,
        name: '雷雨紫藍',
        description: '雷雨、自動天氣主題',
      );
    case WeatherThemeType.foggy:
      return MoodifyThemeColors(
        background: Color(0xFFF4F6F4),
        background2: Color(0xFFE8EDEA),
        card: Color(0xFFFFFFFF),
        primary: Color(0xFF71827B),
        text: Color(0xFF2B3430),
        subText: Color(0xFF77817D),
        line: Color(0xFFDDE4E0),
        soft: Color(0xFFEDF2EF),
        weatherIcon: Icons.cloud_queue_rounded,
        name: '薄霧灰',
        description: '霧天、自動天氣主題',
      );
    case WeatherThemeType.snowy:
      return MoodifyThemeColors(
        background: Color(0xFFF3FBFF),
        background2: Color(0xFFE0F3FA),
        card: Color(0xFFFFFFFF),
        primary: Color(0xFF5AA7C5),
        text: Color(0xFF1D3440),
        subText: Color(0xFF66818C),
        line: Color(0xFFD5EAF2),
        soft: Color(0xFFE5F6FB),
        weatherIcon: Icons.ac_unit_rounded,
        name: '雪天冰藍',
        description: '降雪、自動天氣主題',
      );
    case WeatherThemeType.calm:
      return _mintColors;
  }
}
