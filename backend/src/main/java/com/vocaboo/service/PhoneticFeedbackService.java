package com.vocaboo.service;

import com.vocaboo.entity.LanguageMedium;
import com.vocaboo.entity.PhoneticTip;
import com.vocaboo.repository.PhoneticTipRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class PhoneticFeedbackService {

    private final PhoneticTipRepository tipRepository;

    public String getTip(String soundKey, LanguageMedium pref) {
        if (soundKey == null) {
            return null;
        }
        return tipRepository.findBySoundKey(soundKey)
                .map(tip -> {
                    if (pref == LanguageMedium.CEBUANO_TO_ENGLISH) {
                        return tip.getTipCebuano();
                    } else if (pref == LanguageMedium.CEBUANO_ENGLISH_MIXED) {
                        return tip.getTipMixed();
                    } else {
                        return tip.getTipEnglish();
                    }
                })
                .orElse(null);
    }
}
