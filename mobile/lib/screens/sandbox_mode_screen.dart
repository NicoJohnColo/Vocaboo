import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/motion/motion.dart';
import '../providers/auth_provider.dart';
import '../providers/lesson_provider.dart';
import '../services/local_storage_service.dart';
import '../services/localization_service.dart';
import '../widgets/mascot_bubble.dart';
import '../widgets/mascot_visual.dart';

class SandboxModeScreen extends StatefulWidget {
  final String? initialSessionId;

  const SandboxModeScreen({
    super.key,
    this.initialSessionId,
  });

  @override
  State<SandboxModeScreen> createState() => _SandboxModeScreenState();
}

class _SandboxModeScreenState extends State<SandboxModeScreen> {
  final TextEditingController _customWordController = TextEditingController();

  bool _loading = false;
  String? _error;
  int _historyCount = 0;

  Timer? _shiftingTimer;
  int _currentBatchIndex = 0;

  static const List<List<Map<String, String>>> _topicBatches = [
    [
      {'label': '🚀 Astronaut', 'value': 'Astronaut'},
      {'label': '🍕 Pizza', 'value': 'Pizza'},
      {'label': '⚽ Football', 'value': 'Football'},
      {'label': '🦁 Lion', 'value': 'Lion'},
    ],
    [
      {'label': '🦖 Dinosaur', 'value': 'Dinosaur'},
      {'label': '🎨 Color', 'value': 'Color'},
      {'label': '🏰 Castle', 'value': 'Castle'},
      {'label': '🌊 Ocean', 'value': 'Ocean'},
    ],
    [
      {'label': '🚗 Vehicle', 'value': 'Vehicle'},
      {'label': '🎸 Guitar', 'value': 'Guitar'},
      {'label': '🌦️ Weather', 'value': 'Weather'},
      {'label': '🦸 Superhero', 'value': 'Superhero'},
    ],
    [
      {'label': '🍦 Dessert', 'value': 'Dessert'},
      {'label': '🌳 Forest', 'value': 'Forest'},
      {'label': '🤖 Robot', 'value': 'Robot'},
      {'label': '🐬 Dolphin', 'value': 'Dolphin'},
    ],
    [
      {'label': '🎪 Circus', 'value': 'Circus'},
      {'label': '🏕️ Camping', 'value': 'Camping'},
      {'label': '🪐 Planet', 'value': 'Planet'},
      {'label': '🚂 Train', 'value': 'Train'},
    ],
  ];

