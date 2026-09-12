import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/motion/typography_tokens.dart';
import '../providers/auth_provider.dart';
import '../services/localization_service.dart';
import '../services/phonetic_service.dart';
import '../services/tts_service.dart';

class PhonicsVowelsScreen extends StatefulWidget {
  const PhonicsVowelsScreen({super.key});

  @override
  State<PhonicsVowelsScreen> createState() => _PhonicsVowelsScreenState();
}

class _PhonicsVowelsScreenState extends State<PhonicsVowelsScreen>
    with SingleTickerProviderStateMixin {
  final TtsService _ttsService = TtsService();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  String? _currentlyPlayingSound;
  String _searchQuery = '';

  // Vowels list with dedicated phonetic soundAudio strings
  final List<Map<String, String>> _vowels = [
    {'symbol': 'ɑ', 'soundAudio': 'ah', 'example': 'hot', 'cebuano': 'init', 'ipa': 'ɑ', 'soundName': 'Short O ("ah")'},
    {'symbol': 'æ', 'soundAudio': 'a', 'example': 'cat', 'cebuano': 'iring', 'ipa': 'æ', 'soundName': 'Short A ("a")'},
    {'symbol': 'ʌ', 'soundAudio': 'uh', 'example': 'but', 'cebuano': 'apan', 'ipa': 'ʌ', 'soundName': 'Short U ("uh")'},
    {'symbol': 'ɛ', 'soundAudio': 'eh', 'example': 'bed', 'cebuano': 'katre', 'ipa': 'ɛ', 'soundName': 'Short E ("eh")'},
    {'symbol': 'eɪ', 'soundAudio': 'ay', 'example': 'say', 'cebuano': 'ingon', 'ipa': 'eɪ', 'soundName': 'Long A ("ay")'},
    {'symbol': 'ɚ', 'soundAudio': 'er', 'example': 'bird', 'cebuano': 'langgam', 'ipa': 'ɚ', 'soundName': 'R-controlled ("er")'},
    {'symbol': 'ɪ', 'soundAudio': 'ih', 'example': 'ship', 'cebuano': 'barko', 'ipa': 'ɪ', 'soundName': 'Short I ("ih")'},
    {'symbol': 'i', 'soundAudio': 'ee', 'example': 'sheep', 'cebuano': 'karnero', 'ipa': 'i', 'soundName': 'Long E ("ee")'},
    {'symbol': 'ə', 'soundAudio': 'uh', 'example': 'about', 'cebuano': 'mahitungod', 'ipa': 'ə', 'soundName': 'Schwa ("uh")'},
    {'symbol': 'oʊ', 'soundAudio': 'oh', 'example': 'boat', 'cebuano': 'sakayan', 'ipa': 'oʊ', 'soundName': 'Long O ("oh")'},
    {'symbol': 'ʊ', 'soundAudio': 'uuh', 'example': 'foot', 'cebuano': 'tiil', 'ipa': 'ʊ', 'soundName': 'Short OO ("uuh")'},
    {'symbol': 'u', 'soundAudio': 'ooo', 'example': 'food', 'cebuano': 'pagkaon', 'ipa': 'u', 'soundName': 'Long OO ("ooo")'},
    {'symbol': 'aʊ', 'soundAudio': 'ow', 'example': 'cow', 'cebuano': 'baka', 'ipa': 'aʊ', 'soundName': 'Diphthong ("ow")'},
    {'symbol': 'aɪ', 'soundAudio': 'eye', 'example': 'time', 'cebuano': 'oras', 'ipa': 'aɪ', 'soundName': 'Long I ("eye")'},
    {'symbol': 'ɔɪ', 'soundAudio': 'oy', 'example': 'boy', 'cebuano': 'lalaki', 'ipa': 'ɔɪ', 'soundName': 'Diphthong ("oy")'},
  ];

  // Consonants list with dedicated phonetic soundAudio strings
  final List<Map<String, String>> _consonants = [
    {'symbol': 'b', 'soundAudio': 'buh', 'example': 'book', 'cebuano': 'libro', 'ipa': 'b', 'soundName': 'B sound ("buh")'},
    {'symbol': 'tʃ', 'soundAudio': 'chuh', 'example': 'chair', 'cebuano': 'lingkoranan', 'ipa': 'tʃ', 'soundName': 'CH sound ("ch")'},
    {'symbol': 'd', 'soundAudio': 'duh', 'example': 'day', 'cebuano': 'adlaw', 'ipa': 'd', 'soundName': 'D sound ("duh")'},
    {'symbol': 'f', 'soundAudio': 'ffff', 'example': 'fish', 'cebuano': 'isda', 'ipa': 'f', 'soundName': 'F sound ("ff")'},
    {'symbol': 'ɡ', 'soundAudio': 'guh', 'example': 'goat', 'cebuano': 'kanding', 'ipa': 'ɡ', 'soundName': 'G sound ("guh")'},
    {'symbol': 'h', 'soundAudio': 'huh', 'example': 'hat', 'cebuano': 'kalo', 'ipa': 'h', 'soundName': 'H sound ("huh")'},
    {'symbol': 'dʒ', 'soundAudio': 'juh', 'example': 'jump', 'cebuano': 'lukso', 'ipa': 'dʒ', 'soundName': 'J sound ("juh")'},
    {'symbol': 'k', 'soundAudio': 'kuh', 'example': 'kite', 'cebuano': 'tabanog', 'ipa': 'k', 'soundName': 'K sound ("kuh")'},
    {'symbol': 'l', 'soundAudio': 'lll', 'example': 'lamp', 'cebuano': 'suga', 'ipa': 'l', 'soundName': 'L sound ("lll")'},
    {'symbol': 'm', 'soundAudio': 'mmm', 'example': 'milk', 'cebuano': 'gatas', 'ipa': 'm', 'soundName': 'M sound ("mmm")'},
    {'symbol': 'n', 'soundAudio': 'nnn', 'example': 'nut', 'cebuano': 'mani', 'ipa': 'n', 'soundName': 'N sound ("nnn")'},
    {'symbol': 'ŋ', 'soundAudio': 'ng', 'example': 'sing', 'cebuano': 'kanta', 'ipa': 'ŋ', 'soundName': 'NG sound ("ng")'},
    {'symbol': 'p', 'soundAudio': 'puh', 'example': 'pen', 'cebuano': 'pluma', 'ipa': 'p', 'soundName': 'P sound ("puh")'},
    {'symbol': 'r', 'soundAudio': 'ruh', 'example': 'run', 'cebuano': 'dagan', 'ipa': 'r', 'soundName': 'R sound ("ruh")'},
    {'symbol': 's', 'soundAudio': 'sss', 'example': 'sun', 'cebuano': 'adlaw', 'ipa': 's', 'soundName': 'S sound ("sss")'},
    {'symbol': 'ʃ', 'soundAudio': 'shhh', 'example': 'ship', 'cebuano': 'barko', 'ipa': 'ʃ', 'soundName': 'SH sound ("sh")'},
    {'symbol': 't', 'soundAudio': 'tuh', 'example': 'table', 'cebuano': 'lamesa', 'ipa': 't', 'soundName': 'T sound ("tuh")'},
    {'symbol': 'θ', 'soundAudio': 'th', 'example': 'think', 'cebuano': 'huna-huna', 'ipa': 'θ', 'soundName': 'Voiceless TH ("th")'},
    {'symbol': 'ð', 'soundAudio': 'thuh', 'example': 'this', 'cebuano': 'kini', 'ipa': 'ð', 'soundName': 'Voiced TH ("th")'},
    {'symbol': 'v', 'soundAudio': 'vvv', 'example': 'van', 'cebuano': 'van', 'ipa': 'v', 'soundName': 'V sound ("vvv")'},
    {'symbol': 'w', 'soundAudio': 'wuh', 'example': 'water', 'cebuano': 'tubig', 'ipa': 'w', 'soundName': 'W sound ("wuh")'},
    {'symbol': 'j', 'soundAudio': 'yuh', 'example': 'yes', 'cebuano': 'oo', 'ipa': 'j', 'soundName': 'Y sound ("yuh")'},
    {'symbol': 'z', 'soundAudio': 'zzz', 'example': 'zebra', 'cebuano': 'zebra', 'ipa': 'z', 'soundName': 'Z sound ("zzz")'},
    {'symbol': 'ʒ', 'soundAudio': 'zh', 'example': 'vision', 'cebuano': 'panan-aw', 'ipa': 'ʒ', 'soundName': 'ZH sound ("zh")'},
  ];

  // Digraphs and combinations with dedicated phonetic soundAudio strings
  final List<Map<String, String>> _digraphs = [
    {'symbol': 'ck', 'soundAudio': 'kuh', 'example': 'duck', 'cebuano': 'itik', 'ipa': 'k', 'soundName': 'CK sound ("k")'},
    {'symbol': 'nk', 'soundAudio': 'ngk', 'example': 'pink', 'cebuano': 'pink', 'ipa': 'ŋk', 'soundName': 'NK sound ("ngk")'},
    {'symbol': 'kn', 'soundAudio': 'nnn', 'example': 'knee', 'cebuano': 'tuhod', 'ipa': 'n', 'soundName': 'Silent K ("n")'},
    {'symbol': 'qu', 'soundAudio': 'kwuh', 'example': 'queen', 'cebuano': 'reyna', 'ipa': 'kw', 'soundName': 'QU sound ("kw")'},
    {'symbol': 'wh', 'soundAudio': 'wuh', 'example': 'whale', 'cebuano': 'balyena', 'ipa': 'w', 'soundName': 'WH sound ("w")'},
    {'symbol': 'wr', 'soundAudio': 'rrr', 'example': 'write', 'cebuano': 'suwat', 'ipa': 'r', 'soundName': 'Silent W ("r")'},
    {'symbol': 'll', 'soundAudio': 'lll', 'example': 'ball', 'cebuano': 'bola', 'ipa': 'l', 'soundName': 'Double L ("l")'},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _ttsService.initialize();
  }

  @override
  void dispose() {
    _ttsService.stop();
    _animController.dispose();
    super.dispose();
  }

  /// Speaks the isolated phonetic sound (e.g. "ah", "sh", "buh")
  Future<void> _playSound(String symbol, String soundAudio) async {
    HapticFeedback.lightImpact();
    setState(() => _currentlyPlayingSound = symbol);
    await _ttsService.speakSound(soundAudio);
    if (mounted) {
      setState(() => _currentlyPlayingSound = null);
    }
  }

  /// Speaks the example word (e.g. "hot", "ship", "chair")
  Future<void> _playExampleWord(String symbol, String example) async {
    HapticFeedback.lightImpact();
    setState(() => _currentlyPlayingSound = symbol);
    await _ttsService.speak(example);
    if (mounted) {
      setState(() => _currentlyPlayingSound = null);
    }
  }

  /// Speaks the sound first, pauses, then speaks the example word
  Future<void> _playSoundAndWord(String symbol, String soundAudio, String example) async {
    HapticFeedback.mediumImpact();
    setState(() => _currentlyPlayingSound = symbol);
    await _ttsService.speakSound(soundAudio);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      await _ttsService.speak(example);
      setState(() => _currentlyPlayingSound = null);
    }
  }

  void _showDetailBottomSheet(Map<String, String> item, String? pref) {
    HapticFeedback.mediumImpact();
    final isCebuano = pref == 'CEBUANO_TO_ENGLISH';
    final phonologicalTip = PhoneticService.getPhonologicalTip(
      word: item['example']!,
      languagePreference: pref,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Handle Bar
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 18),

              // Sound Banner & Symbol
              Row(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF0EA5E9), width: 2.0),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        item['symbol']!,
                        style: AppTypography.baloo2(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0284C7),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['soundName'] ?? 'Sound: /${item['symbol']}/',
                          style: AppTypography.baloo2(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'IPA: /${item['ipa']}/  •  Sound: "${item['soundAudio']}"',
                          style: AppTypography.nunito(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0284C7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Dedicated Sound Play Button
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(12),
                    ),
                    tooltip: 'Play Sound',
                    icon: const Icon(Icons.volume_up_rounded, size: 26),
                    onPressed: () => _playSound(item['symbol']!, item['soundAudio'] ?? item['symbol']!),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Example Word Card with audio trigger
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFBAE6FD), width: 1.2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.record_voice_over_rounded, color: Color(0xFF0284C7), size: 26),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item['example']!.toUpperCase(),
                                style: AppTypography.baloo2(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Example Word',
                                  style: AppTypography.nunito(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0284C7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Cebuano: ${item['cebuano']}',
                            style: AppTypography.nunito(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Dedicated Word Play Button
                    IconButton(
                      icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF0284C7), size: 34),
                      tooltip: 'Play Word',
                      onPressed: () => _playExampleWord(item['symbol']!, item['example']!),
                    ),
                  ],
                ),
              ),

              // Articulation Guidance
              if (phonologicalTip.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          phonologicalTip,
                          style: AppTypography.nunito(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF92400E),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Two Action Buttons: Listen to Sound / Listen to Both
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0284C7),
                        side: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.volume_up_rounded, size: 20),
                      label: Text(
                        isCebuano ? 'Tingog Lang' : 'Sound Only',
                        style: AppTypography.baloo2(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      onPressed: () => _playSound(item['symbol']!, item['soundAudio'] ?? item['symbol']!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0EA5E9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.music_note_rounded, size: 20),
                      label: Text(
                        isCebuano ? 'Tingog & Pulong' : 'Sound & Word',
                        style: AppTypography.baloo2(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      onPressed: () => _playSoundAndWord(
                        item['symbol']!,
                        item['soundAudio'] ?? item['symbol']!,
                        item['example']!,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final pref = auth.learner?.languagePreference;

    final q = _searchQuery.toLowerCase().trim();

    List<Map<String, String>> filteredVowels = _vowels;
    List<Map<String, String>> filteredConsonants = _consonants;
    List<Map<String, String>> filteredDigraphs = _digraphs;

    if (q.isNotEmpty) {
      filteredVowels = _vowels.where((item) =>
          item['symbol']!.toLowerCase().contains(q) ||
          item['example']!.toLowerCase().contains(q) ||
          item['cebuano']!.toLowerCase().contains(q) ||
          (item['soundAudio']?.toLowerCase().contains(q) ?? false)).toList();

      filteredConsonants = _consonants.where((item) =>
          item['symbol']!.toLowerCase().contains(q) ||
          item['example']!.toLowerCase().contains(q) ||
          item['cebuano']!.toLowerCase().contains(q) ||
          (item['soundAudio']?.toLowerCase().contains(q) ?? false)).toList();

      filteredDigraphs = _digraphs.where((item) =>
          item['symbol']!.toLowerCase().contains(q) ||
          item['example']!.toLowerCase().contains(q) ||
          item['cebuano']!.toLowerCase().contains(q) ||
          (item['soundAudio']?.toLowerCase().contains(q) ?? false)).toList();
    }

    final vowelsTitle = LocalizationService.translate(pref, 'vowels_section');
    final consonantsTitle = LocalizationService.translate(pref, 'consonants_section');

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
          LocalizationService.translate(pref, 'sound_title'),
          style: AppTypography.baloo2(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: const Color(0xFF06A6FF),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // Search Filter
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBAE6FD), width: 1.2),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search sound or word (e.g. cat, hot, chair)...',
                      hintStyle: AppTypography.nunito(color: const Color(0xFF94A3B8), fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0EA5E9), size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
            ),

            // ── Section 1: Mga Vowel ──────────────────────────────────
            if (filteredVowels.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                  child: Text(
                    vowelsTitle,
                    style: AppTypography.baloo2(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.22,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildSoundCard(filteredVowels[index], pref),
                    childCount: filteredVowels.length,
                  ),
                ),
              ),
            ],

            // ── Section 2: Mga Consonant ──────────────────────────────
            if (filteredConsonants.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
                  child: Text(
                    consonantsTitle,
                    style: AppTypography.baloo2(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.22,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildSoundCard(filteredConsonants[index], pref),
                    childCount: filteredConsonants.length,
                  ),
                ),
              ),
            ],

            // ── Section 3: Digraphs / Combinations ───────────────────
            if (filteredDigraphs.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
                  child: Text(
                    pref == 'CEBUANO_TO_ENGLISH' ? 'Dobleng Katingog (Digraphs)' : 'Digraphs & Special',
                    style: AppTypography.baloo2(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.22,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildSoundCard(filteredDigraphs[index], pref),
                    childCount: filteredDigraphs.length,
                  ),
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundCard(Map<String, String> item, String? pref) {
    final isPlaying = _currentlyPlayingSound == item['symbol'];

    return GestureDetector(
      onTap: () => _playSound(item['symbol']!, item['soundAudio'] ?? item['symbol']!),
      onLongPress: () => _showDetailBottomSheet(item, pref),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isPlaying ? const Color(0xFFF0F9FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPlaying ? const Color(0xFF0284C7) : const Color(0xFFBAE6FD),
            width: isPlaying ? 2.0 : 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: isPlaying
                  ? const Color(0xFF0EA5E9).withValues(alpha: 0.25)
                  : const Color(0xFF0EA5E9).withValues(alpha: 0.04),
              blurRadius: isPlaying ? 6 : 3,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Sound Symbol
                  Text(
                    item['symbol']!,
                    textAlign: TextAlign.center,
                    style: AppTypography.baloo2(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isPlaying ? const Color(0xFF0284C7) : const Color(0xFF0F172A),
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Example Word / Sound text
                  Text(
                    item['example']!,
                    textAlign: TextAlign.center,
                    style: AppTypography.nunito(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Bottom Audio Indicator Pill Bar
                  Container(
                    height: 3.5,
                    width: 28,
                    decoration: BoxDecoration(
                      color: isPlaying ? const Color(0xFF0EA5E9) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
            // Info button in top right for opening full details
            Positioned(
              top: 2,
              right: 2,
              child: GestureDetector(
                onTap: () => _showDetailBottomSheet(item, pref),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
