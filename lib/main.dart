import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'package:shift_tracker/worker/pages/main_page.dart';
import 'manager/manager_main_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// TEMPORARY: Toggle this to switch between worker and manager view
// true = Manager view, false = Worker view
// After we add authentication, this will be automatic based on user role
const bool IS_MANAGER = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MaterialApp(
        home: IS_MANAGER ? ManagerMainPage() : MainPage(),
        debugShowCheckedModeBanner: false,
      ),
    ),
  );
}
