import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  Future<Map<String, dynamic>> fetchWeather(String city) async {
    final Uri url = Uri.parse(
        "https://api.openweathermap.org/data/2.5/weather?q=Tunis&appid=5bc701952b4dc3e313b4cecff7006cd0&units=metric&lang=fr");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Erreur lors du chargement des données météo");
    }
  }
}
