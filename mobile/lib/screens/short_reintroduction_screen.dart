import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../models/vocabulary_word_model.dart';

import '../providers/lesson_provider.dart';

import '../services/tts_service.dart';
import '../widgets/cebuano_text_highlighter.dart';



class ShortReintroductionScreen extends StatefulWidget {

  final VocabularyWordModel word;

  final VoidCallback onCompleted;



  const ShortReintroductionScreen({

    super.key,

    required this.word,

    required this.onCompleted,

  });



  @override

  State<ShortReintroductionScreen> createState() => _ShortReintroductionScreenState();

}



class _ShortReintroductionScreenState extends State<ShortReintroductionScreen> {

  final TtsService _ttsService = TtsService();

  bool _isSubmitting = false;

  bool _isPlayingAudio = false;



  @override

  void initState() {

    super.initState();

    _playAudio();

  }



  Future<void> _playAudio() async {

    if (!mounted) return;

    setState(() => _isPlayingAudio = true);

    await _ttsService.speak(widget.word.englishWord);

    if (mounted) setState(() => _isPlayingAudio = false);

  }



  Future<void> _handleAcknowledge() async {

    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);



    final provider = Provider.of<LessonProvider>(context, listen: false);

    await provider.acknowledgeReintroduction(widget.word.wordId);



    if (mounted) {

      setState(() => _isSubmitting = false);

      Navigator.of(context).pop();

      widget.onCompleted();

    }

  }



  @override

  Widget build(BuildContext context) {

    final word = widget.word;

    final sentence = word.exampleSentenceEnglish.trim().isNotEmpty

        ? word.exampleSentenceEnglish

        : 'I carry my ${word.englishWord}.';

    final targetWord = word.englishWord;



    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // Header Tag

            Center(

              child: Container(

                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),

                decoration: BoxDecoration(

                  color: const Color(0xFFEFF6FF),

                  borderRadius: BorderRadius.circular(20),

                  border: Border.all(color: const Color(0xFF93C5FD)),

                ),

                child: const Row(

                  mainAxisSize: MainAxisSize.min,

                  children: [

                    Icon(Icons.autorenew_rounded, color: Color(0xFF2563EB), size: 18),

                    SizedBox(width: 6),

                    Text(

                      'Short Re-Teach',

                      style: TextStyle(

                        color: Color(0xFF1E40AF),

                        fontWeight: FontWeight.w800,

                        fontSize: 13,

                      ),

                    ),

                  ],

                ),

              ),

            ),

            const SizedBox(height: 20),



            // Cebuano Word & Context

            Center(

              child: Text(

                word.cebuanoMeaning.toUpperCase(),

                style: const TextStyle(

                  fontFamily: 'Outfit',

                  fontSize: 28,

                  fontWeight: FontWeight.w900,

                  color: Color(0xFF0F172A),

                  letterSpacing: 0.5,

                ),

              ),

            ),

            if (word.exampleSentenceCebuano != null && word.exampleSentenceCebuano!.isNotEmpty) ...[
              const SizedBox(height: 4),
              CebuanoTextHighlighter(
                text: '"${word.exampleSentenceCebuano}"',
                highlightWord: word.cebuanoMeaning,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF64748B),
                ),
              ),
            ],

            const SizedBox(height: 20),



            // English Translation Card with Audio

            Container(

              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(

                color: Colors.white,

                borderRadius: BorderRadius.circular(18),

                boxShadow: [

                  BoxShadow(

                    color: Colors.black.withValues(alpha: 0.04),

                    blurRadius: 10,

                    offset: const Offset(0, 4),

                  ),

                ],

              ),

              child: Row(

                children: [

                  Expanded(

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        const Text(

                          'English Translation',

                          style: TextStyle(

                            fontSize: 12,

                            color: Color(0xFF94A3B8),

                            fontWeight: FontWeight.bold,

                          ),

                        ),

                        const SizedBox(height: 2),

                        Text(

                          targetWord,

                          style: const TextStyle(

                            fontFamily: 'Outfit',

                            fontSize: 22,

                            fontWeight: FontWeight.w800,

                            color: Color(0xFF0284C7),

                          ),

                        ),

                      ],

                    ),

                  ),

                  IconButton.filled(

                    onPressed: _isPlayingAudio ? null : _playAudio,

                    style: IconButton.styleFrom(

                      backgroundColor: const Color(0xFFE0F2FE),

                      foregroundColor: const Color(0xFF0284C7),

                    ),

                    icon: Icon(

                      _isPlayingAudio ? Icons.volume_up_rounded : Icons.volume_down_rounded,

                      size: 26,

                    ),

                  ),

                ],

              ),

            ),

            const SizedBox(height: 16),



            // Example Sentence with Highlighted Target Word

            Container(

              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(

                color: const Color(0xFFFEF3C7),

                borderRadius: BorderRadius.circular(16),

                border: Border.all(color: const Color(0xFFFCD34D)),

              ),

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  const Text(

                    'EXAMPLE SENTENCE:',

                    style: TextStyle(

                      fontSize: 11,

                      fontWeight: FontWeight.w900,

                      color: Color(0xFF92400E),

                      letterSpacing: 0.5,

                    ),

                  ),

                  const SizedBox(height: 6),

                  _buildHighlightedSentence(sentence, targetWord),

                ],

              ),

            ),

            const SizedBox(height: 24),



            // Primary Action Button

            ElevatedButton.icon(

              onPressed: _isSubmitting ? null : _handleAcknowledge,

              icon: _isSubmitting

                  ? const SizedBox(

                      width: 20,

                      height: 20,

                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),

                    )

                  : const Icon(Icons.check_circle_rounded, size: 22),

              label: Text(_isSubmitting ? 'Updating...' : 'I understand this word'),

              style: ElevatedButton.styleFrom(

                backgroundColor: const Color(0xFF10B981),

                foregroundColor: Colors.white,

                padding: const EdgeInsets.symmetric(vertical: 16),

                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

                textStyle: const TextStyle(

                  fontFamily: 'Outfit',

                  fontSize: 16,

                  fontWeight: FontWeight.w800,

                ),

              ),

            ),

          ],

        ),

      ),

    );

  }



  Widget _buildHighlightedSentence(String fullSentence, String wordToHighlight) {

    final tokens = fullSentence.split(RegExp(r'\s+'));

    final spans = <TextSpan>[];



    for (int i = 0; i < tokens.length; i++) {

      final token = tokens[i];

      final cleanToken = token.replaceAll(RegExp(r"[^\p{L}\p{N}']", unicode: true), '');

      final isMatch = cleanToken.equalsIgnoreCase(wordToHighlight);



      spans.add(

        TextSpan(

          text: '$token ',

          style: TextStyle(

            fontFamily: 'Outfit',

            fontSize: 15,

            height: 1.4,

            fontWeight: isMatch ? FontWeight.w900 : FontWeight.normal,

            color: isMatch ? const Color(0xFFB45309) : const Color(0xFF78350F),

            backgroundColor: isMatch ? const Color(0xFFFDE68A) : Colors.transparent,

          ),

        ),

      );

    }



    return RichText(text: TextSpan(children: spans));

  }

}



extension StringIgnoreCase on String {

  bool equalsIgnoreCase(String other) => toLowerCase() == other.toLowerCase();

}

