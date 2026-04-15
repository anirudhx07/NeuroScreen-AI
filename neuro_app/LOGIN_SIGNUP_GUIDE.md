# Login & Signup Implementation Guide

## Overview
This Flutter app now includes a complete authentication UI with login and signup screens. The screens are fully functional with form validation and smooth transitions.

## File Structure
```
lib/
├── main.dart                 # App entry point
└── screens/
    ├── auth_screen.dart      # Navigation between login/signup
    ├── login_screen.dart     # Login page
    ├── signup_screen.dart    # Signup page
    └── home_screen.dart      # Home page after successful login
```

## Features

### Login Screen
- Email validation
- Password visibility toggle
- "Forgot password?" link
- Social login buttons (Google, Facebook)
- Smooth transition to signup
- Loading state during authentication

### Signup Screen
- Full name validation (first and last name required)
- Email validation
- Strong password requirements:
  - Minimum 8 characters
  - Must contain uppercase letters
  - Must contain numbers
- Password confirmation field
- Terms & Conditions checkbox
- Social signup options
- Transition back to login

### Form Validation
- Real-time field validation
- Custom error messages
- Email format validation
- Password strength requirements
- Confirm password matching

## Customization

### Theme
The screens use your app's theme colors. To customize:
1. Change the seed color in `main.dart`
2. All screens will automatically update

### API Integration
To integrate with your backend:

1. **In `login_screen.dart`**, replace the mock delay with actual API call:
```dart
void _handleLogin() async {
  if (_formKey.currentState!.validate()) {
    setState(() => _isLoading = true);
    
    try {
      // Replace with actual API call
      final response = await loginUser(
        email: _emailController.text,
        password: _passwordController.text,
      );
      
      // Navigate to home on success
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
```

2. **In `signup_screen.dart`**, do the same for signup

### Social Authentication
To enable social login:
1. Add `google_sign_in` and `flutter_facebook_sdk` packages to `pubspec.yaml`
2. Replace the onPressed callbacks with actual authentication logic

## Navigation Setup
To navigate to the home screen after login, update the login handler:

```dart
// In login_screen.dart, replace the mock navigation with:
Navigator.of(context).pushReplacementNamed('/home');
```

And in `main.dart`, set up named routes:

```dart
return MaterialApp(
  title: 'NeuroScreen',
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
    useMaterial3: true,
  ),
  routes: {
    '/': (context) => const AuthScreen(),
    '/home': (context) => const HomeScreen(),
  },
  initialRoute: '/',
);
```

## Testing
Run the app with:
```bash
flutter run
```

Both login and signup forms include validation. Try:
- Invalid emails
- Weak passwords
- Mismatched passwords
- Empty fields

All will show helpful error messages.

## Next Steps
1. Connect to your backend API
2. Implement proper state management (Provider, Riverpod, Bloc)
3. Add social authentication
4. Implement password reset flow
5. Add email verification
6. Store auth tokens securely
