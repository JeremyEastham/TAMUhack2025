import 'package:aalandmarks/auth/auth.dart';
import 'package:aalandmarks/auth/login_or_register.dart';
import 'package:aalandmarks/firebase_options.dart';
import 'package:aalandmarks/pages/home_page.dart';
import 'package:aalandmarks/pages/login_page.dart';
import 'package:aalandmarks/pages/map_page.dart';
import 'package:aalandmarks/pages/register_page.dart';
import 'package:aalandmarks/theme/dark_mode.dart';
import 'package:aalandmarks/theme/light_mode.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
   MapboxOptions.setAccessToken(
      'sk.eyJ1IjoicmFhZmF5NTkiLCJhIjoiY202Y3JzbnVwMG54ODJ3cHNkdjR6Znd3bSJ9.aTq44U2zhOXaX37txUxbTQ');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: lightMode,
      darkTheme: darkMode,
      home: const AuthPage(),
      routes: {
        'login_or_register_page': (context) => const LoginOrRegister(),
        'home_page': (context) => HomePage(),
        'map_page': (context) => MapPage(title: "RAAFAY'S THE GOAT"),
      },
    );
  }
}
