import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../core/motion/typography_tokens.dart';
import '../providers/auth_provider.dart';
import 'package:mobile/config/app_config.dart';
import '../services/tts_service.dart';
import '../services/localization_service.dart';
import '../widgets/cebuano_text_highlighter.dart';

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

  // Tab filter: 0 = Today's Picks (Top 5), 1 = All Words
  int _selectedFilterIndex = 0;

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
    throw Exception('Failed to load practice words: ${res.statusCode}');
  }

  @override
  void dispose() {
    _ttsService.stop();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final pref = auth.learner?.languagePreference;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          LocalizationService.translate(pref, 'words_to_practice_title'),
          style: AppTypography.baloo2(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: const Color(0xFF06A6FF),
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0EA5E9)),
            );
          }
          if (snapshot.hasError || snapshot.data == null) {
            return _buildError();
          }

          final data = snapshot.data!;
          final allWords = (data['words'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>() ??
              [];

          if (allWords.isEmpty) {
            return FadeTransition(
              opacity: _fadeAnim,
              child: _buildEmptyState(pref),
            );
          }

          // Capped subset for "Today's Picks" (up to 5 words)
          final displayedWords = _selectedFilterIndex == 0
              ? allWords.take(5).toList()
              : allWords;

          return FadeTransition(
            opacity: _fadeAnim,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildEncouragementBanner(allWords.length, pref),
                ),
                SliverToBoxAdapter(
                  child: _buildFilterChips(allWords.length, pref),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _buildWordCard(displayedWords[index], index, pref),
                      childCount: displayedWords.length,
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

  /// Positive encouragement banner replacing the old punitive demerit banner
  Widget _buildEncouragementBanner(int wordCount, String? pref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: Text(
                '🌟',
                style: TextStyle(fontSize: 30),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocalizationService.translate(pref, 'practice_together_title'),
                  style: AppTypography.baloo2(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  LocalizationService.translate(pref, 'practice_together_sub'),
                  style: AppTypography.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.92),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Filter chips allowing child to focus on 5 words or view all
  Widget _buildFilterChips(int totalCount, String? pref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip(
            0,
            '✨ ${LocalizationService.translate(pref, 'todays_picks')} (5)',
            Icons.auto_awesome_rounded,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            1,
            '📚 ${LocalizationService.translate(pref, 'all_words')} ($totalCount)',
            Icons.library_books_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int index, String label, IconData icon) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0EA5E9) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF0EA5E9) : const Color(0xFFE2E8F0),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.baloo2(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordCard(Map<String, dynamic> word, int index, String? pref) {
    final currentlyCorrect = word['currentlyCorrect'] as bool? ?? false;
    final english = word['englishWord'] as String? ?? '';
    final cebuano = word['cebuanoMeaning'] as String? ?? '';
    final partOfSpeech = word['partOfSpeech'] as String? ?? '';
    final lessonTitle = word['lessonTitle'] as String? ?? '';
    final categoryName = word['categoryName'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: currentlyCorrect
              ? const Color(0xFF22C55E).withValues(alpha: 0.35)
              : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Cheerful Word Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: currentlyCorrect
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  currentlyCorrect ? '🌟' : '📖',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Word info & context
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    english,
                    style: AppTypography.baloo2(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      CebuanoTextHighlighter(
                        text: cebuano,
                        highlightWord: cebuano,
                        style: AppTypography.nunito(
                          fontSize: 14,
                          color: const Color(0xFF0284C7),
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: currentlyCorrect
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              currentlyCorrect
                                  ? Icons.check_circle_rounded
                                  : Icons.auto_awesome_rounded,
                              size: 12,
                              color: currentlyCorrect
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFF0284C7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              currentlyCorrect
                                  ? LocalizationService.translate(pref, 'you_got_this')
                                  : LocalizationService.translate(pref, 'in_practice'),
                              style: AppTypography.baloo2(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: currentlyCorrect
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFF0284C7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (partOfSpeech.isNotEmpty || lessonTitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          if (partOfSpeech.isNotEmpty)
                            _buildTag(partOfSpeech,
                                const Color(0xFF0284C7), const Color(0xFFE0F2FE)),
                          if (partOfSpeech.isNotEmpty && lessonTitle.isNotEmpty)
                            const SizedBox(width: 6),
                          if (lessonTitle.isNotEmpty && categoryName.isNotEmpty)
                            Flexible(
                              child: _buildTag(
                                '$categoryName · $lessonTitle',
                                const Color(0xFF0369A1),
                                const Color(0xFFE0F2FE),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Action: TTS & Practice Button
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.volume_up_rounded,
                      color: Color(0xFF0EA5E9), size: 22),
                  onPressed: () => _ttsService.speak(english),
                  tooltip: 'Listen to pronunciation',
                ),
                ElevatedButton(
                  onPressed: () => _showWordDetails(word, pref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0EA5E9),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    minimumSize: const Size(60, 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    LocalizationService.translate(pref, 'practice_btn'),
                    style: AppTypography.baloo2(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.baloo2(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }

  /// Interactive practice modal with pronunciation, context, and positive reinforcement
  void _showWordDetails(Map<String, dynamic> word, String? pref) {
    final english = word['englishWord'] as String? ?? '';
    final cebuano = word['cebuanoMeaning'] as String? ?? '';
    final partOfSpeech = word['partOfSpeech'] as String? ?? '';
    final lessonTitle = word['lessonTitle'] as String? ?? '';
    final categoryName = word['categoryName'] as String? ?? '';
    final currentlyCorrect = word['currentlyCorrect'] as bool? ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        decoration: const BoxDecoration(
          color: Colors.white,
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
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    english,
                    style: AppTypography.baloo2(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up_rounded,
                      color: Color(0xFF0EA5E9), size: 30),
                  onPressed: () => _ttsService.speak(english),
                  tooltip: 'Listen to word',
                ),
              ],
            ),
            const SizedBox(height: 6),
            CebuanoTextHighlighter(
              text: cebuano,
              highlightWord: cebuano,
              style: AppTypography.nunito(
                fontSize: 18,
                color: const Color(0xFF64748B),
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            // Context details
            _buildDetailRow(
                Icons.category_rounded, 'Part of speech', partOfSpeech),
            _buildDetailRow(Icons.menu_book_rounded, 'Lesson', lessonTitle),
            _buildDetailRow(Icons.folder_rounded, 'Category', categoryName),

            const SizedBox(height: 12),
            // Progress encouragement banner inside modal
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: currentlyCorrect
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    currentlyCorrect
                        ? Icons.check_circle_rounded
                        : Icons.auto_awesome_rounded,
                    color: currentlyCorrect
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF0284C7),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      currentlyCorrect
                          ? 'Great job! You\'ve recently answered this word correctly. Keep practising to lock in mastery!'
                          : 'Let\'s practice this word! Listen to the audio and review the meaning above.',
                      style: AppTypography.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: currentlyCorrect
                            ? const Color(0xFF15803D)
                            : const Color(0xFF0369A1),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('Close',
                        style: AppTypography.baloo2(
                            fontSize: 15,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _ttsService.speak(english);
                    },
                    icon: const Icon(Icons.volume_up_rounded, size: 20),
                    label: Text('Listen Again', style: AppTypography.baloo2(fontSize: 15, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF64748B), size: 18),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: AppTypography.nunito(color: const Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.baloo2(
                color: const Color(0xFF0F172A),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String? pref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🌟', style: TextStyle(fontSize: 48)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              LocalizationService.translate(pref, 'all_caught_up_title'),
              textAlign: TextAlign.center,
              style: AppTypography.baloo2(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              LocalizationService.translate(pref, 'all_caught_up_desc'),
              textAlign: TextAlign.center,
              style: AppTypography.nunito(
                fontSize: 15,
                color: const Color(0xFF64748B),
                height: 1.4,
                fontWeight: FontWeight.w600,
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
                color: Color(0xFF94A3B8), size: 52),
            const SizedBox(height: 16),
            Text(
              'Could not load practice words.\nPlease try again.',
              textAlign: TextAlign.center,
              style: AppTypography.nunito(color: const Color(0xFF64748B), fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setState(() {
                _future = _loadData();
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text('Retry', style: AppTypography.baloo2(fontSize: 14, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}
