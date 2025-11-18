import 'package:aihub/screens/splash.dart';
import 'package:aihub/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'screens/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool hasPermission = await AwesomeNotifications().isNotificationAllowed();
  if (!hasPermission) {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
          home: const SplashScreen(),
          routes: {"/home": (context) => const AiHome()},
        );
      },
    );
  }
}
