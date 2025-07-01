import 'package:attendance_app/model/user.dart';
import 'package:attendance_app/loginscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  double screenHeight = 0;
  double screenWidth = 0;

  Color primary = const Color(0xFFE53935);

  String birth = "Date of birth";

  bool showEditCard = false;

  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    firstNameController.text = User.firstName;
    lastNameController.text = User.lastName;
    addressController.text = User.address;
    birth = User.birthDate.isNotEmpty ? User.birthDate : "Date of birth";
  }

  // Get user profile pic
  void _getProfilePic() async {
    DocumentSnapshot doc =
        await FirebaseFirestore.instance
            .collection("Employee")
            .doc(User.id)
            .get();
    final data = doc.data() as Map<String, dynamic>?;
    setState(() {
      if (data != null &&
          data.containsKey('profilePic') &&
          (data['profilePic'] as String).isNotEmpty) {
        User.profilePicLink = data['profilePic'];
      } else {
        User.profilePicLink = "";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: "NexaRegular"),
      ),
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text(
            'Profile',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: Colors.red[600],
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                if (!User.canEdit) {
                  setState(() {
                    User.canEdit = true;
                    showEditCard = true;
                  });
                }
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Profile Header Section
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.red[600],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Profile Picture
                    Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child:
                                User.profilePicLink.isNotEmpty
                                    ? Image.network(
                                      User.profilePicLink,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return _buildDefaultAvatar();
                                      },
                                    )
                                    : _buildDefaultAvatar(),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: Colors.red[600],
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 18,
                              ),
                              onPressed: () {
                                _getProfilePic();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    // User Name
                    Text(
                      "${User.firstName} ${User.lastName}",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Employee ID
                    Text(
                      "Student ID: ${User.employeeId}",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Profile Information Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Personal Information Card
                    _buildInfoCard(
                      title: "Personal Information",
                      children: [
                        _buildInfoRow(
                          Icons.person,
                          "First Name",
                          User.firstName,
                        ),
                        _buildInfoRow(
                          Icons.person_outline,
                          "Last Name",
                          User.lastName,
                        ),
                        _buildInfoRow(Icons.cake, "Birth Date", User.birthDate),
                        _buildInfoRow(Icons.home, "Address", User.address),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Edit Section (if canEdit)
                    if (showEditCard) _buildEditCard(),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          bool? shouldLogout = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: Row(
                                  children: [
                                    const Icon(
                                      Icons.logout,
                                      color: Colors.red,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Logout',
                                      style: TextStyle(
                                        color: Colors.red[700],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                                content: const Text(
                                  'Are you sure you want to logout?',
                                  style: TextStyle(fontSize: 15),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(false),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(true),
                                    child: Text(
                                      'Yes',
                                      style: TextStyle(
                                        color: Colors.red[600],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                          if (shouldLogout == true) {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.clear();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.grey[300],
      child: Icon(Icons.person, size: 60, color: Colors.red[600]),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 15),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.red[600], size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Edit Information",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      showEditCard = false;
                      User.canEdit = false;
                    });
                  },
                  child: const Icon(Icons.close, color: Colors.red),
                ),
              ],
            ),

            const SizedBox(height: 15),
            _editTextField("First Name", firstNameController),
            _editTextField("Last Name", lastNameController),
            _editTextField("Address", addressController),

            GestureDetector(
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() {
                    birth = DateFormat("MM/dd/yyyy").format(picked);
                  });
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[600]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cake, color: Colors.red),
                    const SizedBox(width: 10),
                    Text(
                      birth,
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 16,
                        fontFamily: "NexaBold",
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  String firstName = firstNameController.text;
                  String lastName = lastNameController.text;
                  String birthDate = birth;
                  String address = addressController.text;

                  if (firstName.isEmpty) {
                    showSnackBar("Please enter your first name!");
                  } else if (lastName.isEmpty) {
                    showSnackBar("Please enter your last name!");
                  } else if (birthDate.isEmpty ||
                      birthDate == "Date of birth") {
                    showSnackBar("Please enter your birth date!");
                  } else if (address.isEmpty) {
                    showSnackBar("Please enter your address!");
                  } else {
                    await FirebaseFirestore.instance
                        .collection("Employee")
                        .doc(User.id)
                        .update({
                          'firstName': firstName,
                          'lastName': lastName,
                          'birthDate': birthDate,
                          'address': address,
                          'canEdit': false,
                        })
                        .then((value) {
                          setState(() {
                            User.canEdit = false;
                            showEditCard = false;
                            User.firstName = firstName;
                            User.lastName = lastName;
                            User.birthDate = birthDate;
                            User.address = address;
                          });
                        });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editTextField(String label, TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        cursorColor: Colors.black54,
        maxLines: 1,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Colors.black54,
            fontFamily: "NexaBold",
          ),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red, width: 1.5),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red),
          ),
        ),
      ),
    );
  }

  void showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(text)),
    );
  }
}
