import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/motion/motion.dart';
import '../providers/auth_provider.dart';
import '../providers/lesson_provider.dart';
import '../services/localization_service.dart';
import '../services/tts_service.dart';
import '../widgets/mascot_bubble.dart';
import 'vocabulary_introduction_screen.dart';

class SandboxModeScreen extends StatefulWidget {
  const SandboxModeScreen({super.key});

  @override
  State<SandboxModeScreen> createState() => _SandboxModeScreenState();
}

class _SandboxModeScreenState extends State<SandboxModeScreen> {
  final TextEditingController _customWordController = TextEditingController();

  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _session;
  List<Map<String, dynamic>> _words = [];
  bool _isOffline = false;

  Timer? _shiftingTimer;
  int _currentBatchIndex = 0;

  static const List<List<Map<String, String>>> _topicBatches = [
    [
      {'label': '🚀 Outer Space', 'value': 'Outer Space'},
      {'label': '🍕 Food & Snacks', 'value': 'Food'},
      {'label': '⚽ Sports & Games', 'value': 'Sports'},
      {'label': '🦁 Wild Animals', 'value': 'Animals'},
    ],
    [
      {'label': '🦖 Dinosaurs', 'value': 'Dinosaurs'},
      {'label': '🎨 Colors & Art', 'value': 'Colors'},
      {'label': '🏰 Castles & Knights', 'value': 'Castles'},
      {'label': '🌊 Ocean Creatures', 'value': 'Ocean Animals'},
    ],
    [
      {'label': '🚗 Fast Vehicles', 'value': 'Vehicles'},
      {'label': '🎸 Music & Beats', 'value': 'Music'},
      {'label': '🌦️ Sky & Weather', 'value': 'Weather'},
      {'label': '🦸 Superheroes', 'value': 'Superheroes'},
    ],
    [
      {'label': '🍦 Sweet Desserts', 'value': 'Desserts'},
      {'label': '🌳 Nature & Forest', 'value': 'Nature'},
      {'label': '🤖 Robots & AI', 'value': 'Robots'},
      {'label': '🐬 Sea Life', 'value': 'Sea Creatures'},
    ],
    [
      {'label': '🎪 Circus & Magic', 'value': 'Circus'},
      {'label': '🏕️ Camping & Woods', 'value': 'Camping'},
      {'label': '🪐 Planets & Stars', 'value': 'Astronomy'},
      {'label': '🚂 Trains & Trips', 'value': 'Trains'},
    ],
  ];

  @override
  void initState() {
    super.initState();
    _startShiftingTimer();
  }

