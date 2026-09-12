import { useState, useEffect } from 'react';
import LessonConfigSection, { DEFAULT_CONFIG } from './LessonConfigSection';

const GRADE_LEVELS = ['GRADE_4', 'GRADE_5', 'GRADE_6'];
const LESSON_TYPES = ['REGULAR', 'COMPOSITE_REVIEW'];

export default function CreateLessonModal({ categories, classes = [], isTeacher = false, onSubmit, onClose, submitting, error }) {
  const [form, setForm] = useState({
    lesson_title: '',
    lesson_description: '',
    category_id: categories[0]?.category_id ?? '',
    class_id: isTeacher && classes.length > 0 ? classes[0].section_id : '',
    grade_level: 'GRADE_4',
    lesson_type: 'REGULAR',
    context_paragraph: '',
    ...DEFAULT_CONFIG,
  });
  const [validationErrors, setValidationErrors] = useState({});

  useEffect(() => {
    if (categories.length && !form.category_id) {
      setForm(f => ({ ...f, category_id: categories[0].category_id }));
    }
  }, [categories]);

  const validate = () => {
    const errs = {};
    if (!form.lesson_title.trim()) errs.lesson_title = 'Title is required';
    else if (form.lesson_title.trim().length < 3) errs.lesson_title = 'Title must be at least 3 characters';
    if (!form.lesson_description.trim()) errs.lesson_description = 'Description is required';
    else if (form.lesson_description.trim().length < 10) errs.lesson_description = 'Description must be at least 10 characters';
    if (!form.category_id) {
      errs.category_id = isTeacher
        ? 'Please select a classroom category. Create one in Category Management first if needed.'
        : 'Category is required';
    }
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
        <h2 className="modal__title">✏️ Create New Lesson</h2>

        {error && <div className="alert alert--error">{error}</div>}

        <div className="form-grid">
          <div className="form-field">
            <label className="form-label">Lesson Title *</label>
            <input
              className={`form-input ${validationErrors.lesson_title ? 'form-input--error' : ''}`}
              placeholder="e.g. Lesson 1 – School Objects"
              {...field('lesson_title')}
              autoFocus
            />
            {validationErrors.lesson_title && <span className="form-error">{validationErrors.lesson_title}</span>}
          </div>

          <div className="form-field form-field--row">
            <div className="form-field">
              <label className="form-label">Category *</label>
              {categories.length === 0 ? (
                <div style={{
                  padding: '10px 14px',
                  borderRadius: 'var(--radius-md, 8px)',
                  background: 'rgba(239, 68, 68, 0.08)',
                  border: '1px solid rgba(239, 68, 68, 0.25)',
                  color: '#dc2626',
                  fontSize: '0.82rem',
                  lineHeight: 1.4,
                }}>
                  ⚠️ No {isTeacher ? 'classroom' : ''} categories found.{' '}
                  {isTeacher
                    ? 'Teachers must create a category first to organize classroom lessons. Go to '
                    : 'Please create a category first in '}
                  <a
                    href="/categories"
                    style={{ color: '#dc2626', fontWeight: 700, textDecoration: 'underline' }}
                    onClick={(e) => {
                      e.preventDefault();
                      onClose();
                      window.location.href = '/categories';
                    }}
                  >
                    Category Management
                  </a>.
                </div>
              ) : (
                <select className="form-select" {...field('category_id')}>
                  {categories.map(c => (
                    <option key={c.category_id} value={c.category_id}>{c.category_name}</option>
                  ))}
                </select>
              )}
              {validationErrors.category_id && <span className="form-error">{validationErrors.category_id}</span>}
            </div>
            <div className="form-field">
              <label className="form-label">Grade Level *</label>
              <select className="form-select" {...field('grade_level')}>
                {GRADE_LEVELS.map(g => <option key={g} value={g}>{g.replace('GRADE_', 'Grade ')}</option>)}
              </select>
            </div>
            <div className="form-field">
              <label className="form-label">Lesson Type</label>
              <select className="form-select" {...field('lesson_type')}>
                {LESSON_TYPES.map(t => <option key={t} value={t}>{t}</option>)}
              </select>
            </div>
          </div>

          <div className="form-field">
            <label className="form-label">
              Target Audience / Class {isTeacher ? '(Required for your class)' : '(Global Curriculum)'}
            </label>
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
            <span className="text-muted" style={{ fontSize: '0.75rem', marginTop: '3px', display: 'block' }}>
              {!isTeacher
                ? 'Administrators create global standard curriculum lessons available to all learners.'
                : 'This lesson will be assigned specifically to the selected class.'}
            </span>
          </div>

          <div className="form-field">
            <label className="form-label">Description *</label>
            <textarea
              className={`form-textarea ${validationErrors.lesson_description ? 'form-input--error' : ''}`}
              placeholder="Describe what learners will study in this lesson..."
              rows={4}
              {...field('lesson_description')}
            />
            {validationErrors.lesson_description && <span className="form-error">{validationErrors.lesson_description}</span>}
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
          <button className="btn btn--primary" onClick={handleSubmit} disabled={submitting || categories.length === 0}>
            {submitting ? <span className="spinner spinner--sm" /> : '+ Create Lesson'}
          </button>
        </div>
      </div>
    </div>
  );
}
