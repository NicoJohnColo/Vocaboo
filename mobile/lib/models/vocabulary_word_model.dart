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
  final String? tileSentence;
  final String? hintText;
  final String? sentenceCompletionSentence;
  final String? sentenceCompletionAnswer;
  final String? sentenceCompletionOption1;
  final String? sentenceCompletionOption2;
  final String? sentenceCompletionOption3;
  /// Which activity type this word uses across all 4 difficulty tiers (from admin import).
  final String activityType;
  /// The eligible activity types for this word (semicolon-separated).
  final String? eligibleActivityTypes;
  /// The learner's current difficulty tier for this word (LEARNING/FAMILIAR/PROFICIENT/MASTERED).
  final String difficultyLevel;
  /// Whether hints (cebuano meaning) are shown — true only at LEARNING tier.
  final bool showHint;
  /// Timer in seconds; 0 means no timer (LEARNING tier).
  final int? timeLimitSeconds;
  final String? anchoredWord; // For SENTENCE_ARRANGEMENT LEARNING tier: the pre-placed word

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
    this.tileSentence,
    this.hintText,
    this.sentenceCompletionSentence,
    this.sentenceCompletionAnswer,
    this.sentenceCompletionOption1,
    this.sentenceCompletionOption2,
    this.sentenceCompletionOption3,
    this.activityType = 'MULTIPLE_CHOICE',
    this.eligibleActivityTypes,
    this.difficultyLevel = 'LEARNING',
    this.showHint = true,
    this.timeLimitSeconds,
    this.anchoredWord,
  });

  factory VocabularyWordModel.fromJson(Map<String, dynamic> json) {
    final sentenceCompletionOptions = _readStringList(json, 'sentenceCompletionOptions');
    
    // Parse the distractorPool which comes as a semicolon-separated string from the backend
    String? mc1 = json['mcDistractor1'];
    String? mc2 = json['mcDistractor2'];
    String? mc3 = json['mcDistractor3'];
    
    if (json['distractorPool'] != null && json['distractorPool'].toString().isNotEmpty) {
      final pool = json['distractorPool'].toString().split(';');
      if (pool.isNotEmpty) mc1 = pool[0].trim();
      if (pool.length > 1) mc2 = pool[1].trim();
      if (pool.length > 2) mc3 = pool[2].trim();
    } else if (json['multipleChoiceDistractors'] != null && json['multipleChoiceDistractors'] is List) {
      final pool = json['multipleChoiceDistractors'] as List;
      if (pool.isNotEmpty) mc1 = pool[0].toString().trim();
      if (pool.length > 1) mc2 = pool[1].toString().trim();
      if (pool.length > 2) mc3 = pool[2].toString().trim();
    }

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
      mcDistractor1: mc1,
      mcDistractor2: mc2,
      mcDistractor3: mc3,
      fitbSentence: _readString(json, 'fitbSentence', 'fillInTheBlankSentence'),
      fitbAnswer: _readString(json, 'fitbAnswer', 'sentenceCompletionAnswer', 'sentenceCompletionBlank'),
      matchingSet: (json['matchingSet'] as List<dynamic>?)
          ?.whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      sentenceArrangementTokens: ((json['sentenceArrangementTokens'] ?? json['scrambledTokens']) as List<dynamic>?)?.map((item) => item.toString()).toList(),
      tileSentence: _readString(json, 'tileSentence', 'sentenceCompletionSentence'),
      hintText: json['hintText']?.toString(),
      sentenceCompletionSentence: _readString(json, 'sentenceCompletionSentence', 'sentenceCompletionBlank', 'fillInTheBlankSentence'),
      sentenceCompletionAnswer: _readString(json, 'sentenceCompletionAnswer', 'fitbAnswer', 'englishWord'),
      sentenceCompletionOption1: _readSentenceCompletionOption(json, sentenceCompletionOptions, 0),
      sentenceCompletionOption2: _readSentenceCompletionOption(json, sentenceCompletionOptions, 1),
      sentenceCompletionOption3: _readSentenceCompletionOption(json, sentenceCompletionOptions, 2),
      activityType: _parseActivityType(json),
      eligibleActivityTypes: json['eligibleActivityTypes']?.toString() ?? json['activityType']?.toString(),
      difficultyLevel: json['difficultyLevel']?.toString() ?? 'LEARNING',
      showHint: json['showHints'] == true || json['showHint'] == true,
      timeLimitSeconds: (json['timeLimitSeconds'] as num?)?.toInt(),
      anchoredWord: json['anchoredWord']?.toString(),
      // imageAssetPath already set above from json
    );
  }

  static String _parseActivityType(Map<String, dynamic> json) {
    final eligibleStr = json['eligibleActivityTypes']?.toString() ?? json['activityType']?.toString();
    if (eligibleStr == null || eligibleStr.isEmpty) return 'MULTIPLE_CHOICE';
    
    final types = eligibleStr.split(';').where((s) => s.trim().isNotEmpty).toList();
    if (types.isEmpty) return 'MULTIPLE_CHOICE';
    
    types.shuffle();
    return types.first;
  }

  static String _readString(Map<String, dynamic> json, String primaryKey, String secondaryKey, [String? tertiaryKey]) {
    for (final key in [primaryKey, secondaryKey, tertiaryKey].whereType<String>()) {
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
      'tileSentence': tileSentence,
      'hintText': hintText,
      'sentenceCompletionSentence': sentenceCompletionSentence,
      'sentenceCompletionAnswer': sentenceCompletionAnswer,
      'sentenceCompletionOption1': sentenceCompletionOption1,
      'sentenceCompletionOption2': sentenceCompletionOption2,
      'sentenceCompletionOption3': sentenceCompletionOption3,
      'activityType': activityType,
      'difficultyLevel': difficultyLevel,
      'showHints': showHint,
      'timeLimitSeconds': timeLimitSeconds,
      'anchoredWord': anchoredWord,
    };
  }
}
