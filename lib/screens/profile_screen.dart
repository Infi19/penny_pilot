import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../utils/app_colors.dart';
import '../utils/currency_util.dart';
import '../services/gemini_service.dart';
import 'login_screen.dart';
import 'financial_health_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _authService = AuthService();
  final _userService = UserService();
  final _geminiService = GeminiService(); // Access the singleton
  final _imagePicker = ImagePicker();
  final _apiKeyController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;
  Map<String, dynamic>? _userData;
  File? _selectedImage;
  String _selectedCurrency = CurrencyUtil.getDefaultCurrencyCode();

  @override
  void initState() {
    super.initState();
    super.initState();
    _loadUserData();
    _loadApiKey();
  }
  
  Future<void> _loadApiKey() async {
    // Determine which key to show - only show if it's a custom key
    if (_geminiService.isUsingCustomKey) {
      setState(() {
        _apiKeyController.text = _geminiService.currentCustomApiKey ?? '';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    final user = _authService.getCurrentUser();
    if (user != null) {
      try {
        final userData = await _userService.getUserProfile(user.uid);
        
        // If user has a photoURL in Auth but not in Firestore, update Firestore
        if (user.photoURL != null && (userData == null || userData['photoURL'] == null)) {
          await _userService.updateUserProfile(user.uid, {
            'photoURL': user.photoURL,
            'lastUpdated': DateTime.now().toIso8601String(),
          });
        }
        
        setState(() {
          _userData = userData;
          _nameController.text = userData?['displayName'] ?? user.displayName ?? '';
          _phoneController.text = userData?['phone'] ?? '';
          _bioController.text = userData?['bio'] ?? '';
          _selectedCurrency = userData?['currency'] ?? CurrencyUtil.getDefaultCurrencyCode();
          _isLoading = false;
        });
      } catch (e) {
        print('Error loading user data: $e');
        // Fall back to Firebase Auth data if Firestore is unavailable
        setState(() {
          _nameController.text = user.displayName ?? '';
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final user = _authService.getCurrentUser();
        if (user != null) {
          // Get current photo URL from Firestore or Firebase Auth
          String? photoURL = _userData?['photoURL'] ?? user.photoURL;
          
          // Upload image if selected
          if (_selectedImage != null) {
            try {
              // Create a reference to the storage location
              final storageRef = FirebaseStorage.instance
                  .ref()
                  .child('profile_images');
              
              // Ensure the directory exists by creating a small test file if needed
              try {
                // Check if directory exists by listing its contents
                await storageRef.listAll();
              } catch (e) {
                // Directory might not exist, create it with a placeholder
                final placeholderRef = storageRef.child('.placeholder');
                await placeholderRef.putString('');
              }
              
              // Now create the user-specific file
              final userImageRef = storageRef.child('${user.uid}.jpg');
              
              // Upload with metadata
              final metadata = SettableMetadata(
                contentType: 'image/jpeg',
                customMetadata: {'userId': user.uid},
              );
              
              await userImageRef.putFile(_selectedImage!, metadata);
              photoURL = await userImageRef.getDownloadURL();
              
              // Update Firebase Auth photo URL
              await user.updatePhotoURL(photoURL);
            } catch (e) {
              print('Error uploading profile image: $e');
              // Continue with the rest of the profile update even if image upload fails
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Unable to update profile picture, but other details will be saved'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          }
          
          // Update Firestore profile 
          final Map<String, dynamic> updateData = {
            'displayName': _nameController.text,
            'phone': _phoneController.text,
            'bio': _bioController.text,
            'currency': _selectedCurrency,
            'lastUpdated': DateTime.now().toIso8601String(),
          };
          
          // Always include photoURL in Firestore, whether it's from upload or existing
          if (photoURL != null) {
            updateData['photoURL'] = photoURL;
          }
          
          await _userService.updateUserProfile(user.uid, updateData);

          // Update Firebase Auth display name
          await user.updateDisplayName(_nameController.text);

          setState(() {
            _isEditing = false;
            _selectedImage = null;
            _isLoading = false;
          });

          // Reload user data to refresh the UI
          _loadUserData();

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
        setState(() {
          _isLoading = false;
        });
        
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

  Future<void> _updateApiKey() async {
    final newKey = _apiKeyController.text.trim();
    if (newKey.isNotEmpty) {
      setState(() => _isLoading = true);
      
      // Test the key first
      final String? errorMsg = await _geminiService.testApiKey(newKey);
      
      if (errorMsg != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Verification Failed: $errorMsg'),
              duration: const Duration(seconds: 5),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
        }
        return;
      }
      
      try {
        await _geminiService.setCustomApiKey(newKey);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('API Key verified and updated successfully'),
              backgroundColor: AppColors.mediumGrey,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating API Key: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      // If empty, ask to remove? Or just ignore.
      // Let's assume empty means remove custom key
       setState(() => _isLoading = true);
      try {
        await _geminiService.setCustomApiKey(null);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Custom API Key removed. Using default if available.'),
              backgroundColor: AppColors.mediumGrey,
            ),
          );
        }
      } catch (e) {
        // error handling
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
              icon: const Icon(Icons.cancel, color: AppColors.lightest),
              onPressed: () => setState(() {
                _isEditing = false;
                _selectedImage = null;
                _loadUserData(); // Reset to original data
              }),
            ),
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.mediumGrey,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Picture
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.mediumGrey,
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : _userData?['photoURL'] != null
                                    ? NetworkImage(_userData!['photoURL'])
                                    : user?.photoURL != null
                                        ? NetworkImage(user!.photoURL!)
                                        : null,
                            child: _selectedImage == null && 
                                   _userData?['photoURL'] == null && 
                                   user?.photoURL == null
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
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
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
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Profile Information Section
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.darkGrey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Email
                          ListTile(
                            dense: true,
                            horizontalTitleGap: 10,
                            leading: const Icon(Icons.email, color: AppColors.mediumGrey, size: 24),
                            title: const Text('Email', style: TextStyle(color: AppColors.lightest, fontSize: 15)),
                            subtitle: Text(
                              _userData?['email'] ?? user?.email ?? 'No email',
                              style: const TextStyle(color: AppColors.lightGrey),
                            ),
                          ),
                          Divider(color: AppColors.darkGrey),

                          // Name
                          ListTile(
                            dense: true,
                            horizontalTitleGap: 10,
                            leading: const Icon(Icons.person, color: AppColors.mediumGrey, size: 24),
                            title: const Text('Full Name', style: TextStyle(color: AppColors.lightest, fontSize: 15)),
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
                            dense: true,
                            horizontalTitleGap: 10,
                            leading: const Icon(Icons.phone, color: AppColors.mediumGrey, size: 24),
                            title: const Text('Phone', style: TextStyle(color: AppColors.lightest, fontSize: 15)),
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

                          // Bio
                          ListTile(
                            dense: true,
                            horizontalTitleGap: 10,
                            leading: const Icon(Icons.description, color: AppColors.mediumGrey, size: 24),
                            title: const Text('Bio', style: TextStyle(color: AppColors.lightest, fontSize: 15)),
                            subtitle: _isEditing
                                ? TextFormField(
                                    controller: _bioController,
                                    style: const TextStyle(color: AppColors.lightest),
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                      hintText: 'Tell us about yourself',
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
                                    _userData?['bio'] ?? 'No bio added',
                                    style: const TextStyle(color: AppColors.lightGrey),
                                  ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    
                    // Currency Section - Separated from other profile fields
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.darkGrey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.only(bottom: 20),
                      child: ListTile(
                        dense: true,
                        horizontalTitleGap: 10,
                        leading: const Icon(Icons.currency_exchange, color: AppColors.mediumGrey, size: 24),
                        title: const Text('Currency', style: TextStyle(color: AppColors.lightest, fontSize: 15)),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: AppColors.mediumGrey),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                String tempCurrency = _selectedCurrency;
                                return AlertDialog(
                                  backgroundColor: AppColors.darkGrey,
                                  title: const Text(
                                    'Select Currency',
                                    style: TextStyle(color: AppColors.lightest),
                                  ),
                                  content: DropdownButton<String>(
                                    value: tempCurrency,
                                    dropdownColor: AppColors.darkGrey,
                                    isExpanded: true,
                                    underline: Container(
                                      height: 1,
                                      color: AppColors.mediumGrey,
                                    ),
                                    style: const TextStyle(color: AppColors.lightest),
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        tempCurrency = newValue;
                                        Navigator.pop(context, newValue);
                                      }
                                    },
                                    items: CurrencyUtil.getCurrencyDropdownItems(),
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
                                  ],
                                );
                              },
                            ).then((value) async {
                              if (value != null) {
                                setState(() {
                                  _isLoading = true;
                                });
                                
                                try {
                                  final user = _authService.getCurrentUser();
                                  if (user != null) {
                                    // Only update the currency field
                                    await _userService.updateUserProfile(user.uid, {
                                      'currency': value,
                                      'lastUpdated': DateTime.now().toIso8601String(),
                                    });
                                    
                                    setState(() {
                                      _selectedCurrency = value;
                                      _isLoading = false;
                                    });
                                    
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Currency updated successfully'),
                                          backgroundColor: AppColors.mediumGrey,
                                        ),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  setState(() {
                                    _isLoading = false;
                                  });
                                  
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error updating currency: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            });
                          },
                        ),
                        subtitle: Row(
                          children: [
                            Text(
                              CurrencyUtil.getCurrencyData(_selectedCurrency).flag + ' ',
                              style: const TextStyle(fontSize: 16),
                            ),
                            Text(
                              _selectedCurrency + ' - ' + 
                              CurrencyUtil.getCurrencyData(_selectedCurrency).symbol,
                              style: const TextStyle(color: AppColors.lightGrey),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // AI Settings Section
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.darkGrey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              'AI Configuration',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          ListTile(
                            dense: true,
                            horizontalTitleGap: 10,
                            leading: const Icon(Icons.key, color: AppColors.mediumGrey, size: 24),
                            title: const Text('Gemini API Key', style: TextStyle(color: AppColors.lightest, fontSize: 15)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_isEditing)
                                  TextFormField(
                                    controller: _apiKeyController,
                                    style: const TextStyle(color: AppColors.lightest),
                                    decoration: InputDecoration(
                                      hintText: 'Enter your Gemini API Key',
                                      hintStyle: TextStyle(color: AppColors.lightGrey.withOpacity(0.7)),
                                      helperText: 'Leave empty to use default key',
                                      helperStyle: TextStyle(color: AppColors.lightGrey.withOpacity(0.5)),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(color: AppColors.mediumGrey),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(color: AppColors.mediumGrey),
                                      ),
                                    ),
                                    obscureText: true, // Hide the key
                                  )
                                else
                                  Text(
                                    _geminiService.isUsingCustomKey 
                                        ? '••••••••••••••••' // Masked
                                        : 'Using default system key',
                                    style: const TextStyle(color: AppColors.lightGrey),
                                  ),
                              ],
                            ),
                            trailing: _isEditing 
                                ? IconButton(
                                    icon: const Icon(Icons.save_as, color: AppColors.accent),
                                    onPressed: _updateApiKey,
                                    tooltip: 'Save API Key',
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),

                    // AI Settings Section
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.darkGrey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              'AI Configuration',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          ListTile(
                            dense: true,
                            horizontalTitleGap: 10,
                            leading: const Icon(Icons.key, color: AppColors.mediumGrey, size: 24),
                            title: const Text('Gemini API Key', style: TextStyle(color: AppColors.lightest, fontSize: 15)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_isEditing)
                                  TextFormField(
                                    controller: _apiKeyController,
                                    style: const TextStyle(color: AppColors.lightest),
                                    decoration: InputDecoration(
                                      hintText: 'Enter your Gemini API Key',
                                      hintStyle: TextStyle(color: AppColors.lightGrey.withOpacity(0.7)),
                                      helperText: 'Leave empty to use default key',
                                      helperStyle: TextStyle(color: AppColors.lightGrey.withOpacity(0.5)),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(color: AppColors.mediumGrey),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(color: AppColors.mediumGrey),
                                      ),
                                    ),
                                    obscureText: true, // Hide the key
                                  )
                                else
                                  Text(
                                    _geminiService.isUsingCustomKey 
                                        ? '••••••••••••••••' // Masked
                                        : 'Using default system key',
                                    style: const TextStyle(color: AppColors.lightGrey),
                                  ),
                              ],
                            ),
                            trailing: _isEditing 
                                ? IconButton(
                                    icon: const Icon(Icons.save_as, color: AppColors.accent),
                                    onPressed: _updateApiKey,
                                    tooltip: 'Save API Key',
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _showLogoutDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkGrey,
                          foregroundColor: AppColors.lightest,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          elevation: 2,
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
