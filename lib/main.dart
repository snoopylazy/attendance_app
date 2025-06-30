import 'package:attendance_app/firebase_options.dart';
import 'package:attendance_app/homescreen.dart';
import 'package:attendance_app/loginscreen.dart';
import 'package:attendance_app/model/user.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:month_year_picker/month_year_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Firebase initialized successfully");

  // Set status bar color to red
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.red[600],
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(KeyboardVisibilityProvider(child: const MyApp()));
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
        Locale('en', ''), // English
      ],
      home: const AuthCheck(),
    );
  }
}

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

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    String? employeeId = prefs.getString('employeeId');
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
