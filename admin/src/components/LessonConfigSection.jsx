import { useState } from 'react';

export const DEFAULT_CONFIG = {
  module2_activities: 'MULTIPLE_CHOICE;FILL_IN_BLANK;MATCHING;WORD_SCRAMBLE;IMAGE_LABELING;TRUE_OR_FALSE;HINT_TO_WORD',
  module3_activities: 'SENTENCE_COMPLETION;SENTENCE_ARRANGEMENT;PRONUNCIATION_FEEDBACK',
  module4_activities: 'IMAGE_MATCHING;FILL_IN_BLANK;SENTENCE_RECONSTRUCTION',
  upgrade_streak_required: 2,
  demotion_threshold: 2,
  reintroduction_threshold: 4,
  module3_upgrade_streak_required: 2,
  module3_demotion_threshold: 1,
  streak_celebration_threshold: 3,
};

const MODULE_2_OPTIONS = [
  { id: 'MULTIPLE_CHOICE', label: 'Multiple Choice (4 Options)' },
  { id: 'FILL_IN_BLANK', label: 'Fill in the Blank' },
  { id: 'MATCHING', label: 'Word Matching' },
  { id: 'WORD_SCRAMBLE', label: 'Word Scramble Tiles' },
  { id: 'IMAGE_LABELING', label: 'Image / Visual Choice' },
  { id: 'TRUE_OR_FALSE', label: 'True or False (Flat Rate)' },
  { id: 'HINT_TO_WORD', label: 'Hint-to-Word (Clue / Riddle Match)' },
];

const MODULE_3_OPTIONS = [
  { id: 'SENTENCE_TRUE_OR_FALSE', label: 'True or False Match (Tama/Sayop)' },
  { id: 'SENTENCE_COMPLETION', label: 'Sentence Fill-in-Blank' },
  { id: 'SENTENCE_ARRANGEMENT', label: 'Sentence Tile Arrangement' },
  { id: 'PRONUNCIATION_FEEDBACK', label: 'Pronunciation Speech Check' },
];

const MODULE_4_OPTIONS = [
  { id: 'IMAGE_MATCHING', label: 'Image-Word Matching' },
  { id: 'FILL_IN_BLANK', label: 'Context Fill-in-Blank' },
  { id: 'SENTENCE_RECONSTRUCTION', label: 'Sentence Reconstruction' },
];

