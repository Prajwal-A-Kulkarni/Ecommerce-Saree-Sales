import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/glass_container.dart';
import '../theme/theme.dart';
import 'main_navigation.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoginMode = true;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final provider = Provider.of<AppProvider>(context, listen: false);
    Map<String, dynamic> result;

    if (_isLoginMode) {
      result = await provider.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );
    } else {
      result = await provider.register(
        _usernameController.text.trim(),
        _passwordController.text,
        _emailController.text.trim(),
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'An error occurred. Please try again.';
        });
      }
    }
  }

  void _showSettingsDialog() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final ipController = TextEditingController(text: provider.serverIp);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BoutiqueTheme.cardBg,
        title: const Text('Server Configuration', style: TextStyle(color: BoutiqueTheme.textWhite, fontFamily: 'serif')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Specify your Django backend server URL:',
              style: TextStyle(color: BoutiqueTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ipController,
              style: const TextStyle(color: BoutiqueTheme.textWhite),
              decoration: const InputDecoration(
                hintText: 'http://10.0.2.2:8000',
                hintStyle: TextStyle(color: Colors.white24),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: BoutiqueTheme.accentGold),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: BoutiqueTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              provider.setServerIp(ipController.text.trim());
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Server updated to: ${ipController.text}')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image with overlays
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=1000&q=80'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF08040C).withOpacity(0.92),
                  const Color(0xFF180A2B).withOpacity(0.85),
                  const Color(0xFF090E22).withOpacity(0.92),
                ],
              ),
            ),
          ),
          
          // Settings button
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.settings, color: BoutiqueTheme.accentGold),
                onPressed: _showSettingsDialog,
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'ZARI & GRACE',
                    style: TextStyle(
                      fontSize: 36,
                      color: BoutiqueTheme.accentGold,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4.0,
                      fontFamily: 'serif',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The Ultimate Saree Destination',
                    style: TextStyle(
                      fontSize: 14,
                      color: BoutiqueTheme.textMuted,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  Form(
                    key: _formKey,
                    child: GlassContainer(
                      opacity: 0.1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _isLoginMode ? 'Welcome Back' : 'Create Account',
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          
                          if (_errorMessage.isNotEmpty) ...[
                            Text(
                              _errorMessage,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Username field
                          TextFormField(
                            controller: _usernameController,
                            style: const TextStyle(color: BoutiqueTheme.textWhite),
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              labelStyle: TextStyle(color: BoutiqueTheme.textMuted),
                              prefixIcon: Icon(Icons.person, color: BoutiqueTheme.accentGold),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: BoutiqueTheme.accentGold),
                              ),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Enter username' : null,
                          ),
                          const SizedBox(height: 16),

                          // Email field (register mode only)
                          if (!_isLoginMode) ...[
                            TextFormField(
                              controller: _emailController,
                              style: const TextStyle(color: BoutiqueTheme.textWhite),
                              decoration: const InputDecoration(
                                labelText: 'Email address',
                                labelStyle: TextStyle(color: BoutiqueTheme.textMuted),
                                prefixIcon: Icon(Icons.email, color: BoutiqueTheme.accentGold),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white24),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: BoutiqueTheme.accentGold),
                                ),
                              ),
                              validator: (val) => val == null || !val.contains('@') ? 'Enter valid email' : null,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            style: const TextStyle(color: BoutiqueTheme.textWhite),
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(color: BoutiqueTheme.textMuted),
                              prefixIcon: Icon(Icons.lock, color: BoutiqueTheme.accentGold),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: BoutiqueTheme.accentGold),
                              ),
                            ),
                            validator: (val) => val == null || val.length < 4 ? 'Password must be at least 4 chars' : null,
                          ),
                          const SizedBox(height: 32),

                          // Submit Button
                          _isLoading
                              ? const Center(child: CircularProgressIndicator(color: BoutiqueTheme.accentGold))
                              : ElevatedButton(
                                  onPressed: _submit,
                                  child: Text(_isLoginMode ? 'LOGIN' : 'SIGN UP'),
                                ),
                          const SizedBox(height: 16),

                          // Toggle mode
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isLoginMode = !_isLoginMode;
                                _errorMessage = '';
                              });
                            },
                            child: Text(
                              _isLoginMode 
                                  ? 'New to Zari & Grace? Sign up' 
                                  : 'Already have an account? Log in',
                              style: const TextStyle(color: BoutiqueTheme.accentGold),
                            ),
                          ),
                          
                          // Quick skip for testing
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const MainNavigation()),
                              );
                            },
                            child: const Text(
                              'Skip & Continue as Guest',
                              style: TextStyle(color: Colors.white38, fontSize: 12),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
