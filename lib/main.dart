import 'package:attendance_app/firebase_options.dart';
import 'package:attendance_app/homescreen.dart';
import 'package:attendance_app/loginscreen.dart';
import 'package:attendance_app/model/user.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Add this
import 'package:month_year_picker/month_year_picker.dart'; // Add this

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Firebase initialized successfully");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        MonthYearPickerLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English, add other locales if needed
      ],
      home: const KeyboardVisibilityProvider(child: AuthCheck()),
    );
  }
}

// Auto check
class AuthCheck extends StatefulWidget {
  const AuthCheck({Key? key}) : super(key: key);

  @override
  _AuthCheckState createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool? userAvailable;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  // Handle Submit
  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    String? employeeId = prefs.getString(
      'employeeId',
    ); // Match this key exactly!
    setState(() {
      userAvailable = employeeId != null;
      if (userAvailable == true) {
        User.employeeId = employeeId!;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (userAvailable == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return userAvailable! ? const HomeScreen() : const LoginScreen();
  }
}
