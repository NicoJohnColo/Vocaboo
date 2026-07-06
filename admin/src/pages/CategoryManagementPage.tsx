import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import AdminNav from '../components/AdminNav';
import ConfirmDeleteDialog from '../components/ConfirmDeleteDialog';
import { CategoryService, type AdminCategory } from '../services/CategoryService';

type ModalType = 'create' | 'edit' | 'delete' | null;

interface CategoryForm {
  category_name: string;
  description: string;
}

export default function CategoryManagementPage() {
  const navigate = useNavigate();
  const [categories, setCategories] = useState<AdminCategory[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [modal, setModal] = useState<ModalType>(null);
  const [selected, setSelected] = useState<AdminCategory | null>(null);
  const [form, setForm] = useState<CategoryForm>({ category_name: '', description: '' });
  const [submitting, setSubmitting] = useState(false);
  const [modalError, setModalError] = useState('');
  const [dragging, setDragging] = useState<string | null>(null);

  const flash = (msg: string) => { setSuccess(msg); setTimeout(() => setSuccess(''), 3500); };

  const load = useCallback(async () => {
    setLoading(true);
    try {
      setCategories(await CategoryService.getAll());
    } catch {
      setError('Failed to load categories.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  const openModal = (type: ModalType, cat?: AdminCategory) => {
    setSelected(cat ?? null);
    setForm({ category_name: cat?.category_name ?? '', description: cat?.description ?? '' });
    setModalError('');
    setModal(type);
  };

  const closeModal = () => { setModal(null); setSelected(null); setModalError(''); };

  const handleCreate = async () => {
    if (!form.category_name.trim()) { setModalError('Name is required'); return; }
    setSubmitting(true);
    try {
      await CategoryService.create({ category_name: form.category_name.trim(), description: form.description.trim() });
      flash('Category created!');
      closeModal();
      load();
    } catch (err: unknown) {
      setModalError(err instanceof Error ? err.message : 'Failed to create category');
    } finally { setSubmitting(false); }
  };

  const handleUpdate = async () => {
    if (!selected) return;
    setSubmitting(true);
    try {
      await CategoryService.update(selected.category_id, { category_name: form.category_name.trim(), description: form.description.trim() });
      flash('Category updated!');
      closeModal();
      load();
    } catch (err: unknown) {
      setModalError(err instanceof Error ? err.message : 'Failed to update category');
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
    } catch (err: unknown) {
      setModalError(err instanceof Error ? err.message : 'Failed to delete category');
    } finally { setSubmitting(false); }
  };

  // Drag-to-reorder
  const handleDragStart = (id: string) => setDragging(id);
  const handleDragOver = (e: React.DragEvent, targetId: string) => {
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
    const orders: Record<string, number> = {};
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
      <main className="admin-main" style={{ maxWidth: 800 }}>
        <header className="admin-main__header">
          <div>
            <button className="btn btn--ghost btn--sm" style={{ marginBottom: 12 }}
              onClick={() => navigate('/lessons')}>
              ← Back to Lessons
            </button>
            <h1 className="admin-main__title">🗂️ Category Management</h1>
            <p className="admin-main__subtitle">Drag to reorder · Click ✏️ to edit · Cannot delete categories with lessons</p>
          </div>
          <button className="btn btn--primary" onClick={() => openModal('create')}>+ New Category</button>
        </header>

        {error && <div className="alert alert--error" onClick={() => setError('')}>{error}</div>}
        {success && <div className="alert alert--success">{success}</div>}

        {loading ? (
          <div className="auth-loading" style={{ minHeight: 300 }}><div className="spinner" /></div>
        ) : (
          <div className="category-list">
            {categories.length === 0 && (
              <div className="coming-soon" style={{ padding: 40 }}>
                <div className="coming-soon__icon">🗂️</div>
                <p className="coming-soon__text">No categories yet. Click <strong>+ New Category</strong> to create one.</p>
              </div>
            )}
            {categories.map((cat, index) => (
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
                  <div className="category-card__name">{cat.category_name}</div>
                  {cat.description && (
                    <div className="category-card__desc">{cat.description}</div>
                  )}
                </div>
                <div className="category-card__order">#{index + 1}</div>
                <div className="actions-cell">
                  <button className="btn btn--sm btn--ghost" onClick={() => openModal('edit', cat)}>✏️</button>
                  <button className="btn btn--sm btn--danger-ghost" onClick={() => openModal('delete', cat)}>🗑️</button>
                </div>
              </div>
            ))}
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
                  placeholder="e.g. School Objects" />
              </div>
              <div className="form-field">
                <label className="form-label">Description</label>
                <textarea className="form-textarea" rows={2} value={form.description}
                  onChange={e => setForm(f => ({ ...f, description: e.target.value }))}
                  placeholder="Optional description..." />
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
              <div className="form-field">
                <label className="form-label">Description</label>
                <textarea className="form-textarea" rows={2} value={form.description}
                  onChange={e => setForm(f => ({ ...f, description: e.target.value }))} />
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
