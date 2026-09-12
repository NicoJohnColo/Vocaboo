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
          // Sort naturally by grade and name (e.g. Grade 4 -> Grade 5 -> Grade 6)
          const sorted = [...list].sort((a, b) => {
            const na = a.section_name || '';
            const nb = b.section_name || '';
            return na.localeCompare(nb, undefined, { numeric: true, sensitivity: 'base' });
          });

          setSections(sorted);

          if (sorted.length > 0) {
            // Intelligent preselection based on learner's existing section or grade
            const target = Array.isArray(learners) ? learners[0] : learners;
            const existingSecId = target?.section_id || target?.sectionId || target?.class_id || target?.classId;
            const existingGrade = (target?.grade_level || target?.gradeLevel || '').replace('GRADE_', 'Grade ');

            let matchedId = '';
            if (existingSecId && sorted.some(s => s.section_id === existingSecId)) {
              matchedId = existingSecId;
            } else if (existingGrade) {
              const byGrade = sorted.find(s => s.section_name && s.section_name.includes(existingGrade));
              if (byGrade) matchedId = byGrade.section_id;
            }

            setSelectedSectionId(matchedId || sorted[0].section_id);
          }
          setLoadingSections(false);
        }
      })
      .catch(() => {
        if (!cancelled) setLoadingSections(false);
      });
    return () => { cancelled = true; };
  }, [learners]);

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
