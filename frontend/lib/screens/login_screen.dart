import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aad_oauth/aad_oauth.dart';
import 'package:aad_oauth/model/config.dart' as auth_config;
import 'package:http/http.dart' as http;
import '../main.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static final auth_config.Config config = auth_config.Config(
    tenant: 'common', 
    clientId: '0cde56fa-1ae9-4e58-a23f-1df78dffe979', 
    scope: 'openid profile offline_access User.Read',
    redirectUri: kIsWeb 
        ? 'https://inventory-management-oadl.onrender.com/' 
        : 'msauth://com.blauplug.inventory/uAjnB1SZZB2oraYMvM%2BT71AFJTw%3D', 
    navigatorKey: navigatorKey,
    webUseRedirect: false, 
  );
  
  final AadOAuth oauth = AadOAuth(config);
  bool _isLoading = false;

  Future<void> _handleMicrosoftSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Prompt user login popup/browser
      await oauth.login();
      final String? accessToken = await oauth.getAccessToken();

      if (accessToken != null) {
        await _authenticateWithBackend(accessToken);
      } else {
        _showError('No Access Token received from Microsoft.');
      }
    } catch (error) {
      _showError('Sign in failed: \n$error');
    } finally {
      setState(() {
        if(mounted) _isLoading = false;
      });
    }
  }

  Future<void> _authenticateWithBackend(String accessToken) async {
    print('🔑 Attempting backend authentication...');
    final String apiUrl = '${ApiService.baseUrl}/users/microsoft-login'; 
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'accessToken': accessToken}),
      );

      print('📡 Backend Response Code: ${response.statusCode}');
      print('📡 Backend Response Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ Auth Success!');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      } else {
        final errorMsg = data['message'] ?? 'Authentication failed';
        print('❌ Auth Failed: $errorMsg');
        _showError(errorMsg);
        await oauth.logout();
      }
    } catch (e) {
      print('❌ Network/CORS Error: $e');
      _showError('Error connecting to backend: $e');
      await oauth.logout();
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

  Widget _buildLoginButton({
    required Widget iconWidget,
    required String label,
    required VoidCallback onPressed,
    required BuildContext context,
    bool isPrimary = true,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      height: 56, // Tall, touch-friendly modern button
      decoration: BoxDecoration(
        color: isPrimary ? Colors.white : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ]
            : [],
        border: isPrimary
            ? Border.all(color: const Color(0xFFE5E7EB), width: 1.5)
            : Border.all(color: Colors.transparent, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          highlightColor: Colors.black.withOpacity(0.02),
          splashColor: Colors.black.withOpacity(0.04),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              iconWidget,
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Clean, light background
      body: SafeArea(
        child: isDesktop 
            ? _buildDesktopLayout(context)
            : _buildMobileLayout(context),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        // Top Branding Section
        Expanded(
          flex: 4,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF5EAA5F),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogoHeader(),
                const SizedBox(height: 24),
                Text(
                  'Inventory Platform',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Streamlined Hardware Management',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Bottom Action Section
        Expanded(
          flex: 5,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (_isLoading)
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5EAA5F)),
                  )
                else ...[
                  _buildLoginButton(
                    context: context,
                    iconWidget: const Icon(Icons.window, color: Color(0xFF00A4EF), size: 24),
                    label: 'Sign in with Microsoft',
                    onPressed: _handleMicrosoftSignIn,
                    isPrimary: true,
                  ),
                  
                  if (kDebugMode) ...[
                    const SizedBox(height: 16),
                    _buildLoginButton(
                      context: context,
                      iconWidget: const Icon(Icons.developer_mode, color: Colors.black87, size: 24),
                      label: 'Dev Login (Local Bypass)',
                      onPressed: () {
                        // Bypass Azure AD login for local dev testing 
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const DashboardScreen()),
                        );
                      },
                      isPrimary: false,
                    ),
                  ],
                ],
                
                const Spacer(),
                _buildFooterText(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Left Branding Banner
        Expanded(
          flex: 5,
          child: Container(
            color: const Color(0xFF5EAA5F),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogoHeader(isLarge: true),
                const SizedBox(height: 32),
                Text(
                  'Inventory Platform',
                  style: GoogleFonts.inter(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.0,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Streamlined Hardware Management\nfor modern logistics.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Right Login Form
        Expanded(
          flex: 4,
          child: Container(
            color: const Color(0xFFF9FAFB),
            padding: const EdgeInsets.symmetric(horizontal: 64.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please sign in to your organizational account to continue.',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 48),
                
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5EAA5F)),
                    ),
                  )
                else ...[
                  _buildLoginButton(
                    context: context,
                    iconWidget: const Icon(Icons.window, color: Color(0xFF00A4EF), size: 24),
                    label: 'Sign in with Microsoft',
                    onPressed: _handleMicrosoftSignIn,
                    isPrimary: true,
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 16),
                    _buildLoginButton(
                      context: context,
                      iconWidget: const Icon(Icons.developer_mode, color: Colors.black87, size: 24),
                      label: 'Dev Login (Local Bypass)',
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const DashboardScreen()),
                        );
                      },
                      isPrimary: false,
                    ),
                  ],
                ],
                
                const SizedBox(height: 64),
                Center(child: _buildFooterText()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoHeader({bool isLarge = false}) {
    final double size = isLarge ? 120 : 80;
    return Container(
      padding: EdgeInsets.all(isLarge ? 32 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          )
        ]
      ),
      child: Image.asset(
        'assets/images/logo.jpg',
        height: size,
        width: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => Icon(
          Icons.inventory_2_rounded,
          size: size,
          color: const Color(0xFF5EAA5F),
        ),
      ),
    );
  }

  Widget _buildFooterText() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 14, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Secure access restricted to @blauplug.com',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