  void _startShiftingTimer() {
    _shiftingTimer?.cancel();
    _shiftingTimer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
      if (!mounted) return;
      setState(() {
        _currentBatchIndex = (_currentBatchIndex + 1) % _topicBatches.length;
      });
    });
  }

  @override
  void dispose() {
    _shiftingTimer?.cancel();
    _customWordController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final provider = Provider.of<LessonProvider>(context, listen: false);
    final customWord = _customWordController.text.trim();

    if (customWord.isEmpty) {
      setState(() {
        _error = 'Please enter a topic, phrase, or word.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    Map<String, dynamic>? result;
    String? errorMessage;
    bool isOfflineError = false;
    
    try {
      result = await provider.generateSandbox(customWord: customWord);
    } catch (e) {
      // Log error and capture the error message
      debugPrint('Sandbox generation error (may have fallback): $e');
      errorMessage = e.toString();
      final msg = errorMessage.toLowerCase();
      if (msg.contains('socketexception') ||
          msg.contains('failed host lookup') ||
          msg.contains('network is unreachable') ||
          msg.contains('connection timed out') ||
          msg.contains('connection refused') ||
          msg.contains('httpclientexception') ||
          msg.contains('handshake') ||
          msg.contains('connection closed')) {
        isOfflineError = true;
      }
    }

    if (!mounted) return;

    // Check if we have valid data (even if there was an error)
    final sessionValue = result?['session'];
    final wordsValue = result?['words'];
    Map<String, dynamic>? session = sessionValue is Map ? Map<String, dynamic>.from(sessionValue) : null;
    List<Map<String, dynamic>> words = wordsValue is List
        ? wordsValue.whereType<Map>().map((word) => Map<String, dynamic>.from(word)).toList()
        : <Map<String, dynamic>>[];
    
    debugPrint('After generate: session=${session != null}, words=${words.length}');
    if (words.isNotEmpty) {
      debugPrint('First word data: ${words[0]}');
    }
    
    // Check if backend returned data but with missing/empty cebuanoMeaning
    if (words.isNotEmpty) {
      for (var word in words) {
        final cebuanoMeaning = word['cebuanoMeaning']?.toString() ?? '';
        if (cebuanoMeaning.isEmpty) {
          debugPrint('WARNING: Backend returned empty cebuanoMeaning for word: ${word['englishWord']}');
          debugPrint('Full word data: $word');
        }
      }
    }
    
    setState(() {
      _loading = false;
      _session = session;
      _words = words;
      
      if (isOfflineError) {
        _isOffline = true;
        _error = null;
      } else {
        // Only show error if we have no data at all
        if (_session == null || _words.isEmpty) {
          // Check if it's a rate limit error
          if (errorMessage != null && 
              (errorMessage.contains('429') || 
               errorMessage.toLowerCase().contains('rate limit'))) {
            _error = 'Rate limit reached. Please wait a moment and try again.';
          } else {
            _error = 'Could not generate lesson. Please try again.';
          }
        } else {
          _error = null;
        }
      }
    });

    // If we have data, proceed to lesson (even if Gemini failed but fallback worked)
    if (_session != null && _words.isNotEmpty) {
      final sessionId = _session!['sessionId']?.toString() ?? '';
      final lessonId = _session!['lessonId']?.toString() ?? sessionId;

      if (sessionId.isNotEmpty) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (ctx) => VocabularyIntroductionScreen(
            sessionId: sessionId,
            lessonId: lessonId,
            categoryId: '',
            knownWordIds: <String>[],
            unknownWordIds: <String>[],
            allWords: _words,
            moduleNumber: 1,
            isSandbox: true,
          ),
        ));
      }
    }
  }

  void _speakFirstWord() {
    if (_words.isEmpty) return;
    final word = _words.first['englishWord']?.toString() ?? '';
    if (word.isNotEmpty) {
      TTSService.speak(word);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final learner = auth.learner;
    final pref = learner?.languagePreference;
    final displayName = learner?.displayName;
    final trimmedName = displayName?.trim();
    final learnerName = (trimmedName != null && trimmedName.isNotEmpty)
        ? trimmedName
        : 'Friend';

    if (_isOffline) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
            tooltip: 'Back',
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/home');
              }
            },
          ),
          title: Text(
            LocalizationService.translate(pref, 'sandbox_mode'),
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF06A6FF),
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 80,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(height: 24),
                const Text(
                  'You are offline',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Sandbox Mode requires an active internet connection to generate custom lessons using AI. Please check your connection and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isOffline = false;
                      _error = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06A6FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'TRY AGAIN',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      context.go('/home');
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
            tooltip: 'Back',
            onPressed: () {
              setState(() {
                _loading = false;
              });
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/home');
              }
            },
          ),
          title: Text(
            LocalizationService.translate(pref, 'sandbox_mode'),
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF06A6FF),
            ),
          ),
        ),
        body: _buildLoadingView(pref),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          tooltip: 'Back',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          LocalizationService.translate(pref, 'sandbox_mode'),
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF06A6FF),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Robi Greeting with Speech Bubble
              MascotBubble(
                mascotName: 'Robi',
                speechText: "Hi, $learnerName! I'm Robi! 🤖 Type any topic or word you want to practice, and I'll generate a custom lesson for you!",
                ttsText: "Hi $learnerName! I am Robi! Type any topic or word you want to practice, and I will create a custom lesson for you.",
                avatarSize: 96,
              ),
              const SizedBox(height: 12),

              // Shifting & Phasing Topic Suggestion Chips
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'QUICK TOPIC IDEAS',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF06A6FF),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        _currentBatchIndex = (_currentBatchIndex + 1) % _topicBatches.length;
                      });
                      _startShiftingTimer();
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        children: [
                          Icon(Icons.autorenew_rounded, size: 14, color: Color(0xFF06A6FF)),
                          SizedBox(width: 4),
                          Text(
                            'Shuffle',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF06A6FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                switchInCurve: Curves.easeInOutCubic,
                switchOutCurve: Curves.easeInOutCubic,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  final fade = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
                  final slide = Tween<Offset>(
                    begin: const Offset(0.0, 0.15),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack));
                  return FadeTransition(
                    opacity: fade,
                    child: SlideTransition(
                      position: slide,
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_currentBatchIndex),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _topicBatches[_currentBatchIndex].map((t) {
                      return _suggestionChip(t['label']!, t['value']!);
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _customWordController,
                decoration: const InputDecoration(
                  labelText: 'Topic or Word',
                  hintText: 'e.g., Space, Animals, Weather...',
                ),
              ),
              const SizedBox(height: 16),
              AppPressable(
                onTap: _loading ? null : _generate,
                child: ElevatedButton(
                  onPressed: _loading ? null : _generate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06A6FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'GENERATE SANDBOX',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                ),
              ],
              if (_session != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Session: ${_session!['sessionId'] ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _session!['customWord']?.toString() ?? 'Sandbox practice',
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _speakFirstWord,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F172A),
                          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Hear generated word'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ..._words.map(
                  (word) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          word['englishWord']?.toString() ?? '',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          word['cebuanoMeaning']?.toString() ?? '',
                          style: const TextStyle(color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _suggestionChip(String label, String value) {
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0369A1),
        ),
      ),
      backgroundColor: const Color(0xFFE0F2FE),
      side: const BorderSide(color: Color(0xFFBAE6FD), width: 1.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () {
        _customWordController.text = value;
      },
    );
  }

  Widget _buildLoadingView(String? pref) {
    final topic = _customWordController.text.trim();
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        image: DecorationImage(
          image: AssetImage('assets/images/loadingscreen_background.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Robi GIF animation
              SizedBox(
                width: 180,
                height: 180,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/images/gifs/robi.gif',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: CircularProgressIndicator(color: Color(0xFF06A6FF)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Topic / Progress message card
              Container(
                width: 290,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      topic.isNotEmpty
                          ? 'Creating lesson for "$topic"'
                          : 'Creating your custom lesson...',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Robi is generating words & interactive activities!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Animated progress bar
              Container(
                width: 130,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: const LinearProgressIndicator(
                    backgroundColor: Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF06A6FF)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Loading text
              const Text(
                'Loading...',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
