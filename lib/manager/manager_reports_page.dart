import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ManagerReportsPage extends StatefulWidget {
  @override
  _ManagerReportsPageState createState() => _ManagerReportsPageState();
}

class _ManagerReportsPageState extends State<ManagerReportsPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String? filterLocation;
  bool showResolvedOnly = false;
  bool showUnresolvedOnly = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Storage Reports"),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          // FILTERS SECTION
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Filters",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),

                _buildLocationFilter(),

                SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        title: Text("Unresolved Only"),
                        value: showUnresolvedOnly,
                        onChanged: (value) {
                          setState(() {
                            showUnresolvedOnly = value ?? false;
                            if (value == true) showResolvedOnly = false;
                          });
                        },
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                    Expanded(
                      child: CheckboxListTile(
                        title: Text("Resolved Only"),
                        value: showResolvedOnly,
                        onChanged: (value) {
                          setState(() {
                            showResolvedOnly = value ?? false;
                            if (value == true) showUnresolvedOnly = false;
                          });
                        },
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  ],
                ),

                if (filterLocation != null || showResolvedOnly || showUnresolvedOnly)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        filterLocation = null;
                        showResolvedOnly = false;
                        showUnresolvedOnly = false;
                      });
                    },
                    icon: Icon(Icons.clear),
                    label: Text("Clear Filters"),
                  ),
              ],
            ),
          ),

          // REPORTS LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildQuery(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error loading reports"));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "No reports found",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // Group reports by location and resolved status
                Map<String, List<QueryDocumentSnapshot>> groupedReports = {};
                List<QueryDocumentSnapshot> resolvedReports = [];

                for (var doc in snapshot.data!.docs) {
                  var data = doc.data() as Map<String, dynamic>;
                  bool isResolved = data['resolved'] ?? false;

                  // Apply status filter
                  if (showResolvedOnly && !isResolved) continue;
                  if (showUnresolvedOnly && isResolved) continue;

                  String location = data['location'] ?? 'Unknown location';

                  if (!isResolved) {
                    // Group unresolved by location
                    if (!groupedReports.containsKey(location)) {
                      groupedReports[location] = [];
                    }
                    groupedReports[location]!.add(doc);
                  } else {
                    // Keep resolved separate
                    resolvedReports.add(doc);
                  }
                }

                if (groupedReports.isEmpty && resolvedReports.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.filter_alt_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "No reports match your filters",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: EdgeInsets.all(16),
                  children: [
                    // UNRESOLVED REPORTS (grouped by location)
                    ...groupedReports.entries.map((entry) {
                      return _buildLocationReportsCard(entry.key, entry.value);
                    }),

                    // RESOLVED REPORTS (individual cards)
                    ...resolvedReports.map((doc) {
                      return _buildResolvedReportCard(doc);
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Build grouped card for unresolved reports at a location
  Widget _buildLocationReportsCard(String location, List<QueryDocumentSnapshot> reports) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange, width: 2),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.all(16),
          childrenPadding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
          leading: Icon(Icons.location_on, color: Colors.orange, size: 28),
          title: Text(
            location,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            "${reports.length} unresolved report${reports.length > 1 ? 's' : ''}",
            style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.w600),
          ),
          trailing: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "Pending",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          children: [
            // List all reports for this location
            ...reports.asMap().entries.map((entry) {
              int index = entry.key;
              var doc = entry.value;
              var data = doc.data() as Map<String, dynamic>;

              Timestamp? timestamp = data['timestamp'];
              DateTime? reportDate = timestamp?.toDate();
              String formattedDate = reportDate != null
                  ? DateFormat('MMM dd, yyyy - h:mm a').format(reportDate)
                  : 'Unknown date';

              String message = data['message'] ?? 'No message';
              bool isAutoGenerated = data['isAutoGenerated'] ?? false;

              return Column(
                children: [
                  if (index > 0) Divider(),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: Colors.grey),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                formattedDate,
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ),
                            if (isAutoGenerated)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "AUTO",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue[900],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(message, style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),

            SizedBox(height: 12),

            // Mark all as resolved button
            ElevatedButton.icon(
              onPressed: () => _markAllAsResolved(reports),
              icon: Icon(Icons.check_circle, size: 18),
              label: Text("Mark All as Resolved"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build individual resolved report card
  Widget _buildResolvedReportCard(QueryDocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;

    Timestamp? timestamp = data['timestamp'];
    DateTime? reportDate = timestamp?.toDate();
    String formattedDate = reportDate != null
        ? DateFormat('MMM dd, yyyy - h:mm a').format(reportDate)
        : 'Unknown date';

    String location = data['location'] ?? 'Unknown location';
    String message = data['message'] ?? 'No message';

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 1,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.grey, size: 20),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Resolved",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  formattedDate,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(message, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
            if (data['resolvedAt'] != null)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  "Resolved on ${DateFormat('MMM dd, yyyy').format((data['resolvedAt'] as Timestamp).toDate())}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _buildQuery() {
    Query query = firestore.collection('reports').orderBy('timestamp', descending: true);

    if (filterLocation != null && filterLocation!.isNotEmpty) {
      query = query.where('location', isEqualTo: filterLocation);
    }

    return query.snapshots();
  }

  // Mark all reports at a location as resolved
  Future<void> _markAllAsResolved(List<QueryDocumentSnapshot> reports) async {
    try {
      WriteBatch batch = firestore.batch();

      for (var doc in reports) {
        batch.update(doc.reference, {
          'resolved': true,
          'resolvedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("All reports marked as resolved!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildLocationFilter() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('reports').snapshots(),
      builder: (context, snapshot) {
        Set<String> locations = {};
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            if (data['location'] != null) {
              locations.add(data['location']);
            }
          }
        }

        return DropdownButtonFormField<String>(
          value: filterLocation,
          decoration: InputDecoration(
            labelText: "Location",
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: [
            DropdownMenuItem(value: null, child: Text("All Locations")),
            ...locations.map(
                  (loc) => DropdownMenuItem(value: loc, child: Text(loc)),
            ),
          ],
          onChanged: (value) {
            setState(() {
              filterLocation = value;
            });
          },
        );
      },
    );
  }
}
