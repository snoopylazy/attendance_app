import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../model/user.dart';

class AbsentRequestScreen extends StatefulWidget {
  @override
  _AbsentRequestScreenState createState() => _AbsentRequestScreenState();
}

class _AbsentRequestScreenState extends State<AbsentRequestScreen> {
  final Color primary = const Color(
    0xffef444c,
  ); // Match HomeScreen primary color

  TextEditingController _reasonController = TextEditingController();

  DateTime? _fromDate;
  DateTime? _toDate;

  RequestStatus selectedStatus = RequestStatus.all;

  bool get isAdmin => User.employeeId == 'A123456' || User.lastName == 'Monthy';

  Future<void> _submitRequest() async {
    if (_fromDate == null || _toDate == null || _reasonController.text.isEmpty)
      return;

    await FirebaseFirestore.instance.collection('requestabsent').add({
      'employeeId': User.employeeId,
      'name': "${User.firstName} ${User.lastName}",
      'fromDate': _fromDate!.toIso8601String(),
      'toDate': _toDate!.toIso8601String(),
      'reason': _reasonController.text.trim(),
      'status': 'Pending',
      'timestamp': Timestamp.now(),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Request submitted successfully")));

    _reasonController.clear();
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
  }

  void _approveRejectRequest(String docId, String status) async {
    await FirebaseFirestore.instance
        .collection('requestabsent')
        .doc(docId)
        .update({'status': status});
  }

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
          title: const Text("Edit Absence Request"),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("From Date:"),
                    TextButton(
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: editFromDate,
                          firstDate: DateTime(2023),
                          lastDate: DateTime(2100),
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
                      child: Text(DateFormat.yMMMd().format(editFromDate)),
                    ),
                    const SizedBox(height: 8),
                    const Text("To Date:"),
                    TextButton(
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: editToDate,
                          firstDate: editFromDate,
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setStateDialog(() {
                            editToDate = picked;
                          });
                        }
                      },
                      child: Text(DateFormat.yMMMd().format(editToDate)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: editReasonController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: "Reason"),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Request updated")),
                );
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _deleteRequest(String docId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Confirm Delete"),
            content: const Text(
              "Are you sure you want to delete this request?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primary),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Delete"),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('requestabsent')
          .doc(docId)
          .delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Request deleted")));
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Approved':
        color = Colors.green;
        break;
      case 'Rejected':
        color = Colors.red;
        break;
      default:
        color = primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Absent Request"),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Column(
        children: [
          if (!isAdmin) ...[
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date pickers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("From Date:"),
                          TextButton(
                            onPressed: () async {
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: _fromDate ?? DateTime.now(),
                                firstDate: DateTime(2023),
                                lastDate: DateTime(2100),
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
                            child: Text(
                              _fromDate != null
                                  ? DateFormat.yMMMd().format(_fromDate!)
                                  : "Select",
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("To Date:"),
                          TextButton(
                            onPressed: () async {
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate:
                                    _toDate ?? (_fromDate ?? DateTime.now()),
                                firstDate: _fromDate ?? DateTime(2023),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() => _toDate = picked);
                              }
                            },
                            child: Text(
                              _toDate != null
                                  ? DateFormat.yMMMd().format(_toDate!)
                                  : "Select",
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Reason text field
                  TextField(
                    controller: _reasonController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Reason",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Submit button
                  Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onPressed: _submitRequest,
                      icon: const Icon(Icons.send),
                      label: const Text("Submit Request"),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Wrap(
              spacing: 10,
              children:
                  RequestStatus.values.map((status) {
                    final label =
                        status.name[0].toUpperCase() + status.name.substring(1);
                    return ChoiceChip(
                      label: Text(label),
                      selected: selectedStatus == status,
                      selectedColor: primary.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color:
                            selectedStatus == status ? primary : Colors.black87,
                        fontWeight: FontWeight.bold,
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
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final allRequests = snapshot.data!.docs;

                final requests =
                    allRequests.where((doc) {
                      if (selectedStatus == RequestStatus.all) return true;
                      return doc['status'].toString().toLowerCase() ==
                          selectedStatus.name.toLowerCase();
                    }).toList();

                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final data = requests[index];

                    final bool canEditOrDelete =
                        !isAdmin &&
                        data['employeeId'] == User.employeeId &&
                        data['status'] == 'Pending';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.person,
                                  size: 20,
                                  color: Colors.black87,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  data['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const Spacer(),
                                _buildStatusBadge(data['status']),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "📅 From: ${DateFormat.yMMMd().format(DateTime.parse(data['fromDate']))} "
                              "- To: ${DateFormat.yMMMd().format(DateTime.parse(data['toDate']))}",
                            ),
                            Text("📝 Reason: ${data['reason']}"),

                            if (isAdmin && data['status'] == 'Pending') ...[
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    onPressed:
                                        () => _approveRejectRequest(
                                          data.id,
                                          'Approved',
                                        ),
                                    icon: const Icon(Icons.check),
                                    label: const Text("Approve"),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    onPressed:
                                        () => _approveRejectRequest(
                                          data.id,
                                          'Rejected',
                                        ),
                                    icon: const Icon(Icons.close),
                                    label: const Text("Reject"),
                                  ),
                                ],
                              ),
                            ],

                            if (canEditOrDelete) ...[
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    onPressed: () => _showEditDialog(data),
                                    icon: const Icon(Icons.edit),
                                    label: const Text("Edit"),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    onPressed: () => _deleteRequest(data.id),
                                    icon: const Icon(Icons.delete),
                                    label: const Text("Delete"),
                                  ),
                                ],
                              ),
                            ],
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
    );
  }
}

enum RequestStatus { all, pending, approved, rejected }
