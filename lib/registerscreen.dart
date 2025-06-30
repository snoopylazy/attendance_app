// import 'package:attendance_app/loginscreen.dart';
import 'package:attendance_app/model/user.dart';
import 'package:attendance_app/homescreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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
  Color primary = const Color(0xffeef444c);

  Future<void> _pickBirthDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  void showCustomSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: screenWidth / 24,
            fontFamily: "NexaBold",
          ),
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
      margin: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(fontSize: screenWidth / 26, fontFamily: "NexaRegular"),
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
            child: Icon(icon, color: primary, size: screenWidth / 15),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: screenWidth / 30),
              child: TextFormField(
                controller: controller,
                obscureText: isPassword,
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

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
                size: screenWidth / 4,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              top: screenHeight / 20,
              left: screenWidth / 12,
            ),
            child: Text(
              "Create Account",
              style: TextStyle(
                fontSize: screenWidth / 14,
                fontFamily: "NexaBold",
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: screenWidth / 12),
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
                          vertical: 16,
                          horizontal: 12,
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          _birthDate == null
                              ? 'Select your birth date'
                              : DateFormat.yMMMd().format(_birthDate!),
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                    ),

                    GestureDetector(
                      onTap: _isLoading ? null : _register,
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
                              offset: const Offset(0, 4),
                              blurRadius: 10,
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
                                      fontSize: screenWidth / 25,
                                      color: Colors.white,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.02),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account? ",
                          style: TextStyle(
                            fontFamily: "NexaLight",
                            color: Colors.grey.shade600,
                            fontSize: screenWidth / 30,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            "Login",
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
          ),
        ],
      ),
    );
  }
}
