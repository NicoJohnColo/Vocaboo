import { useState } from 'react';
import type { AdminLesson } from '../services/LessonService';

interface Props {
  lesson: AdminLesson;
  onSubmit: (data: { lesson_title: string; lesson_description: string; grade_level: string }) => Promise<void>;
  onClose: () => void;
  submitting?: boolean;
  error?: string;
}

const GRADE_LEVELS = ['GRADE_3_4', 'GRADE_5_6'];

export default function EditLessonModal({ lesson, onSubmit, onClose, submitting, error }: Props) {
  const [form, setForm] = useState({
    lesson_title: lesson.lesson_title,
    lesson_description: lesson.lesson_description ?? '',
    grade_level: lesson.grade_level,
  });
  const [validationErrors, setValidationErrors] = useState<Record<string, string>>({});

  const validate = () => {
    const errs: Record<string, string> = {};
    if (!form.lesson_title.trim()) errs.lesson_title = 'Title is required';
    else if (form.lesson_title.trim().length < 3) errs.lesson_title = 'Title must be at least 3 characters';
    return errs;
  };

  const handleSubmit = async () => {
    const errs = validate();
    if (Object.keys(errs).length) { setValidationErrors(errs); return; }
    await onSubmit(form);
  };

  const field = (key: keyof typeof form) => ({
    value: form[key],
    onChange: (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
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
              {GRADE_LEVELS.map(g => <option key={g} value={g}>{g.replace('_', ' ')}</option>)}
            </select>
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
