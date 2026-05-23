package com.vocaboo.service;

import com.vocaboo.dto.response.SandboxLessonResponse;
import com.vocaboo.entity.SandboxSession;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SandboxSessionGenerationResult {
    private SandboxSession session;
    private SandboxLessonResponse lesson;
}