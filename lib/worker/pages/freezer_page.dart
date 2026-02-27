import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app_state.dart';

class FreezerPage extends StatefulWidget {
  const FreezerPage({super.key});

  @override
  State<FreezerPage> createState() => _FreezerPageState();
}

class _FreezerPageState extends State<FreezerPage> {
  static const int rows = 2;
  static const int cols = 5;

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // All available flavors
  final List<String> flavors = [
    'Strawberry',
    'Mango',
    'Cherry',
    'Lemon',
    'Sour Apple',
    'Fudgesicle',
    'Banana',
    'Coconut',
    'Grape',
    'Blue Raspberry',
    'Piña Colada',
    'Watermelon',
    'Peach',
    'Orange Creamsicle',
    'Pineapple',
    'Cotton Candy',
    'Lime',
    'Birthday Cake',
    'Bubble Gum',
  ];

  // Show grid size configuration dialog
  void _showGridSizeDialog(BuildContext context, String location, int currentRows, int currentCols) {
    int selectedRows = currentRows;
    int selectedCols = currentCols;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.grid_on, color: Colors.blue),
                  ),
                  SizedBox(width: 12),
                  Text('Configure Grid Size'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Set the number of rows and columns for this location's freezer",
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 24),
                  // Rows selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Rows:",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: selectedRows > 1
                                ? () => setDialogState(() => selectedRows--)
                                : null,
                            icon: Icon(Icons.remove_circle_outline),
                            color: Colors.blue,
                          ),
                          Container(
                            width: 40,
                            child: Text(
                              "$selectedRows",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: selectedRows < 5
                                ? () => setDialogState(() => selectedRows++)
                                : null,
                            icon: Icon(Icons.add_circle_outline),
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Columns selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Columns:",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: selectedCols > 1
                                ? () => setDialogState(() => selectedCols--)
                                : null,
                            icon: Icon(Icons.remove_circle_outline),
                            color: Colors.blue,
                          ),
                          Container(
                            width: 40,
                            child: Text(
                              "$selectedCols",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: selectedCols < 8
                                ? () => setDialogState(() => selectedCols++)
                                : null,
                            icon: Icon(Icons.add_circle_outline),
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Total slots: ${selectedRows * selectedCols}",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Cancel'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    await _updateGridSize(location, selectedRows, selectedCols);
                    Navigator.pop(dialogContext);
                  },
                  icon: Icon(Icons.check, size: 18),
                  label: Text('Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Update grid size in Firebase
  Future<void> _updateGridSize(String location, int newRows, int newCols) async {
    try {
      await firestore.collection('freezer').doc(location).set({
        'rows': newRows,
        'cols': newCols,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Grid size updated to ${newRows}x$newCols!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Error: $e'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // Show flavor picker dialog
  void _showFlavorPicker(BuildContext context, String location, int row, int col) {
    String? selectedFlavor;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.ac_unit, color: Colors.blue),
              ),
              SizedBox(width: 12),
              Text('Select Flavor'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: DropdownSearch<String>(
              items: flavors,
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: "Flavor",
                  hintText: "Search flavors...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  prefixIcon: Icon(Icons.icecream, color: Colors.blue),
                ),
              ),
              popupProps: PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    hintText: "Type to search...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                itemBuilder: (context, item, isSelected) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: Colors.blue,
                        ),
                        SizedBox(width: 12),
                        Text(
                          item,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              onChanged: (String? value) {
                selectedFlavor = value;
              },
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.pop(dialogContext),
              icon: Icon(Icons.close, size: 18),
              label: Text('Cancel'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                await _updateSlot(location, row, col, null);
                Navigator.pop(dialogContext);
              },
              icon: Icon(Icons.delete_outline, size: 18),
              label: Text('Clear'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (selectedFlavor != null) {
                  await _updateSlot(location, row, col, selectedFlavor!);
                }
                Navigator.pop(dialogContext);
              },
              icon: Icon(Icons.check, size: 18),
              label: Text('Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Update a slot in Firebase
  Future<void> _updateSlot(String location, int row, int col, String? flavor) async {
    try {
      // Document path: freezer/{location}
      final docRef = firestore.collection('freezer').doc(location);

      // Field name: "slot_row_col" (e.g., "slot_0_2")
      final fieldName = 'slot_${row}_$col';

      await docRef.set({
        fieldName: flavor,
      }, SetOptions(merge: true)); // merge: true updates only this field

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text(flavor != null ? 'Flavor saved!' : 'Slot cleared!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Error: $e'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocation = Provider.of<AppState>(context).currentLocation;

    if (currentLocation == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Freezer Inventory"),
          backgroundColor: Colors.blue,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.ac_unit, size: 80, color: Colors.grey[300]),
              SizedBox(height: 24),
              Text(
                "You must be working at a location\nto view the freezer",
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Freezer – $currentLocation"),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: firestore.collection('freezer').doc(currentLocation).snapshots(),
        builder: (context, snapshot) {
          // Get the data (or empty map if doesn't exist yet)
          Map<String, dynamic> freezerData = {};
          if (snapshot.hasData && snapshot.data!.exists) {
            freezerData = snapshot.data!.data() as Map<String, dynamic>;
          }

          // Get freezer size from data, default to 2x5
          final int freezerRows = freezerData['rows'] ?? rows;
          final int freezerCols = freezerData['cols'] ?? cols;
          final int totalSlots = freezerRows * freezerCols;

          // Count filled slots
          int filledSlots = 0;
          for (int row = 0; row < freezerRows; row++) {
            for (int col = 0; col < freezerCols; col++) {
              final fieldName = 'slot_${row}_$col';
              if (freezerData[fieldName] != null) {
                filledSlots++;
              }
            }
          }

          return SafeArea(
            child: Column(
              children: [
                // Stats header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue, Colors.blue.shade300],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.ac_unit, size: 48, color: Colors.white),
                      SizedBox(height: 12),
                      Text(
                        "$filledSlots / $totalSlots",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "Slots Filled",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: totalSlots > 0 ? filledSlots / totalSlots : 0,
                          minHeight: 8,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                // Grid
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 12),
                          child: Text(
                            "Tap any slot to update • ${freezerRows}x$freezerCols grid",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: totalSlots,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: freezerCols,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.2,
                          ),
                          itemBuilder: (context, index) {
                            final row = index ~/ freezerCols;
                            final col = index % freezerCols;

                            // Get the flavor for this slot (or null if empty)
                            final fieldName = 'slot_${row}_$col';
                            final flavor = freezerData[fieldName] as String?;

                            return GestureDetector(
                              onTap: () {
                                _showFlavorPicker(context, currentLocation, row, col);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: flavor != null
                                      ? LinearGradient(
                                    colors: [
                                      Colors.blue.shade50,
                                      Colors.blue.shade100,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                      : null,
                                  color: flavor == null ? Colors.grey.shade50 : null,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: flavor != null ? Colors.blue.shade300 : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                  boxShadow: flavor != null
                                      ? [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                      : null,
                                ),
                                child: Stack(
                                  children: [
                                    // Main content
                                    Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            if (flavor != null)
                                              Icon(
                                                Icons.icecream,
                                                color: Colors.blue,
                                                size: 24,
                                              ),
                                            if (flavor != null) SizedBox(height: 4),
                                            Text(
                                              flavor ?? "Empty",
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: flavor != null ? Colors.blue[900] : Colors.grey[400],
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Position indicator
                                    Positioned(
                                      top: 6,
                                      left: 6,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: flavor != null
                                              ? Colors.blue.withOpacity(0.2)
                                              : Colors.grey.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          "${row + 1}-${col + 1}",
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: flavor != null ? Colors.blue[800] : Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Edit indicator
                                    if (flavor != null)
                                      Positioned(
                                        bottom: 6,
                                        right: 6,
                                        child: Icon(
                                          Icons.edit,
                                          size: 14,
                                          color: Colors.blue.withOpacity(0.5),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 16),
                        // Bottom info card
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Tap any slot to add, edit, or clear flavors",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue[900],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        // Settings button
                        OutlinedButton.icon(
                          onPressed: () => _showGridSizeDialog(context, currentLocation, freezerRows, freezerCols),
                          icon: Icon(Icons.settings),
                          label: Text("Change Grid Size"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: BorderSide(color: Colors.blue),
                            minimumSize: Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
      ),
    );
  }
}