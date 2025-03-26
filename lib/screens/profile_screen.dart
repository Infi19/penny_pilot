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
                backgroundColor: AppColors.mediumGrey,
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
          backgroundColor: AppColors.darkGrey,
          title: const Text(
            'Logout',
            style: TextStyle(color: AppColors.lightest),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: AppColors.lightGrey),
          ),
          actions: [
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.mediumGrey),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Logout',
                style: TextStyle(color: AppColors.lightest),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(color: AppColors.lightest),
        ),
        backgroundColor: AppColors.darkGrey,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save, color: AppColors.lightest),
              onPressed: _updateProfile,
            )
          else
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.lightest),
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
                      backgroundColor: AppColors.mediumGrey,
                      backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                      child: user?.photoURL == null
                          ? Text(
                              (_userData?['displayName']?.isNotEmpty == true
                                      ? _userData!['displayName'][0]
                                      : user?.displayName?.isNotEmpty == true
                                          ? user!.displayName![0]
                                          : '?')
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 36,
                                color: AppColors.darkGrey,
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
                            color: AppColors.mediumGrey,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: AppColors.darkest,
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
                leading: const Icon(Icons.email, color: AppColors.mediumGrey),
                title: const Text('Email', style: TextStyle(color: AppColors.lightest)),
                subtitle: Text(
                  _userData?['email'] ?? user?.email ?? 'No email',
                  style: const TextStyle(color: AppColors.lightGrey),
                ),
              ),
              Divider(color: AppColors.darkGrey),

              // Name
              ListTile(
                leading: const Icon(Icons.person, color: AppColors.mediumGrey),
                title: const Text('Full Name', style: TextStyle(color: AppColors.lightest)),
                subtitle: _isEditing
                    ? TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: AppColors.lightest),
                        decoration: InputDecoration(
                          hintText: 'Enter your name',
                          hintStyle: TextStyle(color: AppColors.lightGrey.withOpacity(0.7)),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.mediumGrey),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.mediumGrey),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      )
                    : Text(
                        _userData?['displayName'] ?? user?.displayName ?? 'No name set',
                        style: const TextStyle(color: AppColors.lightGrey),
                      ),
              ),
              Divider(color: AppColors.darkGrey),

              // Phone
              ListTile(
                leading: const Icon(Icons.phone, color: AppColors.mediumGrey),
                title: const Text('Phone', style: TextStyle(color: AppColors.lightest)),
                subtitle: _isEditing
                    ? TextFormField(
                        controller: _phoneController,
                        style: const TextStyle(color: AppColors.lightest),
                        decoration: InputDecoration(
                          hintText: 'Enter your phone number',
                          hintStyle: TextStyle(color: AppColors.lightGrey.withOpacity(0.7)),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.mediumGrey),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.mediumGrey),
                          ),
                        ),
                      )
                    : Text(
                        _userData?['phone'] ?? 'No phone number',
                        style: const TextStyle(color: AppColors.lightGrey),
                      ),
              ),
              Divider(color: AppColors.darkGrey),

              const SizedBox(height: 30),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showLogoutDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkGrey,
                    foregroundColor: AppColors.lightest,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Logout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
