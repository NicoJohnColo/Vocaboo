import 'package:flutter/material.dart';
import '../models/cumulative_review_item.dart';
import '../services/tts_service.dart';

typedef OnAnswerSubmitted = void Function(bool isCorrect);

class FlashcardRecallWidget extends StatefulWidget {
  final CumulativeReviewItem item;
  final OnAnswerSubmitted onAnswerSubmitted;

  const FlashcardRecallWidget({
    super.key,
    required this.item,
    required this.onAnswerSubmitted,
  });

  @override
  State<FlashcardRecallWidget> createState() => _FlashcardRecallWidgetState();
}

class _FlashcardRecallWidgetState extends State<FlashcardRecallWidget> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              if (!_revealed) {
                setState(() {
                  _revealed = true;
                });
              }
            },
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Text(
                      widget.item.englishWord,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (!_revealed)
                      const Text(
                        'Tap to reveal meaning',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      )
                    else
                      Text(
                        widget.item.cebuanoMeaning,
                        style: const TextStyle(
                          fontSize: 20,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (_revealed) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => widget.onAnswerSubmitted(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('I got it ✓'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => widget.onAnswerSubmitted(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('I missed it ✗'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class ListenAndTypeWidget extends StatefulWidget {
  final CumulativeReviewItem item;
  final OnAnswerSubmitted onAnswerSubmitted;

  const ListenAndTypeWidget({
    super.key,
    required this.item,
    required this.onAnswerSubmitted,
  });

  @override
  State<ListenAndTypeWidget> createState() => _ListenAndTypeWidgetState();
}

class _ListenAndTypeWidgetState extends State<ListenAndTypeWidget> {
  final TextEditingController _controller = TextEditingController();
  bool _submitted = false;
  bool? _isCorrect;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkAnswer() {
    if (_controller.text.isEmpty) return;

    final learnerInput = _controller.text.trim().toLowerCase();
    final correctAnswer = widget.item.englishWord.trim().toLowerCase();

    setState(() {
      _isCorrect = learnerInput == correctAnswer;
      _submitted = true;
    });

    widget.onAnswerSubmitted(_isCorrect!);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: const Icon(Icons.volume_up),
          iconSize: 48,
          onPressed: () {
            final textToSpeak = widget.item.audioText ?? widget.item.englishWord;
            TTSService.speak(textToSpeak);
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Type what you hear',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          enabled: !_submitted,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter the word',
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _submitted ? null : _checkAnswer,
          child: const Text('Check'),
        ),
        if (_submitted) ...[
          const SizedBox(height: 16),
          Text(
            _isCorrect == true
                ? 'Correct!'
                : 'Incorrect — the answer was: ${widget.item.englishWord}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _isCorrect == true ? Colors.green : Colors.red,
            ),
          ),
        ],
      ],
    );
  }
}

class DragAndDropSentenceWidget extends StatefulWidget {
  final CumulativeReviewItem item;
  final OnAnswerSubmitted onAnswerSubmitted;

  const DragAndDropSentenceWidget({
    super.key,
    required this.item,
    required this.onAnswerSubmitted,
  });

  @override
  State<DragAndDropSentenceWidget> createState() => _DragAndDropSentenceWidgetState();
}

class _DragAndDropSentenceWidgetState extends State<DragAndDropSentenceWidget> {
  late List<String> _availableTokens;
  final List<String> _assembledTokens = [];
  bool _submitted = false;
  bool? _isCorrect;

  @override
  void initState() {
    super.initState();
    _availableTokens = List<String>.from(widget.item.sentenceTokens ?? []);
  }

  void _moveToAssembled(String token) {
    setState(() {
      _availableTokens.remove(token);
      _assembledTokens.add(token);
    });
  }

  void _moveToAvailable(String token) {
    setState(() {
      _assembledTokens.remove(token);
      _availableTokens.add(token);
    });
  }

  void _checkAnswer() {
    if (_assembledTokens.isEmpty) return;

    final assembledSentence = _assembledTokens.join(' ').trim().toLowerCase();
    final correctSentence = widget.item.correctSentence?.trim().toLowerCase() ?? '';

    setState(() {
      _isCorrect = assembledSentence == correctSentence;
      _submitted = true;
    });

    widget.onAnswerSubmitted(_isCorrect!);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Build the sentence',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _assembledTokens.map((token) {
              return Chip(
                label: Text(token),
                onDeleted: () => _moveToAvailable(token),
                deleteIcon: const Icon(Icons.close, size: 18),
              );
            }).toList(),
          ),
        ),
        const Divider(height: 32),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableTokens.map((token) {
            return ActionChip(
              label: Text(token),
              onPressed: () => _moveToAssembled(token),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _submitted ? null : _checkAnswer,
          child: const Text('Check'),
        ),
        if (_submitted) ...[
          const SizedBox(height: 16),
          Text(
            _isCorrect == true
                ? 'Correct!'
                : 'Incorrect — correct sentence: ${widget.item.correctSentence}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _isCorrect == true ? Colors.green : Colors.red,
            ),
          ),
        ],
      ],
    );
  }
}
