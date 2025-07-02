// import 'package:attendance_app/loginscreen.dart';
import 'package:attendance_app/model/user.dart';
import 'package:attendance_app/homescreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  DateTime? _birthDate;
  bool _isLoading = false;

  double screenHeight = 0;
  double screenWidth = 0;
  Color primary = const Color(0xFFE53935);

  // Add AudioPlayer instance
  final AudioPlayer _player = AudioPlayer();

  Future<void> _pickBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  void showCustomSnackBar(String message, {bool isError = true}) async {
    // Play sound based on message type
    await _player.play(
      AssetSource(
        isError ? 'sounds/errorSounds.wav' : 'sounds/successSounds.wav',
      ),
    );

    // Define style
    final Color backgroundColor =
        isError ? Colors.red.shade600 : Colors.green.shade500;
    final IconData icon =
        isError ? Icons.error_outline : Icons.check_circle_outline;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: screenWidth / 20),
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
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        elevation: 10,
        margin: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.08,
          vertical: screenHeight * 0.05,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      showCustomSnackBar("Please select your birth date");
      return;
    }

    setState(() => _isLoading = true);

    String employeeId = _employeeIdController.text.trim();

    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('Employee')
              .where('employeeId', isEqualTo: employeeId)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        showCustomSnackBar("Employee ID already registered.");
        setState(() => _isLoading = false);
        return;
      }

      final docRef = await FirebaseFirestore.instance
          .collection('Employee')
          .add({
            'id': employeeId,
            'employeeId': employeeId,
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'birthDate': DateFormat('yyyy-MM-dd').format(_birthDate!),
            'address': _addressController.text.trim(),
            'password': _passwordController.text.trim(),
            'profilePic': '',
            'canEdit': true,
          });

      User.id = docRef.id;
      User.employeeId = employeeId;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('employeeId', employeeId);
      await prefs.setString('userDocId', docRef.id);

      showCustomSnackBar("Registered successfully!", isError: false);
      await Future.delayed(const Duration(seconds: 1));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      showCustomSnackBar("Registration failed: $e");
      setState(() => _isLoading = false);
    }
  }

  Widget fieldTitle(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: title,
              style: TextStyle(
                fontSize: screenWidth / 36,
                fontFamily: "NexaRegular",
                color: Colors.black,
              ),
            ),
            TextSpan(
              text: " *",
              style: TextStyle(
                fontSize: screenWidth / 36,
                fontFamily: "NexaRegular",
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget customField(
    String hint,
    TextEditingController controller,
    bool isPassword,
    IconData icon,
  ) {
    return Container(
      width: screenWidth,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(1, 1)),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: screenWidth / 9,
            child: Icon(icon, color: primary, size: screenWidth / 24),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: screenWidth / 30),
              child: TextFormField(
                controller: controller,
                obscureText: isPassword,
                style: TextStyle(
                  fontSize: screenWidth / 36,
                  fontFamily: "NexaRegular",
                ),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    vertical: screenHeight / 60,
                  ),
                  border: InputBorder.none,
                  hintText: hint,
                  hintStyle: TextStyle(fontSize: screenWidth / 36),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
                Icons.person_add,
                color: Colors.white,
                size: screenWidth / 4,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              top: screenHeight / 40,
              left: screenWidth / 20,
            ),
            child: Text(
              "Create Account",
              style: TextStyle(
                fontSize: screenWidth / 22,
                fontFamily: "NexaBold",
              ),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: screenWidth / 15),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    fieldTitle("Employee ID"),
                    customField(
                      "Enter your employee ID",
                      _employeeIdController,
                      false,
                      Icons.badge,
                    ),

                    fieldTitle("First Name"),
                    customField(
                      "Enter your first name",
                      _firstNameController,
                      false,
                      Icons.person,
                    ),

                    fieldTitle("Last Name"),
                    customField(
                      "Enter your last name",
                      _lastNameController,
                      false,
                      Icons.person_outline,
                    ),

                    fieldTitle("Address"),
                    customField(
                      "Enter your address",
                      _addressController,
                      false,
                      Icons.home,
                    ),

                    fieldTitle("Password"),
                    customField(
                      "Enter your password",
                      _passwordController,
                      true,
                      Icons.lock,
                    ),

                    fieldTitle("Birth Date"),
                    GestureDetector(
                      onTap: _pickBirthDate,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 12,
                        ),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          _birthDate == null
                              ? 'Select your birth date'
                              : DateFormat.yMMMd().format(_birthDate!),
                          style: TextStyle(
                            fontSize: screenWidth / 36,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),

                    GestureDetector(
                      onTap: _isLoading ? null : _register,
                      child: Container(
                        height: 42,
                        width: double.infinity,
                        margin: EdgeInsets.only(top: screenHeight / 60),
                        decoration: BoxDecoration(
                          color: _isLoading ? Colors.grey : primary,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withOpacity(0.4),
                              offset: const Offset(0, 3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Center(
                          child:
                              _isLoading
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : Text(
                                    "REGISTER",
                                    style: TextStyle(
                                      fontFamily: "NexaBold",
                                      fontSize: screenWidth / 32,
                                      color: Colors.white,
                                      letterSpacing: 1.1,
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
                          "Already have an account? ",
                          style: TextStyle(
                            fontFamily: "NexaRegular",
                            color: Colors.grey.shade600,
                            fontSize: screenWidth / 36,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            "Login",
                            style: TextStyle(
                              fontFamily: "NexaBold",
                              color: primary,
                              fontSize: screenWidth / 36,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.015),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
