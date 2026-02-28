import 'package:flutter/material.dart';
import 'package:shift_tracker/auth//auth_service.dart';
import 'package:shift_tracker/worker/pages/main_page.dart';
import 'package:shift_tracker/manager/manager_main_page.dart';

class HomeRouter extends StatefulWidget {
  @override
  _HomeRouterState createState() => _HomeRouterState();
}

class _HomeRouterState extends State<HomeRouter> {
  final AuthService _authService = AuthService();
  late Future<String?> _roleFuture;

  @override
  void initState() {
    super.initState();
    _roleFuture = _authService.getUserRole();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _roleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Error loading user role"),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _authService.signOut();
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                    child: Text("Sign Out"),
                  ),
                ],
              ),
            ),
          );
        }

        final role = snapshot.data;

        // Route to appropriate dashboard based on role
        if (role == 'manager') {
          return ManagerMainPage();
        } else if (role == 'worker') {
          return MainPage();
        } else {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Unknown user role: $role"),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _authService.signOut();
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                    child: Text("Sign Out"),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}