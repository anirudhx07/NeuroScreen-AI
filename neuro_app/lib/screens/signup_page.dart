import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'login_page.dart';

/// Signup page widget for new user registration
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

/// State class for SignupPage with registration form handling
class _SignupPageState extends State<SignupPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (_formKey.currentState!.validate() && _agreeToTerms) {
      setState(() => _isLoading = true);

      try {
        // Add timeout for network issues
        final UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw FirebaseAuthException(
              code: 'network-error',
              message: 'Connection timeout. Please check your internet.',
            );
          },
        );

        await userCredential.user?.updateDisplayName(_nameController.text);

        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(user: userCredential.user!),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        setState(() => _isLoading = false);

        String errorMessage;
        switch (e.code) {
          case 'weak-password':
            errorMessage = 'Password must be 6+ characters with letters & numbers';
            break;
          case 'email-already-in-use':
            errorMessage = 'This email is already registered. Try logging in';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email format';
            break;
          case 'operation-not-allowed':
            errorMessage = 'Email/password sign-up is not enabled in Firebase';
            break;
          case 'too-many-requests':
            errorMessage = 'Too many attempts. Try again later';
            break;
          case 'network-error':
            errorMessage = 'Network error. Check your internet connection';
            break;
          default:
            errorMessage = 'Signup failed: ${e.message}';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        print('Signup error: ${e.code} - ${e.message}');
      } catch (e) {
        setState(() => _isLoading = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        print('Unexpected error: $e');
      }
    } else if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to Terms & Conditions'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F4FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E88E5)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Account',
          style: TextStyle(
            color: Color(0xFF1E88E5),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.person_add,
              color: Color(0xFF1E88E5),
              size: 20,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              color: const Color(0xFFF0F4FF),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Clinical Network Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0052CC).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.local_hospital,
                          size: 16,
                          color: Color(0xFF0052CC),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'CLINICAL NETWORK',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0052CC),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  const Text(
                    'Join our network of healthcare workers providing early neurological screening.',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Subtitle
                  Text(
                    'Secure, AI-powered diagnostics for clinicians on the frontlines of neuro-care.',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF666666),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            // Form Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Full Name
                    _buildFormField(
                      label: 'Full Name',
                      hint: '',
                      controller: _nameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Email
                    _buildFormField(
                      label: 'Work Email',
                      hint: '',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter email';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Enter valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Password
                    _buildPasswordField(
                      label: 'Password',
                      hint: '',
                      controller: _passwordController,
                      isObscure: _obscurePassword,
                      onToggle: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter password';
                        }
                        if (value.length < 6) {
                          return 'Password must be 6+ characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Confirm Password
                    _buildPasswordField(
                      label: 'Confirm Password',
                      hint: '',
                      controller: _confirmPasswordController,
                      isObscure: _obscureConfirmPassword,
                      onToggle: () {
                        setState(
                          () => _obscureConfirmPassword = !_obscureConfirmPassword,
                        );
                      },
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Terms Checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _agreeToTerms,
                            onChanged: (value) {
                              setState(() => _agreeToTerms = value ?? false);
                            },
                            fillColor: MaterialStateProperty.all(
                              _agreeToTerms
                                  ? const Color(0xFF0052CC)
                                  : Colors.transparent,
                            ),
                            side: const BorderSide(
                              color: Color(0xFFCCCCCC),
                              width: 2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF666666),
                                ),
                                children: [
                                  const TextSpan(text: 'I agree to the '),
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: TextStyle(
                                      color: const Color(0xFF0052CC),
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(
                                      color: const Color(0xFF0052CC),
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  const TextSpan(text: '.'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Create Account Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0052CC),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          shadowColor:
                              const Color(0xFF0052CC).withOpacity(0.3),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Login Link
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(),
                                ),
                              );
                            },
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF0052CC),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // HIPAA Compliance
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  Icon(
                    Icons.security,
                    size: 40,
                    color: Colors.grey.withOpacity(0.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'HIPAA COMPLIANT CLOUD ARCHITECTURE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.withOpacity(0.4),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2B5BB5),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: InputBorder.none,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFEEEEEE),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF0052CC),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool isObscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2B5BB5),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: isObscure,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: InputBorder.none,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFEEEEEE),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF0052CC),
                width: 2,
              ),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isObscure ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF999999),
              ),
              onPressed: onToggle,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
