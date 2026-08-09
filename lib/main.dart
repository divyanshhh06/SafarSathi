import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/commuter_home_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/driver_home_screen.dart';
import 'modelss/location_ping.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(LocationPingAdapter());
    }
    await Hive.openBox<LocationPing>('trip_pings');
    await Hive.openBox('trip_state');
  } catch (e) {
    debugPrint('⚠️ Hive initialization non-fatal warning: $e');
  }

  runApp(const TransitCommuterApp());
}

class TransitCommuterApp extends StatelessWidget {
  const TransitCommuterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transit Tracker - SafarSathi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/commuter': (context) => const CommuterHomeScreen(),
        '/admin': (context) => const AdminDashboard(),
        '/driver': (context) => const DriverHomeScreen(),
      },
    );
  }
}

