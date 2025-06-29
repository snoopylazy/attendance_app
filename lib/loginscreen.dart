import 'dart:async';
import 'package:attendance_app/homescreen.dart';
import 'package:attendance_app/model/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:attendance_app/registerscreen.dart';

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

  Color primary = const Color(0xffeef444c);

  late SharedPreferences sharedPreferences;

  bool _obscurePassword = true;

  bool _showSplash = true;

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

  // Method to show custom SnackBar (KEEP ONLY ONE VERSION)
  void showCustomSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: Colors.white,
            fontSize: screenWidth / 24,
            fontFamily: "NexaBold",
          ),
          textAlign: TextAlign.center,
        ),
        backgroundColor: isError ? Colors.red[700] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          top: screenHeight * 0.05,
          left: screenWidth * 0.1,
          right: screenWidth * 0.1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    if (_showSplash) {
      // Splash screen UI
      return Scaffold(
        backgroundColor: primary,
        body: Center(
          child: Icon(Icons.person, color: Colors.white, size: screenWidth / 3),
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
              ? SizedBox(height: screenHeight / 16)
              : Container(
                height: screenHeight / 2.8,
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
              top: screenHeight / 20,
              left: screenWidth / 12,
            ),
            child: Text(
              "Welcome Back!",
              style: TextStyle(
                fontSize: screenWidth / 14,
                fontFamily: "NexaBold",
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Login Form
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: screenWidth / 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  fieldTitle("Employee ID"),
                  customField("Enter your employee id", idController, false),

                  SizedBox(height: screenHeight * 0.03),

                  fieldTitle("Password"),
                  customField("Enter your password", passController, true),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: openTelegram,
                      child: Text(
                        "Forgot Password?",
                        style: TextStyle(
                          fontFamily: "NexaLight",
                          color: Colors.grey.shade600,
                          fontSize: screenWidth / 30,
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
                                setState(() {
                                  _isLoading = false;
                                });
                              } else if (password.isEmpty) {
                                showCustomSnackBar("Password is still empty!");
                                setState(() {
                                  _isLoading = false;
                                });
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
                                    setState(() {
                                      _isLoading = false;
                                    });
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

                                    await Future.delayed(
                                      const Duration(seconds: 1),
                                    );
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
                                    setState(() {
                                      _isLoading = false;
                                    });
                                  }
                                } catch (e) {
                                  showCustomSnackBar("Error occurred!");
                                  setState(() {
                                    _isLoading = false;
                                  });
                                }
                              }
                            },
                    child: Container(
                      height: 55,
                      width: double.infinity,
                      margin: EdgeInsets.only(top: screenHeight / 30),
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
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text(
                                  "LOGIN",
                                  style: TextStyle(
                                    fontFamily: "NexaBold",
                                    fontSize: screenWidth / 25,
                                    color: Colors.white,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                      ),
                    ),
                  ),

                  // Navigation to Register Screen
                  SizedBox(height: screenHeight * 0.02),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          fontFamily: "NexaLight",
                          color: Colors.grey.shade600,
                          fontSize: screenWidth / 30,
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
                            fontSize: screenWidth / 30,
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
      margin: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(fontSize: screenWidth / 26, fontFamily: "NexaBold"),
      ),
    );
  }

  // Input Form
  Widget customField(
    String hint,
    TextEditingController controller,
    bool isPassword,
  ) {
    return Container(
      width: screenWidth,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left-side icon
          Container(
            width: screenWidth / 6,
            child: Icon(
              isPassword ? Icons.lock : Icons.person,
              color: primary,
              size: screenWidth / 15,
            ),
          ),

          // TextField + optional eye icon
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: screenWidth / 30),
              child: TextFormField(
                controller: controller,
                obscureText: isPassword ? _obscurePassword : false,
                enableSuggestions: false,
                autocorrect: false,
                maxLines: 1,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    vertical: screenHeight / 35,
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
