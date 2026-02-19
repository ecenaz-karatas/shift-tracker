import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// This page shows a saved shift but NOTHING can be edited
class ShiftDetail extends StatelessWidget {
  // This receives the shift data from the shifts list
  final Map<String, dynamic> shiftData;

  ShiftDetail({required this.shiftData});

  // Helper function to format time from "hour:minute" string
  String formatTime(String? time) {
    if (time == null) return 'Not Set';
    var parts = time.split(':');
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);
    // Convert to 12-hour format
    String amPm = hour >= 12 ? 'PM' : 'AM';
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;
    return '$hour:${minute.toString().padLeft(2, '0')} $amPm';
  }

  // These are the weather conditions OpenWeatherMap returns that count as "rain"
  bool _isRainy(String? condition) {
    if (condition == null) return false;
    final rainyConditions = ['Rain', 'Drizzle', 'Thunderstorm', 'Snow', 'Sleet'];
    return rainyConditions.contains(condition);
  }

  // Check if it was sunny (clear sky)
  bool _isSunny(String? condition) {
    if (condition == null) return false;
    return condition == 'Clear';
  }


  @override
  Widget build(BuildContext context) {
    // Calculate totals from saved data
    int cashCups = int.tryParse(shiftData['cashCups'] ?? '0') ?? 0;
    int ccCups = int.tryParse(shiftData['ccCups'] ?? '0') ?? 0;
    int totalCupsSold = cashCups + ccCups;
    double totalSale = cashCups * 7 + ccCups * 7.27;

    // Format the saved date
    Timestamp savedTimestamp = shiftData['savedDate'];
    DateTime savedDate = savedTimestamp.toDate();
    String formattedDate =
        "${savedDate.month}/${savedDate.day}/${savedDate.year}";
    String dayName =
    ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"][
    savedDate.weekday - 1];

    // Calculate weather summary from saved data
    double? tempStart = shiftData['tempStart']?.toDouble();
    double? tempEnd = shiftData['tempEnd']?.toDouble();
    String? conditionStart = shiftData['weatherConditionStart'];
    String? conditionEnd = shiftData['weatherConditionEnd'];

    // Average temp: if we have both, average them. If only one, use that one.
    double? avgTemp;
    if (tempStart != null && tempEnd != null) {
      avgTemp = (tempStart + tempEnd) / 2;
    } else if (tempStart != null) {
      avgTemp = tempStart;
    } else if (tempEnd != null) {
      avgTemp = tempEnd;
    }

    // Did it rain at any point during the shift?
    bool rained = _isRainy(conditionStart) || _isRainy(conditionEnd);

    // Was it sunny at any point?
    bool sunny = _isSunny(conditionStart) || _isSunny(conditionEnd);

    // Figure out the weather summary text and icon
    String weatherSummary;
    IconData weatherIcon;
    Color weatherColor;

    if (rained) {
      weatherSummary = "Rainy";
      weatherIcon = Icons.water_drop;
      weatherColor = Colors.blue;
    } else if (sunny) {
      weatherSummary = "Sunny";
      weatherIcon = Icons.wb_sunny;
      weatherColor = Colors.orange;
    } else if (conditionStart != null || conditionEnd != null) {
      // Cloudy or other conditions
      weatherSummary = conditionStart ?? conditionEnd ?? "Unknown";
      weatherIcon = Icons.cloud;
      weatherColor = Colors.grey;
    } else {
      weatherSummary = "No data";
      weatherIcon = Icons.help_outline;
      weatherColor = Colors.grey;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Shift Details"),
        backgroundColor: Colors.blue,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // DATE HEADER
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  Text(
                    formattedDate,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // NEW: WEATHER CARD
          Card(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Weather During Shift",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Average Temperature
                      Column(
                        children: [
                          Icon(Icons.thermostat, color: Colors.red, size: 28),
                          SizedBox(height: 6),
                          Text(
                            avgTemp != null ? "${avgTemp.round()}°F" : "N/A",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text("Avg Temp", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      // Divider between columns
                      Container(width: 1, height: 60, color: Colors.grey[200]),
                      // Weather Condition
                      Column(
                        children: [
                          Icon(weatherIcon, color: weatherColor, size: 28),
                          SizedBox(height: 6),
                          Text(
                            weatherSummary,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text("Condition", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      // Divider
                      Container(width: 1, height: 60, color: Colors.grey[200]),
                      // Rain indicator
                      Column(
                        children: [
                          Icon(
                            rained ? Icons.water_drop : Icons.water_drop_outlined,
                            color: rained ? Colors.blue : Colors.grey,
                            size: 28,
                          ),
                          SizedBox(height: 6),
                          Text(
                            rained ? "Yes" : "No",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: rained ? Colors.blue : Colors.grey,
                            ),
                          ),
                          Text("Rained", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // All fields are displayed as READ-ONLY using Text inside
          // disabled TextFields so they look the same as the editable form
          // but the user CANNOT change anything

          // NAME
          _readOnlyField("Name", shiftData['name']),

          // LOCATION
          _readOnlyField("Location", shiftData['location']),

          // AM BANK
          _readOnlyField("AM Bank Cash", shiftData['amCash']),

          // PM BANK
          _readOnlyField("PM Bank Cash", shiftData['pmCash']),

          // CUPS STARTED / ENDED
          Row(
            children: [
              Expanded(child: _readOnlyField("Cups Started", shiftData['cupsStarted'])),
              SizedBox(width: 10),
              Expanded(child: _readOnlyField("Cups Ended", shiftData['cupsEnded'])),
            ],
          ),

          // CASH CUPS
          _readOnlyField("Cash Cups Sold", shiftData['cashCups']),

          // CC CUPS
          _readOnlyField("Credit Card Cups Sold", shiftData['ccCups']),

          // CC TIPS
          _readOnlyField("Credit Card Tips", shiftData['ccTips']),

          // TOTALS
          SizedBox(height: 10),
          Text(
            "Total Cups Sold: $totalCupsSold",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            "Total Sale: \$${totalSale.toStringAsFixed(2)}",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
          ),

          // TIME IN / OUT
          SizedBox(height: 16),
          ListTile(
            title: Text("Time In: ${formatTime(shiftData['timeIn'])}"),
            trailing: Icon(Icons.access_time, color: Colors.grey),
            // No onTap - it does nothing when clicked!
          ),
          ListTile(
            title: Text("Time Out: ${formatTime(shiftData['timeOut'])}"),
            trailing: Icon(Icons.access_time, color: Colors.grey),
          ),

          // TOTAL HOURS
          SizedBox(height: 10),
          Text(
            "Total Hours: ${(shiftData['totalHours'] ?? 0.0).toStringAsFixed(2)}",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // This is a helper function that creates a read-only text field
  // enabled: false makes it uneditable
  // The gray background makes it obvious it can't be changed
  Widget _readOnlyField(String label, dynamic value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: TextEditingController(text: value?.toString() ?? ''),
        enabled: false,  // THIS is what makes it read-only
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[100],  // Light gray background
        ),
      ),
    );
  }
}
