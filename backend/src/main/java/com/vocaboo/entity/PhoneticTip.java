package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "phonetic_tips")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PhoneticTip {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "tip_id", updatable = false, nullable = false)
    private UUID tipId;

    @Column(name = "sound_key", nullable = false, unique = true)
    private String soundKey;

    @Column(name = "tip_cebuano", nullable = false)
    private String tipCebuano;

    @Column(name = "tip_english", nullable = false)
    private String tipEnglish;

    @Column(name = "tip_mixed", nullable = false)
    private String tipMixed;

    @Column(name = "created_at", updatable = false)
    @Builder.Default
    private OffsetDateTime createdAt = OffsetDateTime.now();

    public String getTipCebuano() { return tipCebuano; }
    public String getTipEnglish() { return tipEnglish; }
    public String getTipMixed() { return tipMixed; }

    @PrePersist
    protected void onCreate() {
        createdAt = OffsetDateTime.now();
    }
}