  @override
  void initState() {
    super.initState();
    _startShiftingTimer();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final history = await LocalStorageService.getSandboxSessions();
    if (mounted) {
      setState(() {
        _historyCount = history.length;
      });
    }

    // If initialSessionId is passed, immediately launch that session directly into Module 1
    if (widget.initialSessionId != null && widget.initialSessionId!.isNotEmpty) {
      final session = await LocalStorageService.getSandboxSession(widget.initialSessionId!);
      if (session != null && mounted) {
        final sessionId = session['sessionId']?.toString() ?? session['id']?.toString() ?? '';
        final lessonId = 'sandbox_$sessionId';
        final words = (session['words'] as List?)?.whereType<Map>().map((w) => Map<String, dynamic>.from(w)).toList() ?? [];

        if (words.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.push(
              '/loading',
              extra: {
                'duration': 5000,
                'redirectPath': '/session/$sessionId/introduction',
                'lessonId': lessonId,
                'categoryId': '',
                'knownWordIds': const <String>[],
                'unknownWordIds': const <String>[],
                'allWords': words,
                'moduleNumber': 1,
                'isSandbox': true,
              },
            );
          });
        }
      }
    }
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

  Future<void> _generateAndStartLesson() async {
    final rawInput = _customWordController.text.trim();
    if (rawInput.isEmpty) {
      setState(() {
        _error = 'Please enter 1 word to practice.';
      });
      return;
    }

    final tokens = rawInput.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (tokens.length > 1) {
      setState(() {
        _error = 'Please enter only 1 word at a time in Sandbox Mode.';
      });
      return;
    }

    final input = tokens.first;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final provider = Provider.of<LessonProvider>(context, listen: false);
      final sessionData = await provider.generateSandboxPathCurriculum(customInput: input);
      final history = await LocalStorageService.getSandboxSessions();

      if (!mounted) return;

      setState(() {
        _loading = false;
        _historyCount = history.length;
      });

      final sessionId = sessionData['sessionId']?.toString() ?? '';
      final lessonId = 'sandbox_$sessionId';
      final words = (sessionData['words'] as List?)?.whereType<Map>().map((w) => Map<String, dynamic>.from(w)).toList() ?? [];

      if (words.isNotEmpty) {
        context.push(
          '/loading',
          extra: {
            'duration': 5000,
            'redirectPath': '/session/$sessionId/introduction',
            'lessonId': lessonId,
            'categoryId': '',
            'knownWordIds': const <String>[],
            'unknownWordIds': const <String>[],
            'allWords': words,
            'moduleNumber': 1,
            'isSandbox': true,
          },
        );
      }
    } catch (e) {
      debugPrint('Error generating sandbox lesson: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          if (e.toString().contains('429') || e.toString().toLowerCase().contains('rate limit')) {
            _error = 'Rate limit reached. Please wait a moment and try again.';
          } else {
            _error = 'Could not generate lesson. Please try again.';
          }
        });
      }
    }
  }

  void _openHistory() async {
    await context.push('/sandbox/history');
    if (mounted) {
      _loadInitialData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final pref = auth.learner?.languagePreference;
    final batch = _topicBatches[_currentBatchIndex];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => context.go('/home'),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF0EA5E9), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                LocalizationService.translate(pref, 'sandbox_title'),
                style: AppTypography.baloo2(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: const Color(0xFF06A6FF),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Past Sandbox Words history button with counter badge
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.history_rounded, color: Color(0xFF0F172A), size: 26),
                  onPressed: _openHistory,
                  tooltip: LocalizationService.translate(pref, 'sandbox_history_title'),
                ),
                if (_historyCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0EA5E9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        '$_historyCount',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mascot Chat Bubble with Robi
                  MascotBubble(
                    mascotName: 'robi',
                    speechText: LocalizationService.translate(pref, 'sandbox_input_prompt'),
                    avatarSize: 76,
                  ),

                  const SizedBox(height: 24),

                  // Main Input Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ENTER 1 WORD',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF64748B),
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _customWordController,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _generateAndStartLesson(),
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'\s')), // Enforce single word
                          ],
                          decoration: InputDecoration(
                            hintText: LocalizationService.translate(pref, 'sandbox_input_hint'),
                            hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0EA5E9)),
                            suffixIcon: _customWordController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8)),
                                    onPressed: () => setState(() => _customWordController.clear()),
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 2),
                            ),
                          ),
                          onChanged: (_) {
                            if (_error != null) {
                              setState(() => _error = null);
                            } else {
                              setState(() {});
                            }
                          },
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, color: Colors.redAccent, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Shifting Topic Suggestions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'QUICK SUGGESTIONS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF64748B),
                          letterSpacing: 1.1,
                        ),
                      ),
                      Text(
                        'Tap to choose',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: Wrap(
                      key: ValueKey<int>(_currentBatchIndex),
                      spacing: 8,
                      runSpacing: 8,
                      children: batch.map((item) {
                        final label = item['label']!;
                        final val = item['value']!;
                        final isSelected = _customWordController.text.trim().toLowerCase() == val.toLowerCase();

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _customWordController.text = val;
                              _error = null;
                            });
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFE0F2FE) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF0EA5E9) : const Color(0xFFE2E8F0),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Start Lesson Button
                  App3DButton.primary(
                    onPressed: _loading ? null : _generateAndStartLesson,
                    height: 54,
                    depth: 4.5,
                    isFullWidth: true,
                    text: LocalizationService.translate(pref, 'start_lesson'),
                    icon: Icons.play_arrow_rounded,
                  ),

                  const SizedBox(height: 16),

                  // History shortcut card
                  if (_historyCount > 0)
                    InkWell(
                      onTap: _openHistory,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.history_rounded, color: Color(0xFF64748B), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'View past custom words ($_historyCount saved)',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Loading Overlay
            if (_loading)
              Container(
                color: Colors.white.withValues(alpha: 0.92),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const MascotVisual(type: MascotType.starry, size: 100),
                      const SizedBox(height: 24),
                      const CircularProgressIndicator(color: Color(0xFF0EA5E9)),
                      const SizedBox(height: 16),
                      Text(
                        'Preparing your custom lesson...',
                        style: AppTypography.baloo2(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Generating word, Cebuano translation, and activities',
                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
}