export default function LessonConfigSection({ config, onChange, defaultOpen = false }) {
  const [isOpen, setIsOpen] = useState(defaultOpen);

  const isSelected = (field, id) => {
    const list = (config[field] || DEFAULT_CONFIG[field] || '').split(';');
    return list.includes(id);
  };

  const toggleOption = (field, id) => {
    const current = (config[field] || DEFAULT_CONFIG[field] || '')
      .split(';')
      .filter(Boolean);
    let updated;
    if (current.includes(id)) {
      // Prevent unchecking the last item in a module
      if (current.length <= 1) return;
      updated = current.filter(x => x !== id);
    } else {
      updated = [...current, id];
    }
    onChange({ ...config, [field]: updated.join(';') });
  };

  const handleResetDefaults = (e) => {
    e.stopPropagation();
    onChange({ ...config, ...DEFAULT_CONFIG });
  };

  return (
    <div className={`lesson-config-box ${isOpen ? 'lesson-config-box--open' : ''}`}>
      <div className="lesson-config-header" onClick={() => setIsOpen(!isOpen)}>
        <div className="lesson-config-title">
          <span>⚙️ Activity Formats & Mastery Progression</span>
          <span className="lesson-config-badge">Per-Lesson Customization</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          {isOpen && (
            <button
              type="button"
              className="btn btn--xs btn--ghost"
              onClick={handleResetDefaults}
              title="Reset all settings to standard DepEd defaults"
            >
              🔄 Reset Defaults
            </button>
          )}
          <span style={{ fontSize: '0.9rem', color: '#64748b' }}>
            {isOpen ? '▲ Collapse' : '▼ Expand & Customize'}
          </span>
        </div>
      </div>

      {isOpen && (
        <div className="lesson-config-body">
          {/* Module 2 Formats */}
          <div>
            <div className="lesson-config-section-title">
              <span>🎯 Module 2: Active Practice Formats</span>
            </div>
            <div className="config-pill-grid">
              {MODULE_2_OPTIONS.map(opt => {
                const active = isSelected('module2_activities', opt.id);
                return (
                  <label
                    key={opt.id}
                    className={`config-pill ${active ? 'config-pill--active' : ''}`}
                    onClick={() => toggleOption('module2_activities', opt.id)}
                  >
                    <input
                      type="checkbox"
                      checked={active}
                      onChange={() => {}}
                    />
                    <span>{opt.label}</span>
                  </label>
                );
              })}
            </div>
          </div>

          {/* Module 3 Formats */}
          <div>
            <div className="lesson-config-section-title">
              <span>📝 Module 3: Sentence Building Formats</span>
            </div>
            <div className="config-pill-grid">
              {MODULE_3_OPTIONS.map(opt => {
                const active = isSelected('module3_activities', opt.id);
                return (
                  <label
                    key={opt.id}
                    className={`config-pill ${active ? 'config-pill--active' : ''}`}
                    onClick={() => toggleOption('module3_activities', opt.id)}
                  >
                    <input
                      type="checkbox"
                      checked={active}
                      onChange={() => {}}
                    />
                    <span>{opt.label}</span>
                  </label>
                );
              })}
            </div>
          </div>

          {/* Module 4 Formats */}
          <div>
            <div className="lesson-config-section-title">
              <span>🏆 Module 4: Cumulative Review Formats</span>
            </div>
            <div className="config-pill-grid">
              {MODULE_4_OPTIONS.map(opt => {
                const active = isSelected('module4_activities', opt.id);
                return (
                  <label
                    key={opt.id}
                    className={`config-pill ${active ? 'config-pill--active' : ''}`}
                    onClick={() => toggleOption('module4_activities', opt.id)}
                  >
                    <input
                      type="checkbox"
                      checked={active}
                      onChange={() => {}}
                    />
                    <span>{opt.label}</span>
                  </label>
                );
              })}
            </div>
          </div>

          {/* Module 2 Streak & Demotion Settings */}
          <div>
            <div className="lesson-config-section-title">
              <span>🎯 Module 2: Active Practice Streak & Retention Rules</span>
            </div>
            <div className="config-stepper-grid">
              <div className="config-stepper-card">
                <label className="config-stepper-label">Upgrade Streak</label>
                <input
                  type="number"
                  min="1"
                  max="5"
                  className="config-stepper-input"
                  value={config.upgrade_streak_required ?? 2}
                  onChange={(e) =>
                    onChange({
                      ...config,
                      upgrade_streak_required: Math.max(1, Math.min(5, parseInt(e.target.value) || 2)),
                    })
                  }
                />
                <span className="config-stepper-desc">
                  Consecutive correct answers to advance tier (Learning → Familiar → Proficient → Mastered).
                </span>
              </div>

              <div className="config-stepper-card">
                <label className="config-stepper-label">Demotion Threshold</label>
                <input
                  type="number"
                  min="1"
                  max="5"
                  className="config-stepper-input"
                  value={config.demotion_threshold ?? 2}
                  onChange={(e) =>
                    onChange({
                      ...config,
                      demotion_threshold: Math.max(1, Math.min(5, parseInt(e.target.value) || 2)),
                    })
                  }
                />
                <span className="config-stepper-desc">
                  Consecutive incorrect answers before easing word down one difficulty tier.
                </span>
              </div>

              <div className="config-stepper-card">
                <label className="config-stepper-label">Reintroduction Trigger</label>
                <input
                  type="number"
                  min="2"
                  max="10"
                  className="config-stepper-input"
                  value={config.reintroduction_threshold ?? 4}
                  onChange={(e) =>
                    onChange({
                      ...config,
                      reintroduction_threshold: Math.max(2, Math.min(10, parseInt(e.target.value) || 4)),
                    })
                  }
                />
                <span className="config-stepper-desc">
                  Consecutive incorrect answers at Learning floor to trigger visual reintroduction.
                </span>
              </div>

              <div className="config-stepper-card">
                <label className="config-stepper-label">Streak Celebration Length</label>
                <input
                  type="number"
                  min="2"
                  max="10"
                  className="config-stepper-input"
                  value={config.streak_celebration_threshold ?? config.streakCelebrationThreshold ?? 3}
                  onChange={(e) =>
                    onChange({
                      ...config,
                      streak_celebration_threshold: Math.max(2, Math.min(10, parseInt(e.target.value) || 3)),
                      streakCelebrationThreshold: Math.max(2, Math.min(10, parseInt(e.target.value) || 3)),
                    })
                  }
                />
                <span className="config-stepper-desc">
                  Consecutive correct answers required to trigger the in-app streak celebration overlay.
                </span>
              </div>
            </div>
          </div>

          {/* Module 3 Sentence Building Progression & Streak Settings */}
          <div>
            <div className="lesson-config-section-title">
              <span>📝 Module 3: Sentence Building Progression & Streak Rules</span>
            </div>
            <div className="config-stepper-grid">
              <div className="config-stepper-card">
                <label className="config-stepper-label">Upgrade Streak</label>
                <input
                  type="number"
                  min="1"
                  max="5"
                  className="config-stepper-input"
                  value={config.module3_upgrade_streak_required ?? config.module3UpgradeStreakRequired ?? 2}
                  onChange={(e) =>
                    onChange({
                      ...config,
                      module3_upgrade_streak_required: Math.max(1, Math.min(5, parseInt(e.target.value) || 2)),
                      module3UpgradeStreakRequired: Math.max(1, Math.min(5, parseInt(e.target.value) || 2)),
                    })
                  }
                />
                <span className="config-stepper-desc">
                  Consecutive correct answers to advance tier (Learning → Familiar → Proficient → Mastered).
                </span>
              </div>

              <div className="config-stepper-card">
                <label className="config-stepper-label">Demotion Threshold</label>
                <input
                  type="number"
                  min="1"
                  max="5"
                  className="config-stepper-input"
                  value={config.module3_demotion_threshold ?? config.module3DemotionThreshold ?? 1}
                  onChange={(e) =>
                    onChange({
                      ...config,
                      module3_demotion_threshold: Math.max(1, Math.min(5, parseInt(e.target.value) || 1)),
                      module3DemotionThreshold: Math.max(1, Math.min(5, parseInt(e.target.value) || 1)),
                    })
                  }
                />
                <span className="config-stepper-desc">
                  Consecutive incorrect answers before easing word down one difficulty tier.
                </span>
              </div>

              <div className="config-stepper-card">
                <label className="config-stepper-label">Streak Celebration Length</label>
                <input
                  type="number"
                  min="2"
                  max="10"
                  className="config-stepper-input"
                  value={config.streak_celebration_threshold ?? config.streakCelebrationThreshold ?? 3}
                  onChange={(e) =>
                    onChange({
                      ...config,
                      streak_celebration_threshold: Math.max(2, Math.min(10, parseInt(e.target.value) || 3)),
                      streakCelebrationThreshold: Math.max(2, Math.min(10, parseInt(e.target.value) || 3)),
                    })
                  }
                />
                <span className="config-stepper-desc">
                  Consecutive correct answers required to trigger the in-app streak celebration overlay.
                </span>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
