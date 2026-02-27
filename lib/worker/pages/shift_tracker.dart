import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../services/weather_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';



class ShiftTracker extends StatefulWidget {
  @override
  _ShiftTrackerState createState() => _ShiftTrackerState();
}

class _ShiftTrackerState extends State<ShiftTracker> {

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool isSaving = false;

  // Store raw weather data at the START of the shift
  double? tempStart;
  String? weatherConditionStart;

  DateTime selectedDate = DateTime.now();
  String? selectedLocation;
  TimeOfDay? timeIn;
  TimeOfDay? timeOut;
  String? temperature;
  String? weatherIcon;


  // Controllers for your fields
  final nameController = TextEditingController();
  final amCashController = TextEditingController(text: "100");
  final pmCashController = TextEditingController(text: "100");
  final cupsStartedController = TextEditingController();
  final cupsEndedController = TextEditingController();
  final cashCupsController = TextEditingController(text: "0");
  final ccCupsController = TextEditingController(text: "0");
  final ccTipsController = TextEditingController(text: "0");
  final notesController = TextEditingController();

  // This function selects all text in a field when you tap it
  void _selectAllOnTap(TextEditingController controller) {
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
  }

  final List<String> locations = [
    'T-501', 'T-Nike', 'T-Hanes', 'T-Coach 17', 'T-17', 'Garden City Pier',
    'Lakewood - Beach Access', 'Lakewood - Waterpark', 'Broadway - Wonder Works',
    'Broadway - Aquarium Bridge', 'Broadway - Margaritaville', 'Grand Prix',
    'Myrtle Waves - Wave Pool', 'Myrtle Waves - Kiddie Pool',
    "Barefoot Landing - It's Sugar", 'Barefoot Landing - Pizza',
    'Coastal Grand Mall', 'Compass Cove', 'Crown Reef', 'Paradise',
    'Landmark', 'Hotel Blue', 'Captains Quarters', '4th Ave', 'Camelot',
    'Anderson', 'Carolinian', 'Caravelle', 'Ocean Reef', 'Grand Cayman',
    'Sand Dunes Pool', 'Sand Dunes Waterpark', 'North Shore', 'Beach Cove',
    'Ocean Creek', 'Baywatch', 'Wyndham Lazy River', 'Wyndham Upper Pool',
    'Embassy Suites Kingston Plantation', 'Hilton Myrtle Beach Resort',
    'Sun Outdoors Commonpark', 'Sun Outdoors Waterpark'
  ];

  double calculateTotalHours() {
    if (timeIn == null || timeOut == null) return 0.0;

    double start = timeIn!.hour + (timeIn!.minute / 60.0);
    double end = timeOut!.hour + (timeOut!.minute / 60.0);

    double total = end - start;
    double result = double.parse(total.toStringAsFixed(2));
    return result;
  }

  bool validateCups() {
    int cashCups = int.tryParse(cashCupsController.text) ?? 0;
    int ccCups = int.tryParse(ccCupsController.text) ?? 0;
    int totalCupsSold = cashCups + ccCups;

    int cupsStarted = int.tryParse(cupsStartedController.text) ?? 0;
    int cupsEnded = int.tryParse(cupsEndedController.text) ?? 0;
    int usedCups = cupsStarted - cupsEnded;

    return totalCupsSold == usedCups;
  }

  // Save draft to AppState
  void _saveDraftToAppState() {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.updateDraft(
      name: nameController.text.isEmpty ? null : nameController.text,
      location: selectedLocation,
      timeIn: timeIn,
      timeOut: timeOut,
      amCash: amCashController.text,
      pmCash: pmCashController.text,
      cupsStarted: cupsStartedController.text,
      cupsEnded: cupsEndedController.text,
      cashCups: cashCupsController.text,
      ccCups: ccCupsController.text,
      ccTips: ccTipsController.text,
    );
  }

