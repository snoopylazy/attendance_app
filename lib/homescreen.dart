import 'package:attendance_app/absent_request_screen.dart';
import 'package:attendance_app/calendarscreen.dart';
import 'package:attendance_app/model/user.dart';
import 'package:attendance_app/profilescreen.dart';
import 'package:attendance_app/services/location_service.dart';
import 'package:attendance_app/todayscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double screenHeight = 0;
  double screenWidth = 0;

  Color primary = const Color(0xFFE53935);

  int currentIndex = 1;
  int _selectedIndex = 1;

  List<IconData> navigationIcons = [
    FontAwesomeIcons.calendarDays,
    FontAwesomeIcons.check,
    FontAwesomeIcons.paperPlane,
    FontAwesomeIcons.user,
  ];

  @override
  void initState() {
    super.initState();
    _startLocationService();
    getId().then((value) {
      _getCredentials();
      _getProfilePic();
    });
  }

  // Fetch User
  // Future<void> _initializeUser() async {
  //   // Wait to get User.id first
  //   QuerySnapshot snap =
  //       await FirebaseFirestore.instance
  //           .collection("Employee")
  //           .where('id', isEqualTo: User.employeeId)
  //           .get();

  //   if (snap.docs.isNotEmpty) {
  //     User.id = snap.docs[0].id;

  //     // Then fetch credentials and profile
  //     DocumentSnapshot doc =
  //         await FirebaseFirestore.instance
  //             .collection("Employee")
  //             .doc(User.id)
  //             .get();

  //     setState(() {
  //       User.canEdit = doc['canEdit'];
  //       User.firstName = doc['firstName'];
  //       User.lastName = doc['lastName'];
  //       User.birthDate = doc['birthDate'];
  //       User.address = doc['address'];
  //       User.profilePicLink = doc['profilePic'];
  //     });
  //   } else {
  //     debugPrint("No user found with employeeId ${User.employeeId}");
  //   }
  // }

  // GetPermissioon
  void _getCredentials() async {
    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection("Employee")
              .doc(User.id)
              .get();
      setState(() {
        User.canEdit = doc['canEdit'];
        User.firstName = doc['firstName'];
        User.lastName = doc['lastName'];
        User.birthDate = doc['birthDate'];
        User.address = doc['address'];
      });
    } catch (e) {
      return;
    }
  }

  // GetUser pic
  void _getProfilePic() async {
    DocumentSnapshot doc =
        await FirebaseFirestore.instance
            .collection("Employee")
            .doc(User.id)
            .get();
    setState(() {
      User.profilePicLink = doc['profilePic'];
    });
  }

  // Currrent Laction
  void _startLocationService() async {
    LocationService().initialize();

    LocationService().getLongitude().then((value) {
      setState(() {
        User.long = value!;
      });

      LocationService().getLatitude().then((value) {
        setState(() {
          User.lat = value!;
        });
      });
    });
  }

  // Fetch ID
  Future<void> getId() async {
    QuerySnapshot snap =
        await FirebaseFirestore.instance
            .collection("Employee")
            .where('id', isEqualTo: User.employeeId)
            .get();

    setState(() {
      User.id = snap.docs[0].id;
    });
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: [
          CalendarScreen(),
          TodayScreen(),
          AbsentRequestScreen(),
          ProfileScreen(),
        ],
      ),

      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: primary, width: 2),
          boxShadow: [
            BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(0.1)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
          child: GNav(
            gap: 8,
            selectedIndex: _selectedIndex,
            onTabChange: (index) {
              setState(() {
                _selectedIndex = index;
                currentIndex = index;
              });
            },
            color: Colors.grey[600],
            activeColor: primary,
            tabBackgroundColor: primary.withOpacity(0.15),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            tabs: const [
              GButton(
                icon: FontAwesomeIcons.calendarDays,
                text: 'Report',
                textStyle: TextStyle(
                  fontFamily: 'NexaBold',
                  color: Colors.red,
                ),
              ),
              GButton(
                icon: FontAwesomeIcons.check,
                text: 'Check-In',
                textStyle: TextStyle(
                  fontFamily: 'NexaBold',
                  color: Colors.red,
                ),
              ),
              GButton(
                icon: FontAwesomeIcons.paperPlane,
                text: 'Request',
                textStyle: TextStyle(
                  fontFamily: 'NexaBold',
                  color: Colors.red,
                ),
              ),
              GButton(
                icon: FontAwesomeIcons.user,
                text: 'Profile',
                textStyle: TextStyle(
                  fontFamily: 'NexaBold',
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
