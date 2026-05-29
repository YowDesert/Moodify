import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_theme_controller.dart';

class MoodifyWeatherResult {
  const MoodifyWeatherResult({
    required this.temperature,
    required this.weatherCode,
    required this.isDay,
    required this.label,
    required this.themeType,
  });

  final double temperature;
  final int weatherCode;
  final bool isDay;
  final String label;
  final WeatherThemeType themeType;
}

class WeatherService {
  static const double _taipeiLatitude = 25.0330;
  static const double _taipeiLongitude = 121.5654;

  Future<MoodifyWeatherResult> fetchTaipeiWeather() async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': _taipeiLatitude.toString(),
      'longitude': _taipeiLongitude.toString(),
      'current': 'temperature_2m,weather_code,is_day',
      'timezone': 'Asia/Taipei',
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw Exception('天氣資料取得失敗：${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final current = json['current'] as Map<String, dynamic>?;

    if (current == null) {
      throw Exception('天氣資料格式錯誤');
    }

    final temperature = (current['temperature_2m'] as num?)?.toDouble() ?? 0;
    final weatherCode = (current['weather_code'] as num?)?.toInt() ?? 0;
    final isDay = ((current['is_day'] as num?)?.toInt() ?? 1) == 1;

    return MoodifyWeatherResult(
      temperature: temperature,
      weatherCode: weatherCode,
      isDay: isDay,
      label: _labelForWeatherCode(weatherCode, isDay),
      themeType: _themeForWeatherCode(weatherCode, isDay),
    );
  }

  String _labelForWeatherCode(int code, bool isDay) {
    if (!isDay) return '夜晚模式';
    if (code == 0 || code == 1) return '晴朗';
    if (code == 2 || code == 3 || code == 45 || code == 48) return '多雲';
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) return '下雨';
    if (code >= 95) return '雷雨';
    if (code >= 71 && code <= 77) return '降雪';
    return '舒服天氣';
  }

  WeatherThemeType _themeForWeatherCode(int code, bool isDay) {
    if (!isDay) return WeatherThemeType.night;
    if (code == 0 || code == 1) return WeatherThemeType.sunny;
    if (code == 2 || code == 3 || code == 45 || code == 48) {
      return WeatherThemeType.cloudy;
    }
    if ((code >= 51 && code <= 67) ||
        (code >= 71 && code <= 77) ||
        (code >= 80 && code <= 82) ||
        code >= 95) {
      return WeatherThemeType.rainy;
    }
    return WeatherThemeType.calm;
  }
}
