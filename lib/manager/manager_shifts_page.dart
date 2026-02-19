import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shift_tracker/worker/pages/shift_detail.dart';

class ManagerShiftsPage extends StatefulWidget {
  @override
  _ManagerShiftsPageState createState() => _ManagerShiftsPageState();
}

class _ManagerShiftsPageState extends State<ManagerShiftsPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Filter values
  String? filterLocation;
  String? filterWorker;
  DateTime? filterStartDate;
  DateTime? filterEndDate;

  // Sort option
  String sortBy = 'date'; // 'date', 'location', 'sales'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("All Shifts"),
        backgroundColor: Colors.deepPurple,
        actions: [
          // Export to CSV button
          IconButton(
            icon: Icon(Icons.download),
            tooltip: "Export to CSV",
            onPressed: () {
              // TODO: Implement CSV export
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("CSV export coming soon!")),
              );
            },
          ),
        ],
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

                // Location and Worker filters side by side
                Row(
                  children: [
                    Expanded(
                      child: _buildLocationFilter(),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildWorkerFilter(),
                    ),
                  ],
                ),

                SizedBox(height: 12),

                // Date range and sort
                Row(
                  children: [
                    Expanded(
                      child: _buildDateRangeFilter(),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildSortDropdown(),
                    ),
                  ],
                ),

                // Clear filters button
                if (filterLocation != null ||
                    filterWorker != null ||
                    filterStartDate != null)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        filterLocation = null;
                        filterWorker = null;
                        filterStartDate = null;
                        filterEndDate = null;
                      });
                    },
                    icon: Icon(Icons.clear),
                    label: Text("Clear Filters"),
                  ),
              ],
            ),
          ),

          // SHIFTS LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildQuery(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error loading shifts"));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No shifts found",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                // Apply additional filters that can't be done in Firestore query
                var shifts = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;

                  // Filter by worker name
                  if (filterWorker != null && filterWorker!.isNotEmpty) {
                    String name = (data['name'] ?? '').toString().toLowerCase();
                    if (!name.contains(filterWorker!.toLowerCase())) {
                      return false;
                    }
                  }

                  // Filter by date range
                  if (filterStartDate != null && data['savedDate'] != null) {
                    DateTime shiftDate = (data['savedDate'] as Timestamp).toDate();
                    if (shiftDate.isBefore(filterStartDate!)) return false;
                    if (filterEndDate != null && shiftDate.isAfter(filterEndDate!)) {
                      return false;
                    }
                  }

                  return true;
                }).toList();

                // Sort
                shifts.sort((a, b) {
                  var dataA = a.data() as Map<String, dynamic>;
                  var dataB = b.data() as Map<String, dynamic>;

                  if (sortBy == 'location') {
                    return (dataA['location'] ?? '').compareTo(dataB['location'] ?? '');
                  } else if (sortBy == 'sales') {
                    double saleA = _calculateSale(dataA);
                    double saleB = _calculateSale(dataB);
                    return saleB.compareTo(saleA); // Descending
                  } else {
                    // Sort by date (default)
                    if (dataA['savedDate'] == null) return 1;
                    if (dataB['savedDate'] == null) return -1;
                    return (dataB['savedDate'] as Timestamp)
                        .compareTo(dataA['savedDate'] as Timestamp);
                  }
                });

                return ListView.builder(
                  itemCount: shifts.length,
                  itemBuilder: (context, index) {
                    var doc = shifts[index];
                    var data = doc.data() as Map<String, dynamic>;

                    if (data['savedDate'] == null) return SizedBox();

                    Timestamp savedTimestamp = data['savedDate'];
                    DateTime savedDate = savedTimestamp.toDate();
                    String formattedDate = DateFormat('MMM dd, yyyy').format(savedDate);
                    String formattedTime = DateFormat('h:mm a').format(savedDate);

                    int cashCups = int.tryParse(data['cashCups'] ?? '0') ?? 0;
                    int ccCups = int.tryParse(data['ccCups'] ?? '0') ?? 0;
                    double totalSale = cashCups * 7 + ccCups * 7.27;

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepPurple,
                          child: Text(
                            (data['name'] ?? 'U')[0].toUpperCase(),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          "${data['name'] ?? 'Unknown'} - ${data['location'] ?? 'No location'}",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("$formattedDate at $formattedTime"),
                            Text(
                              "Sale: \$${totalSale.toStringAsFixed(2)} | Cups: ${cashCups + ccCups}",
                              style: TextStyle(color: Colors.green[700]),
                            ),
                          ],
                        ),
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

  // Build Firestore query with location filter
  Stream<QuerySnapshot> _buildQuery() {
    Query query = firestore.collection('shifts').orderBy('savedDate', descending: true);

    // Apply location filter in the query if set
    if (filterLocation != null && filterLocation!.isNotEmpty) {
      query = query.where('location', isEqualTo: filterLocation);
    }

    return query.snapshots();
  }

  // Calculate total sale from shift data
  double _calculateSale(Map<String, dynamic> data) {
    int cashCups = int.tryParse(data['cashCups'] ?? '0') ?? 0;
    int ccCups = int.tryParse(data['ccCups'] ?? '0') ?? 0;
    return cashCups * 7 + ccCups * 7.27;
  }

  Widget _buildLocationFilter() {
    return StreamBuilder<QuerySnapshot>(
      // Get unique locations from all shifts
      stream: firestore.collection('shifts').snapshots(),
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
            ...locations.map((loc) => DropdownMenuItem(value: loc, child: Text(loc))),
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

  Widget _buildWorkerFilter() {
    return TextField(
      decoration: InputDecoration(
        labelText: "Worker Name",
        border: OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (value) {
        setState(() {
          filterWorker = value.isEmpty ? null : value;
        });
      },
    );
  }

  Widget _buildDateRangeFilter() {
    String dateText = filterStartDate == null
        ? "All Dates"
        : "${DateFormat('MMM dd').format(filterStartDate!)}${filterEndDate != null ? ' - ${DateFormat('MMM dd').format(filterEndDate!)}' : ''}";

    return OutlinedButton.icon(
      onPressed: () async {
        DateTimeRange? picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          initialDateRange: filterStartDate != null
              ? DateTimeRange(
            start: filterStartDate!,
            end: filterEndDate ?? DateTime.now(),
          )
              : null,
        );

        if (picked != null) {
          setState(() {
            filterStartDate = picked.start;
            filterEndDate = picked.end;
          });
        }
      },
      icon: Icon(Icons.calendar_today),
      label: Text(dateText, overflow: TextOverflow.ellipsis),
    );
  }

  Widget _buildSortDropdown() {
    return DropdownButtonFormField<String>(
      value: sortBy,
      decoration: InputDecoration(
        labelText: "Sort By",
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        DropdownMenuItem(value: 'date', child: Text("Date")),
        DropdownMenuItem(value: 'location', child: Text("Location")),
        DropdownMenuItem(value: 'sales', child: Text("Sales")),
      ],
      onChanged: (value) {
        setState(() {
          sortBy = value!;
        });
      },
    );
  }
}
