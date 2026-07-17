package com.vocaboo.service;

import com.vocaboo.dto.response.LearnerResponse;
import com.vocaboo.entity.LanguageMedium;
import com.vocaboo.entity.Learner;
import com.vocaboo.repository.LearnerRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class LearnerServicePreferencesTest {

    @Mock
    private LearnerRepository learnerRepository;

    @InjectMocks
    private LearnerService learnerService;

    @Test
    void updatePreferences_updatesMasteryApplyImmediately() {
        UUID learnerId = UUID.randomUUID();
        Learner existing = Learner.builder()
                .learnerId(learnerId)
                .displayName("John")
                .age(10)
                .languagePreference(LanguageMedium.FULL_ENGLISH)
                .onboardingComplete(true)
                .masteryApplyImmediately(true) // initially true
                .build();

        when(learnerRepository.findById(learnerId)).thenReturn(Optional.of(existing));
        when(learnerRepository.save(any(Learner.class))).thenAnswer(invocation -> invocation.getArgument(0));

        // Update to false
        LearnerResponse response = learnerService.updatePreferences(
                learnerId, "John", "FULL_ENGLISH", false
        );

        assertNotNull(response);
        assertFalse(response.getMasteryApplyImmediately());
        verify(learnerRepository).save(argThat(learner -> !learner.getMasteryApplyImmediately()));

        // Update with null (should keep false)
        response = learnerService.updatePreferences(
                learnerId, "John", "FULL_ENGLISH", null
        );

        assertNotNull(response);
        assertFalse(response.getMasteryApplyImmediately());
    }
}
