package com.vocaboo.dto.response;

import com.vocaboo.entity.GradeLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.List;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LessonWordActivityResponse {
    private UUID wordId;
    private UUID lessonId;
    private String englishWord;
    private String cebuanoMeaning;
    private String exampleSentenceEnglish;
    private String exampleSentenceCebuano;
    private String audioAssetPath;
    private String imageAssetPath;
    private String partOfSpeech;
    private GradeLevel gradeLevel;
    private Integer wordOrder;
    private Boolean isConfusablePairMember;
    private String phonologicalTipKey;
    private String mcDistractor1;
    private String mcDistractor2;
    private String mcDistractor3;
    private String fitbSentence;
    private String fitbAnswer;
    private List<MatchingSetEntryResponse> matchingSet;
    private List<String> sentenceArrangementTokens;
    private String sentenceCompletionSentence;
    private String sentenceCompletionAnswer;
    private String sentenceCompletionOption1;
    private String sentenceCompletionOption2;
    private String sentenceCompletionOption3;
    /** Which activity format this word uses across all 4 difficulty tiers. */
    private String activityType;
    private String difficultyLevel; // current learner tier for this word
    private Boolean showHint;       // true only at LEARNING tier
    private Integer timeLimitSeconds;

    public static LessonWordActivityResponseBuilder builder() { return new LessonWordActivityResponseBuilder(); }

    public static class LessonWordActivityResponseBuilder {
        private UUID wordId;
        private UUID lessonId;
        private String englishWord;
        private String cebuanoMeaning;
        private String exampleSentenceEnglish;
        private String exampleSentenceCebuano;
        private String audioAssetPath;
        private String imageAssetPath;
        private String partOfSpeech;
        private GradeLevel gradeLevel;
        private Integer wordOrder;
        private Boolean isConfusablePairMember;
        private String phonologicalTipKey;
        private String mcDistractor1;
        private String mcDistractor2;
        private String mcDistractor3;
        private String fitbSentence;
        private String fitbAnswer;
        private List<MatchingSetEntryResponse> matchingSet;
        private List<String> sentenceArrangementTokens;
        private String sentenceCompletionSentence;
        private String sentenceCompletionAnswer;
        private String sentenceCompletionOption1;
        private String sentenceCompletionOption2;
        private String sentenceCompletionOption3;
        private String activityType;
        private String difficultyLevel;
        private Boolean showHint;
        private Integer timeLimitSeconds;

        public LessonWordActivityResponseBuilder wordId(UUID wordId) { this.wordId = wordId; return this; }
        public LessonWordActivityResponseBuilder lessonId(UUID lessonId) { this.lessonId = lessonId; return this; }
        public LessonWordActivityResponseBuilder englishWord(String englishWord) { this.englishWord = englishWord; return this; }
        public LessonWordActivityResponseBuilder cebuanoMeaning(String cebuanoMeaning) { this.cebuanoMeaning = cebuanoMeaning; return this; }
        public LessonWordActivityResponseBuilder exampleSentenceEnglish(String exampleSentenceEnglish) { this.exampleSentenceEnglish = exampleSentenceEnglish; return this; }
        public LessonWordActivityResponseBuilder exampleSentenceCebuano(String exampleSentenceCebuano) { this.exampleSentenceCebuano = exampleSentenceCebuano; return this; }
        public LessonWordActivityResponseBuilder audioAssetPath(String audioAssetPath) { this.audioAssetPath = audioAssetPath; return this; }
        public LessonWordActivityResponseBuilder imageAssetPath(String imageAssetPath) { this.imageAssetPath = imageAssetPath; return this; }
        public LessonWordActivityResponseBuilder partOfSpeech(String partOfSpeech) { this.partOfSpeech = partOfSpeech; return this; }
        public LessonWordActivityResponseBuilder gradeLevel(GradeLevel gradeLevel) { this.gradeLevel = gradeLevel; return this; }
        public LessonWordActivityResponseBuilder wordOrder(Integer wordOrder) { this.wordOrder = wordOrder; return this; }
        public LessonWordActivityResponseBuilder isConfusablePairMember(Boolean isConfusablePairMember) { this.isConfusablePairMember = isConfusablePairMember; return this; }
        public LessonWordActivityResponseBuilder phonologicalTipKey(String phonologicalTipKey) { this.phonologicalTipKey = phonologicalTipKey; return this; }
        public LessonWordActivityResponseBuilder mcDistractor1(String mcDistractor1) { this.mcDistractor1 = mcDistractor1; return this; }
        public LessonWordActivityResponseBuilder mcDistractor2(String mcDistractor2) { this.mcDistractor2 = mcDistractor2; return this; }
        public LessonWordActivityResponseBuilder mcDistractor3(String mcDistractor3) { this.mcDistractor3 = mcDistractor3; return this; }
        public LessonWordActivityResponseBuilder fitbSentence(String fitbSentence) { this.fitbSentence = fitbSentence; return this; }
        public LessonWordActivityResponseBuilder fitbAnswer(String fitbAnswer) { this.fitbAnswer = fitbAnswer; return this; }
        public LessonWordActivityResponseBuilder matchingSet(List<MatchingSetEntryResponse> matchingSet) { this.matchingSet = matchingSet; return this; }
        public LessonWordActivityResponseBuilder sentenceArrangementTokens(List<String> sentenceArrangementTokens) { this.sentenceArrangementTokens = sentenceArrangementTokens; return this; }
        public LessonWordActivityResponseBuilder sentenceCompletionSentence(String sentenceCompletionSentence) { this.sentenceCompletionSentence = sentenceCompletionSentence; return this; }
        public LessonWordActivityResponseBuilder sentenceCompletionAnswer(String sentenceCompletionAnswer) { this.sentenceCompletionAnswer = sentenceCompletionAnswer; return this; }
        public LessonWordActivityResponseBuilder sentenceCompletionOption1(String sentenceCompletionOption1) { this.sentenceCompletionOption1 = sentenceCompletionOption1; return this; }
        public LessonWordActivityResponseBuilder sentenceCompletionOption2(String sentenceCompletionOption2) { this.sentenceCompletionOption2 = sentenceCompletionOption2; return this; }
        public LessonWordActivityResponseBuilder sentenceCompletionOption3(String sentenceCompletionOption3) { this.sentenceCompletionOption3 = sentenceCompletionOption3; return this; }
        public LessonWordActivityResponseBuilder activityType(String activityType) { this.activityType = activityType; return this; }
        public LessonWordActivityResponseBuilder difficultyLevel(String difficultyLevel) { this.difficultyLevel = difficultyLevel; return this; }
        public LessonWordActivityResponseBuilder showHint(Boolean showHint) { this.showHint = showHint; return this; }
        public LessonWordActivityResponseBuilder timeLimitSeconds(Integer timeLimitSeconds) { this.timeLimitSeconds = timeLimitSeconds; return this; }

        public LessonWordActivityResponse build() {
            LessonWordActivityResponse r = new LessonWordActivityResponse();
            r.wordId = this.wordId;
            r.lessonId = this.lessonId;
            r.englishWord = this.englishWord;
            r.cebuanoMeaning = this.cebuanoMeaning;
            r.exampleSentenceEnglish = this.exampleSentenceEnglish;
            r.exampleSentenceCebuano = this.exampleSentenceCebuano;
            r.audioAssetPath = this.audioAssetPath;
            r.imageAssetPath = this.imageAssetPath;
            r.partOfSpeech = this.partOfSpeech;
            r.gradeLevel = this.gradeLevel;
            r.wordOrder = this.wordOrder;
            r.isConfusablePairMember = this.isConfusablePairMember;
            r.phonologicalTipKey = this.phonologicalTipKey;
            r.mcDistractor1 = this.mcDistractor1;
            r.mcDistractor2 = this.mcDistractor2;
            r.mcDistractor3 = this.mcDistractor3;
            r.fitbSentence = this.fitbSentence;
            r.fitbAnswer = this.fitbAnswer;
            r.matchingSet = this.matchingSet;
            r.sentenceArrangementTokens = this.sentenceArrangementTokens;
            r.sentenceCompletionSentence = this.sentenceCompletionSentence;
            r.sentenceCompletionAnswer = this.sentenceCompletionAnswer;
            r.sentenceCompletionOption1 = this.sentenceCompletionOption1;
            r.sentenceCompletionOption2 = this.sentenceCompletionOption2;
            r.sentenceCompletionOption3 = this.sentenceCompletionOption3;
            r.activityType = this.activityType;
            r.difficultyLevel = this.difficultyLevel;
            r.showHint = this.showHint;
            r.timeLimitSeconds = this.timeLimitSeconds;
            return r;
        }
    }
}