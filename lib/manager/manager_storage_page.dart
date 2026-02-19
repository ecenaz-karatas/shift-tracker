import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManagerStoragePage extends StatefulWidget {
  const ManagerStoragePage({super.key});

  @override
  State<ManagerStoragePage> createState() => _ManagerStoragePageState();
}

class _ManagerStoragePageState extends State<ManagerStoragePage> {
  // Storage thresholds
  static const int cupBagsLow = 2;
  static const int paperTowelsLow = 2;
  static const int spoonBoxesLow = 1;

  // Freezer grid size
  static const int freezerRows = 2;
  static const int freezerCols = 5;

  String searchQuery = '';
  String filterStatus = 'all'; // 'all', 'issues', 'storage', 'freezer'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Inventory Overview"),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                // Search Field
                TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by location...',
                    prefixIcon: Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),

                SizedBox(height: 12),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('All', 'all', Icons.grid_view),
                      SizedBox(width: 8),
                      _filterChip('Issues Only', 'issues', Icons.warning_amber),
                      SizedBox(width: 8),
                      _filterChip('Storage', 'storage', Icons.inventory),
                      SizedBox(width: 8),
                      _filterChip('Freezer', 'freezer', Icons.ac_unit),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('storage').snapshots(),
              builder: (context, storageSnapshot) {
                if (storageSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (storageSnapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error loading inventory data",
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  );
                }

                if (!storageSnapshot.hasData || storageSnapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "No inventory data available yet",
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                // Get all storage docs
                final storageDocs = storageSnapshot.data!.docs;

                // Filter by search query
                final filteredDocs = storageDocs.where((doc) {
                  final location = doc.id.toLowerCase();
                  return location.contains(searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "No locations match your search",
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                // Calculate overall stats
                int totalLocations = filteredDocs.length;
                int locationsWithIssues = 0;
                int totalLowItems = 0;

                for (var doc in filteredDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  bool hasIssue = false;

                  if ((data['cupBags'] ?? 0) <= cupBagsLow) {
                    totalLowItems++;
                    hasIssue = true;
                  }
                  if ((data['paperTowels'] ?? 0) <= paperTowelsLow) {
                    totalLowItems++;
                    hasIssue = true;
                  }
                  if ((data['spoonBoxes'] ?? 0) <= spoonBoxesLow) {
                    totalLowItems++;
                    hasIssue = true;
                  }

                  if (hasIssue) locationsWithIssues++;
                }

                return ListView(
                  padding: EdgeInsets.all(16),
                  children: [
                    // Summary Cards (only show if 'all' filter)
                    if (filterStatus == 'all') ...[
                      Row(
                        children: [
                          Expanded(
                            child: _summaryCard(
                              icon: Icons.location_on,
                              title: "Locations",
                              value: totalLocations.toString(),
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _summaryCard(
                              icon: Icons.warning_amber,
                              title: "With Issues",
                              value: locationsWithIssues.toString(),
                              color: locationsWithIssues > 0 ? Colors.orange : Colors.green,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _summaryCard(
                              icon: Icons.inventory,
                              title: "Low Items",
                              value: totalLowItems.toString(),
                              color: totalLowItems > 0 ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                    ],

                    // Location Cards
                    ...filteredDocs.map((doc) {
                      final location = doc.id;
                      final storageData = doc.data() as Map<String, dynamic>;

                      return _buildLocationCard(context, location, storageData);
                    }).toList(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, IconData icon) {
    final isSelected = filterStatus == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey[700]),
          SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          filterStatus = value;
        });
      },
      selectedColor: Colors.green,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context, String location, Map<String, dynamic> storageData) {
    final cupBags = storageData['cupBags'] ?? 0;
    final paperTowels = storageData['paperTowels'] ?? 0;
    final spoonBoxes = storageData['spoonBoxes'] ?? 0;
    final lastUpdated = storageData['lastUpdated'] as Timestamp?;

    final cupBagsLowStatus = cupBags <= cupBagsLow;
    final paperTowelsLowStatus = paperTowels <= paperTowelsLow;
    final spoonBoxesLowStatus = spoonBoxes <= spoonBoxesLow;
    final hasStorageIssues = cupBagsLowStatus || paperTowelsLowStatus || spoonBoxesLowStatus;

    // Apply filters
    if (filterStatus == 'issues' && !hasStorageIssues) {
      return SizedBox.shrink();
    }
    if (filterStatus == 'freezer') {
      // Show only freezer for this location
      return _buildFreezerOnlyCard(context, location);
    }
    if (filterStatus == 'storage') {
      // Show only storage (no freezer section)
      return _buildStorageOnlyCard(context, location, storageData, hasStorageIssues, lastUpdated);
    }

    // Default: show both storage and freezer
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: hasStorageIssues ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasStorageIssues ? Colors.red.withOpacity(0.5) : Colors.grey.withOpacity(0.2),
          width: hasStorageIssues ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location Header
            _buildLocationHeader(location, hasStorageIssues, lastUpdated),

            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 12),

            // Storage Section
            Row(
              children: [
                Icon(Icons.inventory, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text(
                  "Storage Items",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _inventoryItem(
              label: "Cup Bags",
              value: cupBags,
              threshold: cupBagsLow,
              isLow: cupBagsLowStatus,
            ),
            SizedBox(height: 12),
            _inventoryItem(
              label: "Paper Towels",
              value: paperTowels,
              threshold: paperTowelsLow,
              isLow: paperTowelsLowStatus,
            ),
            SizedBox(height: 12),
            _inventoryItem(
              label: "Spoon Boxes",
              value: spoonBoxes,
              threshold: spoonBoxesLow,
              isLow: spoonBoxesLowStatus,
            ),

            SizedBox(height: 20),
            Divider(),
            SizedBox(height: 12),

            // Freezer Section
            _buildFreezerSection(location),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageOnlyCard(BuildContext context, String location, Map<String, dynamic> storageData, bool hasIssues, Timestamp? lastUpdated) {
    final cupBags = storageData['cupBags'] ?? 0;
    final paperTowels = storageData['paperTowels'] ?? 0;
    final spoonBoxes = storageData['spoonBoxes'] ?? 0;

    final cupBagsLowStatus = cupBags <= cupBagsLow;
    final paperTowelsLowStatus = paperTowels <= paperTowelsLow;
    final spoonBoxesLowStatus = spoonBoxes <= spoonBoxesLow;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: hasIssues ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasIssues ? Colors.red.withOpacity(0.5) : Colors.grey.withOpacity(0.2),
          width: hasIssues ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLocationHeader(location, hasIssues, lastUpdated),
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 12),
            _inventoryItem(
              label: "Cup Bags",
              value: cupBags,
              threshold: cupBagsLow,
              isLow: cupBagsLowStatus,
            ),
            SizedBox(height: 12),
            _inventoryItem(
              label: "Paper Towels",
              value: paperTowels,
              threshold: paperTowelsLow,
              isLow: paperTowelsLowStatus,
            ),
            SizedBox(height: 12),
            _inventoryItem(
              label: "Spoon Boxes",
              value: spoonBoxes,
              threshold: spoonBoxesLow,
              isLow: spoonBoxesLowStatus,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreezerOnlyCard(BuildContext context, String location) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.ac_unit,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 12),
            _buildFreezerSection(location),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationHeader(String location, bool hasIssues, Timestamp? lastUpdated) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: hasIssues ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            hasIssues ? Icons.warning_amber : Icons.check_circle,
            color: hasIssues ? Colors.red : Colors.green,
            size: 24,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                location,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (lastUpdated != null)
                Text(
                  "Updated ${_formatTimestamp(lastUpdated)}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
        if (hasIssues)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "ACTION NEEDED",
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFreezerSection(String location) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('freezer').doc(location).snapshots(),
      builder: (context, freezerSnapshot) {
        Map<String, dynamic> freezerData = {};
        if (freezerSnapshot.hasData && freezerSnapshot.data!.exists) {
          freezerData = freezerSnapshot.data!.data() as Map<String, dynamic>;
        }

        // Get freezer size from data, default to 2x5
        final int locationRows = freezerData['rows'] ?? freezerRows;
        final int locationCols = freezerData['cols'] ?? freezerCols;
        final int totalSlots = locationRows * locationCols;

        // Count filled slots
        int filledSlots = 0;
        for (int row = 0; row < locationRows; row++) {
          for (int col = 0; col < locationCols; col++) {
            final fieldName = 'slot_${row}_$col';
            if (freezerData[fieldName] != null) {
              filledSlots++;
            }
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.ac_unit, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Freezer",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "$filledSlots/$totalSlots filled • ${locationRows}x$locationCols",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: totalSlots,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: locationCols,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.5,
              ),
              itemBuilder: (context, index) {
                final row = index ~/ locationCols;
                final col = index % locationCols;
                final fieldName = 'slot_${row}_$col';
                final flavor = freezerData[fieldName] as String?;

                return Container(
                  decoration: BoxDecoration(
                    color: flavor != null ? Colors.blue.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: flavor != null ? Colors.blue : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      flavor ?? "Empty",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: flavor != null ? Colors.blue[900] : Colors.grey[500],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _inventoryItem({
    required String label,
    required int value,
    required int threshold,
    required bool isLow,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (value / (threshold * 3)).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isLow ? Colors.red : Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Container(
                width: 50,
                child: Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isLow ? Colors.red : Colors.green[700],
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8),
        Icon(
          isLow ? Icons.error : Icons.check_circle,
          color: isLow ? Colors.red : Colors.green,
          size: 20,
        ),
      ],
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return "just now";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes}m ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours}h ago";
    } else if (difference.inDays == 1) {
      return "yesterday";
    } else if (difference.inDays < 7) {
      return "${difference.inDays}d ago";
    } else {
      return "${date.month}/${date.day}/${date.year}";
    }
  }
}
