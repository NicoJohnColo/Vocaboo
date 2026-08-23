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

    public SandboxSession getSession() { return session; }
    public SandboxLessonResponse getLesson() { return lesson; }

    public static SandboxSessionGenerationResultBuilder builder() { return new SandboxSessionGenerationResultBuilder(); }

    public static class SandboxSessionGenerationResultBuilder {
        private SandboxSession session;
        private SandboxLessonResponse lesson;

        public SandboxSessionGenerationResultBuilder session(SandboxSession session) { this.session = session; return this; }
        public SandboxSessionGenerationResultBuilder lesson(SandboxLessonResponse lesson) { this.lesson = lesson; return this; }

        public SandboxSessionGenerationResult build() {
            SandboxSessionGenerationResult r = new SandboxSessionGenerationResult();
            r.session = this.session;
            r.lesson = this.lesson;
            return r;
        }
    }
}