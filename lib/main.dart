import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth/login_page.dart';
import 'auth/initial_setup_page.dart';
import 'auth/home_router.dart';
import 'auth/auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shift Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
      routes: {
        '/login': (context) => LoginPage(),
        '/setup': (context) => InitialSetupPage(),
        '/home': (context) => HomeRouter(),
      },
    );
  }
}

// AuthWrapper handles the initial auth state AND checks for first user
class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  late Future<bool> _isFirstUserFuture;

  @override
  void initState() {
    super.initState();
    _isFirstUserFuture = _authService.isFirstUser();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isFirstUserFuture,
      builder: (context, firstUserSnapshot) {
        // Still checking if first user
        if (firstUserSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isFirstUser = firstUserSnapshot.data ?? false;

        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnapshot) {
            // Still loading auth state
            if (authSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // First user AND not logged in → show setup
            if (isFirstUser && authSnapshot.data == null) {
              return InitialSetupPage();
            }

            // User is logged in → go to home router
            if (authSnapshot.hasData) {
              return HomeRouter();
            }

            // User is NOT logged in → show login
            return LoginPage();
          },
        );
      },
    );
  }
}
