import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shift_tracker/auth//auth_service.dart';

class AdminPanelPage extends StatefulWidget {
  @override
  _AdminPanelPageState createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _emailController = TextEditingController();
  String _selectedRole = 'worker'; // Default to worker
  bool _isCreating = false;
  String? _successMessage;
  String? _errorMessage;

  Future<void> _createNewUser() async {
    if (_emailController.text.isEmpty) {
      setState(() => _errorMessage = "Please enter an email");
      return;
    }

    if (!_emailController.text.contains('@')) {
      setState(() => _errorMessage = "Please enter a valid email");
      return;
    }

    setState(() {
      _isCreating = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _authService.createUserAccount(
        email: _emailController.text.trim(),
        role: _selectedRole,
      );

      setState(() {
        _successMessage = "User created! They can now sign up with this email.";
        _emailController.clear();
        _selectedRole = 'worker';
        _isCreating = false;
      });

      // Clear message after 3 seconds
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _successMessage = null);
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isCreating = false;
      });
    }
  }

  Future<void> _deleteUser(String userId, String email) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete User?"),
        content: Text("Are you sure you want to delete $email?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _firestore.collection('users').doc(userId).delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("User deleted"),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Error deleting user: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Panel"),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // CREATE NEW USER SECTION
          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Create New User",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),

                  SizedBox(height: 16),

                  // Email input
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Email",
                      hintText: "user@example.com",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Role selector
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Role",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text("Worker"),
                              value: 'worker',
                              groupValue: _selectedRole,
                              onChanged: (value) {
                                setState(() => _selectedRole = value!);
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text("Manager"),
                              value: 'manager',
                              groupValue: _selectedRole,
                              onChanged: (value) {
                                setState(() => _selectedRole = value!);
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Error message
                  if (_errorMessage != null)
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[900]),
                      ),
                    ),

                  // Success message
                  if (_successMessage != null)
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _successMessage!,
                        style: TextStyle(color: Colors.green[900]),
                      ),
                    ),

                  SizedBox(height: 16),

                  // Create button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isCreating ? null : _createNewUser,
                      icon: Icon(Icons.add),
                      label: Text("Create User"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 24),

          // ALL USERS SECTION
          Text(
            "All Users",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),

          SizedBox(height: 12),

          // Users list
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text("Error loading users"));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    "No users yet",
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              final users = snapshot.data!.docs;

              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final userDoc = users[index];
                  final userData = userDoc.data() as Map<String, dynamic>;
                  final email = userData['email'] ?? 'Unknown';
                  final role = userData['role'] ?? 'Unknown';
                  final status = userData['status'] ?? 'unknown';

                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: role == 'manager'
                            ? Colors.deepPurple
                            : Colors.blue,
                        child: Text(
                          (email[0] ?? 'U').toUpperCase(),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(email),
                      subtitle: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: role == 'manager'
                                  ? Colors.deepPurple[100]
                                  : Colors.blue[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              role.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: role == 'manager'
                                    ? Colors.deepPurple
                                    : Colors.blue,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: status == 'active'
                                  ? Colors.green[100]
                                  : Colors.orange[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: status == 'active'
                                    ? Colors.green[800]
                                    : Colors.orange[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _deleteUser(userDoc.id, email);
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}