import 'dart:async';
import 'package:attendance_app/model/user.dart';
import 'package:attendance_app/services/location_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;

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

  int _pendingRequestCount = 0;
  late StreamSubscription<QuerySnapshot> _pendingRequestsSubscription;

  // static bool get isAdmin =>
  //     User.employeeId == 'A123456' || User.lastName == 'Monthy';

  final GlobalKey<SlideActionState> _slideKey = GlobalKey<SlideActionState>();
  final LocationService _locationService = LocationService();

  // Add AudioPlayer instance
  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _initializeLocationService();
    _getRecord();
    _getOfficeCode();
    _loadTodayRecord();

    // Start real-time listener instead of one-time fetch
    _pendingRequestsSubscription = FirebaseFirestore.instance
        .collection("requestabsent")
        .where("status", isEqualTo: "Pending")
        .snapshots()
        .listen((snapshot) {
          setState(() {
            _pendingRequestCount = snapshot.docs.length;
          });
        });
  }

  @override
  void dispose() {
    // Cancel listener to prevent memory leaks
    _pendingRequestsSubscription.cancel();
    super.dispose();
  }

  Future<void> sendTelegramMessage(String message) async {
    const String botToken = '7876712552:AAGl4DL9rJOvbcJVtJ-OqEH8_C-_gJ-qLw0';
    const String chatId = '1088041386';

    final String url = 'https://api.telegram.org/bot$botToken/sendMessage';

    try {
      await http.post(
        Uri.parse(url),
        body: {'chat_id': chatId, 'text': message, 'parse_mode': 'Markdown'},
      );
    } catch (e) {
      print("Telegram message error: $e");
    }
  }

  // Notification
  void _showPopupMenu(Offset position) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection("requestabsent")
            .where("status", isEqualTo: "Pending")
            .get();

    final requests = snapshot.docs;

    final List<PopupMenuEntry<int>> menuItems = [];

    if (requests.isEmpty) {
      menuItems.add(
        const PopupMenuItem<int>(
          value: 0,
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.redAccent),
              SizedBox(width: 8),
              Text("No ask for permission"),
            ],
          ),
        ),
      );
    } else {
      for (int i = 0; i < requests.length; i++) {
        final data = requests[i].data() as Map<String, dynamic>;
        final name = data["name"] ?? "Unknown";
        final reason = data["reason"] ?? "No reason";

        menuItems.add(
          PopupMenuItem<int>(
            value: i,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.pending_actions, color: Colors.red.shade600),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Reason: $reason",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: menuItems,
      elevation: 8,
      color: Colors.white,
    );
  }

  // Fetch In NUBB
  bool isWithinAllowedDistance(double userLat, double userLon) {
    // const double allowedLat = 11.2237383;
    // const double allowedLon = 105.1258955;
    const double allowedLat = 13.0903905;
    const double allowedLon = 103.2165881;
    const double allowedRadiusMeters = 1000;

    double distance = geo.Geolocator.distanceBetween(
      userLat,
      userLon,
      allowedLat,
      allowedLon,
    );

    print('=== LOCATION DEBUG ===');
    print('User: $userLat, $userLon');
    print('Target: $allowedLat, $allowedLon');
    print('Distance: ${distance.toStringAsFixed(2)}m');
    print('Allowed: ${allowedRadiusMeters}m');
    print('Result: ${distance <= allowedRadiusMeters}');
    print('====================');

    return distance <= allowedRadiusMeters;
  }

  // Define your custom locations
  final Map<String, Map<String, double>> customLocations = {
    'NUBB': {'lat': 13.0903905, 'lon': 103.2165881, 'radius': 1000.0},
    'Main Office': {'lat': 13.0862629, 'lon': 103.2197316, 'radius': 1000.0},
  };

  // Store location
  Future<void> _getLocationAddress(double latitude, double longitude) async {
    try {
      print('Getting address for: $latitude, $longitude');

      // Check if user is at any of the custom locations
      String? customLocationName = _getCustomLocationName(latitude, longitude);

      if (customLocationName != null) {
        print('Using custom location: $customLocationName');
        setState(() {
          checkInLocation = customLocationName;
        });
      } else {
        print('Getting address from geocoding...');
        // Get actual address for other locations
        List<Placemark> placemark = await placemarkFromCoordinates(
          latitude,
          longitude,
        );

        if (placemark.isNotEmpty) {
          setState(() {
            checkInLocation =
                "${placemark[0].street}, ${placemark[0].administrativeArea}, ${placemark[0].postalCode}, ${placemark[0].country}";
          });
          print('Address found: $checkInLocation');
        } else {
          setState(() {
            checkInLocation = "No address found for this location";
          });
        }
      }
    } catch (e) {
      print('Error getting location address: $e');
      setState(() {
        checkInLocation = "Location address unavailable: ${e.toString()}";
      });
    }
  }

  // Custome
  String? _getCustomLocationName(double userLat, double userLon) {
    print('=== CUSTOM LOCATION CHECK ===');
    print('User location: $userLat, $userLon');

    for (String locationName in customLocations.keys) {
      Map<String, double> location = customLocations[locationName]!;

      double distance = geo.Geolocator.distanceBetween(
        userLat,
        userLon,
        location['lat']!,
        location['lon']!,
      );

      print(
        '$locationName - Distance: ${distance.toStringAsFixed(2)}m, Allowed: ${location['radius']}m',
      );

      if (distance <= location['radius']!) {
        print('✅ Found match: $locationName');
        return locationName;
      }
    }
    print('❌ No custom location match found');
    return null;
  }

  // Initialize LocationService
  Future<void> _initializeLocationService() async {
    try {
      bool isInitialized = await _locationService.initialize();
      print('Location service initialized: $isInitialized');

      if (!isInitialized) {
        showCustomSnackBar("Unable to initialize location services!");
        // Add more specific error handling here
        return;
      }

      // Test getting current location
      // Position? position = await _locationService.getCurrentPosition();
      // if (position != null) {
      //   print('Current position: ${position.latitude}, ${position.longitude}');
      //   _getLocationAddress(position.latitude, position.longitude);
      // }
    } catch (e) {
      print('Error initializing location service: $e');
      showCustomSnackBar("Location service error: ${e.toString()}");
    }
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
    // Open Camera
    var status = await Permission.camera.status;

    if (!status.isGranted) {
      status = await Permission.camera.request();

      if (status.isPermanentlyDenied) {
        showCustomSnackBar(
          "Camera permission is permanently denied. Please enable it in settings.",
        );
        openAppSettings();
        return;
      }

      if (!status.isGranted) {
        showCustomSnackBar("Camera permission is required!");
        return;
      }
    }

    // Proceed with scan...
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

  // Detect Fake Location
  Future<bool> isLocationMocked() async {
    try {
      geo.Position position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
      );
      return position.isMocked;
    } catch (e) {
      print('Error checking mock location: $e');
      return false;
    }
  }

  // Show Reason Dialog
  Future<String?> _showReasonDialog(bool isLateCheckIn) async {
    TextEditingController reasonController = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 16,
          title: Row(
            children: [
              Icon(Icons.edit_note, color: Color(0xFFE53935)),
              const SizedBox(width: 8),
              Text(
                isLateCheckIn
                    ? "Late Check-in Reason"
                    : "Early Check-out Reason",
                style: TextStyle(
                  color: Color(0xFFE53935),
                  fontWeight: FontWeight.bold,
                  fontFamily: "NexaBold",
                ),
              ),
            ],
          ),
          content: Container(
            decoration: BoxDecoration(
              color: Color(0xFFFFFDE7), // light yellow
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFE53935).withOpacity(0.08),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: "Please enter your reason",
                filled: true,
                fillColor: Color(0xFFFFFDE7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFFE53935), width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFFE53935), width: 2),
                ),
              ),
              maxLines: 3,
              style: TextStyle(
                fontFamily: "NexaRegular",
                color: Colors.black87,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null);
              },
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFFE53935),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE53935),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
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

  // Method to show custom SnackBar
  void showCustomSnackBar(String message, {bool isError = true}) async {
    if (!mounted) return; // Prevent SnackBar if widget not mounted

    // Play appropriate sound first
    await _player.play(
      AssetSource(isError ? 'sounds/checkout.mp3' : 'sounds/checkin.mp3'),
    );

    // Then show the SnackBar
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

    // Modern red color
    primary = const Color(0xFFE53935); // Red 600

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 12),
            Text(
              "Welcome, ${User.lastName} ${User.firstName}",
              style: TextStyle(
                color: primary,
                fontFamily: "NexaRegular",
                fontSize: screenWidth / 34,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              "Student ID: ${User.employeeId}",
              style: TextStyle(
                color: Colors.black,
                fontFamily: "NexaRegular",
                fontSize: screenWidth / 40,
              ),
            ),
          ],
        ),
        actions: [
          if (User.isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: GestureDetector(
                onTapDown: (TapDownDetails details) {
                  _showPopupMenu(details.globalPosition);
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.notifications,
                      color: Colors.black87,
                      size: 28,
                    ),
                    if (_pendingRequestCount > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.shade900.withOpacity(0.6),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 18,
                          ),
                          child: Center(
                            child: Text(
                              '$_pendingRequestCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary, primary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                child: Row(
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
                              fontSize: screenWidth / 22,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            checkIn,
                            style: TextStyle(
                              fontFamily: "NexaBold",
                              fontSize: screenWidth / 18,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 48, color: Colors.white24),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Check Out",
                            style: TextStyle(
                              fontFamily: "NexaRegular",
                              fontSize: screenWidth / 22,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            checkOut,
                            style: TextStyle(
                              fontFamily: "NexaBold",
                              fontSize: screenWidth / 18,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Date & Time
            Row(
              children: [
                RichText(
                  text: TextSpan(
                    text: DateTime.now().day.toString(),
                    style: TextStyle(
                      color: primary,
                      fontSize: screenWidth / 24,
                      fontFamily: "NexaBold",
                    ),
                    children: [
                      TextSpan(
                        text: DateFormat(' MMMM yyyy').format(DateTime.now()),
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: screenWidth / 24,
                          fontFamily: "NexaBold",
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                StreamBuilder(
                  stream: Stream.periodic(const Duration(seconds: 1)),
                  builder: (context, snapshot) {
                    return Text(
                      DateFormat('hh:mm:ss a').format(DateTime.now()),
                      style: TextStyle(
                        fontFamily: "NexaRegular",
                        fontSize: screenWidth / 24,
                        color: primary,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Slide Action
            checkOut == "--/--"
                ? Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Builder(
                    builder: (context) {
                      return SlideAction(
                        key: _slideKey,
                        text:
                            checkIn == "--/--"
                                ? "Slide to Check-In >>>"
                                : "Slide to Check-Out >>>",
                        textStyle: TextStyle(
                          color: primary,
                          fontSize: screenWidth / 22,
                          fontFamily: "NexaRegular",
                          fontWeight: FontWeight.bold,
                        ),
                        outerColor: Colors.white,
                        innerColor: primary,
                        elevation: 4,
                        borderRadius: 32,
                        onSubmit: () async {
                          if (!mounted) return;

                          bool mocked = await isLocationMocked();
                          if (mocked) {
                            showCustomSnackBar(
                              "Fake location detected. Check-in rejected.",
                            );
                            if (mounted) _slideKey.currentState?.reset();
                            return;
                          }

                          // Get location once
                          LocationData? locData =
                              await _locationService.getLocation();
                          if (locData == null ||
                              locData.latitude == null ||
                              locData.longitude == null) {
                            showCustomSnackBar("Location not available!");
                            if (mounted) _slideKey.currentState?.reset();
                            return;
                          }

                          // Check allowed location radius using the same location data
                          if (!isWithinAllowedDistance(
                            locData.latitude!,
                            locData.longitude!,
                          )) {
                            showCustomSnackBar(
                              "You are not at the allowed location to check-in.",
                            );
                            if (mounted) _slideKey.currentState?.reset();
                            return;
                          }

                          // Get address using the same location data
                          await _getLocationAddress(
                            locData.latitude!,
                            locData.longitude!,
                          );

                          // Rest of your code remains the same...
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
                              'hh:mm a',
                            ).format(DateTime.now());

                            setState(() {
                              checkIn = newCheckIn;
                              checkInLocation = checkInLocation;
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
                            await sendTelegramMessage(
                              "🕘 *Check-In*\n👤 ${User.firstName} ${User.lastName}\n📅 ${DateFormat('dd MMM yyyy').format(DateTime.now())}\n⏰ $newCheckIn\n📍 $checkInLocation",
                            );
                          } else if (checkOut == "--/--") {
                            String oldCheckIn = snap2['checkIn'];
                            String newCheckOut = DateFormat(
                              'hh:mm a',
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
                            await sendTelegramMessage(
                              "🕔 *Check-Out*\n👤 ${User.firstName} ${User.lastName}\n📅 ${DateFormat('dd MMM yyyy').format(DateTime.now())}\n⏰ $newCheckOut\n📍 $checkOutLocation",
                            );
                          }

                          if (mounted) _slideKey.currentState?.reset();
                        },
                      );
                    },
                  ),
                )
                : Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 10),
                  child: Text(
                    "You have completed this day!",
                    style: TextStyle(
                      fontFamily: "NexaRegular",
                      fontSize: screenWidth / 28,
                      color: primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            // Location Info
            if (checkInLocation.trim().isNotEmpty && checkInLocation != " ")
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: primary, size: 24),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        "Check-in: $checkInLocation",
                        style: TextStyle(
                          color: const Color.fromARGB(255, 0, 183, 6),
                          fontSize: screenWidth / 38,
                          fontFamily: "NexaRegular",
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            if (checkOutLocation.trim().isNotEmpty && checkOutLocation != " ")
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: primary, size: 24),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        "Check-out: $checkOutLocation",
                        style: TextStyle(
                          color: Colors.blueGrey,
                          fontSize: screenWidth / 38,
                          fontFamily: "NexaRegular",
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

            // QR Scan Button
            Center(
              child: GestureDetector(
                onTap: () {
                  scanQRandCheck();
                },
                child: Container(
                  height: screenWidth / 2.2,
                  width: screenWidth / 2.2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primary, primary.withOpacity(0.85)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withOpacity(0.18),
                        offset: const Offset(2, 2),
                        blurRadius: 12,
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
                          Icon(
                            FontAwesomeIcons.expand,
                            size: 70,
                            color: Colors.white.withOpacity(0.18),
                          ),
                          Icon(
                            FontAwesomeIcons.camera,
                            size: 32,
                            color: Colors.white,
                          ),
                        ],
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        child: Text(
                          checkIn == "--/--"
                              ? "Scan to Check-In"
                              : "Scan to Check-Out",
                          style: TextStyle(
                            fontFamily: "NexaRegular",
                            fontSize: screenWidth / 22,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}
