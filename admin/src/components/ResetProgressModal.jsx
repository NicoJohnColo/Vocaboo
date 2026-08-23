import { useState, useEffect } from 'react';
import { LessonService } from '../services/LessonService';

export default function ResetProgressModal({ learner, onConfirm, onClose, loading }) {
  const [resetType, setResetType] = useState('FULL'); // 'FULL' or 'LESSON'
  const [selectedLessonId, setSelectedLessonId] = useState('');
  const [lessons, setLessons] = useState([]);
  const [loadingLessons, setLoadingLessons] = useState(false);

  useEffect(() => {
    let cancelled = false;
    setLoadingLessons(true);
    LessonService.getAll()
      .then(list => {
        if (!cancelled) {
          setLessons(list);
          if (list.length > 0) setSelectedLessonId(list[0].lesson_id);
          setLoadingLessons(false);
        }
      })
      .catch(() => {
        if (!cancelled) setLoadingLessons(false);
      });
    return () => { cancelled = true; };
  }, []);

  const handleReset = () => {
    const lessonId = resetType === 'LESSON' ? selectedLessonId : null;
    onConfirm(learner.learnerId || learner.learner_id, lessonId);
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal modal--md" onClick={e => e.stopPropagation()}>
        <div className="modal__icon">⚠️</div>
        <h2 className="modal__title" style={{ color: 'var(--color-danger)' }}>Reset Learner Progress</h2>
        
        <p className="modal__note">
          You are about to reset progress for <strong>{learner.displayName || learner.display_name}</strong>.
          This action will permanently delete performance data and cannot be undone.
        </p>

        <div className="form-field" style={{ marginTop: 20 }}>
          <label className="form-label">Select Reset Scope</label>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10, marginTop: 8 }}>
            <label className={`status-option ${resetType === 'FULL' ? 'status-option--active' : ''}`} style={{ cursor: 'pointer' }}>
              <input
                type="radio"
                name="resetType"
                value="FULL"
                checked={resetType === 'FULL'}
                onChange={() => setResetType('FULL')}
              />
              <div>
                <div style={{ fontWeight: 600 }}>Full Progress Reset</div>
                <div style={{ fontSize: '0.8rem', color: 'var(--color-text-muted)' }}>
                  Wipes all lesson statuses, scores, and resets all words to LEARNING tier baseline.
                </div>
              </div>
            </label>

            <label className={`status-option ${resetType === 'LESSON' ? 'status-option--active' : ''}`} style={{ cursor: 'pointer' }}>
              <input
                type="radio"
                name="resetType"
                value="LESSON"
                checked={resetType === 'LESSON'}
                onChange={() => setResetType('LESSON')}
              />
              <div>
                <div style={{ fontWeight: 600 }}>Lesson-Specific Reset</div>
                <div style={{ fontSize: '0.8rem', color: 'var(--color-text-muted)' }}>
                  Resets progress, module scores, and word tiers for a single chosen lesson.
                </div>
              </div>
            </label>
          </div>
        </div>

        {resetType === 'LESSON' && (
          <div className="form-field" style={{ marginTop: 16 }}>
            <label className="form-label">Choose Lesson to Reset *</label>
            {loadingLessons ? (
              <span className="spinner spinner--sm" />
            ) : (
              <select
                className="form-select"
                value={selectedLessonId}
                onChange={e => setSelectedLessonId(e.target.value)}
              >
                {lessons.map(l => (
                  <option key={l.lesson_id} value={l.lesson_id}>
                    {l.lesson_title} ({l.grade_level ? l.grade_level.replace('_', ' ') : ''})
                  </option>
                ))}
              </select>
            )}
          </div>
        )}

        <div className="modal__actions" style={{ marginTop: 24 }}>
          <button className="btn btn--ghost" onClick={onClose} disabled={loading}>
            Cancel
          </button>
          <button
            className="btn btn--danger"
            onClick={handleReset}
            disabled={loading || (resetType === 'LESSON' && !selectedLessonId)}
          >
            {loading ? <span className="spinner spinner--sm" /> : 'Confirm Destructive Reset'}
          </button>
        </div>
      </div>
    </div>
  );
}
