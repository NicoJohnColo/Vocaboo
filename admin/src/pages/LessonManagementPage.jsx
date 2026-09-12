import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import AdminNav from '../components/AdminNav';
import LessonTable from '../components/LessonTable';
import CreateLessonModal from '../components/CreateLessonModal';
import EditLessonModal from '../components/EditLessonModal';
import ConfirmDeleteDialog from '../components/ConfirmDeleteDialog';
import PublishWorkflowModal from '../components/PublishWorkflowModal';
import { LessonService } from '../services/LessonService';
import { CategoryService } from '../services/CategoryService';
import { SectionService } from '../services/SectionService';
import { useAdminAuth } from '../hooks/useAdminAuth';

export default function LessonManagementPage() {
  const navigate = useNavigate();
  const { admin } = useAdminAuth();
  const isTeacher = admin?.role?.toLowerCase() === 'teacher' || admin?.role?.toUpperCase() === 'ROLE_TEACHER';

  const [lessons, setLessons] = useState([]);
  const [categories, setCategories] = useState([]);
  const [classes, setClasses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [modal, setModal] = useState(null);
  const [selected, setSelected] = useState(null);
  const [submitting, setSubmitting] = useState(false);
  const [modalError, setModalError] = useState('');
  const [searchQuery, setSearchQuery] = useState('');
  const [filterCategory, setFilterCategory] = useState('');
  const [filterGrade, setFilterGrade] = useState('');
  const [filterClass, setFilterClass] = useState('');
  const [togglingId, setTogglingId] = useState(null);

  const flash = (msg) => {
    setSuccess(msg);
    setTimeout(() => setSuccess(''), 3500);
  };

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const [l, c, clsList] = await Promise.all([
        LessonService.getAll(),
        CategoryService.getAll(),
        SectionService.getAllSections().catch(() => [])
      ]);
      setLessons(l);
      setCategories(c);
      setClasses(clsList);
    } catch {
      setError('Failed to load lessons or categories.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  const openModal = (type, lesson) => {
    setSelected(lesson ?? null);
    setModalError('');
    setModal(type);
  };

  const closeModal = () => { setModal(null); setSelected(null); setModalError(''); };

  const handleCreate = async (data) => {
    setSubmitting(true);
    try {
      await LessonService.create(data);
      flash('Lesson created successfully!');
      closeModal();
      load();
    } catch (err) {
      setModalError(err?.message || 'Failed to create lesson');
    } finally {
      setSubmitting(false);
    }
  };

  const handleUpdate = async (data) => {
    if (!selected) return;
    setSubmitting(true);
    try {
      await LessonService.update(selected.lesson_id, data);
      flash('Lesson updated successfully!');
      closeModal();
      load();
    } catch (err) {
      setModalError(err?.message || 'Failed to update lesson');
    } finally {
      setSubmitting(false);
    }
  };

  const handleDelete = async () => {
    if (!selected) return;
    setSubmitting(true);
    try {
      await LessonService.delete(selected.lesson_id);
      flash('Lesson deleted successfully.');
      closeModal();
      load();
    } catch (err) {
      setModalError(err?.message || 'Failed to delete lesson');
    } finally {
      setSubmitting(false);
    }
  };

  const handlePublish = async (status, targetGrades) => {
    if (!selected) return;
    setSubmitting(true);
    try {
      await LessonService.updateStatus(selected.lesson_id, status, targetGrades);
      flash(`Lesson status updated to ${status}.`);
      closeModal();
      load();
    } catch (err) {
      setModalError(err?.message || 'Failed to update status');
    } finally {
      setSubmitting(false);
    }
  };

  const handleQuickTogglePublish = async (lesson) => {
    const isCurrentlyPublished = lesson.content_status === 'PUBLISHED';
    const newStatus = isCurrentlyPublished ? 'DRAFT' : 'PUBLISHED';
    const targetGrades = lesson.target_grades ? lesson.target_grades.split(',') : (lesson.grade_level ? [lesson.grade_level] : ['GRADE_4', 'GRADE_5', 'GRADE_6']);

    setTogglingId(lesson.lesson_id);
    setError('');
    try {
      await LessonService.updateStatus(lesson.lesson_id, newStatus, targetGrades);
      flash(`"${lesson.lesson_title}" is now ${newStatus === 'PUBLISHED' ? '🚀 Published' : '📝 set to Draft'}.`);
      await load();
    } catch (err) {
      setError(err?.message || `Failed to update status for "${lesson.lesson_title}". Note: Lessons require at least 5 vocabulary words before publishing.`);
    } finally {
      setTogglingId(null);
    }
  };

  return (
    <div className="admin-layout">
      <AdminNav />
      <main className="admin-main" style={{ maxWidth: '100%' }}>
        <header className="admin-main__header">
          <div>
            <h1 className="admin-main__title">Lesson Management</h1>
            <p className="admin-main__subtitle">Create, organize, and publish vocabulary lessons for learners</p>
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            <button
              className="btn btn--ghost btn--sm"
              onClick={() => navigate('/categories')}
            >
              🗂️ Categories
            </button>
          </div>
        </header>

        {error   && <div className="alert alert--error"   onClick={() => setError('')}>{error}</div>}
        {success && <div className="alert alert--success">{success}</div>}

        <LessonTable
          lessons={lessons}
          categories={categories}
          classes={classes}
          filterClass={filterClass}
          onFilterClass={setFilterClass}
          isTeacher={isTeacher}
          searchQuery={searchQuery}
          onSearchChange={setSearchQuery}
          filterCategory={filterCategory}
          onFilterCategory={setFilterCategory}
          filterGrade={filterGrade}
          onFilterGrade={setFilterGrade}
          onCreate={() => openModal('create')}
          onEdit={l => openModal('edit', l)}
          onDelete={l => openModal('delete', l)}
          onViewWords={l => navigate(`/lessons/${l.lesson_id}/vocabulary`, { state: { lesson: l } })}
          onPublish={l => openModal('publish', l)}
          onTogglePublish={handleQuickTogglePublish}
          togglingId={togglingId}
          loading={loading}
        />

        {/* Modals */}
        {modal === 'create' && (
          <CreateLessonModal
            categories={categories}
            classes={classes}
            isTeacher={isTeacher}
            onSubmit={handleCreate}
            onClose={closeModal}
            submitting={submitting}
            error={modalError}
          />
        )}
        {modal === 'edit' && selected && (
          <EditLessonModal
            lesson={selected}
            classes={classes}
            isTeacher={isTeacher}
            onSubmit={handleUpdate}
            onClose={closeModal}
            submitting={submitting}
            error={modalError}
          />
        )}
        {modal === 'delete' && selected && (
          <ConfirmDeleteDialog
            title="Delete Lesson"
            message={`Are you sure you want to delete "${selected.lesson_title}"? This will also delete all vocabulary words in this lesson. This action cannot be undone.`}
            onConfirm={handleDelete}
            onCancel={closeModal}
            loading={submitting}
          />
        )}
        {modal === 'publish' && selected && (
          <PublishWorkflowModal
            lesson={selected}
            onSubmit={handlePublish}
            onClose={closeModal}
            submitting={submitting}
            error={modalError}
          />
        )}
      </main>
    </div>
  );
}
