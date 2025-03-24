import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../utils/app_colors.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _authService = AuthService();
  final _userService = UserService();
  bool _isEditing = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = _authService.getCurrentUser();
    if (user != null) {
      try {
        final userData = await _userService.getUserProfile(user.uid);
        setState(() {
          _userData = userData;
          _nameController.text = userData?['displayName'] ?? user.displayName ?? '';
          _phoneController.text = userData?['phone'] ?? '';
        });
      } catch (e) {
        print('Error loading user data: $e');
        // Fall back to Firebase Auth data if Firestore is unavailable
        setState(() {
          _nameController.text = user.displayName ?? '';
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = _authService.getCurrentUser();
        if (user != null) {
          // Update Firestore profile
          await _userService.updateUserProfile(user.uid, {
            'displayName': _nameController.text,
            'phone': _phoneController.text,
            'lastUpdated': DateTime.now().toIso8601String(),
          });

          // Update Firebase Auth display name
          await user.updateDisplayName(_nameController.text);

          setState(() {
            _isEditing = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully'),
                backgroundColor: AppColors.primaryPurple,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating profile: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.primaryPurple,
          title: const Text(
            'Logout',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFFe6ccff)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Logout',
                style: TextStyle(color: Color(0xFFe6ccff)),
              ),
              onPressed: () async {
                await _authService.signOut();
                if (context.mounted) {
                  // Close the dialog
                  Navigator.of(context).pop();
                  // Navigate to login screen and clear the stack
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.getCurrentUser();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryPurple,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: _updateProfile,
            )
          else
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Picture
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.lightPurple,
                      backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                      child: user?.photoURL == null
                          ? Text(
                              (_userData?['displayName']?.isNotEmpty == true
                                      ? _userData!['displayName'][0]
                                      : user?.displayName?.isNotEmpty == true
                                          ? user!.displayName![0]
                                          : '?')
                                  .toUpperCase(),
                              style: TextStyle(
                                fontSize: 36,
                                color: AppColors.primaryPurple,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPurple,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Email
              ListTile(
                leading: Icon(Icons.email, color: AppColors.primaryPurple),
                title: const Text('Email'),
                subtitle: Text(_userData?['email'] ?? user?.email ?? 'No email'),
              ),
              const Divider(),

              // Name
              ListTile(
                leading: Icon(Icons.person, color: AppColors.primaryPurple),
                title: const Text('Full Name'),
                subtitle: _isEditing
                    ? TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Enter your name',
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.primaryPurple),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.primaryPurple),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      )
                    : Text(_userData?['displayName'] ?? user?.displayName ?? 'No name set'),
              ),
              const Divider(),

              // Phone
              ListTile(
                leading: Icon(Icons.phone, color: AppColors.primaryPurple),
                title: const Text('Phone Number'),
                subtitle: _isEditing
                    ? TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: 'Enter your phone number',
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.primaryPurple),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.primaryPurple),
                          ),
                        ),
                      )
                    : Text(_userData?['phone'] ?? 'No phone number'),
              ),
              const Divider(),

              // Logout Button
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showLogoutDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(
                    Icons.logout,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
