import { useState } from 'react';

const GRADES = ['GRADE_4', 'GRADE_5', 'GRADE_6'];
const STATUSES = [
  { value: 'DRAFT', label: '📝 Draft', desc: 'Visible to admins only. Not shown to learners.' },
  { value: 'PUBLISHED', label: '🚀 Published', desc: 'Live for selected grade levels.' },
  { value: 'ARCHIVED', label: '📦 Archived', desc: 'Hidden from learners, kept for records.' },
];

export default function PublishWorkflowModal({ lesson, onSubmit, onClose, submitting, error }) {
  const [status, setStatus] = useState(lesson.content_status ?? 'DRAFT');
  const [targetGrades, setTargetGrades] = useState(
    lesson.target_grades ? lesson.target_grades.split(',') : GRADES
  );

  const toggleGrade = (g) => {
    setTargetGrades(prev => prev.includes(g) ? prev.filter(x => x !== g) : [...prev, g]);
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal modal--lg" onClick={e => e.stopPropagation()}>
        <h2 className="modal__title">🚦 Publish Workflow</h2>
        <p className="modal__note">
          <strong>{lesson.lesson_title}</strong> · {lesson.total_word_count} words
        </p>

        {error && <div className="alert alert--error">{error}</div>}

        <div className="form-field">
          <label className="form-label">Content Status</label>
          <div className="status-selector">
            {STATUSES.map(s => (
              <label key={s.value} className={`status-option ${status === s.value ? 'status-option--active' : ''}`}>
                <input type="radio" name="status" value={s.value} checked={status === s.value} onChange={() => setStatus(s.value)} />
                <div>
                  <div className="status-option__label">{s.label}</div>
                  <div className="status-option__desc">{s.desc}</div>
                </div>
              </label>
            ))}
          </div>
        </div>

        {status === 'PUBLISHED' && (
          <div className="form-field" style={{ marginTop: 16 }}>
            <label className="form-label">Target Grade Levels</label>
            <div style={{ display: 'flex', gap: 12, marginTop: 8 }}>
              {GRADES.map(g => (
                <label key={g} className="grade-checkbox">
                  <input
                    type="checkbox"
                    checked={targetGrades.includes(g)}
                    onChange={() => toggleGrade(g)}
                  />
                  <span>{g.replace('GRADE_', 'Grade ')}</span>
                </label>
              ))}
            </div>
          </div>
        )}

        <div className="modal__actions">
          <button className="btn btn--ghost" onClick={onClose} disabled={submitting}>Cancel</button>
          <button
            className="btn btn--primary"
            onClick={() => onSubmit(status, targetGrades)}
            disabled={submitting || (status === 'PUBLISHED' && targetGrades.length === 0)}
          >
            {submitting ? <span className="spinner spinner--sm" /> : 'Apply Status'}
          </button>
        </div>
      </div>
    </div>
  );
}
