import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:neuro_app/helpers/test_result_helper.dart';
import 'package:neuro_app/screens/neurology_report_screen.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

class VoiceAnalysisTest extends StatefulWidget {
  const VoiceAnalysisTest({super.key});

  @override
  State<VoiceAnalysisTest> createState() => _VoiceAnalysisTestState();
}

class _VoiceAnalysisTestState extends State<VoiceAnalysisTest> {
  final SpeechToText _speechToText = SpeechToText();

  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _timer;
  bool _testCompleted = false;
  String _testResult = '';
  bool _speechReady = false;
  bool _isStopping = false;
  bool _isRestartingListen = false;

  DateTime? _currentSpeechSegmentStart;
  DateTime? _lastSilenceStart;
  int _speakingMilliseconds = 0;
  int _pauseCount = 0;

  // Sound-level based VAD state
  double _smoothedSoundLevel = 0.0;
  double _noiseFloor = 0.0;
  bool _hasLevelBaseline = false;
  bool _wasSpeaking = false;

  String _transcript = '';
  int _wordCount = 0;

  static const int _maxRecordingSeconds = 45;
  static const int _minPauseMilliseconds = 450;

  Future<void> _startRecording() async {
    if (_isRecording || _isStopping) return;

    try {
      _speechReady = await _speechToText.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
        debugLogging: false,
      );

      if (!_speechReady) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Speech recognition is unavailable on this device.'),
            ),
          );
        }
        return;
      }

      _resetVoiceMetrics();

      setState(() {
        _isRecording = true;
        _testCompleted = false;
        _testResult = '';
        _recordingSeconds = 0;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;

        setState(() {
          _recordingSeconds++;
        });

        if (_recordingSeconds >= _maxRecordingSeconds) {
          _stopRecording();
        }
      });

      await _startListeningSession();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording || _isStopping) return;

    _isStopping = true;

    try {
      _timer?.cancel();
      _timer = null;
      _isRestartingListen = false;

      await _speechToText.stop();

      _finalizeSpeakingWindow();

      final totalDurationSeconds = _recordingSeconds;
      final speakingSeconds = (_speakingMilliseconds / 1000.0);
        final totalMinutes = totalDurationSeconds > 0
          ? (totalDurationSeconds / 60.0)
          : 0.0;
        final speakingMinutes = speakingSeconds > 0
          ? (speakingSeconds / 60.0)
          : 0.0;

        // Primary speed metric based on total recording duration so it still works
        // when sound-level callbacks are noisy or unavailable on some devices.
        final wordsPerMinute = totalMinutes > 0 ? (_wordCount / totalMinutes) : 0.0;

        // Secondary articulation speed (speech-only duration) when VAD timing is available.
        final articulationWpm = speakingMinutes > 0
          ? (_wordCount / speakingMinutes)
          : wordsPerMinute;

      final speechRateLabel = _speechRateCategory(wordsPerMinute);
      final pauseRatePerMinute = totalDurationSeconds > 0
          ? (_pauseCount / (totalDurationSeconds / 60.0))
          : 0.0;

      final analysisScore = _computeVoiceScore(
        wpm: wordsPerMinute,
        pauseRatePerMinute: pauseRatePerMinute,
        speakingRatio: totalDurationSeconds > 0
            ? (speakingSeconds / totalDurationSeconds).clamp(0.0, 1.0)
            : 0.0,
      );

      if (mounted) {
        setState(() {
          _isRecording = false;
          _testCompleted = true;
          _testResult = 'Voice analysis complete!\n\n'
              'Recording Duration: ${totalDurationSeconds}s\n'
              'Words Detected: $_wordCount\n'
              'Speech Speed: ${wordsPerMinute.toStringAsFixed(1)} WPM ($speechRateLabel)\n'
              'Articulation Speed: ${articulationWpm.toStringAsFixed(1)} WPM\n'
              'Pauses: $_pauseCount\n'
              'Pause Rate: ${pauseRatePerMinute.toStringAsFixed(1)} / min\n'
              'Speaking Time: ${speakingSeconds.toStringAsFixed(1)}s\n'
              'Voice Score: ${analysisScore.toStringAsFixed(1)}/100';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error stopping recording: $e')),
        );
      }
    } finally {
      _isStopping = false;
    }
  }

  void _restartTest() {
    _timer?.cancel();

    setState(() {
      _isRecording = false;
      _recordingSeconds = 0;
      _testCompleted = false;
      _testResult = '';
    });

    _resetVoiceMetrics();
  }

  void _resetVoiceMetrics() {
    _currentSpeechSegmentStart = null;
    _lastSilenceStart = null;
    _speakingMilliseconds = 0;
    _pauseCount = 0;
    _smoothedSoundLevel = 0.0;
    _noiseFloor = 0.0;
    _hasLevelBaseline = false;
    _wasSpeaking = false;
    _transcript = '';
    _wordCount = 0;
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) return;

    setState(() {
      _transcript = result.recognizedWords.trim();
      _wordCount = _countWords(_transcript);
    });
  }

  void _onSpeechStatus(String status) {
    if (!_isRecording) return;

    // Android frequently ends single listen sessions early; restart until timer limit.
    if (status == 'done' || status == 'notListening') {
      _restartListeningSession();
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    if (!_isRecording) return;

    if (error.permanent) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speech error: ${error.errorMsg}')),
        );
      }
      _stopRecording();
      return;
    }

    // Transient errors are common; retry the listen session without ending the test.
    if (mounted && error.errorMsg != 'error_no_match') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speech retry: ${error.errorMsg}')),
      );
    }

    _restartListeningSession();
  }

  Future<void> _startListeningSession() async {
    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(minutes: 2),
      pauseFor: const Duration(seconds: 30),
      onSoundLevelChange: _onSoundLevelChange,
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.dictation,
        cancelOnError: false,
      ),
    );
  }

  void _restartListeningSession() {
    if (!_isRecording || _isStopping || _isRestartingListen) return;
    if (_recordingSeconds >= _maxRecordingSeconds) return;

    _isRestartingListen = true;
    Future<void>.delayed(const Duration(milliseconds: 250), () async {
      try {
        if (!_isRecording || _isStopping) return;
        await _startListeningSession();
      } catch (_) {
        if (_isRecording && !_isStopping) {
          // Keep test alive even if one session restart fails.
          Future<void>.delayed(const Duration(seconds: 1), _restartListeningSession);
        }
      } finally {
        _isRestartingListen = false;
      }
    });
  }

  void _onSoundLevelChange(double level) {
    if (!_isRecording || !mounted) return;

    final now = DateTime.now();

    if (!_hasLevelBaseline) {
      _noiseFloor = level;
      _smoothedSoundLevel = level;
      _hasLevelBaseline = true;
    } else {
      _noiseFloor = (_noiseFloor * 0.995) + (level * 0.005);
      _smoothedSoundLevel = (_smoothedSoundLevel * 0.8) + (level * 0.2);
    }

    final speakingThreshold = _noiseFloor + 2.5;
    final isSpeaking = _smoothedSoundLevel > speakingThreshold;

    if (isSpeaking) {
      if (!_wasSpeaking) {
        if (_lastSilenceStart != null) {
          final silenceDurationMs = now.difference(_lastSilenceStart!).inMilliseconds;
          if (silenceDurationMs >= _minPauseMilliseconds) {
            _pauseCount++;
          }
        }

        _currentSpeechSegmentStart = now;
      }

      _lastSilenceStart = null;
    } else {
      if (_wasSpeaking && _currentSpeechSegmentStart != null) {
        _speakingMilliseconds +=
            now.difference(_currentSpeechSegmentStart!).inMilliseconds;
        _currentSpeechSegmentStart = null;
      }

      _lastSilenceStart ??= now;
    }

    _wasSpeaking = isSpeaking;

    setState(() {});
  }

  void _finalizeSpeakingWindow() {
    if (!_isRecording) return;

    final now = DateTime.now();
    if (_wasSpeaking && _currentSpeechSegmentStart != null) {
      _speakingMilliseconds +=
          now.difference(_currentSpeechSegmentStart!).inMilliseconds;
      _currentSpeechSegmentStart = null;
    }
  }

  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text
        .trim()
        .split(RegExp(r'\s+'))
        .where((token) => token.trim().isNotEmpty)
        .length;
  }

  String _speechRateCategory(double wpm) {
    if (wpm <= 0) return 'No speech detected';
    if (wpm < 110) return 'Slow';
    if (wpm <= 170) return 'Average';
    return 'Fast';
  }

  double _computeVoiceScore({
    required double wpm,
    required double pauseRatePerMinute,
    required double speakingRatio,
  }) {
    double score = 100.0;

    if (wpm == 0) {
      score -= 70;
    } else if (wpm < 90 || wpm > 190) {
      score -= 25;
    } else if (wpm < 110 || wpm > 170) {
      score -= 12;
    }

    if (pauseRatePerMinute > 12) {
      score -= 20;
    } else if (pauseRatePerMinute > 7) {
      score -= 10;
    }

    if (speakingRatio < 0.35) {
      score -= 20;
    } else if (speakingRatio < 0.5) {
      score -= 10;
    }

    return score.clamp(0.0, 100.0);
  }

  Map<String, dynamic> _voiceMetrics() {
    final totalDurationSeconds = _recordingSeconds;
    final speakingSeconds = (_speakingMilliseconds / 1000.0);
    final totalMinutes = totalDurationSeconds > 0
      ? (totalDurationSeconds / 10.0)
      : 0.0;
    final speakingMinutes = speakingSeconds > 0
      ? (speakingSeconds / 10.0)
      : 0.0;

    // Keep wordsPerMinute as recording-duration WPM to guarantee non-zero speed
    // when transcript exists, even if VAD speaking time is zero.
    final wordsPerMinute = totalMinutes > 0 ? (_wordCount / totalMinutes) : 0.0;
    final articulationWpm = speakingMinutes > 0
      ? (_wordCount / speakingMinutes)
      : wordsPerMinute;

    final pauseRatePerMinute = totalDurationSeconds > 0
        ? (_pauseCount / (totalDurationSeconds / 10.0))
        : 0.0;
    final speakingRatio = totalDurationSeconds > 0
        ? (speakingSeconds / totalDurationSeconds).clamp(0.0, 1.0)
        : 0.0;

    return {
      'recordingDurationSeconds': totalDurationSeconds,
      'speakingDurationSeconds': speakingSeconds,
      'speakingRatio': speakingRatio,
      'pauseCount': _pauseCount,
      'pauseRatePerMinute': pauseRatePerMinute,
      'wordsDetected': _wordCount,
      'wordsPerMinute': wordsPerMinute,
      'articulationWordsPerMinute': articulationWpm,
      'speechRateCategory': _speechRateCategory(wordsPerMinute),
      'transcript': _transcript,
    };
  }

  Future<void> _storeTestResult() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      print('DEBUG: currentUser = $currentUser');
      if (currentUser != null) {
        print('DEBUG: Storing test result for user: ${currentUser.uid}');
        final metrics = _voiceMetrics();
        final score = _computeVoiceScore(
          wpm: (metrics['wordsPerMinute'] as num).toDouble(),
          pauseRatePerMinute: (metrics['pauseRatePerMinute'] as num).toDouble(),
          speakingRatio: (metrics['speakingRatio'] as num).toDouble(),
        );

        await TestResultHelper.storeVoiceAnalysisTestResult(
          userId: currentUser.uid,
          analysisScore: score,
          metrics: metrics,
        );
        print('✅ Voice analysis test result stored: ${metrics['recordingDurationSeconds']} seconds');
      } else {
        print('❌ ERROR: currentUser is null - user not authenticated');
      }
    } catch (e) {
      print('❌ Error storing test result: $e');
      rethrow;
    }
  }

  void _viewReport() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NeurologyReportScreen(userId: currentUser.uid),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _speechToText.stop();
    _speechToText.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Analysis'),
        backgroundColor: Colors.blue[50],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: Colors.grey[50],
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_testCompleted)
                  Column(
                    children: [
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isRecording ? Colors.red[100] : Colors.blue[100],
                          border: Border.all(
                            color: _isRecording ? Colors.red : Colors.blue,
                            width: 4,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.mic,
                            size: 60,
                            color: _isRecording ? Colors.red : Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        _isRecording
                            ? 'Recording... ${_recordingSeconds}s'
                            : 'Tap to Start Recording',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_isRecording)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue[100]!),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Live Sound Level'),
                                  Text(_smoothedSoundLevel.toStringAsFixed(1)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  minHeight: 8,
                                  value: (_smoothedSoundLevel / 40.0).clamp(0.0, 1.0),
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _wasSpeaking ? Colors.green : Colors.orange,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text('Words: $_wordCount | Pauses: $_pauseCount'),
                              Text(
                                'Estimated WPM: ${(_voiceMetrics()['wordsPerMinute'] as num).toDouble().toStringAsFixed(1)}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                      Text(
                        'Read the sentence below clearly:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!, width: 1),
                        ),
                        child: const Text(
                          '"The quick brown fox jumps over the lazy dog. This is a common test sentence used in speech analysis."',
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 48),
                      ElevatedButton.icon(
                        onPressed: _isRecording ? _stopRecording : _startRecording,
                        icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                        label: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isRecording ? Colors.red : Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 64,
                              color: Colors.green,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Test Completed!',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _testResult,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                height: 1.8,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _restartTest,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blue[700],
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              side: BorderSide(color: Colors.blue[700]!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await _storeTestResult();
                              if (mounted) {
                                Navigator.pop(context);
                              }
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('Complete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