  Future<void> saveShift() async {

    List<String> emptyFields = [];

    if (nameController.text.trim().isEmpty) emptyFields.add("Name");
    if (selectedLocation == null) emptyFields.add("Location");
    if (amCashController.text.trim().isEmpty) emptyFields.add("AM Bank Cash");
    if (pmCashController.text.trim().isEmpty) emptyFields.add("PM Bank Cash");
    if (cupsStartedController.text.trim().isEmpty) emptyFields.add("Cups Started");
    if (cupsEndedController.text.trim().isEmpty) emptyFields.add("Cups Ended");
    if (cashCupsController.text.trim().isEmpty) emptyFields.add("Cash Cups Sold");
    if (ccCupsController.text.trim().isEmpty) emptyFields.add("Credit Card Cups Sold");
    if (ccTipsController.text.trim().isEmpty) emptyFields.add("Credit Card Tips");
    if (timeIn == null) emptyFields.add("Time In");
    if (timeOut == null) emptyFields.add("Time Out");

    // If there are any empty fields, show them
    if (emptyFields.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please fill in: ${emptyFields.join(', ')}"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3), // Show longer so user can read it
        ),
      );
      return;
    }

    setState(() {
      isSaving = true; // Show loading indicator
    });

    try {
      // Fetch weather again right before saving (end of shift)
      double? tempEnd;
      String? weatherConditionEnd;

      try {
        final endData = await WeatherService().getWeather("Myrtle Beach");
        tempEnd = endData['main']['temp'].toDouble();
        weatherConditionEnd = endData['weather'][0]['main']; // e.g. "Clear", "Rain"
      } catch (e) {
        print("Could not fetch end weather: $e");
      }

      // This is how you save data to Firebase
      // 'shifts' is the collection name (like a folder)
      // .add() creates a new document with an auto-generated ID
      await firestore.collection('shifts').add({
        'name': nameController.text,
        'location': selectedLocation,
        'amCash': amCashController.text,
        'pmCash': pmCashController.text,
        'cupsStarted': cupsStartedController.text,
        'cupsEnded': cupsEndedController.text,
        'cashCups': cashCupsController.text,
        'ccCups': ccCupsController.text,
        'ccTips': ccTipsController.text,
        'timeIn': timeIn != null ? '${timeIn!.hour}:${timeIn!.minute}' : null,
        'timeOut': timeOut != null ? '${timeOut!.hour}:${timeOut!.minute}' : null,
        'totalHours': calculateTotalHours(),
        // savedDate is when the shift was saved - used for sorting
        'savedDate': FieldValue.serverTimestamp(),

        // NEW: Save all weather data
        'tempStart': tempStart,
        'tempEnd': tempEnd,
        'weatherConditionStart': weatherConditionStart,
        'weatherConditionEnd': weatherConditionEnd,
      });

      // Clear the draft after successful save
      Provider.of<AppState>(context, listen: false).clearDraft();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Shift saved!"),
          backgroundColor: Colors.green,
        ),
      );

      // Go back to shifts page
      Navigator.pop(context);
    } catch (e) {
      // If something went wrong
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saving shift: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      isSaving = false;
    });
  }

  @override
  void initState() {
    super.initState();
    loadWeather();

    // Load draft data from AppState when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);

      if (appState.hasDraft) {
        setState(() {
          if (appState.draftName != null) nameController.text = appState.draftName!;
          if (appState.draftLocation != null) selectedLocation = appState.draftLocation;
          if (appState.draftTimeIn != null) timeIn = appState.draftTimeIn;
          if (appState.draftTimeOut != null) timeOut = appState.draftTimeOut;
          if (appState.draftAmCash != null) amCashController.text = appState.draftAmCash!;
          if (appState.draftPmCash != null) pmCashController.text = appState.draftPmCash!;
          if (appState.draftCupsStarted != null) cupsStartedController.text = appState.draftCupsStarted!;
          if (appState.draftCupsEnded != null) cupsEndedController.text = appState.draftCupsEnded!;
          if (appState.draftCashCups != null) cashCupsController.text = appState.draftCashCups!;
          if (appState.draftCcCups != null) ccCupsController.text = appState.draftCcCups!;
          if (appState.draftCcTips != null) ccTipsController.text = appState.draftCcTips!;
        });
      }
    });
  }

  void loadWeather() async {
    try {
      final data = await WeatherService().getWeather("Myrtle Beach");

      setState(() {
        temperature = "${data['main']['temp'].round()}°F";
        weatherIcon = data['weather'][0]['icon'];

        tempStart = data['main']['temp'].toDouble();
        weatherConditionStart = data['weather'][0]['main'];
      });
    } catch (e) {
      print(e);
    }
  }


  @override
  Widget build(BuildContext context) {

    int cashCups = int.tryParse(cashCupsController.text) ?? 0;
    int ccCups = int.tryParse(ccCupsController.text) ?? 0;
    int totalCupsSold = cashCups + ccCups;

    int cupsStarted = int.tryParse(cupsStartedController.text) ?? 0;
    int cupsEnded = int.tryParse(cupsEndedController.text) ?? 0;
    int usedCups = cupsStarted - cupsEnded;

    double totalSale = cashCups*7 + ccCups*7.27;

    final isCupsValid = validateCups();

    return Scaffold(
      appBar: AppBar(
        title: Text("Shift Tracker"),
      ),
      body: Stack(

        children: [

          ListView(
            padding: EdgeInsets.all(16),
            children: [

              // NAME
              TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Name",
                  ),
                  onChanged: (value) {
                    setState(() {});
                    _saveDraftToAppState(); // Save draft on every change
                  }
              ),

              // LOCATION
              SizedBox(height: 20),
              DropdownSearch<String>(
                items: locations,

                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: "Location",
                    border: OutlineInputBorder(),
                  ),
                ),

                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    decoration: InputDecoration(
                      hintText: "Search location...",
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),

                onChanged: (String? newValue) {
                  setState(() {
                    selectedLocation = newValue;
                  });
                  if (newValue != null) {
                    Provider.of<AppState>(context, listen: false)
                        .setLocation(newValue);
                  }
                  _saveDraftToAppState(); // Save draft
                },

                selectedItem: selectedLocation,

              ),

              // AM BANK
              SizedBox(height: 20),
              TextField(
                controller: amCashController,
                decoration: InputDecoration(
                  labelText: "AM Bank Cash",
                  prefixText: "\$",
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  setState(() {});
                  _saveDraftToAppState();
                },
              ),

              // PM BANK
              SizedBox(height: 20),
              TextField(
                controller: pmCashController,
                decoration: InputDecoration(
                  labelText: "PM Bank Cash",
                  prefixText: "\$",
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  setState(() {});
                  _saveDraftToAppState();
                },
              ),

              // CUPS STARTED / ENDED
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: cupsStartedController,
                      decoration: InputDecoration(labelText: "Cups Started"),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        setState(() {});
                        _saveDraftToAppState();
                      },
                    ),
                  ),

                  SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: cupsEndedController,
                      decoration: InputDecoration(labelText: "Cups Ended"),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        setState(() {});
                        _saveDraftToAppState();
                      },
                    ),
                  ),
                ],
              ),

              // CASH CUPS SOLD
              SizedBox(height: 20),
              TextField(
                controller: cashCupsController,
                decoration: InputDecoration(labelText: "Cash Cups Sold"),
                keyboardType: TextInputType.number,
                onTap: () => _selectAllOnTap(cashCupsController),
                onChanged: (v) {
                  setState(() {});
                  _saveDraftToAppState();
                },
              ),

              // CC CUPS SOLD
              SizedBox(height: 20),
              TextField(
                controller: ccCupsController,
                decoration: InputDecoration(labelText: "Credit Card Cups Sold"),
                keyboardType: TextInputType.number,
                onTap: () => _selectAllOnTap(ccCupsController),
                onChanged: (v) {
                  setState(() {});
                  _saveDraftToAppState();
                },
              ),

              // CC TIPS
              SizedBox(height: 20),
              TextField(
                controller: ccTipsController,
                decoration: InputDecoration(
                  labelText: "Credit Card Tips",
                  prefixText: "\$",
                ),
                keyboardType: TextInputType.number,
                onTap: () => _selectAllOnTap(ccTipsController),
                onChanged: (v) {
                  setState(() {});
                  _saveDraftToAppState();
                },
              ),

              // VALIDATE CUPS USED == CUPS SOLD
              SizedBox(height: 20),
              if (!isCupsValid)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    "⚠️ Cups sold do not match cups used. (Cups used: $usedCups)",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              Text(
                "Total Cups Sold: $totalCupsSold",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              Text(
                "Total Sale: \$${totalSale.toStringAsFixed(2)}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
              ),

              // TIME IN
              SizedBox(height: 20),
              ListTile(
                  title: Text("Time In: ${timeIn?.format(context) ?? 'Not Set'}"),
                  trailing: Icon(Icons.access_time),
                  onTap: () async {
                    TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setState(() => timeIn = picked);
                      _saveDraftToAppState();
                    }
                  }
              ),

              // TIME OUT
              ListTile(
                title: Text("Time Out: ${timeOut?.format(context) ?? 'Not Set'}"),
                trailing: Icon(Icons.access_time),
                onTap: () async {
                  TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (picked != null) {
                    setState(() => timeOut = picked);
                    _saveDraftToAppState();
                  }
                },
              ),

              // TOTAL HOUR
              SizedBox(height: 20),
              Text(
                "Total Hour: ${calculateTotalHours()}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              // SAVE BUTTON
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: isSaving ? null : saveShift,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(15),
                  backgroundColor: Colors.blue,
                  minimumSize: Size(double.infinity, 50),
                ),
                child: isSaving
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                  "Save Shift",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),

          // 2️⃣ WEATHER UI (TOP RIGHT)
          Positioned(
            top: 16,
            right: 16,
            child: WeatherWidget(
              temperature: temperature,
              icon: weatherIcon,
            ),
          ),
        ],
      ),
    );
  }
}

class WeatherWidget extends StatelessWidget {
  final String? temperature;
  final String? icon;

  const WeatherWidget({
    super.key,
    this.temperature,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (temperature == null) return SizedBox();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            color: Colors.black26,
          ),
        ],
      ),
      child: Row(
        children: [
          if (icon != null)
            Image.network(
              "https://openweathermap.org/img/wn/$icon@2x.png",
              width: 30,
              height: 30,
            ),
          SizedBox(width: 6),
          Text(
            temperature!,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
