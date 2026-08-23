import { useState, useEffect } from 'react';

const GRADE_LEVELS = ['GRADE_3_4', 'GRADE_5_6'];
const LESSON_TYPES = ['REGULAR', 'COMPOSITE_REVIEW'];

export default function CreateLessonModal({ categories, onSubmit, onClose, submitting, error }) {
  const [form, setForm] = useState({
    lesson_title: '',
    lesson_description: '',
    category_id: categories[0]?.category_id ?? '',
    grade_level: 'GRADE_3_4',
    lesson_type: 'REGULAR',
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
    if (!form.category_id) errs.category_id = 'Category is required';
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
              <select className="form-select" {...field('category_id')}>
                {categories.map(c => (
                  <option key={c.category_id} value={c.category_id}>{c.category_name}</option>
                ))}
              </select>
              {validationErrors.category_id && <span className="form-error">{validationErrors.category_id}</span>}
            </div>
            <div className="form-field">
              <label className="form-label">Grade Level *</label>
              <select className="form-select" {...field('grade_level')}>
                {GRADE_LEVELS.map(g => <option key={g} value={g}>{g.replace('_', ' ')}</option>)}
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
        </div>

        <div className="modal__actions">
          <button className="btn btn--ghost" onClick={onClose} disabled={submitting}>Cancel</button>
          <button className="btn btn--primary" onClick={handleSubmit} disabled={submitting}>
            {submitting ? <span className="spinner spinner--sm" /> : '+ Create Lesson'}
          </button>
        </div>
      </div>
    </div>
  );
}
