class VocabularyWordModel {
  final String wordId;
  final String lessonId;
  final String englishWord;
  final String cebuanoMeaning;
  final String exampleSentenceEnglish;
  final String? exampleSentenceCebuano;
  final String? audioAssetPath;
  final String? imageAssetPath;
  final String? partOfSpeech;
  final String gradeLevel;
  final int wordOrder;
  final bool isConfusablePairMember;
  final String? phonologicalTipKey;
  final String? mcDistractor1;
  final String? mcDistractor2;
  final String? mcDistractor3;
  final String? fitbSentence;
  final String? fitbAnswer;
  final List<Map<String, dynamic>>? matchingSet;
  final List<String>? sentenceArrangementTokens;
  final String? sentenceCompletionSentence;
  final String? sentenceCompletionAnswer;
  final String? sentenceCompletionOption1;
  final String? sentenceCompletionOption2;
  final String? sentenceCompletionOption3;

  VocabularyWordModel({
    required this.wordId,
    required this.lessonId,
    required this.englishWord,
    required this.cebuanoMeaning,
    required this.exampleSentenceEnglish,
    this.exampleSentenceCebuano,
    this.audioAssetPath,
    this.imageAssetPath,
    this.partOfSpeech,
    required this.gradeLevel,
    required this.wordOrder,
    required this.isConfusablePairMember,
    this.phonologicalTipKey,
    this.mcDistractor1,
    this.mcDistractor2,
    this.mcDistractor3,
    this.fitbSentence,
    this.fitbAnswer,
    this.matchingSet,
    this.sentenceArrangementTokens,
    this.sentenceCompletionSentence,
    this.sentenceCompletionAnswer,
    this.sentenceCompletionOption1,
    this.sentenceCompletionOption2,
    this.sentenceCompletionOption3,
  });

  factory VocabularyWordModel.fromJson(Map<String, dynamic> json) {
    final sentenceCompletionOptions = _readStringList(json, 'sentenceCompletionOptions');
    return VocabularyWordModel(
      wordId: json['wordId'] ?? '',
      lessonId: json['lessonId'] ?? '',
      englishWord: json['englishWord'] ?? '',
      cebuanoMeaning: json['cebuanoMeaning'] ?? '',
      exampleSentenceEnglish: _readString(json, 'exampleSentenceEnglish', 'englishExampleSentence', 'example'),
      exampleSentenceCebuano: _readString(json, 'exampleSentenceCebuano', 'cebuanoExampleSentence', 'cebuanoExample'),
      audioAssetPath: json['audioAssetPath'],
      imageAssetPath: json['imageAssetPath'],
      partOfSpeech: json['partOfSpeech'],
      gradeLevel: json['gradeLevel'] ?? 'GRADE_4',
      wordOrder: json['wordOrder'] ?? 1,
      isConfusablePairMember: json['isConfusablePairMember'] ?? false,
      phonologicalTipKey: json['phonologicalTipKey'],
      mcDistractor1: json['mcDistractor1'],
      mcDistractor2: json['mcDistractor2'],
      mcDistractor3: json['mcDistractor3'],
      fitbSentence: _readString(json, 'fitbSentence', 'fillInTheBlankSentence'),
      fitbAnswer: _readString(json, 'fitbAnswer', 'sentenceCompletionAnswer', 'sentenceCompletionBlank'),
      matchingSet: (json['matchingSet'] as List<dynamic>?)
          ?.whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      sentenceArrangementTokens: (json['sentenceArrangementTokens'] as List<dynamic>?)?.map((item) => item.toString()).toList(),
      sentenceCompletionSentence: _readString(json, 'sentenceCompletionSentence', 'sentenceCompletionBlank', 'fillInTheBlankSentence'),
      sentenceCompletionAnswer: _readString(json, 'sentenceCompletionAnswer', 'fitbAnswer', 'englishWord'),
      sentenceCompletionOption1: _readSentenceCompletionOption(json, sentenceCompletionOptions, 0),
      sentenceCompletionOption2: _readSentenceCompletionOption(json, sentenceCompletionOptions, 1),
      sentenceCompletionOption3: _readSentenceCompletionOption(json, sentenceCompletionOptions, 2),
      // imageAssetPath already set above from json
    );
  }

  static String _readString(Map<String, dynamic> json, String primaryKey, String secondaryKey, [String? tertiaryKey]) {
    for (final key in [primaryKey, secondaryKey, if (tertiaryKey != null) tertiaryKey]) {
      final value = json[key];
      if (value != null) {
        final text = value.toString().trim();
        if (text.isNotEmpty) {
          return text;
        }
      }
    }
    return '';
  }

  static List<String> _readStringList(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is List) {
      return value.map((item) => item.toString().trim()).where((item) => item.isNotEmpty).toList();
    }
    return const [];
  }

  static String? _readSentenceCompletionOption(Map<String, dynamic> json, List<String> options, int index) {
    if (options.length > index) {
      final value = options[index].trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    final legacyKey = 'sentenceCompletionOption${index + 1}';
    final fallback = json[legacyKey]?.toString().trim() ?? '';
    return fallback.isEmpty ? null : fallback;
  }

  Map<String, dynamic> toJson() {
    return {
      'wordId': wordId,
      'lessonId': lessonId,
      'englishWord': englishWord,
      'cebuanoMeaning': cebuanoMeaning,
      'exampleSentenceEnglish': exampleSentenceEnglish,
      'exampleSentenceCebuano': exampleSentenceCebuano,
      'audioAssetPath': audioAssetPath,
      'partOfSpeech': partOfSpeech,
      'gradeLevel': gradeLevel,
      'wordOrder': wordOrder,
      'isConfusablePairMember': isConfusablePairMember,
      'phonologicalTipKey': phonologicalTipKey,
      'mcDistractor1': mcDistractor1,
      'mcDistractor2': mcDistractor2,
      'mcDistractor3': mcDistractor3,
      'fitbSentence': fitbSentence,
      'fitbAnswer': fitbAnswer,
      'imageAssetPath': imageAssetPath,
      'matchingSet': matchingSet,
      'sentenceArrangementTokens': sentenceArrangementTokens,
      'sentenceCompletionSentence': sentenceCompletionSentence,
      'sentenceCompletionAnswer': sentenceCompletionAnswer,
      'sentenceCompletionOption1': sentenceCompletionOption1,
      'sentenceCompletionOption2': sentenceCompletionOption2,
      'sentenceCompletionOption3': sentenceCompletionOption3,
    };
  }
}
