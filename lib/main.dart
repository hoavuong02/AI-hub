import 'package:aihub/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _checkNotificationPermission();
  runApp(const MyApp());
}

Future<void> _checkNotificationPermission() async {
  final prefs = await SharedPreferences.getInstance();
  final bool hasBeenPrompted = prefs.getBool('first_time') ?? false;

  if (!hasBeenPrompted) {
    bool hasPermission = await AwesomeNotifications().isNotificationAllowed();
    if (!hasPermission) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
    await prefs.setBool('first_time', true);
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final ColorScheme lightScheme =
            lightDynamic ??
            ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.light,
            );

        final ColorScheme darkScheme =
            darkDynamic ??
            ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            );

        return MaterialApp(
          title: name,
          themeMode: ThemeMode.system,
          theme: ThemeData(useMaterial3: true, colorScheme: lightScheme),
          darkTheme: ThemeData(useMaterial3: true, colorScheme: darkScheme),
          home: AiHome(),
        );
      },
    );
  }
}
