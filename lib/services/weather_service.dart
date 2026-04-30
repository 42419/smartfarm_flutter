import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/config.dart';

class WeatherService {
  WeatherService._();

  static final WeatherService instance = WeatherService._();

  String city = '--';
  String weatherText = '--';
  String weatherTemp = '--';
  String weatherWind = '--';
  String weatherHumidity = '--';
  String reportTime = '';
  bool fetched = false;

  static const _cacheKey = 'weather_cache';

  Future<void> loadCached() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null || fetched) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      city = data['city'] ?? '--';
      weatherText = data['text'] ?? '--';
      weatherTemp = data['temp'] ?? '--';
      weatherWind = data['wind'] ?? '--';
      weatherHumidity = data['hum'] ?? '--';
      reportTime = data['report'] ?? '';
    } catch (_) {}
  }

  Future<void> _saveCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode({
      'city': city,
      'text': weatherText,
      'temp': weatherTemp,
      'wind': weatherWind,
      'hum': weatherHumidity,
      'report': reportTime,
    }));
  }

  Future<void> fetch() async {
    try {
      final dio = Dio();
      final ipResp = await dio.get(
        'https://restapi.amap.com/v3/ip',
        queryParameters: {'key': Config.amapAuthKey},
      );
      final adcode = ipResp.data['adcode']?.toString();
      if (adcode == null || adcode.isEmpty) {
        weatherText = '定位失败';
        return;
      }

      final weatherResp = await dio.get(
        'https://restapi.amap.com/v3/weather/weatherInfo',
        queryParameters: {
          'key': Config.amapAuthKey,
          'city': adcode,
          'extensions': 'base',
        },
      );
      final lives = weatherResp.data['lives'] as List<dynamic>?;
      if (lives == null || lives.isEmpty) {
        weatherText = '无数据';
        return;
      }
      final live = lives[0] as Map<String, dynamic>;

      fetched = true;
      city = live['city']?.toString() ?? '--';
      weatherText = live['weather']?.toString() ?? '--';
      weatherTemp = '${live['temperature']?.toString() ?? '--'}°';
      weatherWind = '${live['winddirection']?.toString() ?? '--'} '
          '${live['windpower']?.toString() ?? '--'}级';
      weatherHumidity = '湿度${live['humidity']?.toString() ?? '--'}%';
      reportTime = live['reporttime']?.toString() ?? '';
      await _saveCache();
    } catch (e) {
      weatherText = '获取失败';
    }
  }

  IconData weatherIcon() {
    if (weatherText.contains('晴')) return Icons.wb_sunny;
    if (weatherText.contains('云') || weatherText.contains('阴')) return Icons.cloud;
    if (weatherText.contains('雨')) return Icons.grain;
    if (weatherText.contains('雪')) return Icons.ac_unit;
    if (weatherText.contains('风')) return Icons.air;
    return Icons.cloud;
  }

  Color get accentColor {
    if (weatherText.contains('晴')) return Colors.orange;
    if (weatherText.contains('云')) return Colors.blueGrey;
    if (weatherText.contains('阴')) return Colors.blueGrey.shade400;
    if (weatherText.contains('雨')) return Colors.blue;
    if (weatherText.contains('雪')) return Colors.lightBlue;
    return Colors.blueGrey;
  }
}
