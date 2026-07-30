package com.vocaboo.service;

import com.vocaboo.entity.Learner;
import com.vocaboo.entity.VocabularyWord;
import com.vocaboo.entity.WrongAnswerRecord;
import com.vocaboo.repository.LearnerRepository;
import com.vocaboo.repository.VocabularyWordRepository;
import com.vocaboo.repository.WrongAnswerRecordRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import java.util.Optional;
import java.util.UUID;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class WrongAnswerTrackingServiceTest {

    @Mock
    private WrongAnswerRecordRepository recordRepository;
    @Mock
    private LearnerRepository learnerRepository;
    @Mock
    private VocabularyWordRepository wordRepository;

    @InjectMocks
    private WrongAnswerTrackingService service;

    @Test
    void trackWrongAnswer_savesRecordWhenEntitiesExist() {
        UUID learnerId = UUID.randomUUID();
        UUID wordId = UUID.randomUUID();

        Learner learner = Learner.builder().learnerId(learnerId).build();
        VocabularyWord word = VocabularyWord.builder().wordId(wordId).build();

        when(learnerRepository.findById(learnerId)).thenReturn(Optional.of(learner));
        when(wordRepository.findById(wordId)).thenReturn(Optional.of(word));

        service.trackWrongAnswer(learnerId, wordId, "pader", "MULTIPLE_CHOICE");

        verify(recordRepository).save(any(WrongAnswerRecord.class));
    }
}
