import { useState, useEffect, useCallback, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import AdminNav from '../components/AdminNav';
import ConfirmDeleteDialog from '../components/ConfirmDeleteDialog';
import { CategoryService } from '../services/CategoryService';
import { LessonService } from '../services/LessonService';
import { SectionService } from '../services/SectionService';
import { useAdminAuth } from '../hooks/useAdminAuth';

const MODULE_4_OPTIONS = [
  { id: 'MULTIPLE_CHOICE',          label: 'Multiple Choice',         desc: '4-option recognition question' },
  { id: 'MATCHING',                 label: 'Word Matching',            desc: 'Match word to English/Cebuano meaning' },
  { id: 'FILL_IN_BLANK',            label: 'Fill in Blank',            desc: 'Type the missing word in context' },
  { id: 'WORD_SCRAMBLE',            label: 'Word Scramble',            desc: 'Arrange scrambled letter tiles' },
  { id: 'SENTENCE_RECONSTRUCTION',  label: 'Sentence Reconstruction',  desc: 'Arrange scrambled sentence tiles' },
  { id: 'TRUE_OR_FALSE',            label: 'True or False',            desc: 'Evaluate word/definition validity' },
];

const DEFAULT_MODULE_4 = 'MULTIPLE_CHOICE;MATCHING;FILL_IN_BLANK;WORD_SCRAMBLE';

export default function CategoryManagementPage() {
  const navigate = useNavigate();
  const { admin } = useAdminAuth();
  const isTeacher = admin?.role?.toLowerCase() === 'teacher' || admin?.role?.toUpperCase() === 'ROLE_TEACHER';

  const [categories, setCategories] = useState([]);
  const [lessons, setLessons] = useState([]);
  const [classes, setClasses] = useState([]);
  const [filterClassId, setFilterClassId] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [modal, setModal] = useState(null);
  const [selected, setSelected] = useState(null);
  const [form, setForm] = useState({
    category_name: '',
    description: '',
    class_id: '',
    module4_activities: DEFAULT_MODULE_4,
  });
  const [submitting, setSubmitting] = useState(false);
  const [modalError, setModalError] = useState('');
  const [dragging, setDragging] = useState(null);

  const isModule4OptionSelected = (optId) => {
    const raw = form.module4_activities || DEFAULT_MODULE_4;
    const list = raw.split(';').filter(Boolean);
    return list.includes(optId);
  };

  const toggleModule4Option = (optId) => {
    const raw = form.module4_activities || DEFAULT_MODULE_4;
    const list = raw.split(';').filter(Boolean);
    let nextList;
    if (list.includes(optId)) {
      if (list.length <= 1) return;
      nextList = list.filter(id => id !== optId);
    } else {
      nextList = [...list, optId];
    }
    setForm(f => ({ ...f, module4_activities: nextList.join(';') }));
  };

  const flash = (msg) => { setSuccess(msg); setTimeout(() => setSuccess(''), 3500); };

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const [catList, lesList, clsList] = await Promise.all([
        CategoryService.getAll(filterClassId || undefined),
        LessonService.getAll().catch(() => []),
        isTeacher ? SectionService.getAllSections().catch(() => []) : Promise.resolve([]),
      ]);
      setCategories(catList || []);
      setLessons(lesList || []);
      if (clsList) setClasses(clsList);
    } catch {
      setError('Failed to load categories.');
    } finally {
      setLoading(false);
    }
  }, [filterClassId, isTeacher]);

  useEffect(() => { load(); }, [load]);

  // Compute lesson count per category in active scope
  const lessonCountsByCat = useMemo(() => {
    const counts = {};
    for (const l of lessons) {
      if (l.category_id) {
        counts[l.category_id] = (counts[l.category_id] || 0) + 1;
      }
    }
    return counts;
  }, [lessons]);

  const openModal = (type, cat) => {
    setSelected(cat ?? null);
    const defaultClassId = filterClassId || (classes[0]?.section_id || classes[0]?.class_id || '');
    setForm({
      category_name: cat?.category_name ?? '',
      description: cat?.description ?? '',
      class_id: cat?.class_id ?? defaultClassId,
      module4_activities: cat?.module4_activities ?? DEFAULT_MODULE_4,
    });
    setModalError('');
    setModal(type);
  };

  const closeModal = () => { setModal(null); setSelected(null); setModalError(''); };

  const handleCreate = async () => {
    if (!form.category_name.trim()) { setModalError('Name is required'); return; }
    if (isTeacher && !form.class_id) {
      setModalError('Please select a classroom for this category');
      return;
    }
    setSubmitting(true);
    try {
      await CategoryService.create({
        category_name: form.category_name.trim(),
        description: form.description.trim(),
        class_id: isTeacher ? form.class_id : null,
        module4_activities: form.module4_activities || DEFAULT_MODULE_4,
      });
      flash('Category created!');
      closeModal();
      load();
    } catch (err) {
      setModalError(err?.message || 'Failed to create category');
    } finally { setSubmitting(false); }
  };

  const handleUpdate = async () => {
    if (!selected) return;
    if (isTeacher && !form.class_id) {
      setModalError('Please select a classroom for this category');
      return;
    }
    setSubmitting(true);
    try {
      await CategoryService.update(selected.category_id, {
        category_name: form.category_name.trim(),
        description: form.description.trim(),
        class_id: isTeacher ? form.class_id : null,
        module4_activities: form.module4_activities || DEFAULT_MODULE_4,
      });
      flash('Category updated!');
      closeModal();
      load();
    } catch (err) {
      setModalError(err?.message || 'Failed to update category');
    } finally { setSubmitting(false); }
  };

  const handleDelete = async () => {
    if (!selected) return;
    setSubmitting(true);
    try {
      await CategoryService.delete(selected.category_id);
      flash('Category deleted.');
      closeModal();
      load();
    } catch (err) {
      setModalError(err?.message || 'Failed to delete category');
    } finally { setSubmitting(false); }
  };

  const handleDragStart = (id) => {
    setDragging(id);
  };

  const handleDragOver = (e, targetId) => {
    e.preventDefault();
    if (!dragging || dragging === targetId) return;
    const from = categories.findIndex(c => c.category_id === dragging);
    const to = categories.findIndex(c => c.category_id === targetId);
    if (from === -1 || to === -1) return;
    const reordered = [...categories];
    const [moved] = reordered.splice(from, 1);
    reordered.splice(to, 0, moved);
    setCategories(reordered);
  };

  const handleDragEnd = async () => {
    setDragging(null);
    const orders = {};
    categories.forEach((c, i) => { orders[c.category_id] = i + 1; });
    try {
      await CategoryService.reorder(orders);
      flash('Order saved!');
    } catch {
      setError('Failed to save order. Please try again.');
      load();
    }
  };

  return (
    <div className="admin-layout">
      <AdminNav />
      <main className="admin-main" style={{ maxWidth: 840 }}>
        <header className="admin-main__header">
          <div>
            <button className="btn btn--ghost btn--sm" style={{ marginBottom: 12 }}
              onClick={() => navigate('/lessons')}>
              ← Back to Lessons
            </button>
            <h1 className="admin-main__title">
              {isTeacher ? '🗂️ My Classroom Categories' : '🗂️ Category Management'}
            </h1>
            <p className="admin-main__subtitle">
              {isTeacher
                ? 'Create and manage custom vocabulary categories for your classroom lessons'
                : 'Drag to reorder · Click ✏️ to edit · Cannot delete categories with lessons'}
            </p>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            {isTeacher ? (
              <span style={{
                padding: '4px 10px',
                borderRadius: 8,
                background: 'rgba(99, 102, 241, 0.1)',
                border: '1px solid rgba(99, 102, 241, 0.25)',
                fontSize: '0.75rem',
                fontWeight: 700,
                color: '#4f46e5',
                letterSpacing: '0.04em',
              }}>
                TEACHER CATEGORIES
              </span>
            ) : (
              <span style={{
                padding: '4px 10px',
                borderRadius: 8,
                background: 'rgba(16, 185, 129, 0.1)',
                border: '1px solid rgba(16, 185, 129, 0.25)',
                fontSize: '0.75rem',
                fontWeight: 700,
                color: '#059669',
                letterSpacing: '0.04em',
              }}>
                GLOBAL CURRICULUM
              </span>
            )}
            <button className="btn btn--ghost" onClick={() => navigate('/cumulative')}>🎓 Cumulative Review</button>
            <button className="btn btn--primary" onClick={() => openModal('create')}>+ New Category</button>
          </div>
        </header>

        {/* Informative Teacher POV Banner */}
        {isTeacher && (
          <div style={{
            background: 'linear-gradient(135deg, rgba(99, 102, 241, 0.08), rgba(79, 70, 229, 0.04))',
            border: '1.5px solid rgba(99, 102, 241, 0.25)',
            borderRadius: 'var(--radius-lg)',
            padding: '14px 18px',
            marginBottom: 20,
            display: 'flex',
            alignItems: 'center',
            gap: 12,
          }}>
            <span style={{ fontSize: '1.4rem' }}>🏷️</span>
            <div>
              <div style={{ fontWeight: 800, fontSize: '0.92rem', color: '#4338ca' }}>
                Classroom Category Workspace
              </div>
              <div style={{ fontSize: '0.8rem', color: '#6366f1', marginTop: 2 }}>
                Categories created here are exclusively yours and will be used to organize your classroom lessons. Global curriculum categories are managed separately by administrators.
              </div>
            </div>
          </div>
        )}

        {error && <div className="alert alert--error" onClick={() => setError('')}>{error}</div>}
        {success && <div className="alert alert--success">{success}</div>}

        {/* Classroom Filter for Teachers */}
        {isTeacher && classes.length > 0 && (
          <div style={{
            display: 'flex',
            alignItems: 'center',
            gap: 12,
            marginBottom: 16,
            background: '#ffffff',
            border: '1px solid var(--color-border, #e2e8f0)',
            borderRadius: 'var(--radius-md, 10px)',
            padding: '10px 14px',
          }}>
            <span style={{ fontSize: '0.86rem', fontWeight: 700, color: '#334155' }}>
              Filter by Classroom:
            </span>
            <select
              className="form-select"
              style={{ maxWidth: 280, fontSize: '0.85rem' }}
              value={filterClassId}
              onChange={e => setFilterClassId(e.target.value)}
            >
              <option value="">🏫 All My Classes</option>
              {classes.map(cls => {
                const cid = cls.section_id || cls.class_id;
                const cname = cls.section_name || cls.name || 'Class';
                return <option key={cid} value={cid}>🏫 {cname}</option>;
              })}
            </select>
          </div>
        )}

        {loading ? (
          <div className="auth-loading" style={{ minHeight: 300 }}><div className="spinner" /></div>
        ) : (
          <div className="category-list">
            {categories.length === 0 && (
              <div className="coming-soon" style={{ padding: 40, textAlign: 'center' }}>
                <div className="coming-soon__icon">🗂️</div>
                <p className="coming-soon__text" style={{ fontWeight: 600, fontSize: '1rem', marginTop: 8 }}>
                  {isTeacher ? 'No classroom categories yet.' : 'No categories yet.'}
                </p>
                <p style={{ color: 'var(--color-text-muted)', fontSize: '0.85rem', maxWidth: 420, margin: '8px auto 16px' }}>
                  {isTeacher
                    ? 'Create your first category so you can organize and assign classroom lessons to your students.'
                    : 'Create global categories to organize vocabulary curriculum.'}
                </p>
                <button className="btn btn--primary btn--sm" onClick={() => openModal('create')}>
                  + Create Your First Category
                </button>
              </div>
            )}
            {categories.map((cat, index) => {
              const myLessonCount = lessonCountsByCat[cat.category_id] || 0;
              return (
                <div
                  key={cat.category_id}
                  className={`category-card ${dragging === cat.category_id ? 'category-card--dragging' : ''}`}
                  draggable
                  onDragStart={() => handleDragStart(cat.category_id)}
                  onDragOver={e => handleDragOver(e, cat.category_id)}
                  onDragEnd={handleDragEnd}
                >
                  <div className="category-card__handle">⣿</div>
                  <div className="category-card__body">
                    <div style={{ display: 'flex', alignItems: 'center', gap: 10, flexWrap: 'wrap' }}>
                      <div className="category-card__name">{cat.category_name}</div>
                      {cat.class_name && (
                        <span style={{
                          padding: '2px 8px',
                          borderRadius: 12,
                          fontSize: '0.72rem',
                          fontWeight: 700,
                          background: 'rgba(99, 102, 241, 0.1)',
                          color: '#4f46e5',
                          border: '1px solid rgba(99, 102, 241, 0.25)',
                        }}>
                          🏫 {cat.class_name}
                        </span>
                      )}
                      {isTeacher ? (
                        <span style={{
                          padding: '2px 8px',
                          borderRadius: 12,
                          fontSize: '0.72rem',
                          fontWeight: 700,
                          background: myLessonCount > 0 ? 'rgba(16,185,129,0.1)' : 'rgba(100,116,139,0.1)',
                          color: myLessonCount > 0 ? '#059669' : '#64748b',
                          border: `1px solid ${myLessonCount > 0 ? 'rgba(16,185,129,0.25)' : 'rgba(100,116,139,0.2)'}`,
                        }}>
                          {myLessonCount > 0 ? `📖 ${myLessonCount} of your lessons` : '0 classroom lessons'}
                        </span>
                      ) : (
                        <span style={{
                          padding: '2px 8px',
                          borderRadius: 12,
                          fontSize: '0.72rem',
                          fontWeight: 700,
                          background: myLessonCount > 0 ? 'rgba(37,99,235,0.1)' : 'rgba(100,116,139,0.1)',
                          color: myLessonCount > 0 ? '#2563eb' : '#64748b',
                          border: `1px solid ${myLessonCount > 0 ? 'rgba(37,99,235,0.2)' : 'rgba(100,116,139,0.2)'}`,
                        }}>
                          {myLessonCount} {myLessonCount === 1 ? 'lesson' : 'lessons'}
                        </span>
                      )}
                    </div>
                    {cat.description && (
                      <div className="category-card__desc">{cat.description}</div>
                    )}
                  </div>
                  <div className="category-card__order">#{index + 1}</div>
                  <div className="actions-cell">
                    {isTeacher && (
                      <button
                        type="button"
                        className="btn btn--sm btn--ghost"
                        onClick={() => navigate('/lessons', { state: { filterCategory: cat.category_id } })}
                        title="View lessons in this category"
                        style={{ fontSize: '0.78rem' }}
                      >
                        📖 Lessons →
                      </button>
                    )}
                    <button className="btn btn--sm btn--ghost" onClick={() => openModal('edit', cat)} title="Edit category">✏️</button>
                    <button className="btn btn--sm btn--danger-ghost" onClick={() => openModal('delete', cat)} title="Delete category">🗑️</button>
                  </div>
                </div>
              );
            })}
          </div>
        )}

        {/* Create Modal */}
        {modal === 'create' && (
          <div className="modal-overlay" onClick={closeModal}>
            <div className="modal" onClick={e => e.stopPropagation()}>
              <h2 className="modal__title">➕ New Category</h2>
              {modalError && <div className="alert alert--error">{modalError}</div>}
              <div className="form-field">
                <label className="form-label">Category Name *</label>
                <input className="form-input" autoFocus value={form.category_name}
                  onChange={e => setForm(f => ({ ...f, category_name: e.target.value }))}
                  placeholder="e.g. Animals, School Objects" />
              </div>
              {isTeacher ? (
                <div className="form-field">
                  <label className="form-label">Classroom * (Target Class)</label>
                  {classes.length === 0 ? (
                    <div style={{ padding: '8px 12px', background: 'rgba(239, 68, 68, 0.08)', borderRadius: 8, color: '#dc2626', fontSize: '0.82rem' }}>
                      ⚠️ No classrooms found. Please create a classroom first.
                    </div>
                  ) : (
                    <select
                      className="form-select"
                      value={form.class_id}
                      onChange={e => setForm(f => ({ ...f, class_id: e.target.value }))}
                    >
                      {classes.map(cls => {
                        const cid = cls.section_id || cls.class_id;
                        const cname = cls.section_name || cls.name || 'Class';
                        return <option key={cid} value={cid}>🏫 {cname}</option>;
                      })}
                    </select>
                  )}
                  <span style={{ fontSize: '0.74rem', color: '#64748b', marginTop: 3 }}>
                    This category will belong strictly to this specific class.
                  </span>
                </div>
              ) : (
                <div className="form-field">
                  <label className="form-label">Scope</label>
                  <div style={{
                    padding: '8px 12px',
                    borderRadius: 8,
                    background: 'rgba(16, 185, 129, 0.08)',
                    border: '1px solid rgba(16, 185, 129, 0.25)',
                    color: '#059669',
                    fontSize: '0.82rem',
                    fontWeight: 600,
                  }}>
                    🌍 Global Curriculum (Visible to All Learners)
                  </div>
                </div>
              )}
              <div className="form-field">
                <label className="form-label">Description</label>
                <textarea className="form-textarea" rows={2} value={form.description}
                  onChange={e => setForm(f => ({ ...f, description: e.target.value }))}
                  placeholder="Optional description..." />
              </div>

              <div className="form-field" style={{ marginTop: 8, padding: '14px', background: '#f8fafc', borderRadius: 10, border: '1px solid #e2e8f0' }}>
                <label className="form-label" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 4 }}>
                  <span style={{ fontWeight: 700, color: '#1e293b' }}>🎓 Module 4 (Cumulative Review) Formats</span>
                  <span style={{ fontSize: '0.75rem', fontWeight: 600, color: '#4f46e5', background: '#e0e7ff', padding: '2px 8px', borderRadius: 4 }}>Category Default</span>
                </label>
                <p style={{ fontSize: '0.8rem', color: '#64748b', margin: '0 0 10px 0' }}>
                  These activity formats will be used during Cumulative Review across all lessons in this category.
                </p>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px' }}>
                  {MODULE_4_OPTIONS.map(opt => {
                    const active = isModule4OptionSelected(opt.id);
                    return (
                      <label
                        key={opt.id}
                        style={{
                          display: 'flex', alignItems: 'center', gap: 8, padding: '8px 12px',
                          border: active ? '1.5px solid #4f46e5' : '1px solid #cbd5e1',
                          borderRadius: 8, background: active ? '#eef2ff' : '#fff', cursor: 'pointer',
                          fontSize: '0.85rem', fontWeight: active ? 600 : 500, color: active ? '#312e81' : '#475569'
                        }}
                      >
                        <input
                          type="checkbox"
                          checked={active}
                          onChange={() => toggleModule4Option(opt.id)}
                        />
                        <span>{opt.label}</span>
                      </label>
                    );
                  })}
                </div>
              </div>

              <div className="modal__actions">
                <button className="btn btn--ghost" onClick={closeModal} disabled={submitting}>Cancel</button>
                <button className="btn btn--primary" onClick={handleCreate} disabled={submitting}>
                  {submitting ? <span className="spinner spinner--sm" /> : 'Create'}
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Edit Modal */}
        {modal === 'edit' && selected && (
          <div className="modal-overlay" onClick={closeModal}>
            <div className="modal" onClick={e => e.stopPropagation()}>
              <h2 className="modal__title">✏️ Edit Category</h2>
              {modalError && <div className="alert alert--error">{modalError}</div>}
              <div className="form-field">
                <label className="form-label">Category Name *</label>
                <input className="form-input" autoFocus value={form.category_name}
                  onChange={e => setForm(f => ({ ...f, category_name: e.target.value }))} />
              </div>
              {isTeacher && classes.length > 0 && (
                <div className="form-field">
                  <label className="form-label">Classroom</label>
                  <select
                    className="form-select"
                    value={form.class_id}
                    onChange={e => setForm(f => ({ ...f, class_id: e.target.value }))}
                  >
                    {classes.map(cls => {
                      const cid = cls.section_id || cls.class_id;
                      const cname = cls.section_name || cls.name || 'Class';
                      return <option key={cid} value={cid}>🏫 {cname}</option>;
                    })}
                  </select>
                </div>
              )}
              <div className="form-field">
                <label className="form-label">Description</label>
                <textarea className="form-textarea" rows={2} value={form.description}
                  onChange={e => setForm(f => ({ ...f, description: e.target.value }))} />
              </div>

              <div className="form-field" style={{ marginTop: 8, padding: '14px', background: '#f8fafc', borderRadius: 10, border: '1px solid #e2e8f0' }}>
                <label className="form-label" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 4 }}>
                  <span style={{ fontWeight: 700, color: '#1e293b' }}>🎓 Module 4 (Cumulative Review) Formats</span>
                  <span style={{ fontSize: '0.75rem', fontWeight: 600, color: '#4f46e5', background: '#e0e7ff', padding: '2px 8px', borderRadius: 4 }}>Category Default</span>
                </label>
                <p style={{ fontSize: '0.8rem', color: '#64748b', margin: '0 0 10px 0' }}>
                  These activity formats will be used during Cumulative Review across all lessons in this category.
                </p>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px' }}>
                  {MODULE_4_OPTIONS.map(opt => {
                    const active = isModule4OptionSelected(opt.id);
                    return (
                      <label
                        key={opt.id}
                        style={{
                          display: 'flex', alignItems: 'center', gap: 8, padding: '8px 12px',
                          border: active ? '1.5px solid #4f46e5' : '1px solid #cbd5e1',
                          borderRadius: 8, background: active ? '#eef2ff' : '#fff', cursor: 'pointer',
                          fontSize: '0.85rem', fontWeight: active ? 600 : 500, color: active ? '#312e81' : '#475569'
                        }}
                      >
                        <input
                          type="checkbox"
                          checked={active}
                          onChange={() => toggleModule4Option(opt.id)}
                        />
                        <span>{opt.label}</span>
                      </label>
                    );
                  })}
                </div>
              </div>

              <div className="modal__actions">
                <button className="btn btn--ghost" onClick={closeModal} disabled={submitting}>Cancel</button>
                <button className="btn btn--primary" onClick={handleUpdate} disabled={submitting}>
                  {submitting ? <span className="spinner spinner--sm" /> : 'Save'}
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Delete confirm */}
        {modal === 'delete' && selected && (
          <ConfirmDeleteDialog
            title="Delete Category"
            message={`Delete "${selected.category_name}"? This cannot be undone. Categories with lessons cannot be deleted.`}
            onConfirm={handleDelete}
            onCancel={closeModal}
            loading={submitting}
          />
        )}
      </main>
    </div>
  );
}
