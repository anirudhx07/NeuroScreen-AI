# NeuroScreen AI - Neurological Assessment Report System

## Overview
This system stores cognitive test scores in Firestore, analyzes them against predefined thresholds and ML-based scoring, and generates comprehensive neurology assessment reports with PDF export capability.

## Components Created

### 1. **Data Models**
- `TestResult` (`models/test_result.dart`) - Stores individual test scores
- `NeurologyReport` (`models/neurology_report.dart`) - Stores analysis results and recommendations

### 2. **Services**
- `NeurologicalAnalysisService` (`services/neurological_analysis_service.dart`) - Analyzes test results and generates risk scores
- `FirestoreTestService` (`services/firestore_test_service.dart`) - Firestore database operations
- `PDFExportService` (`services/pdf_export_service.dart`) - Generates PDF reports

### 3. **UI Components**
- `ReportCardWidget` (`widgets/report_card_widget.dart`) - Displays report in Flutter UI
- `NeurologyReportScreen` (`screens/neurology_report_screen.dart`) - Full report viewing screen

## Required Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  cloud_firestore: ^4.13.0
  pdf: ^3.10.0
  path_provider: ^2.1.0
  share_plus: ^7.0.0
  intl: ^0.19.0
  google_generative_ai: ^0.4.0  # Optional for future ML enhancements
```

Run: `flutter pub get`

## Firestore Structure

```
users/
  {userId}/
    test_results/
      {testId}:
        - userId
        - testType (memory, reaction_time, motor_skills, voice_analysis, eye_tracking)
        - score (0-100)
        - timestamp
        - details {}
    
    neurology_reports/
      {reportId}:
        - userId
        - generatedAt
        - overallRiskScore (0-100)
        - riskLevel (low, medium, high)
        - testScores {}
        - trendData {}
        - interpretation
        - recommendations []
        - disclaimer
```

## How to Integrate

### Step 1: Store Test Results

After a user completes a test, store the result:

```dart
import 'package:neuro_app/models/test_result.dart';
import 'package:neuro_app/services/firestore_test_service.dart';

final firestoreService = FirestoreTestService();

// After memory test completes with score (0-5)
final testScore = 5; // from memory test
final normalizedScore = (testScore / 5) * 100; // Convert to 0-100

final testResult = TestResult(
  id: DateTime.now().millisecondsSinceEpoch.toString(),
  userId: currentUserId,
  testType: 'memory',
  score: normalizedScore,
  timestamp: DateTime.now(),
  details: {
    'maxScore': 5,
    'userScore': testScore,
    'correctAnswers': 4,
  },
);

await firestoreService.storeTestResult(testResult);
```

### Step 2: View Report

Navigate to the report screen after completing a test:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => NeurologyReportScreen(
      userId: currentUserId,
    ),
  ),
);
```

### Step 3: Handle Score Conversion for Each Test

**Memory Test (0-5):**
```dart
double score = (userScore / 5) * 100;
```

**Reaction Time Test (milliseconds):**
```dart
// Lower reaction time = better
// Normal: 200-300ms, Above 500ms = at risk
double score = 100 - ((reactionTimeMs / 1000) * 100).clamp(0, 100);
```

**Motor Skills Test (varies by implementation):**
```dart
// Normalize based on your test's max score
double score = (userScore / maxPossibleScore) * 100;
```

**Voice Analysis (varies):**
```dart
// Normalize based on analysis metrics
double score = analysisScore;
```

**Eye Tracking (varies):**
```dart
// Normalize based on tracking accuracy
double score = (accuracyPercentage);
```

## Risk Thresholds

The system uses these thresholds for assessment:

| Test Type | High Risk | Medium Risk | Low Risk |
|-----------|-----------|------------|----------|
| Memory | < 40 | 40-70 | > 70 |
| Reaction Time | < 40 | 40-70 | > 70 |
| Motor Skills | < 40 | 40-70 | > 70 |
| Voice Analysis | < 40 | 40-70 | > 70 |
| Eye Tracking | < 40 | 40-70 | > 70 |

## Test Weights (Overall Score Calculation)

```
Overall Score = (Memory × 0.25) + 
                (Reaction Time × 0.20) + 
                (Motor Skills × 0.20) + 
                (Voice Analysis × 0.18) + 
                (Eye Tracking × 0.17)
```

## Overall Risk Levels

| Score | Risk Level | Color |
|-------|-----------|-------|
| 80-100 | Low Risk | Green |
| 50-79 | Medium Risk | Orange |
| 0-49 | High Risk | Red |

## Example: Complete Integration in Memory Test

```dart
// After user completes memory test
void _onMemoryTestComplete(int correctAnswers, int totalItems) {
  // Calculate score (0-5 becomes 0-100)
  double normalizedScore = (correctAnswers / totalItems) * 100;
  
  // Create test result
  final testResult = TestResult(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    userId: currentUserId,
    testType: 'memory',
    score: normalizedScore,
    timestamp: DateTime.now(),
    details: {
      'totalItems': totalItems,
      'correctAnswers': correctAnswers,
      'percentage': (correctAnswers / totalItems * 100).toStringAsFixed(0),
    },
  );
  
  // Store in Firestore
  firestoreService.storeTestResult(testResult).then((_) {
    // Show success message and navigate to report
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test result saved!')),
    );
    
    // Navigate to report screen
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NeurologyReportScreen(
            userId: currentUserId,
          ),
        ),
      );
    });
  });
}
```

## Features

✅ **Firestore Integration** - Stores all test scores with timestamps
✅ **ML-Based Analysis** - Uses weighted scoring and thresholds
✅ **Risk Assessment** - Categorizes into Low/Medium/High risk
✅ **Trend Analysis** - Tracks improvement/decline over time
✅ **Beautiful UI** - Card-based report display
✅ **PDF Export** - Generate shareable PDF reports
✅ **Medical Disclaimer** - Compliance and user safety
✅ **Recommendations** - Personalized health suggestions
✅ **Real-time Updates** - Stream data from Firestore

## Medical Disclaimer

All reports include the following disclaimer:
> "This assessment is not a medical diagnosis. Please consult a healthcare professional for medical evaluation."

This is essential for compliance and user safety.

## Future Enhancements

1. **Cloud ML Integration** - Use Google Cloud ML for advanced analysis
2. **Doctor Sharing** - Allow users to share reports with healthcare providers
3. **Historical Comparison** - Visual charts showing progression over months/years
4. **Alerts** - Notify users of significant changes in scores
5. **Recommendations Refinement** - More personalized recommendations based on specific test patterns
6. **API Integration** - Send data to external healthcare systems

## Troubleshooting

### No tests showing
- Ensure Firestore rules allow read/write for the user
- Check user ID is correctly passed
- Verify tests are being stored with correct testType

### Report not generating
- Ensure all 5 test types have scores
- Check Firestore connectivity
- Verify user has completed at least one test

### PDF export failing
- Ensure path_provider permissions are set
- Check disk space available
- Verify pdf package is properly installed

## Questions?
Refer to individual service files for detailed documentation and method signatures.
