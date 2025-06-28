import 'package:attendance_app/absent_request_screen.dart';
import 'package:attendance_app/calendarscreen.dart';
import 'package:attendance_app/model/user.dart';
import 'package:attendance_app/profilescreen.dart';
import 'package:attendance_app/services/location_service.dart';
import 'package:attendance_app/todayscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double screenHeight = 0;
  double screenWidth = 0;

  Color primary = const Color(0xffeef444c);

  int currentIndex = 1;

  List<IconData> navigationIcons = [
    FontAwesomeIcons.calendarAlt,
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
  Future<void> _initializeUser() async {
    // Wait to get User.id first
    QuerySnapshot snap =
        await FirebaseFirestore.instance
            .collection("Employee")
            .where('id', isEqualTo: User.employeeId)
            .get();

    if (snap.docs.isNotEmpty) {
      User.id = snap.docs[0].id;

      // Then fetch credentials and profile
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
        User.profilePicLink = doc['profilePic'];
      });
    } else {
      debugPrint("No user found with employeeId ${User.employeeId}");
    }
  }

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
          new CalendarScreen(),
          new TodayScreen(),
          new AbsentRequestScreen(),
          new ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        height: 70,
        margin: const EdgeInsets.only(left: 12, right: 12, bottom: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(40)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(40)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < navigationIcons.length; i++) ...<Expanded>{
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        currentIndex = i;
                      });
                    },
                    child: Container(
                      height: screenHeight,
                      width: screenWidth,
                      color: Colors.white,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              navigationIcons[i],
                              color:
                                  i == currentIndex ? primary : Colors.black54,
                              size: i == currentIndex ? 30 : 26,
                            ),
                            i == currentIndex
                                ? Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  height: 3,
                                  width: 22,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(40),
                                    ),
                                    color: primary,
                                  ),
                                )
                                : const SizedBox(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              },
            ],
          ),
        ),
      ),
    );
  }
}
