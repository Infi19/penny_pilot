import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4b0082), // Darkest purple background
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Welcome text
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'Welcome',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        
                        // Username/Email field
                        Container(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Username Or Email',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFe6ccff), // Lightest purple
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: TextField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    hintText: 'example@example.com',
                                    hintStyle: TextStyle(color: Colors.grey.shade600),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Password field
                        Container(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Password',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFe6ccff), // Lightest purple
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: TextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    hintText: '••••••••',
                                    hintStyle: TextStyle(color: Colors.grey.shade600),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(16),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                        color: const Color(0xFF6a0dad), // Medium-dark purple
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Login Button
                        Container(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFa64dff), // Medium purple
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                              'Log In',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        
                        // Forgot Password
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: Color(0xFF6a0dad), // Medium-dark purple
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        
                        // Sign Up Button
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignUpScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFe6ccff), // Lightest purple
                              minimumSize: const Size(120, 40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                color: Color(0xFF4b0082), // Darkest purple
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'or sign in with',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        
                        // Google Sign In button
                        _socialButton(Icons.g_mobiledata),
                        
                        const SizedBox(height: 20),
                        
                        // Sign up text
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account? ",
                              style: TextStyle(color: Colors.black54),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SignUpScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: Color(0xFF6a0dad), // Medium-dark purple
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _socialButton(IconData icon) {
    return InkWell(
      onTap: icon == Icons.g_mobiledata ? _handleGoogleSignIn : null,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFd1a6ff)), // Light purple
        ),
        child: Icon(
          icon,
          color: const Color(0xFF6a0dad), // Medium-dark purple
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (result?.user != null) {
        try {
          // Get user profile data with retry mechanism already in place
          await _userService.getUserProfile(result!.user!.uid);
        } catch (e) {
          print('Warning: Could not fetch user profile immediately after login: $e');
          // Continue anyway since auth was successful
        }
        
        if (!mounted) return;

        // Clear the navigation stack and replace with home screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false, // This will remove all previous routes
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = 'An error occurred during login';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'No user found with this email';
            break;
          case 'wrong-password':
            errorMessage = 'Invalid password';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email format';
            break;
          case 'user-disabled':
            errorMessage = 'This account has been disabled';
            break;
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final result = await _authService.signInWithGoogle();

      if (result?.user != null) {
        final user = result!.user!;
        
        try {
          // Try to get existing profile
          final userData = await _userService.getUserProfile(user.uid);
          
          // If profile doesn't exist or needs updating, update with latest Google info
          if (userData == null || 
              userData['email'] != user.email || 
              userData['displayName'] != user.displayName) {
            await _userService.createUserProfile(user.uid, {
              'email': user.email,
              'displayName': user.displayName,
              'photoURL': user.photoURL,
              'createdAt': userData == null ? DateTime.now().toIso8601String() : userData['createdAt'],
              'lastLogin': DateTime.now().toIso8601String(),
              'lastUpdated': DateTime.now().toIso8601String(),
              'provider': 'google',
              // Preserve existing data if any
              ...?userData,
              // Ensure these fields are always updated with Google data
              'email': user.email,
              'displayName': user.displayName,
              'photoURL': user.photoURL,
            });
          } else {
            // Just update login time for existing users
            await _userService.updateUserProfile(user.uid, {
              'lastLogin': DateTime.now().toIso8601String(),
            });
          }
          
          if (!mounted) return;

          // Clear the navigation stack and replace with home screen
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        } catch (e) {
          print('Error managing user profile: $e');
          // Even if profile management fails, we can still proceed to home screen
          // as the user is authenticated
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = 'An error occurred during Google Sign-In';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'account-exists-with-different-credential':
            errorMessage = 'An account already exists with the same email address';
            break;
          case 'invalid-credential':
            errorMessage = 'Invalid credentials';
            break;
          case 'operation-not-allowed':
            errorMessage = 'Google Sign-In is not enabled';
            break;
          case 'user-disabled':
            errorMessage = 'This account has been disabled';
            break;
          case 'user-not-found':
            errorMessage = 'No user found for that email';
            break;
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}