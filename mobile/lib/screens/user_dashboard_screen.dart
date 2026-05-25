import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/lesson_provider.dart';
import '../services/localization_service.dart';
import '../widgets/mascot_visual.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  Future<Map<String, dynamic>?>? _dashboardFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<LessonProvider>(context, listen: false);
      setState(() {
        _dashboardFuture = provider.fetchDashboardProgress();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final learner = auth.learner;
    final pref = learner?.languagePreference;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Profile',
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: const [SizedBox(width: 12)],
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            if (_dashboardFuture == null || snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final dashboard = snapshot.data;
            if (dashboard == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 56),
                      const SizedBox(height: 12),
                      const Text(
                        'Profile data could not be loaded.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          final provider = Provider.of<LessonProvider>(context, listen: false);
                          setState(() {
                            _dashboardFuture = provider.fetchDashboardProgress();
                          });
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final completedLessons = dashboard['completedLessons'] ?? 0;
            final totalLessons = dashboard['totalLessons'] ?? 0;
            final averageScore = (dashboard['averageMasteryScore'] as num?)?.toDouble() ?? 0.0;
            final pronunciationAttempts = dashboard['totalPronunciationAttempts'] ?? 0;
            final correctPronunciations = dashboard['correctPronunciationAttempts'] ?? 0;
            final sandboxHistory = List<Map<String, dynamic>>.from(dashboard['sandboxHistory'] ?? []);

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE0F2FE),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const MascotVisual(type: MascotType.bibo, size: 104),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    learner?.displayName ?? 'Learner',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Age ${learner?.age ?? '-'} • ${learner?.languagePreference ?? 'FULL_ENGLISH'}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        _buildMetricRow('Lessons completed', '$completedLessons / $totalLessons'),
                        const SizedBox(height: 12),
                        _buildMetricRow('Average mastery', '${averageScore.toStringAsFixed(0)}%'),
                        const SizedBox(height: 12),
                        _buildMetricRow('Pronunciation correct', '$correctPronunciations / $pronunciationAttempts'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                            onPressed: () => GoRouter.of(context).go('/settings'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: const Text('Edit profile'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                            onPressed: () => GoRouter.of(context).go('/sandbox'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF06A6FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: const Text('Sandbox'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Recent sandbox sessions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 12),
                  if (sandboxHistory.isEmpty)
                    const Text('No sandbox sessions yet.', style: TextStyle(color: Color(0xFF64748B)))
                  else
                    ...sandboxHistory.take(3).map((session) {
                      final words = List<String>.from(session['words'] ?? []);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session['topic']?.toString() ?? session['customWord']?.toString() ?? 'Sandbox',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              words.join(', '),
                              style: const TextStyle(color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text(LocalizationService.translate(pref, 'back')),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
        Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
      ],
    );
  }
}
