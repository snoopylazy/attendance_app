import 'dart:async';
import 'package:attendance_app/model/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:location/location.dart';
import 'package:attendance_app/services/location_service.dart';
import 'dart:math';

class TodayScreen extends StatefulWidget {
  const TodayScreen({Key? key}) : super(key: key);

  @override
  _TodayScreenState createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  double screenHeight = 0;
  double screenWidth = 0;

  String checkIn = "--/--";
  String checkOut = "--/--";
  String checkInLocation = " ";
  String checkOutLocation = " ";
  String scanResult = " ";
  String officeCode = " ";

  Color primary = const Color(0xffeef444c);

  final GlobalKey<SlideActionState> _slideKey = GlobalKey<SlideActionState>();
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _initializeLocationService();
    _getRecord();
    _getOfficeCode();
    _loadTodayRecord();
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  // Initialize LocationService
  Future<void> _initializeLocationService() async {
    bool isInitialized = await _locationService.initialize();
    if (!isInitialized) {
      showCustomSnackBar("Unable to initialize location services!");
    }
  }

  // Method to show custom SnackBar
  void showCustomSnackBar(String message, {bool isError = true}) {
    if (!mounted) return; // Prevent SnackBar if not mounted
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

  // Show Reason Dialog
  Future<String?> _showReasonDialog(bool isLateCheckIn) async {
    TextEditingController reasonController = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(
            isLateCheckIn ? "Late Check-in Reason" : "Early Check-out Reason",
          ),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              hintText: "Please enter your reason",
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.trim().isEmpty) {
                  return;
                }
                Navigator.of(context).pop(reasonController.text.trim());
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  // Fetch Data
  Future<void> _loadTodayRecord() async {
    if (User.employeeId.isEmpty) return;

    QuerySnapshot snap =
        await FirebaseFirestore.instance
            .collection("Employee")
            .where('id', isEqualTo: User.employeeId)
            .get();

    if (snap.docs.isEmpty) return;

    DocumentSnapshot snap2 =
        await FirebaseFirestore.instance
            .collection("Employee")
            .doc(snap.docs[0].id)
            .collection("Record")
            .doc(DateFormat('dd MMMM yyyy').format(DateTime.now()))
            .get();

    if (snap2.exists) {
      setState(() {
        checkIn = snap2['checkIn'] ?? "--/--";
        checkOut = snap2['checkOut'] ?? "--/--";
        checkInLocation = snap2['checkInLocation'] ?? " ";
        checkOutLocation = snap2['checkOutLocation'] ?? " ";
      });
    } else {
      setState(() {
        checkIn = "--/--";
        checkOut = "--/--";
        checkInLocation = " ";
        checkOutLocation = " ";
      });
    }
  }

  // Fetch Office Code
  void _getOfficeCode() async {
    DocumentSnapshot snap =
        await FirebaseFirestore.instance
            .collection("Attributes")
            .doc("Office1")
            .get();
    setState(() {
      officeCode = snap['code'];
    });
  }

  // Fetch Location and Convert to String
  Future<void> _getLocation() async {
    try {
      LocationData? locData = await _locationService.getLocation();
      if (locData == null ||
          locData.latitude == null ||
          locData.longitude == null) {
        showCustomSnackBar("Unable to fetch location!");
        return;
      }

      List<Placemark> placemark = await placemarkFromCoordinates(
        locData.latitude!,
        locData.longitude!,
      );

      setState(() {
        checkInLocation =
            "${placemark[0].street}, ${placemark[0].administrativeArea}, ${placemark[0].postalCode}, ${placemark[0].country}";
      });
    } catch (e) {
      // showCustomSnackBar("Error getting location!");
    }
  }

  // Scan QR Code and Handle Check-in/Check-out
  Future<void> scanQRandCheck() async {
    String result = " ";

    try {
      result = await FlutterBarcodeScanner.scanBarcode(
        "#ffffff",
        "Cancel",
        false,
        ScanMode.QR,
      );
    } catch (e) {
      showCustomSnackBar("Error scanning QR code!");
      return;
    }

    if (!mounted) return; // Prevent further execution if not mounted

    setState(() {
      scanResult = result;
    });

    if (scanResult == officeCode) {
      LocationData? locData = await _locationService.getLocation();
      if (locData == null ||
          locData.latitude == null ||
          locData.longitude == null) {
        showCustomSnackBar("Location not available!");
        return;
      }

      await _getLocation();

      QuerySnapshot snap =
          await FirebaseFirestore.instance
              .collection("Employee")
              .where('id', isEqualTo: User.employeeId)
              .get();

      if (snap.docs.isEmpty) {
        showCustomSnackBar("Employee not found!");
        return;
      }

      DocumentSnapshot snap2 =
          await FirebaseFirestore.instance
              .collection("Employee")
              .doc(snap.docs[0].id)
              .collection("Record")
              .doc(DateFormat('dd MMMM yyyy').format(DateTime.now()))
              .get();

      try {
        String checkInTime = snap2['checkIn'];

        setState(() {
          checkOut = DateFormat('hh:mm').format(DateTime.now());
          checkOutLocation = checkInLocation;
        });

        await FirebaseFirestore.instance
            .collection("Employee")
            .doc(snap.docs[0].id)
            .collection("Record")
            .doc(DateFormat('dd MMMM yyyy').format(DateTime.now()))
            .update({
              'date': Timestamp.now(),
              'checkIn': checkInTime,
              'checkOut': checkOut,
              'checkInLocation': snap2['checkInLocation'] ?? checkInLocation,
              'checkOutLocation': checkOutLocation,
              'latitude': locData.latitude,
              'longitude': locData.longitude,
            });

        showCustomSnackBar("Check-out recorded successfully!", isError: false);
      } catch (e) {
        setState(() {
          checkIn = DateFormat('hh:mm').format(DateTime.now());
          checkInLocation = checkInLocation;
        });

        await FirebaseFirestore.instance
            .collection("Employee")
            .doc(snap.docs[0].id)
            .collection("Record")
            .doc(DateFormat('dd MMMM yyyy').format(DateTime.now()))
            .set({
              'date': Timestamp.now(),
              'checkIn': checkIn,
              'checkOut': "--/--",
              'checkInLocation': checkInLocation,
              'checkOutLocation': " ",
              'latitude': locData.latitude,
              'longitude': locData.longitude,
            });

        showCustomSnackBar("Check-in recorded successfully!", isError: false);
      }
    } else {
      showCustomSnackBar("Invalid QR code!");
    }
  }

  // Fetch Record
  void _getRecord() async {
    try {
      QuerySnapshot snap =
          await FirebaseFirestore.instance
              .collection("Employee")
              .where('id', isEqualTo: User.employeeId)
              .get();

      if (snap.docs.isEmpty) return;

      DocumentSnapshot snap2 =
          await FirebaseFirestore.instance
              .collection("Employee")
              .doc(snap.docs[0].id)
              .collection("Record")
              .doc(DateFormat('dd MMMM yyyy').format(DateTime.now()))
              .get();

      setState(() {
        checkIn = snap2['checkIn'] ?? "--/--";
        checkOut = snap2['checkOut'] ?? "--/--";
        checkInLocation = snap2['checkInLocation'] ?? " ";
        checkOutLocation = snap2['checkOutLocation'] ?? " ";
      });
    } catch (e) {
      setState(() {
        checkIn = "--/--";
        checkOut = "--/--";
        checkInLocation = " ";
        checkOutLocation = " ";
      });
    }
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
            Container(
              alignment: Alignment.centerLeft,
              margin: const EdgeInsets.only(top: 32),
              child: Text(
                "Welcome,",
                style: TextStyle(
                  color: Colors.black54,
                  fontFamily: "NexaRegular",
                  fontSize: screenWidth / 20,
                ),
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              child: Text(
                "Employee " + User.employeeId,
                style: TextStyle(
                  fontFamily: "NexaBold",
                  fontSize: screenWidth / 18,
                ),
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              margin: const EdgeInsets.only(top: 32),
              child: Text(
                "Today's Status",
                style: TextStyle(
                  fontFamily: "NexaBold",
                  fontSize: screenWidth / 18,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 32),
              height: 150,
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(2, 2),
                  ),
                ],
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Check In",
                          style: TextStyle(
                            fontFamily: "NexaRegular",
                            fontSize: screenWidth / 20,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          checkIn,
                          style: TextStyle(
                            fontFamily: "NexaBold",
                            fontSize: screenWidth / 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Check Out",
                          style: TextStyle(
                            fontFamily: "NexaRegular",
                            fontSize: screenWidth / 20,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          checkOut,
                          style: TextStyle(
                            fontFamily: "NexaBold",
                            fontSize: screenWidth / 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              child: RichText(
                text: TextSpan(
                  text: DateTime.now().day.toString(),
                  style: TextStyle(
                    color: primary,
                    fontSize: screenWidth / 18,
                    fontFamily: "NexaBold",
                  ),
                  children: [
                    TextSpan(
                      text: DateFormat(' MMMM yyyy').format(DateTime.now()),
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: screenWidth / 20,
                        fontFamily: "NexaBold",
                      ),
                    ),
                  ],
                ),
              ),
            ),
            StreamBuilder(
              stream: Stream.periodic(const Duration(seconds: 1)),
              builder: (context, snapshot) {
                return Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    DateFormat('hh:mm:ss a').format(DateTime.now()),
                    style: TextStyle(
                      fontFamily: "NexaRegular",
                      fontSize: screenWidth / 20,
                      color: Colors.black54,
                    ),
                  ),
                );
              },
            ),
            checkOut == "--/--"
                ? Container(
                  margin: const EdgeInsets.only(top: 24, bottom: 12),
                  child: Builder(
                    builder: (context) {
                      return SlideAction(
                        key: _slideKey,
                        text:
                            checkIn == "--/--"
                                ? "Slide to Check In"
                                : "Slide to Check Out",
                        textStyle: TextStyle(
                          color: Colors.black54,
                          fontSize: screenWidth / 20,
                          fontFamily: "NexaRegular",
                        ),
                        outerColor: Colors.white,
                        innerColor: primary,
                        onSubmit: () async {
                          if (!mounted) return;

                          // Static office location for NUBB
                          const double officeLat = 13.1041;
                          const double officeLong = 103.2022;

                          LocationData? locData =
                              await _locationService.getLocation();

                          if (locData == null ||
                              locData.latitude == null ||
                              locData.longitude == null) {
                            showCustomSnackBar("Location not available!");
                            if (mounted) _slideKey.currentState?.reset();
                            return;
                          }

                          // Calculate distance between current location and office
                          double distance = calculateDistance(
                            locData.latitude!,
                            locData.longitude!,
                            officeLat,
                            officeLong,
                          );

                          // Allow a radius of 100 meters
                          if (distance > 100) {
                            showCustomSnackBar(
                              "You are not at the office location.",
                            );
                            if (mounted) _slideKey.currentState?.reset();
                            return;
                          }

                          await _getLocation(); // This updates checkInLocation with address string

                          TimeOfDay now = TimeOfDay.now();
                          bool isLateCheckIn = false;
                          bool isEarlyCheckOut = false;

                          if (checkIn == "--/--") {
                            if (now.hour > 7 ||
                                (now.hour == 7 && now.minute > 0)) {
                              isLateCheckIn = true;
                            }
                          } else if (checkOut == "--/--") {
                            if (now.hour < 12) {
                              isEarlyCheckOut = true;
                            }
                          }

                          String? reason;

                          if (isLateCheckIn || isEarlyCheckOut) {
                            reason = await _showReasonDialog(isLateCheckIn);
                            if (reason == null) {
                              if (mounted) _slideKey.currentState?.reset();
                              return;
                            }
                          }

                          QuerySnapshot snap =
                              await FirebaseFirestore.instance
                                  .collection("Employee")
                                  .where('id', isEqualTo: User.employeeId)
                                  .get();

                          if (snap.docs.isEmpty) {
                            showCustomSnackBar("Employee not found!");
                            if (mounted) _slideKey.currentState?.reset();
                            return;
                          }

                          DocumentSnapshot snap2 =
                              await FirebaseFirestore.instance
                                  .collection("Employee")
                                  .doc(snap.docs[0].id)
                                  .collection("Record")
                                  .doc(
                                    DateFormat(
                                      'dd MMMM yyyy',
                                    ).format(DateTime.now()),
                                  )
                                  .get();

                          if (checkIn == "--/--") {
                            String newCheckIn = DateFormat(
                              'hh:mm',
                            ).format(DateTime.now());

                            setState(() {
                              checkIn = newCheckIn;
                              checkInLocation =
                                  checkInLocation; // updated by _getLocation()
                            });

                            await FirebaseFirestore.instance
                                .collection("Employee")
                                .doc(snap.docs[0].id)
                                .collection("Record")
                                .doc(
                                  DateFormat(
                                    'dd MMMM yyyy',
                                  ).format(DateTime.now()),
                                )
                                .set({
                                  'date': Timestamp.now(),
                                  'checkIn': newCheckIn,
                                  'checkOut': "--/--",
                                  'checkInLocation': checkInLocation,
                                  'checkOutLocation': " ",
                                  'latitude': locData.latitude,
                                  'longitude': locData.longitude,
                                  'reason': reason ?? "",
                                });

                            showCustomSnackBar(
                              "Check-in recorded successfully!",
                              isError: false,
                            );
                          } else if (checkOut == "--/--") {
                            String oldCheckIn = snap2['checkIn'];
                            String newCheckOut = DateFormat(
                              'hh:mm',
                            ).format(DateTime.now());

                            setState(() {
                              checkOut = newCheckOut;
                              checkOutLocation = checkInLocation;
                            });

                            await FirebaseFirestore.instance
                                .collection("Employee")
                                .doc(snap.docs[0].id)
                                .collection("Record")
                                .doc(
                                  DateFormat(
                                    'dd MMMM yyyy',
                                  ).format(DateTime.now()),
                                )
                                .update({
                                  'date': Timestamp.now(),
                                  'checkIn': oldCheckIn,
                                  'checkOut': newCheckOut,
                                  'checkInLocation':
                                      snap2['checkInLocation'] ??
                                      checkInLocation,
                                  'checkOutLocation': checkOutLocation,
                                  'latitude': locData.latitude,
                                  'longitude': locData.longitude,
                                  'reason': reason ?? snap2['reason'] ?? "",
                                });

                            showCustomSnackBar(
                              "Check-out recorded successfully!",
                              isError: false,
                            );
                          }

                          if (mounted) _slideKey.currentState?.reset();
                        },
                      );
                    },
                  ),
                )
                : Container(
                  margin: const EdgeInsets.only(top: 32, bottom: 32),
                  child: Text(
                    "You have completed this day!",
                    style: TextStyle(
                      fontFamily: "NexaRegular",
                      fontSize: screenWidth / 20,
                      color: Colors.black54,
                    ),
                  ),
                ),
            checkInLocation != " "
                ? Text("Check-in Location: $checkInLocation")
                : const SizedBox(),
            checkOutLocation != " "
                ? Text("Check-out Location: $checkOutLocation")
                : const SizedBox(),
            GestureDetector(
              onTap: () {
                scanQRandCheck();
              },
              child: Container(
                height: screenWidth / 2,
                width: screenWidth / 2,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(2, 2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(FontAwesomeIcons.expand, size: 70, color: primary),
                        Icon(FontAwesomeIcons.camera, size: 25, color: primary),
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      child: Text(
                        checkIn == "--/--"
                            ? "Scan to Check In"
                            : "Scan to Check Out",
                        style: TextStyle(
                          fontFamily: "NexaRegular",
                          fontSize: screenWidth / 20,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
