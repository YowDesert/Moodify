import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_theme_controller.dart';

class MoodifyWeatherResult {
  MoodifyWeatherResult({
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
  static double _taipeiLatitude = 25.0330;
  static double _taipeiLongitude = 121.5654;

  Future<MoodifyWeatherResult> fetchTaipeiWeather() async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': _taipeiLatitude.toString(),
      'longitude': _taipeiLongitude.toString(),
      'current': 'temperature_2m,weather_code,is_day',
      'timezone': 'Asia/Taipei',
    });

    final response = await http.get(uri).timeout(Duration(seconds: 8));

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
      themeType: _themeForWeatherCode(weatherCode),
    );
  }

  String _labelForWeatherCode(int code, bool isDay) {
    final prefix = isDay ? '' : '夜晚・';
    if (code == 0 || code == 1) return '${prefix}晴朗';
    if (code == 2 || code == 3) return '${prefix}多雲';
    if (code == 45 || code == 48) return '${prefix}有霧';
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) return '${prefix}下雨';
    if (code >= 95) return '${prefix}雷雨';
    if (code >= 71 && code <= 77) return '${prefix}降雪';
    return '${prefix}舒服天氣';
  }

  WeatherThemeType _themeForWeatherCode(int code) {
    if (code == 0 || code == 1) return WeatherThemeType.sunny;
    if (code == 2 || code == 3) return WeatherThemeType.cloudy;
    if (code == 45 || code == 48) return WeatherThemeType.foggy;
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
      return WeatherThemeType.rainy;
    }
    if (code >= 95) return WeatherThemeType.thunder;
    if (code >= 71 && code <= 77) return WeatherThemeType.snowy;
    return WeatherThemeType.calm;
  }
}
