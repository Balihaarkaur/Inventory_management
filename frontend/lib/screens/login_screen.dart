import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    clientId: '697508222834-1uf9q9n8ls7dam7d1dks78rmj7u6qqc9.apps.googleusercontent.com',
  );
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account == null) {
        // User canceled the login
        setState(() {
          _isLoading = false;
        });
        return;
      }

      GoogleSignInAuthentication? auth;
      String? idToken;

      try {
        auth = await account.authentication;
        idToken = auth.idToken;
      } catch (e) {
        print("Initial authentication object failed: $e");
      }

      // Web Fallback: If `idToken` is null, it's often because Google's new 
      // GIS library on the web returns an access token, but strips the ID token 
      // if `serverClientId` isn't strictly configured in the console. 
      // We will grab whatever token is available.
      if (idToken == null && kIsWeb) {
         // Some versions of the plugin expose the raw serverAuthCode or accessToken
         idToken = auth?.accessToken ?? account.serverAuthCode; 
      }

      if (idToken != null) {
        await _authenticateWithBackend(idToken);
      } else {
        _showError('No ID Token received from Google.');
      }
    } catch (error) {
      _showError('Sign in failed: \n$error');
    } finally {
      setState(() {
        if(mounted) _isLoading = false;
      });
    }
  }

  Future<void> _authenticateWithBackend(String idToken) async {
    // Use your laptop's Local IPv4 Address so the Android device can reach it over WiFi
    const String apiUrl = 'http://192.168.1.4:3000/api/users/google-login'; 
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      } else {
        _showError(data['message'] ?? 'Authentication failed');
        await _googleSignIn.signOut();
      }
    } catch (e) {
      _showError('Error connecting to backend: $e');
      await _googleSignIn.signOut();
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.jpg',
                  height: 100,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
                Text(
                  'Inventory',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to manage your hardware',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 48),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton.icon(
                    onPressed: _handleGoogleSignIn,
                    icon: Image.network(
                      'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                      height: 24,
                      width: 24,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.g_mobiledata, size: 24, color: Colors.blue);
                      },
                    ),
                    label: Text(
                      'Sign in with Google',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Company access only (@blauplug.com)',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
