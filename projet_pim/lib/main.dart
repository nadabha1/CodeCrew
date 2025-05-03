import 'package:flutter/material.dart';
import 'package:projet_pim/Model/carnet.dart';
import 'package:projet_pim/Providers/UserPreferences.dart';
import 'package:projet_pim/Providers/auth_provider.dart';
import 'package:projet_pim/Providers/carnet_provider.dart';
import 'package:projet_pim/Providers/event_provider.dart';
import 'package:projet_pim/Providers/review_provider.dart';
import 'package:projet_pim/Providers/theme_provider.dart';
import 'package:projet_pim/Providers/user_provider.dart';
import 'package:projet_pim/View/UserPreferences/EventPreferencePage.dart';
import 'package:projet_pim/View/UserPreferences/FinalConfirmationPage.dart';
import 'package:projet_pim/View/UserPreferences/GenderSelectionPage.dart';
import 'package:projet_pim/View/UserPreferences/PreferredEventTime.dart';
import 'package:projet_pim/View/UserPreferences/SocialInteractionPage.dart';
import 'package:projet_pim/View/UserPreferences/activity_selection_page.dart';
import 'package:projet_pim/View/carnet&place/PlaceDetailsProviderScreen.dart';
import 'package:projet_pim/View/carnet&place/add_place_screen.dart';
import 'package:projet_pim/View/Event/event_chat_screen.dart';
import 'package:projet_pim/View/forgot_password_screen.dart';
import 'package:projet_pim/View/home_screen.dart';
import 'package:projet_pim/View/reset_password_screen.dart';
import 'package:projet_pim/View/signup_page.dart';
import 'package:projet_pim/View/user_profile.dart';
import 'package:projet_pim/ViewModel/api_constants.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projet_pim/View/login.dart';
import 'package:projet_pim/View/main_screen.dart';
import 'package:projet_pim/ViewModel/login.dart';
// ignore: library_prefixes
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

late IO.Socket socket;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString("jwt_token");
  String? userId = prefs.getString("user_id");
  bool isDarkMode = prefs.getBool('isDarkMode') ?? false;
  MapboxOptions.setAccessToken(
      "pk.eyJ1Ijoic2FsbWF5Y2IiLCJhIjoiY205bGV4YzhuMDFvODJtcjdudWdnc2Z4aiJ9.QOLpg1lQZCsB0fy0_3Cekg");

  // 🛠️ Proper initialization settings for both platforms
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS, // ✅ Updated class name
  );

  // ✅ Ensure the notification plugin is initialized properly
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      if (response.payload != null) {
        print("📥 Notification clicked: ${response.payload}");
      }
    },
  );

  // ✅ Initialiser Socket.IO
  socket = IO.io(ApiConstants.baseUrl, <String, dynamic>{
    'transports': ['websocket'],
    'autoConnect': false,
  });

  socket.connect();

  socket.onConnect((_) {
    print("✅ Connecté à Socket.IO");
    if (userId != null) {
      socket.emit('join', userId);
    }
  });

  // ✅ Gérer les notifications en temps réel
  socket.on('new_notification', (data) {
    print("📥 Nouvelle notification: $data");
    _showNotification(data);
  });

  socket.onDisconnect((_) => print("❌ Déconnecté de Socket.IO"));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<LoginViewModel>(
            create: (_) => LoginViewModel()..loadSession()),
        ChangeNotifierProvider<CarnetProvider>(create: (_) => CarnetProvider()),
        ChangeNotifierProvider<UserPreferences>(
            create: (_) => UserPreferences()),
        ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
        ChangeNotifierProvider<ThemeProvider>(
            create: (_) => ThemeProvider(isDarkMode)),
        ChangeNotifierProvider<EventProvider>(
            create: (_) => EventProvider(userId: userId ?? '')),
      ],
      child: MyApp(userId: userId, token: token),
    ),
  );
}

// ✅ Afficher les notifications locales
Future<void> _showNotification(Map<String, dynamic> data) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'default_channel',
    'Notifications',
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0,
    data['type'], // Titre de la notification
    data['message'], // Contenu de la notification
    platformChannelSpecifics,
    payload: data.toString(), // Charger des données supplémentaires
  );
}

class MyApp extends StatelessWidget {
  final String? userId;
  final String? token;

  const MyApp({super.key, this.userId, this.token});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(builder: (context, ThemeProvider, child) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "Flutter App",
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeProvider.themeMode,
        home:
            userId != null && token != null ? const MainScreen() : LoginView(),
        routes: {
          '/home': (context) =>
              const HomeScreen(userId: '67a37ac68b9e4e153a914e9e', token: ''),
          '/signup': (context) => SignUpPage(),
          '/gender-selection': (context) => GenderSelectionPage(),
          '/activity-selection': (context) => ActivitySelectionPage(),
          '/event-preference': (context) => EventPreferencePage(),
          '/social-interaction': (context) => SocialInteractionPage(),
          '/preferred-event-time': (context) => PreferredEventTimePage(),
          '/final-confirmation': (context) => FinalConfirmationPage(),
          '/forgot-password': (context) => ForgotPasswordScreen(),
          '/reset-password': (context) => ResetPasswordScreen(email: ''),
          '/login': (context) => LoginView(),
          '/profile': (context) => const UserProfileScreen(
                userId: 'exampleId',
                token: 'exampleToken',
              ),
          '/add-place': (context) => AddPlaceScreen(carnetId: ''),
          '/event-chat': (context) => EventChatScreen(
                eventId:
                    ModalRoute.of(context)?.settings.arguments as String? ?? '',
                userId: userId ?? '',
              ),
          '/place': (context) {
            final place = ModalRoute.of(context)?.settings.arguments as Place;
            return PlaceDetailsProviderScreen(place: place); // ✅ Avec provider
          },
        },
      );
    });
  }
}
