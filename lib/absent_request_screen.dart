import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/user.dart';

class AbsentRequestScreen extends StatefulWidget {
  @override
  _AbsentRequestScreenState createState() => _AbsentRequestScreenState();
}

class _AbsentRequestScreenState extends State<AbsentRequestScreen> {
  TextEditingController _reasonController = TextEditingController();

  DateTime? _fromDate;
  DateTime? _toDate;

  // Filtering enums
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Absent Request")),
      body: Column(
        children: [
          if (!isAdmin) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("From Date:"),
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
                              // If toDate is before fromDate, reset toDate
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
                      Text("To Date:"),
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
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Reason",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _submitRequest,
              icon: Icon(Icons.send),
              label: Text("Submit Request"),
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
                  return Center(child: CircularProgressIndicator());
                final allRequests = snapshot.data!.docs;

                // Apply filter
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

                    // Check if user owns this request and it's pending (for edit/delete buttons)
                    final bool canEditOrDelete =
                        !isAdmin &&
                        data['employeeId'] == User.employeeId &&
                        data['status'] == 'Pending';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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

                            // Admin Approve/Reject
                            if (isAdmin && data['status'] == 'Pending') ...[
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
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

                            // Employee Edit/Delete own pending requests
                            if (canEditOrDelete) ...[
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                    ),
                                    onPressed: () => _showEditDialog(data),
                                    icon: const Icon(Icons.edit),
                                    label: const Text("Edit"),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey,
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
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Show dialog to edit reason and dates
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
          title: Text("Edit Absence Request"),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("From Date:"),
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
                    Text("To Date:"),
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
                    TextField(
                      controller: editReasonController,
                      maxLines: 3,
                      decoration: InputDecoration(labelText: "Reason"),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
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
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("Request updated")));
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // Delete request
  void _deleteRequest(String docId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Confirm Delete"),
            content: Text("Are you sure you want to delete this request?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("Delete"),
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
      ).showSnackBar(SnackBar(content: Text("Request deleted")));
    }
  }
}

enum RequestStatus { all, pending, approved, rejected }
