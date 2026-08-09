import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/admin_dashboard.dart';
import 'screens/driver_home_screen.dart';
import 'modelss/location_ping.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(LocationPingAdapter());
  await Hive.openBox<LocationPing>('trip_pings');
  await Hive.openBox('trip_state');

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
      home: const DriverHomeScreen(),
      routes: {
        '/admin': (context) => const AdminDashboard(),
        '/driver': (context) => const DriverHomeScreen(),
      },
    );
  }
}

