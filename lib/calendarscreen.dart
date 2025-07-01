import 'package:attendance_app/model/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_year_picker/month_year_picker.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  double screenHeight = 0;
  double screenWidth = 0;

  Color primary = const Color(0xFFE53935);

  String _month = DateFormat('MMMM').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "My Attendance",
                style: TextStyle(
                  fontFamily: "NexaBold",
                  fontSize: screenWidth / 34,
                  color: Colors.grey[800],
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _month ?? "Select Month",
                    style: TextStyle(
                      fontFamily: "NexaBold",
                      fontSize: screenWidth / 24,
                      color: Colors.grey[900],
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final month = await showMonthYearPicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2022),
                        lastDate: DateTime(2099),
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
                                headlineMedium: TextStyle(
                                  fontFamily: "NexaBold",
                                ),
                                labelSmall: TextStyle(fontFamily: "NexaBold"),
                                labelLarge: TextStyle(fontFamily: "NexaBold"),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );

                      if (month != null) {
                        setState(() {
                          _month = DateFormat('MMMM').format(month);
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.red.shade300,
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            color: Colors.red[600],
                            size: screenWidth / 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _month ?? "Pick a Month",
                            style: TextStyle(
                              fontFamily: "NexaBold",
                              fontSize: screenWidth / 26,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_drop_down,
                            color: Colors.red[600],
                            size: screenWidth / 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              SizedBox(
                height: screenHeight / 1.45,
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection("Employee")
                          .doc(User.id)
                          .collection("Record")
                          .snapshots(),
                  builder: (
                    BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot,
                  ) {
                    if (!snapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(color: primary),
                      );
                    }

                    final snap = snapshot.data!.docs;
                    final filteredRecords =
                        snap.where((doc) {
                          final recordDate = doc['date'].toDate();
                          final recordMonth = DateFormat(
                            'MMMM',
                          ).format(recordDate);
                          return recordMonth == _month;
                        }).toList();

                    if (filteredRecords.isEmpty) {
                      return Center(
                        child: Text(
                          "No records for $_month",
                          style: TextStyle(
                            fontFamily: "NexaRegular",
                            fontSize: screenWidth / 22,
                            color: Colors.grey[600],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: filteredRecords.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final record = filteredRecords[index];
                        final recordDate = record['date'].toDate();

                        final cardHeight = (screenHeight * 0.20).clamp(
                          120.0,
                          150.0,
                        );

                        return Container(
                          height: cardHeight,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: LinearGradient(
                              colors: [
                                Colors.red.shade400,
                                Colors.red.shade600,
                                Colors.red.shade800,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withOpacity(0.4),
                                blurRadius: 14,
                                offset: const Offset(4, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: screenWidth * 0.25,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(28),
                                    bottomLeft: Radius.circular(28),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    DateFormat('EEE\ndd').format(recordDate),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: "NexaBold",
                                      fontSize: screenWidth / 20,
                                      color: Colors.white,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ), // less padding
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Check In",
                                        style: TextStyle(
                                          fontFamily: "NexaRegular",
                                          fontSize: screenWidth / 28,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        record['checkIn'],
                                        style: TextStyle(
                                          fontFamily: "NexaBold",
                                          fontSize: screenWidth / 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Check Out",
                                        style: TextStyle(
                                          fontFamily: "NexaRegular",
                                          fontSize: screenWidth / 28,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        record['checkOut'],
                                        style: TextStyle(
                                          fontFamily: "NexaBold",
                                          fontSize: screenWidth / 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
