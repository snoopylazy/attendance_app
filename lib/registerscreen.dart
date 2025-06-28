import 'package:attendance_app/homescreen.dart';
import 'package:attendance_app/loginscreen.dart'; // Import LoginScreen for navigation
import 'package:attendance_app/model/user.dart';
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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please select your birth date')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String employeeId = _employeeIdController.text.trim();

    try {
      // Check if employeeId already exists
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('Employee')
              .where('employeeId', isEqualTo: employeeId)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Employee ID already registered. Please login.'),
          ),
        );
        return;
      }

      // Add new user document with password field
      final docRef = await FirebaseFirestore.instance
          .collection('Employee')
          .add({
            'employeeId': employeeId,
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'birthDate': DateFormat('yyyy-MM-dd').format(_birthDate!),
            'address': _addressController.text.trim(),
            'password': _passwordController.text.trim(),
            'profilePic': '', // default empty
            'canEdit': true, // default permission
          });

      // Save to local user model
      User.id = docRef.id;
      User.employeeId = employeeId;
      User.firstName = _firstNameController.text.trim();
      User.lastName = _lastNameController.text.trim();
      User.birthDate = DateFormat('yyyy-MM-dd').format(_birthDate!);
      User.address = _addressController.text.trim();
      User.profilePicLink = '';
      User.canEdit = true;

      // Save employeeId and userDocId in shared preferences for auto-login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('employeeId', employeeId);
      await prefs.setString('userDocId', docRef.id);

      setState(() {
        _isLoading = false;
      });

      // Navigate to HomeScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Registration failed: $e')));
    }
  }

  @override
  void dispose() {
    _employeeIdController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _employeeIdController,
                decoration: InputDecoration(labelText: 'Employee ID'),
                validator:
                    (val) =>
                        val == null || val.isEmpty ? 'Enter Employee ID' : null,
              ),
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(labelText: 'First Name'),
                validator:
                    (val) =>
                        val == null || val.isEmpty ? 'Enter First Name' : null,
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(labelText: 'Last Name'),
                validator:
                    (val) =>
                        val == null || val.isEmpty ? 'Enter Last Name' : null,
              ),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Address'),
                validator:
                    (val) =>
                        val == null || val.isEmpty ? 'Enter Address' : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? 'Enter Password' : null,
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  const Text('Birth Date: '),
                  Text(
                    _birthDate == null
                        ? 'Not selected'
                        : DateFormat.yMMMd().format(_birthDate!),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _pickBirthDate,
                    child: const Text('Select Date'),
                  ),
                ],
              ),
              SizedBox(height: 24),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: _register,
                    child: const Text('Register'),
                  ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // Go back to LoginScreen
                    },
                    child: Text(
                      "Login",
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
