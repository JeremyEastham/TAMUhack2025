import 'package:aalandmarks/auth/login_or_register.dart';
import 'package:aalandmarks/pages/home_page.dart';
import 'package:aalandmarks/pages/map_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(stream: FirebaseAuth.instance.authStateChanges(), builder: (context, snapshot) {
        if (snapshot.hasData) {
          return MapPage(title: "RAAFAY'S THE GOAT");
        } else {
          return const LoginOrRegister();
        }
      })
    );
  }
}