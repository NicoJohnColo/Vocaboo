package com.vocaboo.controller;

import com.vocaboo.entity.DailyGoal;
import com.vocaboo.service.DailyGoalService;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/learners/{learnerId}/daily-goal")
@RequiredArgsConstructor
public class DailyGoalController {

    private final DailyGoalService dailyGoalService;

    @Data
    public static class DailyGoalResponse {
        private UUID id;
        private UUID learnerId;
        private LocalDate goalDate;
        private Integer targetCount;
        private Integer currentProgress;
        private Boolean isCompleted;

        public static DailyGoalResponse fromEntity(DailyGoal entity) {
            DailyGoalResponse response = new DailyGoalResponse();
            response.setId(entity.getId());
            response.setLearnerId(entity.getLearner().getLearnerId());
            response.setGoalDate(entity.getGoalDate());
            response.setTargetCount(entity.getTargetCount());
            response.setCurrentProgress(entity.getCurrentProgress());
            response.setIsCompleted(entity.getIsCompleted());
            return response;
        }
    }

    @GetMapping
    public ResponseEntity<DailyGoalResponse> getDailyGoal(@PathVariable UUID learnerId) {
        LocalDate today = LocalDate.now(ZoneId.systemDefault());
        DailyGoal goal = dailyGoalService.getOrCreateGoal(learnerId, today);
        return ResponseEntity.ok(DailyGoalResponse.fromEntity(goal));
    }

    @PostMapping("/increment")
    public ResponseEntity<DailyGoalResponse> incrementDailyGoal(@PathVariable UUID learnerId) {
        DailyGoal goal = dailyGoalService.incrementGoal(learnerId, 1);
        return ResponseEntity.ok(DailyGoalResponse.fromEntity(goal));
    }
}
