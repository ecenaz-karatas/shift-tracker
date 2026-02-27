import 'package:flutter/material.dart';
import 'manager_shifts_page.dart';
import 'manager_reports_page.dart';
import 'manager_analytics_page.dart';
import 'manager_storage_page.dart';

class ManagerMainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manager Dashboard"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome text
            Text(
              "Manager Dashboard",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 10),

            Text(
              "Manage shifts, reports, and inventory",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 40),

            // VIEW ALL SHIFTS BUTTON
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ManagerShiftsPage()),
                );
              },
              icon: Icon(Icons.work_history, size: 28),
              label: Text(
                "View All Shifts",
                style: TextStyle(fontSize: 20),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(20),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),

            SizedBox(height: 20),

            // REPORTS BUTTON
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ManagerReportsPage()),
                );
              },
              icon: Icon(Icons.flag, size: 28),
              label: Text(
                "Storage Reports",
                style: TextStyle(fontSize: 20),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(20),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),

            SizedBox(height: 20),

            // ANALYTICS BUTTON
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ManagerAnalyticsPage()),
                );
              },
              icon: Icon(Icons.analytics, size: 28),
              label: Text(
                "Analytics",
                style: TextStyle(fontSize: 20),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(20),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),

            SizedBox(height: 20),

            // INVENTORY BUTTON
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ManagerStoragePage()),
                );
              },
              icon: Icon(Icons.inventory, size: 28),
              label: Text(
                "Inventory Overview",
                style: TextStyle(fontSize: 20),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(20),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}