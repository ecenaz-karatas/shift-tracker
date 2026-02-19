import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class WeatherService {
  Future<Map<String, dynamic>> getWeather(String city) async {
    final url =
        "https://api.openweathermap.org/data/2.5/weather?q=$city&units=imperial&appid=$openWeatherApiKey";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to load weather");
    }
  }
}
