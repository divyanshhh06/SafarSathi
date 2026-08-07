import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const TransitCommuterApp());
}

class TransitCommuterApp extends StatelessWidget {
  const TransitCommuterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transit Tracker - Commuter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const SplashScreen(),
    );
  }
}

