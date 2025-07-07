import 'dart:async';
import 'package:attendance_app/homescreen.dart';
import 'package:attendance_app/model/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:attendance_app/registerscreen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lottie/lottie.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController idController = TextEditingController();
  TextEditingController passController = TextEditingController();

  bool _isLoading = false;

  double screenHeight = 0;
  double screenWidth = 0;

  Color primary = const Color(0xFFE53935);

  late SharedPreferences sharedPreferences;

  bool _obscurePassword = true;

  bool _showSplash = true;

  // Add AudioPlayer instance
  final AudioPlayer _player = AudioPlayer();

  // URl from telegram
  Future<void> openTelegram() async {
    final Uri url = Uri.parse("https://t.me/BenjaminKirby_BenTennyson");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  void initState() {
    super.initState();

    // Show splash for 3 seconds then show login form
    Timer(const Duration(seconds: 3), () {
      setState(() {
        _showSplash = false;
      });
    });
  }

  // Method to show custom SnackBar
  void showCustomSnackBar(String message, {bool isError = true}) async {
    // Play appropriate sound
    await _player.play(
      AssetSource(
        isError ? 'sounds/errorSounds.wav' : 'sounds/successSounds.wav',
      ),
    );

    // Define colors and icon
    final backgroundColor =
        isError ? Colors.red.shade600 : Colors.green.shade500;
    final icon = isError ? Icons.error_outline : Icons.check_circle_outline;

    // Show the custom SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: screenWidth / 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth / 26,
                  fontFamily: "NexaBold",
                  height: 1.3,
                ),
                textAlign: TextAlign.left,
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        elevation: 10,
        margin: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.1,
          vertical: screenHeight * 0.05,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    if (_showSplash) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Lottie.asset(
            'assets/splashscreen.json',
            width: screenWidth / 2,
            onLoaded: (composition) {
              // Auto hide splash after animation duration
              Future.delayed(composition.duration, () {
                setState(() {
                  _showSplash = false;
                });
              });
            },
          ),
        ),
      );
    }

    final bool isKeyboardVisible = KeyboardVisibilityProvider.isKeyboardVisible(
      context,
    );

    // Login form UI
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          isKeyboardVisible
              ? SizedBox(height: screenHeight / 20)
              : Container(
                height: screenHeight / 3.5,
                width: screenWidth,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(70),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: screenWidth / 4,
                  ),
                ),
              ),

          // Title
          Padding(
            padding: EdgeInsets.only(
              top: screenHeight / 30,
              left: screenWidth / 15,
            ),
            child: Text(
              "Welcome Back!",
              style: TextStyle(
                fontSize: screenWidth / 22,
                fontFamily: "NexaBold",
              ),
            ),
          ),

          const SizedBox(height: 8),
          // Login Form
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: screenWidth / 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  fieldTitle("Employee ID"),
                  customField("Enter your employee id", idController, false),

                  SizedBox(height: screenHeight * 0.015), // Reduced spacing

                  fieldTitle("Password"),
                  customField("Enter your password", passController, true),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: openTelegram,
                      child: TextButton(
                        onPressed: openTelegram,
                        child: Text(
                          "Forgot Password?",
                          style: TextStyle(
                            fontFamily: "NexaRegular",
                            color: Colors.grey.shade600,
                            fontSize: screenWidth / 32,
                          ),
                        ),
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap:
                        _isLoading
                            ? null
                            : () async {
                              setState(() {
                                _isLoading = true;
                              });

                              FocusScope.of(context).unfocus();
                              String id = idController.text.trim();
                              String password = passController.text.trim();

                              if (id.isEmpty) {
                                showCustomSnackBar(
                                  "Employee id is still empty!",
                                );
                                setState(() => _isLoading = false);
                              } else if (password.isEmpty) {
                                showCustomSnackBar("Password is still empty!");
                                setState(() => _isLoading = false);
                              } else {
                                try {
                                  QuerySnapshot snap =
                                      await FirebaseFirestore.instance
                                          .collection("Employee")
                                          .where('id', isEqualTo: id)
                                          .get();

                                  if (snap.docs.isEmpty) {
                                    showCustomSnackBar(
                                      "Employee id does not exist!",
                                    );
                                    setState(() => _isLoading = false);
                                    return;
                                  }

                                  if (password == snap.docs[0]['password']) {
                                    sharedPreferences =
                                        await SharedPreferences.getInstance();
                                    sharedPreferences.setString(
                                      'employeeId',
                                      id,
                                    );
                                    sharedPreferences.setString(
                                      'userDocId',
                                      snap.docs[0].id,
                                    );

                                    User.employeeId = id;
                                    User.id = snap.docs[0].id;

                                    showCustomSnackBar(
                                      "Login successful!",
                                      isError: false,
                                    );
                                    await Future.delayed(Duration(seconds: 1));

                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => const HomeScreen(),
                                      ),
                                    );
                                  } else {
                                    showCustomSnackBar(
                                      "Password is not correct!",
                                    );
                                    setState(() => _isLoading = false);
                                  }
                                } catch (e) {
                                  showCustomSnackBar("Error occurred!");
                                  setState(() => _isLoading = false);
                                }
                              }
                            },
                    child: Container(
                      height: 45,
                      width: double.infinity,
                      margin: EdgeInsets.only(top: screenHeight / 40),
                      decoration: BoxDecoration(
                        color: _isLoading ? Colors.grey : primary,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withOpacity(0.4),
                            offset: Offset(0, 4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child:
                            _isLoading
                                ? CircularProgressIndicator(color: primary)
                                : Text(
                                  "LOGIN",
                                  style: TextStyle(
                                    fontFamily: "NexaBold",
                                    fontSize: screenWidth / 28,
                                    color: Colors.white,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.015),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          fontFamily: "NexaRegular",
                          color: Colors.grey.shade600,
                          fontSize: screenWidth / 32,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: Text(
                          "Register",
                          style: TextStyle(
                            fontFamily: "NexaBold",
                            color: primary,
                            fontSize: screenWidth / 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Label
  Widget fieldTitle(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: title,
              style: TextStyle(
                fontSize: screenWidth / 38,
                fontFamily: "NexaBold",
                color: Colors.black,
              ),
            ),
            TextSpan(
              text: " *",
              style: TextStyle(
                fontSize: screenWidth / 38,
                fontFamily: "NexaBold",
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Input
  Widget customField(
    String hint,
    TextEditingController controller,
    bool isPassword,
  ) {
    return Container(
      width: screenWidth,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(2, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: screenWidth / 7,
            child: Icon(
              isPassword ? Icons.lock : Icons.person,
              color: primary,
              size: screenWidth / 18,
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: screenWidth / 30),
              child: TextFormField(
                controller: controller,
                obscureText: isPassword ? _obscurePassword : false,
                enableSuggestions: false,
                autocorrect: false,
                maxLines: 1,
                style: TextStyle(
                  fontSize: screenWidth / 32,
                  fontFamily: "NexaRegular",
                ),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    vertical: screenHeight / 50,
                  ),
                  border: InputBorder.none,
                  hintText: hint,
                  suffixIcon:
                      isPassword
                          ? IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          )
                          : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
