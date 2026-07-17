import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:mobile/config/app_config.dart';
import '../services/tts_service.dart';

class WrongAnswersScreen extends StatefulWidget {
  const WrongAnswersScreen({super.key});

  @override
  State<WrongAnswersScreen> createState() => _WrongAnswersScreenState();
}

class _WrongAnswersScreenState extends State<WrongAnswersScreen>
    with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _future;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  final TtsService _ttsService = TtsService();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _future = _loadData();
    _ttsService.initialize();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final uri =
        Uri.parse('${AppConfig.baseUrl}/learners/wrong-answers');
    final res = await http.get(uri, headers: {
      'Authorization': 'Bearer ${auth.token}',
      'Content-Type': 'application/json',
    });
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load wrong answers: ${res.statusCode}');
  }

  @override
  void dispose() {
    _ttsService.stop();
    _animController.dispose();
    super.dispose();
  }

  Color _errorCountColor(int count) {
    if (count >= 5) return const Color(0xFFEF4444);
    if (count >= 3) return const Color(0xFFF97316);
    return const Color(0xFFFBBF24);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Words I Need Help With',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFF97316)),
            );
          }
          if (snapshot.hasError || snapshot.data == null) {
            return _buildError();
          }

          final data = snapshot.data!;
          final demeritPoints = data['demeritPoints'] as int? ?? 0;
          final words = (data['words'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>() ??
              [];

          return FadeTransition(
            opacity: _fadeAnim,
            child: words.isEmpty
                ? _buildEmptyState()
                : CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _buildDemeritBanner(demeritPoints, words.length),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) =>
                                _buildWordCard(words[index], index),
                            childCount: words.length,
                          ),
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildDemeritBanner(int demeritPoints, int wordCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: Colors.white, size: 36),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$demeritPoints',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                const Text(
                  'Demerit Points',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$wordCount word${wordCount == 1 ? '' : 's'} need review',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordCard(Map<String, dynamic> word, int index) {
    final errorCount = word['errorCount'] as int? ?? 0;
    final currentlyCorrect = word['currentlyCorrect'] as bool? ?? false;
    final english = word['englishWord'] as String? ?? '';
    final cebuano = word['cebuanoMeaning'] as String? ?? '';
    final partOfSpeech = word['partOfSpeech'] as String? ?? '';
    final lessonTitle = word['lessonTitle'] as String? ?? '';
    final categoryName = word['categoryName'] as String? ?? '';
    final accentColor = _errorCountColor(errorCount);

    return GestureDetector(
      onTap: () => _showWordDetails(word),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: currentlyCorrect
                ? const Color(0xFF22C55E).withValues(alpha: 0.4)
                : accentColor.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              // Error count badge
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: accentColor.withValues(alpha: 0.5), width: 1.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$errorCount',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: accentColor,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      errorCount == 1 ? 'error' : 'errors',
                      style: TextStyle(
                        fontSize: 9,
                        color: accentColor.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Word info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            english,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        // Status chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: currentlyCorrect
                                ? const Color(0xFF22C55E).withValues(alpha: 0.15)
                                : const Color(0xFFEF4444).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                currentlyCorrect
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded,
                                size: 13,
                                color: currentlyCorrect
                                    ? const Color(0xFF22C55E)
                                    : const Color(0xFFEF4444),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                currentlyCorrect ? 'Recovered' : 'Struggling',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: currentlyCorrect
                                      ? const Color(0xFF22C55E)
                                      : const Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cebuano,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        color: Color(0xFF94A3B8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    if (partOfSpeech.isNotEmpty || lessonTitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            if (partOfSpeech.isNotEmpty)
                              _buildTag(partOfSpeech,
                                  const Color(0xFF7C3AED), const Color(0xFF4C1D95)),
                            if (partOfSpeech.isNotEmpty && lessonTitle.isNotEmpty)
                              const SizedBox(width: 6),
                            if (lessonTitle.isNotEmpty && categoryName.isNotEmpty)
                              Flexible(
                                child: _buildTag(
                                  '$categoryName · $lessonTitle',
                                  const Color(0xFF0EA5E9),
                                  const Color(0xFF0C4A6E),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFF475569), size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  void _showWordDetails(Map<String, dynamic> word) {
    final english = word['englishWord'] as String? ?? '';
    final cebuano = word['cebuanoMeaning'] as String? ?? '';
    final partOfSpeech = word['partOfSpeech'] as String? ?? '';
    final lessonTitle = word['lessonTitle'] as String? ?? '';
    final categoryName = word['categoryName'] as String? ?? '';
    final errorCount = word['errorCount'] as int? ?? 0;
    final currentlyCorrect = word['currentlyCorrect'] as bool? ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF475569),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    english,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up_rounded, color: Color(0xFFF97316), size: 28),
                  onPressed: () => _ttsService.speak(english),
                  tooltip: "Listen to word",
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              cebuano,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18,
                color: Color(0xFF94A3B8),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),
            _buildDetailRow(
                Icons.category_rounded, 'Part of speech', partOfSpeech),
            _buildDetailRow(Icons.menu_book_rounded, 'Lesson', lessonTitle),
            _buildDetailRow(Icons.folder_rounded, 'Category', categoryName),
            _buildDetailRow(Icons.close_rounded, 'Total errors',
                '$errorCount time${errorCount == 1 ? '' : 's'}'),
            _buildDetailRow(
              currentlyCorrect
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              'Latest attempt',
              currentlyCorrect ? 'Correct ✓' : 'Still struggling ❌',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF334155),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Close',
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF64748B), size: 18),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star_rounded,
                  color: Color(0xFF22C55E), size: 52),
            ),
            const SizedBox(height: 24),
            const Text(
              'You\'re doing great!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'No wrong answers recorded yet.\nKeep up the excellent work!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: Color(0xFF475569), size: 52),
            const SizedBox(height: 16),
            const Text(
              'Could not load your progress.\nPlease try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setState(() {
                _future = _loadData();
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
