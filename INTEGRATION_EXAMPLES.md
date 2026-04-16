# Integration Guide for Remaining Tests

## Quick Integration Pattern

After each test completes, add this code to store the result:

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:neuro_app/helpers/test_result_helper.dart';
import 'package:neuro_app/screens/neurology_report_screen.dart';

// When test completes:
final currentUser = FirebaseAuth.instance.currentUser;
if (currentUser != null) {
  await TestResultHelper.store[TestName]TestResult(
    userId: currentUser.uid,
    // test-specific parameters
  );
  
  // Show success message
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Test result saved!')),
  );
  
  // Navigate to report
  Future.delayed(const Duration(seconds: 1), () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NeurologyReportScreen(userId: currentUser.uid),
      ),
    );
  });
}
```

---

## 1. REACTION TIME TEST

**Location:** `lib/screens/reaction_time_test.dart`

**When test completes, add:**

```dart
void _onTestComplete(double averageReactionTimeMs) {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    TestResultHelper.storeReactionTimeTestResult(
      userId: currentUser.uid,
      reactionTimeMs: averageReactionTimeMs,
      normalReactionTime: 300, // baseline in milliseconds
    ).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reaction time: ${averageReactionTimeMs.toStringAsFixed(0)}ms')),
      );
      
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NeurologyReportScreen(userId: currentUser.uid),
          ),
        );
      });
    });
  }
}
```

**Add button to results screen:**
```dart
ElevatedButton.icon(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => NeurologyReportScreen(userId: currentUser.uid),
    ),
  ),
  icon: const Icon(Icons.assessment),
  label: const Text('View Report'),
),
```

---

## 2. MOTOR SKILLS TEST

**Location:** `lib/screens/motor_skills_test.dart`

**When test completes, add:**

```dart
void _onMotorSkillsComplete(double userScore, double maxScore) {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    TestResultHelper.storeMotorSkillsTestResult(
      userId: currentUser.uid,
      score: userScore,
      maxScore: maxScore,
    ).then((_) {
      final percentage = (userScore / maxScore * 100).toStringAsFixed(0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Motor Skills Score: $percentage%')),
      );
      
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NeurologyReportScreen(userId: currentUser.uid),
          ),
        );
      });
    });
  }
}
```

**Example with different scoring systems:**

```dart
// If your motor skills test uses points/time:
double normalizeMotorScore(double rawScore, String metric) {
  switch (metric) {
    case 'taps_per_second':
      // Normal: 5-7 taps/sec, max 10
      return (rawScore / 10) * 100;
    case 'accuracy_percentage':
      // Already 0-100
      return rawScore;
    case 'speed_milliseconds':
      // Lower is better, normal 500ms, max 2000ms
      return ((2000 - rawScore) / 2000) * 100;
    default:
      return rawScore;
  }
}

// Usage:
final normalizedScore = normalizeMotorScore(tapSpeed, 'taps_per_second');
await TestResultHelper.storeMotorSkillsTestResult(
  userId: currentUser.uid,
  score: normalizedScore,
  maxScore: 100,
);
```

---

## 3. VOICE ANALYSIS TEST

**Location:** `lib/screens/voice_analysis_test.dart`

**When analysis completes, add:**

```dart
void _onVoiceAnalysisComplete(VoiceAnalysisResult result) {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    TestResultHelper.storeVoiceAnalysisTestResult(
      userId: currentUser.uid,
      analysisScore: result.overallScore, // 0-100
      metrics: {
        'clarity': result.clarity,
        'pitch': result.pitch,
        'speech_rate': result.speechRate,
        'voice_stability': result.voiceStability,
        'pronunciation': result.pronunciation,
        'duration_ms': result.durationMs,
      },
    ).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Voice Score: ${result.overallScore.toStringAsFixed(1)}')),
      );
      
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NeurologyReportScreen(userId: currentUser.uid),
          ),
        );
      });
    });
  }
}
```

**Score calculation helper:**
```dart
class VoiceAnalysisScore {
  static double calculateOverallScore({
    required double clarity,      // 0-100
    required double pitch,        // 0-100
    required double speechRate,   // 0-100
    required double stability,    // 0-100
  }) {
    // Weighted average
    return (clarity * 0.35 +
            pitch * 0.25 +
            speechRate * 0.25 +
            stability * 0.15);
  }
}

