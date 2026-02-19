import 'package:flutter/material.dart';
import 'shifts_page.dart';
import 'freezer_page.dart';
import 'storage_page.dart';

class MainPage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    return Scaffold (
      appBar: AppBar (
        title: Text("Ricciardi's Italian Ice"),
        backgroundColor: Colors.blue,
      ),

      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Welcome!",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 40),

            // SHIFTS BUTTON
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ShiftsPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(20),
                backgroundColor: Colors.blue,
              ),
              child: Text(
                "Shifts",
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),

            SizedBox(height: 20),

            // FREEZER BUTTON
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FreezerPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(20),
                backgroundColor: Colors.blue,
              ),
              child: Text(
                "Freezer",
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),

            SizedBox(height: 20),

            // STORAGE BUTTON
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StoragePage()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(20),
                backgroundColor: Colors.blue,
              ),
              child: Text(
                "Storage",
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}