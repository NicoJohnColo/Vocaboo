import { useState, useEffect, useCallback } from 'react';
import AdminNav from '../components/AdminNav';
import { SectionService } from '../services/SectionService';
import ConfirmDeleteDialog from '../components/ConfirmDeleteDialog';

export default function ClassManagementPage() {
  const [sections, setSections] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  // Modals
  const [modalMode, setModalMode] = useState(null); // 'create' | 'edit' | 'delete' | null
  const [selectedSection, setSelectedSection] = useState(null);
  const [sectionName, setSectionName] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [modalError, setModalError] = useState('');

  const flash = (msg) => { setSuccess(msg); setTimeout(() => setSuccess(''), 3500); };

  const loadSections = useCallback(async () => {
    setLoading(true);
    try {
      const list = await SectionService.getAllSections();
      setSections(list);
    } catch {
      setError('Failed to load class sections.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { loadSections(); }, [loadSections]);

  const openCreate = () => {
    setSelectedSection(null);
    setSectionName('');
    setModalError('');
    setModalMode('create');
  };

  const openEdit = (sec) => {
    setSelectedSection(sec);
    setSectionName(sec.section_name);
    setModalError('');
    setModalMode('edit');
  };

  const openDelete = (sec) => {
    setSelectedSection(sec);
    setModalError('');
    setModalMode('delete');
  };

  const closeModal = () => {
    setModalMode(null);
    setSelectedSection(null);
    setSectionName('');
    setModalError('');
  };

  const handleCreate = async () => {
    if (!sectionName.trim()) { setModalError('Section name is required'); return; }
    setSubmitting(true);
    try {
      await SectionService.createSection(sectionName.trim());
      flash('Class section created successfully!');
      closeModal();
      loadSections();
    } catch (err) {
      setModalError(err?.message || 'Failed to create section');
    } finally {
      setSubmitting(false);
    }
  };

  const handleUpdate = async () => {
    if (!selectedSection || !sectionName.trim()) return;
    setSubmitting(true);
    try {
      await SectionService.updateSection(selectedSection.section_id, sectionName.trim());
      flash('Class section renamed successfully!');
      closeModal();
      loadSections();
    } catch (err) {
      setModalError(err?.message || 'Failed to update section');
    } finally {
      setSubmitting(false);
    }
  };

  const handleDelete = async () => {
    if (!selectedSection) return;
    setSubmitting(true);
    try {
      await SectionService.deleteSection(selectedSection.section_id);
      flash('Class section deleted. Enrolled students have been unlinked safely.');
      closeModal();
      loadSections();
    } catch (err) {
      setModalError(err?.message || 'Failed to delete section');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="admin-layout">
      <AdminNav />
      <main className="admin-main" style={{ maxWidth: 1000 }}>
        <header className="admin-main__header">
          <div>
            <h1 className="admin-main__title">🏫 Class / Section Management</h1>
            <p className="admin-main__subtitle">Create and organize classroom cohorts and student rosters</p>
          </div>
          <button className="btn btn--primary" onClick={openCreate}>
            + New Section
          </button>
        </header>

        {error && <div className="alert alert--error" onClick={() => setError('')}>{error}</div>}
        {success && <div className="alert alert--success">{success}</div>}

        {loading ? (
          <div className="auth-loading" style={{ minHeight: 300 }}><div className="spinner" /></div>
        ) : (
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: 18 }}>
            {sections.length === 0 && (
              <div style={{ gridColumn: '1 / -1' }} className="coming-soon">
                <div className="coming-soon__icon">🏫</div>
                <div className="coming-soon__title">No sections yet</div>
                <p className="coming-soon__text">Click <strong>+ New Section</strong> to create your first classroom cohort.</p>
              </div>
            )}
            {sections.map(sec => (
              <div key={sec.section_id} className="section-card" style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between', gap: 0, marginBottom: 0 }}>
                <div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 10 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                      <div style={{
                        width: 38, height: 38, borderRadius: 10,
                        background: 'linear-gradient(135deg, #3b82f6, #1d4ed8)',
                        display: 'grid', placeItems: 'center',
                        fontSize: '1.1rem', flexShrink: 0,
                        boxShadow: '0 4px 12px rgba(37,99,235,0.25)',
                      }}>🏫</div>
                      <span style={{ fontSize: '1.0rem', fontWeight: 700, color: 'var(--color-text-main)', lineHeight: 1.2 }}>
                        {sec.section_name}
                      </span>
                    </div>
                    <div style={{
                      fontSize: '0.72rem', fontWeight: 700, padding: '3px 9px', borderRadius: 20,
                      background: 'rgba(37,99,235,0.10)', color: 'var(--primary-mid)',
                      border: '1px solid rgba(37,99,235,0.20)', flexShrink: 0,
                    }}>
                      {sec.learner_count || 0} students
                    </div>
                  </div>

                  {sec.grade_distribution && Object.keys(sec.grade_distribution).length > 0 ? (
                    <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginTop: 10 }}>
                      {Object.entries(sec.grade_distribution).map(([grade, count]) => (
                        <span key={grade} className="status-pill status-pill--neutral" style={{ fontSize: '0.68rem' }}>
                          {grade.replace('_', ' ')}: {count}
                        </span>
                      ))}
                    </div>
                  ) : (
                    <div style={{ fontSize: '0.8rem', color: 'var(--color-text-dim)', marginTop: 8 }}>
                      No students enrolled yet
                    </div>
                  )}
                </div>

                <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 8, marginTop: 18, paddingTop: 12, borderTop: '1px solid var(--color-border)' }}>
                  <button className="btn btn--sm btn--ghost" onClick={() => openEdit(sec)}>✏️ Rename</button>
                  <button className="btn btn--sm btn--danger-ghost" onClick={() => openDelete(sec)}>🗑️ Delete</button>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Create Modal */}
        {modalMode === 'create' && (
          <div className="modal-overlay" onClick={closeModal}>
            <div className="modal modal--sm" onClick={e => e.stopPropagation()}>
              <h2 className="modal__title">➕ Create Class Section</h2>
              {modalError && <div className="alert alert--error">{modalError}</div>}
              <div className="form-field" style={{ marginTop: 16 }}>
                <label className="form-label">Section Name *</label>
                <input
                  className="form-input"
                  autoFocus
                  placeholder="e.g. Grade 4 - Diamond"
                  value={sectionName}
                  onChange={e => setSectionName(e.target.value)}
                />
              </div>
              <div className="modal__actions" style={{ marginTop: 24 }}>
                <button className="btn btn--ghost" onClick={closeModal} disabled={submitting}>Cancel</button>
                <button className="btn btn--primary" onClick={handleCreate} disabled={submitting || !sectionName.trim()}>
                  {submitting ? <span className="spinner spinner--sm" /> : 'Create Section'}
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Edit Modal */}
        {modalMode === 'edit' && selectedSection && (
          <div className="modal-overlay" onClick={closeModal}>
            <div className="modal modal--sm" onClick={e => e.stopPropagation()}>
              <h2 className="modal__title">✏️ Rename Class Section</h2>
              {modalError && <div className="alert alert--error">{modalError}</div>}
              <div className="form-field" style={{ marginTop: 16 }}>
                <label className="form-label">Section Name *</label>
                <input
                  className="form-input"
                  autoFocus
                  value={sectionName}
                  onChange={e => setSectionName(e.target.value)}
                />
              </div>
              <div className="modal__actions" style={{ marginTop: 24 }}>
                <button className="btn btn--ghost" onClick={closeModal} disabled={submitting}>Cancel</button>
                <button className="btn btn--primary" onClick={handleUpdate} disabled={submitting || !sectionName.trim()}>
                  {submitting ? <span className="spinner spinner--sm" /> : 'Save Changes'}
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Delete Confirmation */}
        {modalMode === 'delete' && selectedSection && (
          <ConfirmDeleteDialog
            title="Delete Class Section"
            message={`Delete section "${selectedSection.section_name}"? All ${selectedSection.learner_count || 0} enrolled students will be unlinked safely.`}
            onConfirm={handleDelete}
            onCancel={closeModal}
            loading={submitting}
          />
        )}
      </main>
    </div>
  );
}
