import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  String? currentLocation;

  // Draft shift data - this persists while user fills out the form
  String? draftName;
  String? draftLocation;
  TimeOfDay? draftTimeIn;
  TimeOfDay? draftTimeOut;
  String? draftAmCash;
  String? draftPmCash;
  String? draftCupsStarted;
  String? draftCupsEnded;
  String? draftCashCups;
  String? draftCcCups;
  String? draftCcTips;

  // Check if there's any draft data
  bool get hasDraft {
    return draftName != null ||
        draftLocation != null ||
        draftTimeIn != null ||
        draftTimeOut != null;
  }

  void setLocation(String location) {
    currentLocation = location;
    notifyListeners();
  }

  void clearLocation() {
    currentLocation = null;
    notifyListeners();
  }

  // Save draft shift data
  void updateDraft({
    String? name,
    String? location,
    TimeOfDay? timeIn,
    TimeOfDay? timeOut,
    String? amCash,
    String? pmCash,
    String? cupsStarted,
    String? cupsEnded,
    String? cashCups,
    String? ccCups,
    String? ccTips,
  }) {
    if (name != null) draftName = name;
    if (location != null) draftLocation = location;
    if (timeIn != null) draftTimeIn = timeIn;
    if (timeOut != null) draftTimeOut = timeOut;
    if (amCash != null) draftAmCash = amCash;
    if (pmCash != null) draftPmCash = pmCash;
    if (cupsStarted != null) draftCupsStarted = cupsStarted;
    if (cupsEnded != null) draftCupsEnded = cupsEnded;
    if (cashCups != null) draftCashCups = cashCups;
    if (ccCups != null) draftCcCups = ccCups;
    if (ccTips != null) draftCcTips = ccTips;
    notifyListeners();
  }

  // Clear all draft data (when shift is saved or discarded)
  void clearDraft() {
    draftName = null;
    draftLocation = null;
    draftTimeIn = null;
    draftTimeOut = null;
    draftAmCash = null;
    draftPmCash = null;
    draftCupsStarted = null;
    draftCupsEnded = null;
    draftCashCups = null;
    draftCcCups = null;
    draftCcTips = null;
    notifyListeners();
  }

  // Calculate total cups from draft data
  int get draftTotalCups {
    int cashCups = int.tryParse(draftCashCups ?? '0') ?? 0;
    int ccCups = int.tryParse(draftCcCups ?? '0') ?? 0;
    return cashCups + ccCups;
  }

  // Calculate total sale from draft data
  double get draftTotalSale {
    int cashCups = int.tryParse(draftCashCups ?? '0') ?? 0;
    int ccCups = int.tryParse(draftCcCups ?? '0') ?? 0;
    return cashCups * 7 + ccCups * 7.27;
  }
}
