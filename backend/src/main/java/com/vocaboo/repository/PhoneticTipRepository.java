package com.vocaboo.repository;

import com.vocaboo.entity.PhoneticTip;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface PhoneticTipRepository extends JpaRepository<PhoneticTip, UUID> {
    Optional<PhoneticTip> findBySoundKey(String soundKey);
}
