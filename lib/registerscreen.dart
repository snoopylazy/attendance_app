import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController idController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  double screenHeight = 0;
  double screenWidth = 0;

  Color primary = const Color(0xffeef444c);

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = KeyboardVisibilityProvider.isKeyboardVisible(
      context,
    );
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: SingleChildScrollView(
          reverse: true, // Keeps bottom visible when keyboard shows
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              children: [
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
                          Icons.person_add,
                          color: Colors.white,
                          size: screenWidth / 5,
                        ),
                      ),
                    ),
                Container(
                  margin: EdgeInsets.only(top: screenHeight / 20),
                  child: Text(
                    "Register",
                    style: TextStyle(
                      fontSize: screenWidth / 18,
                      fontFamily: "NexaBold",
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: screenWidth / 12,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      fieldTitle("First Name"),
                      customField(
                        "Enter first name",
                        firstNameController,
                        false,
                      ),
                      fieldTitle("Last Name"),
                      customField("Enter last name", lastNameController, false),
                      fieldTitle("Employee ID"),
                      customField("Enter employee ID", idController, false),
                      fieldTitle("Password"),
                      customField("Enter password", passwordController, true),
                      GestureDetector(
                        onTap: () async {
                          // Same logic here — unchanged
                        },
                        child: Container(
                          height: 55,
                          width: screenWidth,
                          margin: const EdgeInsets.only(top: 20),
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Center(
                            child: Text(
                              "REGISTER",
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
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Center(
                          child: Text(
                            "Back to Login",
                            style: TextStyle(
                              color: primary,
                              fontSize: screenWidth / 28,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget fieldTitle(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
          Container(
            width: screenWidth / 6,
            child: Icon(Icons.person, color: primary, size: screenWidth / 15),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: screenWidth / 12),
              child: TextFormField(
                controller: controller,
                obscureText: obscure,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    vertical: screenHeight / 35,
                  ),
                  border: InputBorder.none,
                  hintText: hint,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
