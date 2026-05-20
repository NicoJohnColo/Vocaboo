class VocabularyWordModel {
  final String wordId;
  final String lessonId;
  final String englishWord;
  final String cebuanoMeaning;
  final String exampleSentenceEnglish;
  final String? exampleSentenceCebuano;
  final String? audioAssetPath;
  final String? partOfSpeech;
  final String gradeLevel;
  final int wordOrder;
  final bool isConfusablePairMember;
  final String? phonologicalTipKey;

  VocabularyWordModel({
    required this.wordId,
    required this.lessonId,
    required this.englishWord,
    required this.cebuanoMeaning,
    required this.exampleSentenceEnglish,
    this.exampleSentenceCebuano,
    this.audioAssetPath,
    this.partOfSpeech,
    required this.gradeLevel,
    required this.wordOrder,
    required this.isConfusablePairMember,
    this.phonologicalTipKey,
  });

  factory VocabularyWordModel.fromJson(Map<String, dynamic> json) {
    return VocabularyWordModel(
      wordId: json['wordId'] ?? '',
      lessonId: json['lessonId'] ?? '',
      englishWord: json['englishWord'] ?? '',
      cebuanoMeaning: json['cebuanoMeaning'] ?? '',
      exampleSentenceEnglish: json['exampleSentenceEnglish'] ?? '',
      exampleSentenceCebuano: json['exampleSentenceCebuano'],
      audioAssetPath: json['audioAssetPath'],
      partOfSpeech: json['partOfSpeech'],
      gradeLevel: json['gradeLevel'] ?? 'GRADE_4',
      wordOrder: json['wordOrder'] ?? 1,
      isConfusablePairMember: json['isConfusablePairMember'] ?? false,
      phonologicalTipKey: json['phonologicalTipKey'],
    );
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
    };
  }
}
