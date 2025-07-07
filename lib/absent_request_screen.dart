import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/user.dart';

class AbsentRequestScreen extends StatefulWidget {
  @override
  _AbsentRequestScreenState createState() => _AbsentRequestScreenState();
}

class _AbsentRequestScreenState extends State<AbsentRequestScreen> {
  final Color primary = const Color(0xFFE53935);

  TextEditingController _reasonController = TextEditingController();

  DateTime? _fromDate;
  DateTime? _toDate;

  RequestStatus selectedStatus = RequestStatus.all;

  bool get isAdmin => User.employeeId == 'A123456' || User.lastName == 'Monthy';

  // Handle Submit
  Future<void> _submitRequest() async {
    if (_fromDate == null || _toDate == null || _reasonController.text.isEmpty)
      return;

    // Convert to string for easier comparison
    String fromDateStr = _fromDate!.toIso8601String();
    String toDateStr = _toDate!.toIso8601String();

    // Check if a similar request already exists
    final existingRequests =
        await FirebaseFirestore.instance
            .collection('requestabsent')
            .where('employeeId', isEqualTo: User.employeeId)
            .where('fromDate', isEqualTo: fromDateStr)
            .where('toDate', isEqualTo: toDateStr)
            .get();

    if (existingRequests.docs.isNotEmpty) {
      // Duplicate found - show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Request already submitted for this date range",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: "NexaBold",
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Add new request if no duplicates found
    await FirebaseFirestore.instance.collection('requestabsent').add({
      'employeeId': User.employeeId,
      'name': "${User.firstName} ${User.lastName}",
      'fromDate': fromDateStr,
      'toDate': toDateStr,
      'reason': _reasonController.text.trim(),
      'status': 'Pending',
      'timestamp': Timestamp.now(),
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Request submitted successfully",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: "NexaBold",
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        duration: const Duration(seconds: 3),
      ),
    );

    _reasonController.clear();
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
  }

  // approval
  void _approveRejectRequest(String docId, String status) async {
    await FirebaseFirestore.instance
        .collection('requestabsent')
        .doc(docId)
        .update({'status': status});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Request $status successfully",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: "NexaBold",
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Handle Edit
  void _showEditDialog(QueryDocumentSnapshot data) {
    final TextEditingController editReasonController = TextEditingController(
      text: data['reason'],
    );

    DateTime editFromDate = DateTime.parse(data['fromDate']);
    DateTime editToDate = DateTime.parse(data['toDate']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Edit Absence Request",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: 20,
              fontFamily: "NexaBold",
            ),
          ),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "From Date:",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: "NexaRegular",
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: editFromDate,
                          firstDate: DateTime(2023),
                          lastDate: DateTime(2100),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary:
                                      Colors
                                          .red[600]!, // Header background & selected date
                                  onPrimary: Colors.white, // Header text color
                                  onSurface: Colors.black, // Default text color
                                ),
                                textButtonTheme: TextButtonThemeData(
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        Colors.red[600], // OK/Cancel buttons
                                  ),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );

