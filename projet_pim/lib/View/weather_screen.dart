import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projet_pim/ViewModel/weather_service.dart';

class WeatherScreen extends StatefulWidget {
  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService _weatherService = WeatherService();
  Map<String, dynamic>? weatherData;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  void _loadWeather() async {
    try {
      final data = await _weatherService.fetchWeather("Tunis");
      setState(() {
        weatherData = data;
      });
    } catch (e) {
      print("Erreur : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFFCEFEF), // Light blue background for a fresh look
      appBar: AppBar(
        title: Text("Météo d'aujourd'hui"),
        backgroundColor:
            const Color(0xFFDBD9FE), // Subtle blue color for the app bar
        elevation: 0,
      ),
      body: weatherData == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Nom de la ville et icône météo
                    Column(
                      children: [
                        Text(
                          "${weatherData!['name']}, ${weatherData!['sys']['country']}",
                          style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                        SizedBox(height: 10),
                        Image.network(
                          "https://openweathermap.org/img/wn/${weatherData!['weather'][0]['icon']}@2x.png",
                          width: 120,
                          height: 120,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "${weatherData!['weather'][0]['description']}",
                          style:
                              TextStyle(fontSize: 20, color: Colors.grey[700]),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    // Carte principale des températures
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 8,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              "${weatherData!['main']['temp']}°C",
                              style: TextStyle(
                                  fontSize: 50,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF161055)),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Température ressentie : ${weatherData!['main']['feels_like']}°C",
                              style: TextStyle(
                                  fontSize: 18, color: Colors.grey[600]),
                            ),
                            Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    Text("Min",
                                        style: TextStyle(
                                            fontSize: 16, color: Colors.grey)),
                                    Text(
                                        "${weatherData!['main']['temp_min']}°C",
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text("Max",
                                        style: TextStyle(
                                            fontSize: 16, color: Colors.grey)),
                                    Text(
                                        "${weatherData!['main']['temp_max']}°C",
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    // Autres informations météo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _weatherInfoTile(Icons.water_drop, "Humidité",
                            "${weatherData!['main']['humidity']}%"),
                        _weatherInfoTile(Icons.air, "Vent",
                            "${weatherData!['wind']['speed']} km/h"),
                      ],
                    ),

                    SizedBox(height: 20),

                    // Lever et coucher du soleil
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Icon(Icons.wb_sunny,
                                    color: Colors.orange, size: 35),
                                Text("Lever du soleil",
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.grey)),
                                Text(
                                    _formatTime(weatherData!['sys']['sunrise']),
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              children: [
                                Icon(Icons.nightlight_round,
                                    color: Colors.blueAccent, size: 35),
                                Text("Coucher du soleil",
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.grey)),
                                Text(_formatTime(weatherData!['sys']['sunset']),
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Fonction pour formater le temps (lever et coucher du soleil)
  String _formatTime(int timestamp) {
    DateTime time = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat.Hm().format(time);
  }

  // Widget pour afficher une info météo sous forme d'icône + texte
  Widget _weatherInfoTile(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 40),
        SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black)),
      ],
    );
  }
}
