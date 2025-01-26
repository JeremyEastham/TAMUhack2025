import 'package:aalandmarks/auth/auth.dart';
import 'package:aalandmarks/auth/login_or_register.dart';
import 'package:aalandmarks/firebase_options.dart';
import 'package:aalandmarks/pages/home_page.dart';
import 'package:aalandmarks/pages/login_page.dart';
import 'package:aalandmarks/pages/register_page.dart';
import 'package:aalandmarks/theme/dark_mode.dart';
import 'package:aalandmarks/theme/light_mode.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      },
    );
  }
}
