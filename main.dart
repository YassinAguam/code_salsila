import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/family_member.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeHive(); // Init Hive DB

  runApp(const KinshipApp());
}

/// Initializes Hive DB and registers adapters
Future<void> _initializeHive() async {
  try {
    await Hive.initFlutter();
    Hive.registerAdapter(FamilyMemberAdapter());
    await Hive.openBox<FamilyMember>('familyTree');
  } catch (e) {
    debugPrint("Hive initialization failed: $e");
  }
}

class KinshipApp extends StatelessWidget {
  const KinshipApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kinship Verification',
      theme: _buildLightTheme(),
      home: const HomeScreen(),
    );
  }

  /// Light theme for the entire app
  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      primaryColor: Colors.blue,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.black, fontSize: 14),
        titleLarge: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        shadowColor: Colors.black12,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