// Usage:
final voiceScore = VoiceAnalysisScore.calculateOverallScore(
  clarity: clarityValue,
  pitch: pitchValue,
  speechRate: rateValue,
  stability: stabilityValue,
);
```

---

## 4. EYE TRACKING TEST

**Location:** `lib/screens/eye_tracking_test.dart`

**When tracking completes, add:**

```dart
void _onEyeTrackingComplete(EyeTrackingResult result) {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    TestResultHelper.storeEyeTrackingTestResult(
      userId: currentUser.uid,
      accuracyPercentage: result.accuracyPercentage, // 0-100
      trackingQuality: {
        'calibration_error': result.calibrationError,
        'gaze_stability': result.gazeStability,
        'fixation_duration': result.fixationDuration,
        'saccade_velocity': result.saccadeVelocity,
        'blink_rate': result.blinkRate,
        'data_quality': result.dataQuality,
      },
    ).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Eye Tracking Accuracy: ${result.accuracyPercentage.toStringAsFixed(1)}%'
          ),
        ),
      );
      
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NeurologyReportScreen(userId: currentUser.uid),
          ),
        );
      });
    });
  }
}
```

**Accuracy calculation helper:**
```dart
class EyeTrackingScore {
  static double calculateAccuracy({
    required double calibrationError,  // in pixels
    required double gazeDeviation,     // in degrees
    required int validSamples,
    required int totalSamples,
  }) {
    // Normalize calibration error (0-50px = 0-100 score)
    final calibrationScore = (50 - calibrationError.clamp(0, 50)) / 50 * 100;
    
    // Normalize gaze deviation (0-5 degrees = 0-100 score)
    final gazeScore = (5 - gazeDeviation.clamp(0, 5)) / 5 * 100;
    
    // Data validity score
    final validityScore = (validSamples / totalSamples) * 100;
    
    // Weighted average
    return (calibrationScore * 0.3 + gazeScore * 0.4 + validityScore * 0.3);
  }
}

// Usage:
final eyeScore = EyeTrackingScore.calculateAccuracy(
  calibrationError: calibError,
  gazeDeviation: gzDeviation,
  validSamples: validCount,
  totalSamples: totalCount,
);
```

---

## Integration Checklist

- [ ] **Memory Test** - ✅ DONE
- [ ] **Reaction Time Test**
  - [ ] Import TestResultHelper and NeurologyReportScreen
  - [ ] Add storage code to completion handler
  - [ ] Add "View Report" button
  - [ ] Test end-to-end

- [ ] **Motor Skills Test**
  - [ ] Import TestResultHelper and NeurologyReportScreen
  - [ ] Normalize score to 0-100
  - [ ] Add storage code
  - [ ] Add "View Report" button
  - [ ] Test end-to-end

- [ ] **Voice Analysis Test**
  - [ ] Import TestResultHelper and NeurologyReportScreen
  - [ ] Calculate weighted voice score
  - [ ] Add storage code with metrics
  - [ ] Add "View Report" button
  - [ ] Test end-to-end

- [ ] **Eye Tracking Test**
  - [ ] Import TestResultHelper and NeurologyReportScreen
  - [ ] Calculate accuracy from tracking data
  - [ ] Add storage code with quality metrics
  - [ ] Add "View Report" button
  - [ ] Test end-to-end

---

## Testing the Complete Flow

1. **Complete any test** (start with Reaction Time)
2. **Tap "View Report"**
3. **Report should show:**
   - That test's score
   - Overall risk (will improve as you add more tests)
   - Personalized recommendations
   - PDF export option

4. **Complete another test** - Report updates with both results

5. **After 2+ tests of same type** - Trends will show

---

## Common Issues & Solutions

### Issue: "No recent test results found"
**Solution:** 
- Ensure test actually stored (check console logs)
- User must be logged in via Firebase
- Check Firestore rules allow write access

### Issue: Report shows only one test
**Solution:**
- Make sure you're completing different test types
- Check Firestore under `/users/{userId}/test_results`

### Issue: Score doesn't normalize correctly
**Solution:**
- Verify your score is 0-100 range before storing
- Use TestResultHelper methods which auto-normalize
- Check score calculation matches your test

### Issue: Navigation not working
**Solution:**
- Ensure `neurology_report_screen.dart` is imported
- Verify user ID is not null
- Check for route conflicts

---

## Next Steps

1. Pick **one test** to integrate first (Reaction Time recommended)
2. Copy the integration code
3. Test locally with Firebase
4. Repeat for other 3 tests
5. Verify all 5 tests work together

**Estimated time:** 15-20 minutes per test

---

**Questions?** Refer to `SETUP_GUIDE.md` or `NEUROLOGICAL_ASSESSMENT_SYSTEM.md`
