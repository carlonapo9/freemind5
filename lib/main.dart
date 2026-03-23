import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/schedule_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('users');

  runApp(const FreeMindApp());
}

class FreeMindApp extends StatelessWidget {
  const FreeMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'FreeMind',
      debugShowCheckedModeBanner: false,
      home: ScheduleScreen(),
    );
  }
}
