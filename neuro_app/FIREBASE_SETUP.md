# Firebase Integration Setup Guide

## Overview
Your login and signup pages are now integrated with Firebase Authentication. Follow these steps to complete the setup.

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a new project"
3. Enter project name: `NeuroScreen`
4. Click "Continue" through the setup steps
5. Create the project

## Step 2: Set Up Firebase for Android

### 2.1 Register Android App
1. In Firebase Console, click "Add app" → Select "Android"
2. Enter Package name: `com.example.neuro_app`
3. Click "Register app"
4. Download `google-services.json`
5. Place it in: `neuro_app/android/app/`

### 2.2 Update Android Files

**File: `android/build.gradle`**
Add to dependencies:
```gradle
classpath 'com.google.gms:google-services:4.3.15'
```

**File: `android/app/build.gradle`**
At the bottom, add:
```gradle
apply plugin: 'com.google.gms.google-services'
```

## Step 3: Set Up Firebase for iOS (Optional)

### 3.1 Register iOS App
1. In Firebase Console, click "Add app" → Select "iOS"
2. Enter Bundle ID: `com.example.neuroApp`
3. Click "Register app"
4. Download `GoogleService-Info.plist`
5. Open Xcode: `neuro_app/ios/Runner.xcworkspace`
6. Drag & drop `GoogleService-Info.plist` into Xcode

## Step 4: Enable Firebase Authentication

1. In Firebase Console, go to **Authentication**
2. Click "Get started"
3. Enable **Email/Password** sign-in method
4. Click "Save"

## Step 5: Generate Firebase Options File

Run this command in your project:
```bash
flutterfire configure
```

This will:
- Detect your Firebase project
- Create `lib/firebase_options.dart` automatically
- Update configuration files

If `flutterfire` is not installed, run:
```bash
dart pub global activate flutterfire_cli
```

## Step 6: Install Dependencies

Run:
```bash
flutter pub get
```

This installs Firebase packages from `pubspec.yaml`:
- `firebase_core: ^2.24.0`
- `firebase_auth: ^4.14.0`

## Step 7: Test the App

```bash
flutter run
```

### Test Signup:
1. Fill all fields
2. Accept terms
3. Click "Sign Up"
4. Should create account and navigate to home

### Test Login:
1. Enter registered email
2. Enter correct password
3. Click "Login"
4. Should log in and show home page

## Files Updated

- **`pubspec.yaml`** - Added Firebase dependencies
- **`lib/main.dart`** - Added Firebase initialization
- **`lib/screens/login_page.dart`** - Firebase login integration
- **`lib/screens/signup_page.dart`** - Firebase signup integration
- **`lib/screens/home_page.dart`** - Home page after login

## Error Handling

Both pages handle common Firebase errors:
- **Email already in use** - Shows on signup
- **User not found** - Shows on login
- **Wrong password** - Shows on login attempt
- **Weak password** - Shows if password < 6 chars
- **Invalid email** - Shows on format validation

## User Features

### After Login, Users Can:
- See their email
- See their user ID
- Check email verification status
- Logout and return to login

## Security Features

✅ Email validation
✅ Password visibility toggle
✅ Firebase secure authentication
✅ Error handling
✅ Session management
✅ User ID management

## Next Steps

1. Add "Forgot Password" functionality
2. Add Email verification
3. Add Google/Facebook social login
4. Add User profile management
5. Add Firestore database integration

## Troubleshooting

### Issue: "google-services.json not found"
**Solution:** Download from Firebase Console and place in `android/app/`

### Issue: "FirebaseApp.initializeApp failed"
**Solution:** Run `flutterfire configure` again

### Issue: "Email already registered"
**Solution:** Use a different email or reset Firebase project data

### Issue: "Weak password error"
**Solution:** Passwords must be at least 6 characters

## Resources
- [Firebase Flutter Documentation](https://firebase.flutter.dev/)
- [Firebase Authentication Docs](https://firebase.google.com/docs/auth)
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/)