                        if (picked != null) {
                          setStateDialog(() {
                            editFromDate = picked;
                            if (editToDate.isBefore(editFromDate)) {
                              editToDate = picked;
                            }
                          });
                        }
                      },
                      icon: const Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: Colors.red,
                      ),
                      label: Text(
                        DateFormat.yMMMd().format(editFromDate),
                        style: TextStyle(
                          color: Colors.red[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: "NexaBold",
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    const Text(
                      "To Date:",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: "NexaRegular",
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: editToDate,
                          firstDate: editFromDate,
                          lastDate: DateTime(2100),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary:
                                      Colors
                                          .red[600]!, // Header & selected date
                                  onPrimary: Colors.white, // Text on header
                                  onSurface: Colors.black, // Default text color
                                ),
                                textButtonTheme: TextButtonThemeData(
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        Colors
                                            .red[600], // OK/Cancel button text
                                  ),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );

                        if (picked != null) {
                          setStateDialog(() {
                            editToDate = picked;
                          });
                        }
                      },
                      icon: const Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: Colors.red,
                      ),
                      label: Text(
                        DateFormat.yMMMd().format(editToDate),
                        style: TextStyle(
                          color: Colors.red[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: "NexaBold",
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      "Reason:",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: "NexaRegular",
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: editReasonController,
                      style: TextStyle(fontFamily: "NexaRegular"),
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Enter reason for absence",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primary, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.black87, fontFamily: "NexaBold"),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('requestabsent')
                    .doc(data.id)
                    .update({
                      'fromDate': editFromDate.toIso8601String(),
                      'toDate': editToDate.toIso8601String(),
                      'reason': editReasonController.text.trim(),
                    });

                Navigator.pop(context);

                //  Beautiful success SnackBar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "Request updated successfully",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: "NexaBold",
                            ),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green.shade600,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
              icon: const Icon(Icons.save),
              label: const Text(
                "Save",
                style: TextStyle(fontFamily: "NexaBold"),
              ),
            ),
          ],
        );
      },
    );
  }

  // Handle delete
  void _deleteRequest(String docId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              "Confirm Delete",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
                fontFamily: "NexaBold",
              ),
            ),
            content: const Text(
              "Are you sure you want to delete this request?\nThis action cannot be undone.",
              style: TextStyle(fontSize: 15, fontFamily: "NexaRegular"),
            ),
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  "Cancel",
                  style: TextStyle(
                    color: Colors.black87,
                    fontFamily: "NexaBold",
                  ),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.delete_outline),
                label: const Text(
                  "Delete",
                  style: TextStyle(fontFamily: "NexaBold"),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('requestabsent')
          .doc(docId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.delete_outline, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Request deleted successfully",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: "NexaBold",
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Status
  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case 'Approved':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'Rejected':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = primary;
        icon = Icons.hourglass_top;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 1.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              fontFamily: "NexaRegular",
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: "NexaRegular"),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Absent Request"),
          backgroundColor: primary,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 2,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
          ),
        ),
        body: Column(
          children: [
            if (!isAdmin) ...[
              Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text("From:", style: TextStyle(fontSize: 12)),
                            TextButton(
                              onPressed: () async {
                                DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: _fromDate ?? DateTime.now(),
                                  firstDate: DateTime(2023),
                                  lastDate: DateTime(2100),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary:
                                              Colors
                                                  .red[600]!, // Header & selected date
                                          onPrimary:
                                              Colors
                                                  .white, // Text color on header
                                          onSurface:
                                              Colors
                                                  .black, // Default text color
                                        ),
                                        textButtonTheme: TextButtonThemeData(
                                          style: TextButton.styleFrom(
                                            foregroundColor:
                                                Colors
                                                    .red[600], // Button text (Cancel/OK)
                                          ),
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );

                                if (picked != null) {
                                  setState(() {
                                    _fromDate = picked;
                                    if (_toDate != null &&
                                        _toDate!.isBefore(_fromDate!)) {
                                      _toDate = null;
                                    }
                                  });
                                }
                              },
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    Colors.red[600], // Text & splash
                                backgroundColor:
                                    Colors.red[50], // Soft red background
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Colors.red[600]!,
                                  ), // Red border
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontFamily:
                                      "NexaBold", // optional: use your desired font
                                ),
                              ),
                              child: Text(
                                _fromDate != null
                                    ? DateFormat.yMMMd().format(_fromDate!)
                                    : "Select",
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text("To:", style: TextStyle(fontSize: 12)),
                            TextButton(
                              onPressed: () async {
                                DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      _toDate ?? (_fromDate ?? DateTime.now()),
                                  firstDate: _fromDate ?? DateTime(2023),
                                  lastDate: DateTime(2100),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary:
                                              Colors
                                                  .red[600]!, // Header background & selected date
                                          onPrimary:
                                              Colors
                                                  .white, // Text color on header
                                          onSurface:
                                              Colors.black, // Default body text
                                        ),
                                        textButtonTheme: TextButtonThemeData(
                                          style: TextButton.styleFrom(
                                            foregroundColor:
                                                Colors
                                                    .red[600], // OK & Cancel button colors
                                          ),
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );

                                if (picked != null) {
                                  setState(() => _toDate = picked);
                                }
                              },
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    Colors.red[600], // Text & splash color
                                backgroundColor:
                                    Colors.red[50], // Light red background
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Colors.red[600]!,
                                  ), // Red border
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontFamily:
                                      "NexaBold", // Optional custom font
                                ),
                              ),
                              child: Text(
                                _toDate != null
                                    ? DateFormat.yMMMd().format(_toDate!)
                                    : "Select",
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _reasonController,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: "Reason",
                        labelStyle: TextStyle(
                          color: Colors.red[600],
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.red[600]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.red[300]!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _submitRequest,
                        icon: const Icon(
                          Icons.send,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "Submit",
                          style: TextStyle(fontSize: 13, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children:
                    RequestStatus.values.map((status) {
                      final label =
                          status.name[0].toUpperCase() +
                          status.name.substring(1);
                      final isSelected = selectedStatus == status;
                      return ChoiceChip(
                        label: Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: Colors.red[600],
                        backgroundColor: Colors.white,
                        elevation: 1,
                        pressElevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color:
                                isSelected
                                    ? Colors.red[600]!
                                    : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        onSelected:
                            (_) => setState(() => selectedStatus = status),
                      );
                    }).toList(),
              ),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('requestabsent')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allRequests = snapshot.data!.docs;
                  final requests =
                      allRequests.where((doc) {
                        final matchesStatus =
                            selectedStatus == RequestStatus.all
                                ? true
                                : doc['status'].toString().toLowerCase() ==
                                    selectedStatus.name.toLowerCase();
                        final canView =
                            isAdmin || doc['employeeId'] == User.employeeId;
                        return matchesStatus && canView;
                      }).toList();

                  if (requests.isEmpty) {
                    return const Center(
                      child: Text(
                        "No requests found.",
                        style: TextStyle(fontSize: 13),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final data = requests[index];
                      final canEditOrDelete =
                          !isAdmin &&
                          data['employeeId'] == User.employeeId &&
                          data['status'] == 'Pending';

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.red.shade100,
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person, size: 18),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      data['name'],
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  _buildStatusBadge(data['status']),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.date_range, size: 16),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      "${DateFormat.yMMMd().format(DateTime.parse(data['fromDate']))} → ${DateFormat.yMMMd().format(DateTime.parse(data['toDate']))}",
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.edit_note, size: 16),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      "Reason: ${data['reason']}",
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (isAdmin && data['status'] == 'Pending')
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton(
                                      onPressed:
                                          () => _approveRejectRequest(
                                            data.id,
                                            'Approved',
                                          ),
                                      child: const Text(
                                        "Approve",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green[600],
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    ElevatedButton(
                                      onPressed:
                                          () => _approveRejectRequest(
                                            data.id,
                                            'Rejected',
                                          ),
                                      child: const Text(
                                        "Reject",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red[600],
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              if (canEditOrDelete)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () => _showEditDialog(data),
                                      child: const Text(
                                        "Edit",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange[600],
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    ElevatedButton(
                                      onPressed: () => _deleteRequest(data.id),
                                      child: const Text(
                                        "Delete",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey[700],
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
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
    );
  }
}

enum RequestStatus { all, pending, approved, rejected }
