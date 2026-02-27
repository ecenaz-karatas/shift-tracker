import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import 'shift_tracker.dart';
import 'shift_detail.dart';

class ShiftsPage extends StatelessWidget {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Not Set';
    int hour = time.hour;
    int minute = time.minute;
    String amPm = hour >= 12 ? 'PM' : 'AM';
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;
    return '$hour:${minute.toString().padLeft(2, '0')} $amPm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Shifts"),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // NEW: CURRENT SHIFT CARD (shows draft if it exists)
          Consumer<AppState>(
            builder: (context, appState, child) {
              if (!appState.hasDraft) {
                // No draft - just show the Add Shift button
                return Padding(
                  padding: EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ShiftTracker()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      backgroundColor: Colors.blue,
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: Text(
                      "Add Shift",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                );
              }

              // Draft exists - show Current Shift card
              return Card(
                margin: EdgeInsets.all(16),
                elevation: 4,
                color: Colors.orange[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.orange, width: 2),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Icon(Icons.edit_note, color: Colors.orange, size: 28),
                          SizedBox(width: 8),
                          Text(
                            "Current Shift (Unsaved)",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[900],
                            ),
                          ),
                        ],
                      ),

                      Divider(height: 24),

                      // Shift info
                      if (appState.draftName != null)
                        _infoRow("Name", appState.draftName!),
                      if (appState.draftLocation != null)
                        _infoRow("Location", appState.draftLocation!),
                      if (appState.draftTimeIn != null || appState.draftTimeOut != null)
                        _infoRow(
                          "Time",
                          "${_formatTime(appState.draftTimeIn)} - ${_formatTime(appState.draftTimeOut)}",
                        ),
                      if (appState.draftTotalCups > 0)
                        _infoRow("Total Cups", "${appState.draftTotalCups}"),
                      if (appState.draftTotalSale > 0)
                        _infoRow(
                          "Total Sale",
                          "\$${appState.draftTotalSale.toStringAsFixed(2)}",
                        ),

                      SizedBox(height: 16),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ShiftTracker(),
                                  ),
                                );
                              },
                              icon: Icon(Icons.edit),
                              label: Text("Continue Editing"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              // Confirm before discarding
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text("Discard Shift?"),
                                  content: Text(
                                    "Are you sure you want to discard this unsaved shift?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        appState.clearDraft();
                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                        "Discard",
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: Icon(Icons.delete_outline),
                            label: Text("Discard"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // LIST OF SAVED SHIFTS
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('shifts')
                  .orderBy('savedDate', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Something went wrong"));
                }

                if (snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No saved shifts yet.",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var data = doc.data() as Map<String, dynamic>;

                    if (data['savedDate'] == null) return SizedBox();

                    Timestamp savedTimestamp = data['savedDate'];
                    DateTime savedDate = savedTimestamp.toDate();
                    String formattedDate =
                        "${savedDate.month}/${savedDate.day}/${savedDate.year}";
                    String dayName =
                    ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][
                    savedDate.weekday - 1];

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              dayName,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue),
                            ),
                            Text(
                              formattedDate,
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        title: Text(data['location'] ?? 'No location'),
                        subtitle: Text(data['name'] ?? 'No name'),
                        trailing: Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ShiftDetail(shiftData: data),
                            ),
                          );
                        },
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
