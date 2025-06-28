import 'package:attendance_app/firebase_options.dart';
import 'package:attendance_app/homescreen.dart';
import 'package:attendance_app/loginscreen.dart';
import 'package:attendance_app/model/user.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Firebase initialized successfully");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      home: KeyboardVisibilityProvider(child: const AuthCheck()),
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

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    String? employeeId = prefs.getString(
      'employeeId',
    ); // match this key exactly!
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
