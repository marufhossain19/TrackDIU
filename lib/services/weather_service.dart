import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

import '../core/constants.dart';
import 'location_service.dart';

class WeatherSnapshot {
  final int temperatureC;
  final String condition;
  final String city;

  const WeatherSnapshot({
    required this.temperatureC,
    required this.condition,
    required this.city,
  });
}

class WeatherService {
  static WeatherSnapshot? _sessionCache;

  static Future<WeatherSnapshot?> fetchCampusWeather() async {
    if (_sessionCache != null) return _sessionCache;
    if (AppConstants.openWeatherApiKey.isEmpty) return null;

    final position = await LocationService().getCurrentPosition();
    final lat = position?.latitude ?? AppConstants.defaultLat;
    final lon = position?.longitude ?? AppConstants.defaultLng;

    final uri = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
      'lat': lat.toString(),
      'lon': lon.toString(),
      'appid': AppConstants.openWeatherApiKey,
      'units': 'metric',
    });

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final weatherList = data['weather'] as List<dynamic>?;
      final main = data['main'] as Map<String, dynamic>?;
      String? city = (data['name'] as String?)?.trim();

      if (weatherList == null ||
          weatherList.isEmpty ||
          main == null ||
          city == null ||
          city.isEmpty) {
        return null;
      }

      // Try geocoding to get the exact exact local area name (e.g. Ashulia/Savar)
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
        if (placemarks.isNotEmpty) {
          final mark = placemarks.first;
          final localArea = mark.locality ?? mark.subLocality ?? mark.subAdministrativeArea;
          if (localArea != null && localArea.isNotEmpty) {
            city = localArea;
          }
        }
      } catch (_) {
        // Fallback to API's default area name (like Tongi)
      }

      final condition =
          (weatherList.first as Map<String, dynamic>)['main'] as String? ??
              'Unknown';
      final tempRaw = main['temp'];
      if (tempRaw is! num) return null;

      _sessionCache = WeatherSnapshot(
        temperatureC: tempRaw.round(),
        condition: condition,
        city: city!,
      );
      return _sessionCache;
    } catch (_) {
      return null;
    }
  }

  static String iconForCondition(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return '☀️';
      case 'clouds':
        return '⛅';
      case 'rain':
        return '🌧';
      default:
        return '🌤';
    }
  }
}
