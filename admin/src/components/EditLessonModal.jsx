import { useState } from 'react';
import LessonConfigSection, { DEFAULT_CONFIG } from './LessonConfigSection';

const GRADE_LEVELS = ['GRADE_4', 'GRADE_5', 'GRADE_6'];

export default function EditLessonModal({ lesson, classes = [], isTeacher = false, onSubmit, onClose, submitting, error }) {
  const [form, setForm] = useState({
    lesson_title: lesson.lesson_title ?? lesson.lessonTitle ?? '',
    lesson_description: lesson.lesson_description ?? lesson.lessonDescription ?? '',
    class_id: lesson.class_id ?? lesson.classId ?? '',
    grade_level: lesson.grade_level ?? lesson.gradeLevel ?? 'GRADE_4',
    module2_activities: lesson.module2_activities ?? lesson.module2Activities ?? DEFAULT_CONFIG.module2_activities,
    module3_activities: lesson.module3_activities ?? lesson.module3Activities ?? DEFAULT_CONFIG.module3_activities,
    module4_activities: lesson.module4_activities ?? lesson.module4Activities ?? DEFAULT_CONFIG.module4_activities,
    upgrade_streak_required: lesson.upgrade_streak_required ?? lesson.upgradeStreakRequired ?? DEFAULT_CONFIG.upgrade_streak_required,
    demotion_threshold: lesson.demotion_threshold ?? lesson.demotionThreshold ?? DEFAULT_CONFIG.demotion_threshold,
    reintroduction_threshold: lesson.reintroduction_threshold ?? lesson.reintroductionThreshold ?? DEFAULT_CONFIG.reintroduction_threshold,
    module3_upgrade_streak_required: lesson.module3_upgrade_streak_required ?? lesson.module3UpgradeStreakRequired ?? DEFAULT_CONFIG.module3_upgrade_streak_required,
    module3_demotion_threshold: lesson.module3_demotion_threshold ?? lesson.module3DemotionThreshold ?? DEFAULT_CONFIG.module3_demotion_threshold,
    streak_celebration_threshold: lesson.streak_celebration_threshold ?? lesson.streakCelebrationThreshold ?? DEFAULT_CONFIG.streak_celebration_threshold,
    context_paragraph: lesson.context_paragraph ?? lesson.contextParagraph ?? '',
  });
  const [validationErrors, setValidationErrors] = useState({});

  const validate = () => {
    const errs = {};
    if (!form.lesson_title.trim()) errs.lesson_title = 'Title is required';
    else if (form.lesson_title.trim().length < 3) errs.lesson_title = 'Title must be at least 3 characters';
    return errs;
  };

  const handleSubmit = async () => {
    const errs = validate();
    if (Object.keys(errs).length) { setValidationErrors(errs); return; }
    await onSubmit(form);
  };

  const field = (key) => ({
    value: form[key],
    onChange: (e) => {
      setForm(f => ({ ...f, [key]: e.target.value }));
      setValidationErrors(ve => ({ ...ve, [key]: '' }));
    },
  });

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal modal--lg" onClick={e => e.stopPropagation()}>
        <h2 className="modal__title">✏️ Edit Lesson</h2>
        <p className="modal__note" style={{ marginTop: -8, marginBottom: 20 }}>
          <strong>{lesson.category_name}</strong> · Order #{lesson.lesson_order}
        </p>

        {error && <div className="alert alert--error">{error}</div>}

        <div className="form-grid">
          <div className="form-field">
            <label className="form-label">Lesson Title *</label>
            <input
              className={`form-input ${validationErrors.lesson_title ? 'form-input--error' : ''}`}
              {...field('lesson_title')}
              autoFocus
            />
            {validationErrors.lesson_title && <span className="form-error">{validationErrors.lesson_title}</span>}
          </div>

          <div className="form-field">
            <label className="form-label">Grade Level</label>
            <select className="form-select" {...field('grade_level')}>
              {GRADE_LEVELS.map(g => <option key={g} value={g}>{g.replace('GRADE_', 'Grade ')}</option>)}
            </select>
          </div>

          <div className="form-field">
            <label className="form-label">Target Audience / Class</label>
            {!isTeacher ? (
              <div style={{
                padding: '10px 14px',
                borderRadius: 'var(--radius-md, 8px)',
                background: 'rgba(16, 185, 129, 0.08)',
                border: '1px solid rgba(16, 185, 129, 0.25)',
                color: '#059669',
                fontSize: '0.85rem',
                fontWeight: 600,
                display: 'flex',
                alignItems: 'center',
                gap: 8,
              }}>
                <span>🌍</span>
                <span>Global Curriculum (All Learners)</span>
              </div>
            ) : (
              <select className="form-select" {...field('class_id')}>
                {classes.map(c => (
                  <option key={c.section_id} value={c.section_id}>
                    🏫 Class: {c.section_name} {c.section_code ? `(${c.section_code})` : ''}
                  </option>
                ))}
                {classes.length === 0 && (
                  <option value="">No classes available</option>
                )}
              </select>
            )}
          </div>

          <div className="form-field">
            <label className="form-label">Description</label>
            <textarea
              className="form-textarea"
              rows={4}
              {...field('lesson_description')}
            />
            <span className="form-hint">{form.lesson_description.length}/5000 chars</span>
          </div>

          <div className="form-field">
            <label className="form-label">Context Story / Reading Passage (Module 1)</label>
            <textarea
              className="form-textarea"
              placeholder="e.g. Maria enters her classroom and takes out a sharp pencil to write in her notebook..."
              rows={3}
              {...field('context_paragraph')}
            />
            <span className="form-hint">
              Optional narrative reading passage shown to learners in Module 1 before introducing vocabulary words ({form.context_paragraph?.length ?? 0}/5000 chars)
            </span>
          </div>

          {/* Per-Lesson Configurable Activity & Mastery Section */}
          <LessonConfigSection
            config={form}
            onChange={(newCfg) => setForm(f => ({ ...f, ...newCfg }))}
          />
        </div>

        <div className="modal__actions">
          <button className="btn btn--ghost" onClick={onClose} disabled={submitting}>Cancel</button>
          <button className="btn btn--primary" onClick={handleSubmit} disabled={submitting}>
            {submitting ? <span className="spinner spinner--sm" /> : 'Save Changes'}
          </button>
        </div>
      </div>
    </div>
  );
}
