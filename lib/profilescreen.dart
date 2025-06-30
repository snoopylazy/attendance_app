import 'package:attendance_app/model/user.dart';
import 'package:attendance_app/loginscreen.dart'; // make sure this path is correct
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

  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController addressController = TextEditingController();

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
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                _getProfilePic();
              },
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 24),
                height: 120,
                width: 120,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: primary,
                ),
                child: Center(
                  child:
                      User.profilePicLink.isEmpty
                          ? const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 80,
                          )
                          : ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              User.profilePicLink,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 80,
                                );
                              },
                            ),
                          ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Text(
                "Employee ${User.employeeId}",
                style: const TextStyle(fontFamily: "NexaBold", fontSize: 18),
              ),
            ),
            const SizedBox(height: 24),
            User.canEdit
                ? textField("First Name", "First name", firstNameController)
                : field("First Name", User.firstName),
            User.canEdit
                ? textField("Last Name", "Last name", lastNameController)
                : field("Last Name", User.lastName),
            User.canEdit
                ? GestureDetector(
                  onTap: () {
                    showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: primary,
                              secondary: primary,
                              onSecondary: Colors.white,
                            ),
                            textButtonTheme: TextButtonThemeData(
                              style: TextButton.styleFrom(
                                foregroundColor: primary,
                              ),
                            ),
                            textTheme: const TextTheme(
                              headlineMedium: TextStyle(fontFamily: "NexaBold"),
                              labelSmall: TextStyle(fontFamily: "NexaBold"),
                              labelLarge: TextStyle(fontFamily: "NexaBold"),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    ).then((value) {
                      if (value != null) {
                        setState(() {
                          birth = DateFormat("MM/dd/yyyy").format(value);
                        });
                      }
                    });
                  },
                  child: field("Date of Birth", birth),
                )
                : field("Date of Birth", User.birthDate),
            User.canEdit
                ? textField("Address", "Address", addressController)
                : field("Address", User.address),

            // SAVE Button (Only show when canEdit is true)
            User.canEdit
                ? GestureDetector(
                  onTap: () async {
                    String firstName = firstNameController.text;
                    String lastName = lastNameController.text;
                    String birthDate = birth;
                    String address = addressController.text;

                    if (User.canEdit) {
                      if (firstName.isEmpty) {
                        showSnackBar("Please enter your first name!");
                      } else if (lastName.isEmpty) {
                        showSnackBar("Please enter your last name!");
                      } else if (birthDate.isEmpty) {
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
                                User.firstName = firstName;
                                User.lastName = lastName;
                                User.birthDate = birthDate;
                                User.address = address;
                              });
                            });
                      }
                    } else {
                      showSnackBar(
                        "You can't edit anymore, please contact support team.",
                      );
                    }
                  },
                  child: Container(
                    height: kToolbarHeight,
                    width: screenWidth,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: primary,
                    ),
                    child: const Center(
                      child: Text(
                        "SAVE",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: "NexaBold",
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                )
                : const SizedBox(),

            Align(
              alignment: Alignment.centerRight, // Align right
              child: SizedBox(
                height: kToolbarHeight,
                child: TextButton.icon(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    "Log-out",
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: "NexaBold",
                      fontSize: 16,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear();

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget field(String title, String text) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: "NexaBold",
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          height: kToolbarHeight,
          width: screenWidth,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.only(left: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: primary, width: 2.5),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.black54,
                fontFamily: "NexaBold",
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget textField(
    String title,
    String hint,
    TextEditingController controller,
  ) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: "NexaBold",
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: controller,
            cursorColor: Colors.black54,
            maxLines: 1,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Colors.black54,
                fontFamily: "NexaBold",
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: primary),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: primary),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(text)),
    );
  }
}
