package com.vocaboo.repository;

import com.vocaboo.entity.Section;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface SectionRepository extends JpaRepository<Section, UUID> {
    Optional<Section> findBySectionNameIgnoreCase(String sectionName);
    boolean existsBySectionNameIgnoreCase(String sectionName);
    boolean existsBySectionNameIgnoreCaseAndSectionIdNot(String sectionName, UUID sectionId);
    List<Section> findAllByOrderBySectionNameAsc();
}
