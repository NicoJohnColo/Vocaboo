package com.vocaboo.repository;

import com.vocaboo.entity.WrongAnswerRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface WrongAnswerRecordRepository extends JpaRepository<WrongAnswerRecord, UUID> {
    List<WrongAnswerRecord> findByLearnerLearnerId(UUID learnerId);
}
