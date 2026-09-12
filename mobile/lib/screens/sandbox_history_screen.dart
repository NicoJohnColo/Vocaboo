import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/motion/motion.dart';
import '../providers/auth_provider.dart';
import '../providers/lesson_provider.dart';
import '../services/local_storage_service.dart';
import '../services/localization_service.dart';
import '../widgets/mascot_visual.dart';

class SandboxHistoryScreen extends StatefulWidget {
  const SandboxHistoryScreen({super.key});

  @override
  State<SandboxHistoryScreen> createState() => _SandboxHistoryScreenState();
}

class _SandboxHistoryScreenState extends State<SandboxHistoryScreen> {
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final history = await LocalStorageService.getSandboxSessions();
    if (mounted) {
      setState(() {
        _sessions = history;
        _isLoading = false;
      });
    }
  }

  void _startPastLesson(Map<String, dynamic> session) {
    final sessionId = session['sessionId']?.toString() ?? session['id']?.toString() ?? '';
    final lessonId = 'sandbox_$sessionId';
    final rawWords = (session['words'] as List?)?.whereType<Map>().map((w) => Map<String, dynamic>.from(w)).toList() ?? [];

    List<Map<String, dynamic>> words = rawWords;
    if (words.isEmpty) {
      final topic = session['topic']?.toString() ?? session['customWord']?.toString() ?? 'Lesson';
      words = [
        {
          'wordId': sessionId,
          'englishWord': topic,
          'cebuanoMeaning': topic,
          'exampleSentenceEnglish': 'I like $topic.',
          'exampleSentenceCebuano': 'Ganahan ko sa $topic.',
          'wordOrder': 1,
        }
      ];
    }

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

  Future<void> _deleteSession(String sessionId, String topic) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final pref = auth.learner?.languagePreference;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          LocalizationService.translate(pref, 'sandbox_delete_confirm_title'),
          style: AppTypography.baloo2(fontWeight: FontWeight.w800),
        ),
        content: Text(
          LocalizationService.translate(pref, 'sandbox_delete_confirm_body'),
          style: AppTypography.nunito(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(LocalizationService.translate(pref, 'cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      final provider = Provider.of<LessonProvider>(context, listen: false);
      await provider.deleteSandboxSession(sessionId);
      await _loadHistory();
    }
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'Recent';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final month = months[dt.month - 1];
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$month ${dt.day}, ${dt.year} • $hour:$minute $period';
    } catch (_) {
      return 'Recent';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final pref = auth.learner?.languagePreference;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          LocalizationService.translate(pref, 'sandbox_history_title'),
          style: AppTypography.baloo2(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: const Color(0xFF06A6FF),
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0EA5E9)))
          : _sessions.isEmpty
              ? _buildEmptyState(pref)
              : _buildHistoryList(pref),
    );
  }

  Widget _buildEmptyState(String? pref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const MascotVisual(type: MascotType.starry, size: 100),
            const SizedBox(height: 20),
            Text(
              LocalizationService.translate(pref, 'sandbox_history_empty_title'),
              style: AppTypography.baloo2(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: const Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              LocalizationService.translate(pref, 'sandbox_history_empty_desc'),
              style: AppTypography.nunito(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            App3DButton.primary(
              onPressed: () => context.pop(),
              height: 50,
              depth: 4.0,
              text: LocalizationService.translate(pref, 'start_lesson'),
              icon: Icons.play_arrow_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(String? pref) {
    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: const Color(0xFF0EA5E9),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        itemCount: _sessions.length,
        itemBuilder: (context, index) {
          final session = _sessions[index];
          final sessionId = session['sessionId']?.toString() ?? session['id']?.toString() ?? '';
          final topic = session['topic']?.toString() ?? session['customWord']?.toString() ?? 'Custom Lesson';
          final createdAt = session['createdAt']?.toString();
          final words = (session['words'] as List?)?.whereType<Map>().toList() ?? [];
          final totalCount = (session['totalCount'] as int?) ?? words.length;
          final masteredCount = (session['masteredCount'] as int?) ?? 0;
          final isCompleted = totalCount > 0 && masteredCount >= totalCount;

          final progressRatio = totalCount > 0 ? (masteredCount / totalCount).clamp(0.0, 1.0) : 0.0;
          final mascotType = MascotType.values[index % MascotType.values.length];

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isCompleted ? const Color(0xFF10B981).withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Header: Mascot avatar, Topic, Date, and Delete action
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted ? const Color(0xFFECFDF5) : const Color(0xFFE0F2FE),
                        ),
                        child: Center(
                          child: MascotVisual(
                            type: mascotType,
                            size: 40,
                            isCelebrating: isCompleted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              topic,
                              style: AppTypography.baloo2(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDate(createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFF94A3B8), size: 20),
                        onPressed: () => _deleteSession(sessionId, topic),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Mastery progress bar & badge
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progressRatio,
                            minHeight: 10,
                            backgroundColor: const Color(0xFFF1F5F9),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isCompleted ? const Color(0xFF10B981) : const Color(0xFF0EA5E9),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isCompleted ? const Color(0xFFECFDF5) : const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$masteredCount/$totalCount ${LocalizationService.translate(pref, 'mastered')}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isCompleted ? const Color(0xFF10B981) : const Color(0xFF0284C7),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Word chips preview
                  if (words.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: words.take(5).map((w) {
                        final wordText = w['englishWord']?.toString() ?? '';
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            wordText,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Start Lesson / Practice button
                  App3DButton.primary(
                    onPressed: () => _startPastLesson(session),
                    height: 44,
                    depth: 3.5,
                    isFullWidth: true,
                    text: LocalizationService.translate(pref, 'start_lesson'),
                    icon: Icons.play_arrow_rounded,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
