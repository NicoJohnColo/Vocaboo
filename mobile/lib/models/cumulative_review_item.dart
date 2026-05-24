/// Data model representing a single item in the cumulative mixed review.
///
/// Used by [FlashcardRecallWidget], [ListenAndTypeWidget], and
/// [DragAndDropSentenceWidget] in cumulative_activity_widgets.dart.
class CumulativeReviewItem {
  final String wordId;
  final String englishWord;
  final String cebuanoMeaning;

  /// Optional audio text to speak aloud (falls back to [englishWord]).
  final String? audioText;

  /// Shuffled tokens for the drag-and-drop sentence activity.
  final List<String>? sentenceTokens;

  /// The correct assembled sentence for the drag-and-drop activity.
  final String? correctSentence;

  const CumulativeReviewItem({
    required this.wordId,
    required this.englishWord,
    required this.cebuanoMeaning,
    this.audioText,
    this.sentenceTokens,
    this.correctSentence,
  });

  factory CumulativeReviewItem.fromJson(Map<String, dynamic> json) {
    return CumulativeReviewItem(
      wordId: (json['wordId'] ?? json['word_id'] ?? '').toString(),
      englishWord: (json['englishWord'] ?? json['english_word'] ?? '').toString(),
      cebuanoMeaning: (json['cebuanoMeaning'] ?? json['cebuano_meaning'] ?? '').toString(),
      audioText: json['audioText']?.toString(),
      sentenceTokens: json['sentenceTokens'] != null
          ? List<String>.from(json['sentenceTokens'])
          : null,
      correctSentence: json['correctSentence']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'wordId': wordId,
        'englishWord': englishWord,
        'cebuanoMeaning': cebuanoMeaning,
        'audioText': audioText,
        'sentenceTokens': sentenceTokens,
        'correctSentence': correctSentence,
      };
}
