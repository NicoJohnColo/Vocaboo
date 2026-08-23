import { useState, useEffect } from 'react';
import { SectionService } from '../services/SectionService';

export default function AssignSectionModal({ learners, onConfirm, onClose, loading }) {
  const [sections, setSections] = useState([]);
  const [selectedSectionId, setSelectedSectionId] = useState('');
  const [loadingSections, setLoadingSections] = useState(true);

  useEffect(() => {
    let cancelled = false;
    setLoadingSections(true);
    SectionService.getAllSections()
      .then(list => {
        if (!cancelled) {
          setSections(list);
          if (list.length > 0) setSelectedSectionId(list[0].section_id);
          setLoadingSections(false);
        }
      })
      .catch(() => {
        if (!cancelled) setLoadingSections(false);
      });
    return () => { cancelled = true; };
  }, []);

  const isBulk = Array.isArray(learners);
  const count = isBulk ? learners.length : 1;
  const displayName = isBulk ? `${count} selected learners` : (learners.displayName || learners.display_name);

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal modal--md" onClick={e => e.stopPropagation()}>
        <h2 className="modal__title">🏫 Assign Class / Section</h2>
        
        <p className="modal__note">
          Assign <strong>{displayName}</strong> to a classroom section.
        </p>

        <div className="form-field" style={{ marginTop: 20 }}>
          <label className="form-label">Select Section *</label>
          {loadingSections ? (
            <div className="auth-loading" style={{ minHeight: 80 }}><div className="spinner" /></div>
          ) : (
            <select
              className="form-select"
              value={selectedSectionId}
              onChange={e => setSelectedSectionId(e.target.value)}
            >
              {sections.length === 0 && <option value="">No sections available</option>}
              {sections.map(s => (
                <option key={s.section_id} value={s.section_id}>
                  {s.section_name} ({s.learner_count || 0} students)
                </option>
              ))}
            </select>
          )}
        </div>

        <div className="modal__actions" style={{ marginTop: 24 }}>
          <button className="btn btn--ghost" onClick={onClose} disabled={loading}>
            Cancel
          </button>
          <button
            className="btn btn--primary"
            onClick={() => onConfirm(selectedSectionId)}
            disabled={loading || !selectedSectionId}
          >
            {loading ? <span className="spinner spinner--sm" /> : 'Assign Section'}
          </button>
        </div>
      </div>
    </div>
  );
}
