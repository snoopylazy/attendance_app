import 'dart:async';
import 'package:attendance_app/homescreen.dart';
import 'package:attendance_app/model/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController idController = TextEditingController();
  TextEditingController passController = TextEditingController();

  double screenHeight = 0;
  double screenWidth = 0;

  Color primary = const Color(0xffeef444c);

  late SharedPreferences sharedPreferences;

  bool _showSplash = true;

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
        children: [
          isKeyboardVisible
              ? SizedBox(height: screenHeight / 16)
              : Container(
                height: screenHeight / 2.5,
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
                    size: screenWidth / 5,
                  ),
                ),
              ),
          Container(
            margin: EdgeInsets.only(
              top: screenHeight / 15,
              bottom: screenHeight / 20,
            ),
            child: Text(
              "Login",
              style: TextStyle(
                fontSize: screenWidth / 18,
                fontFamily: "NexaBold",
              ),
            ),
          ),
          Container(
            alignment: Alignment.centerLeft,
            margin: EdgeInsets.symmetric(horizontal: screenWidth / 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                fieldTitle("Employee ID"),
                customField("Enter your employee id", idController, false),
                fieldTitle("Password"),
                customField("Enter your password", passController, true),
                GestureDetector(
                  onTap: () async {
                    FocusScope.of(context).unfocus();
                    String id = idController.text.trim();
                    String password = passController.text.trim();

                    if (id.isEmpty) {
                      showCustomSnackBar("Employee id is still empty!");
                    } else if (password.isEmpty) {
                      showCustomSnackBar("Password is still empty!");
                    } else {
                      try {
                        QuerySnapshot snap =
                            await FirebaseFirestore.instance
                                .collection("Employee")
                                .where('id', isEqualTo: id)
                                .get();

                        if (snap.docs.isEmpty) {
                          showCustomSnackBar("Employee id does not exist!");
                          return;
                        }

                        if (password == snap.docs[0]['password']) {
                          sharedPreferences =
                              await SharedPreferences.getInstance();

                          // Save employeeId and Firestore doc ID
                          sharedPreferences.setString('employeeId', id);
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

                          await Future.delayed(const Duration(seconds: 1));

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomeScreen(),
                            ),
                          );
                        } else {
                          showCustomSnackBar("Password is not correct!");
                        }
                      } catch (e) {
                        showCustomSnackBar("Error occurred!");
                      }
                    }
                  },
                  child: Container(
                    height: 60,
                    width: screenWidth,
                    margin: EdgeInsets.only(top: screenHeight / 40),
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: const BorderRadius.all(Radius.circular(30)),
                    ),
                    child: Center(
                      child: Text(
                        "LOGIN",
                        style: TextStyle(
                          fontFamily: "NexaBold",
                          fontSize: screenWidth / 26,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget fieldTitle(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(fontSize: screenWidth / 26, fontFamily: "NexaBold"),
      ),
    );
  }

  Widget customField(
    String hint,
    TextEditingController controller,
    bool obscure,
  ) {
    return Container(
      width: screenWidth,
      margin: EdgeInsets.only(bottom: 12),
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
          Container(
            width: screenWidth / 6,
            child: Icon(Icons.person, color: primary, size: screenWidth / 15),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: screenWidth / 12),
              child: TextFormField(
                controller: controller,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    vertical: screenHeight / 35,
                  ),
                  border: InputBorder.none,
                  hintText: hint,
                ),
                maxLines: 1,
                obscureText: obscure,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
