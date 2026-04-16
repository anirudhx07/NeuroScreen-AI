# Testing NeuroScreen with Firebase

## Prerequisites Check

### ✅ Step 1: Verify Firebase Setup
```bash
cd /c/Users/LENOVO/Desktop/NeuroScreen-AI/neuro_app

# Check if firebase_options.dart exists
ls -la lib/firebase_options.dart
```

If file exists → ✅ Firebase configured
If not → Run step 2

---

## Setup Steps (if needed)

### Step 2: Generate Firebase Configuration
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for your project
flutterfire configure
```

When prompted:
- Select your Firebase project: **NeuroScreen**
- Select platforms: Android, iOS, Web (as needed)
- Accept the defaults

This creates `lib/firebase_options.dart`

---

## Testing Approaches

### **Option A: Android Emulator (Best for mobile testing)**

#### 1. Install Android Studio
- Download: https://developer.android.com/studio
- Follow installer, accept defaults
- Accept licenses: `flutter doctor --android-licenses`

#### 2. Create Emulator
- Open Android Studio → Virtual Device Manager → Create Device
- Select Pixel 6 → Android 14
- Click Play button to start

#### 3. Run App on Emulator
```bash
cd neuro_app

# Get dependencies
flutter pub get

# Run on emulator
flutter run
```

#### 4. Test Authentication
1. **Signup:**
   - Click "Sign Up"
   - Enter: Name, Email, Password, Confirm Password
   - Accept terms
   - Should see success and redirect to HomePage

2. **Login:**
   - Go back to login
   - Use same email/password
   - Click "Login"
   - Should see HomePage with your email

3. **Logout:**
   - Click logout (top right)
   - Should return to LoginPage

4. **Test Errors:**
   - Wrong password → See error
   - Email not found → See error
   - Email already exists → See error

---

### **Option B: Web Browser (Fastest)**

```bash
flutter run -d chrome
```

Same testing steps as above, but runs in Chrome instantly!

---

### **Option C: Windows Desktop**

Requires Visual Studio (not installed). Skip this for now.

---

## Firebase Console Verification

### 1. Check Registered Users
1. Go to https://console.firebase.google.com
2. Select "NeuroScreen" project
3. Navigate to **Authentication** → Users
4. You should see your test users with timestamps

### 2. Verify Email/Password Auth
- Go to **Authentication** → Sign-in method
- Check: ✅ Email/Password is enabled

---

## Debugging Commands

### View Live Logs
```bash
flutter logs
```

### Run with Verbose Output
```bash
flutter run -v
```

### Clean and Rebuild
```bash
flutter clean
flutter pub get
flutter run
```

### Hot Reload During Testing
While app is running, press:
- `r` → Hot reload (fast reload)
- `R` → Full restart
- `q` → Quit

---

## Common Issues & Fixes

### Issue: "firebase_options.dart not found"
**Fix:** Run `flutterfire configure`

### Issue: "App crashes on startup"
**Fix:**
```bash
flutter clean
flutter pub get
flutter run -v  # Check logs
```

### Issue: "Firebase connection timeout"
**Fix:**
- Check internet connection
- Check Firebase project is active
- Verify firebase_options.dart has correct project ID

### Issue: "Sign up fails silently"
**Fix:**
```bash
flutter logs  # Check error messages
```

---

## Quick Start Command

```bash
cd /c/Users/LENOVO/Desktop/NeuroScreen-AI/neuro_app

# Get dependencies
flutter pub get

# Run on Chrome (fastest testing)
flutter run -d chrome

# OR run on Android emulator
flutter run
```

---

## Testing Checklist

After app starts, verify:

- [ ] Login page loads with form fields
- [ ] Can click "Sign Up" and see signup form
- [ ] Can fill registration form
- [ ] Password validation works (matching)
- [ ] Can submit signup
- [ ] User gets created in Firebase
- [ ] Auto-redirects to HomePage
- [ ] HomePage shows user email
- [ ] Logout button works
- [ ] Can login with same credentials
- [ ] Error messages show for wrong password
- [ ] Error message shows for non-existent email

---

## Next Steps

1. **Immediate:** Run `flutter run -d chrome` to test
2. **Check:** Go to Firebase Console → confirm users registered
3. **Debug:** Use `flutter logs` if issues occur
4. **Test:** Try all flows (signup, login, logout, errors)

---

## Firebase Console URLs

- **Firebase Project:** https://console.firebase.google.com/project/neuroscreen-xxxxxxx
- **Authentication:** https://console.firebase.google.com/project/neuroscreen-xxxxxxx/authentication/users
- **Realtime Database:** https://console.firebase.google.com/project/neuroscreen-xxxxxxx/database

---

**Which option would you like to try first?**
1. Chrome/Web (fastest, 1 minute)
2. Android Emulator (requires setup, 10 min)
