import { useState, useEffect, useCallback } from 'react';
import { useNavigate, useParams, useLocation } from 'react-router-dom';
import AdminNav from '../components/AdminNav';
import VocabularyTable from '../components/VocabularyTable';
import { AddVocabularyModal, EditVocabularyModal } from '../components/VocabWordModals';
import ConfirmDeleteDialog from '../components/ConfirmDeleteDialog';
import BulkImportModal from '../components/BulkImportModal';
import ConfusablePairsModal from '../components/ConfusablePairsModal';
import { VocabularyService } from '../services/VocabularyService';
import { useAdminAuth } from '../hooks/useAdminAuth';

export default function VocabularyListPage() {
  const { admin } = useAdminAuth();
  const isTeacher = admin?.role?.toLowerCase() === 'teacher' || admin?.role?.toUpperCase() === 'ROLE_TEACHER';

  const { lessonId } = useParams();
  const navigate = useNavigate();
  const location = useLocation();
  const locationState = location.state;
  const lesson = locationState?.lesson;

  const isTeacherLesson = Boolean(lesson?.class_id || (lesson?.is_global === false));
  const isReadOnly = !isTeacher && isTeacherLesson;

  const [words, setWords] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [modal, setModal] = useState(
    locationState?.autoAdd ? 'add' :
    locationState?.openModal ? locationState.openModal : null
  );

  useEffect(() => {
    if (locationState?.autoAdd || locationState?.openModal) {
      navigate('.', { replace: true, state: { ...locationState, autoAdd: false, openModal: null } });
    }
  }, [locationState?.autoAdd, locationState?.openModal, navigate, locationState]);

  const [selected, setSelected] = useState(null);
  const [submitting, setSubmitting] = useState(false);
  const [modalError, setModalError] = useState('');

  const flash = (msg) => { setSuccess(msg); setTimeout(() => setSuccess(''), 3500); };

  const load = useCallback(async () => {
    if (!lessonId) return;
    setLoading(true);
    try {
      setWords(await VocabularyService.getWords(lessonId));
    } catch {
      setError('Failed to load vocabulary words.');
    } finally {
      setLoading(false);
    }
  }, [lessonId]);

  useEffect(() => { load(); }, [load]);

  const openModal = (type, word) => {
    setSelected(word ?? null);
    setModalError('');
    setModal(type);
  };
  const closeModal = () => { setModal(null); setSelected(null); setModalError(''); };

  const handleAdd = async (data) => {
    if (!lessonId) return;
    setSubmitting(true);
    try {
      await VocabularyService.addWord(lessonId, data);
      flash('Word added successfully!');
      closeModal();
      load();
    } catch (err) {
      setModalError(err?.message || 'Failed to add word');
    } finally { setSubmitting(false); }
  };

  const handleUpdate = async (data) => {
    if (!lessonId || !selected) return;
    setSubmitting(true);
    try {
      await VocabularyService.updateWord(lessonId, selected.word_id, data);
      flash('Word updated successfully!');
      closeModal();
      load();
    } catch (err) {
      setModalError(err?.message || 'Failed to update word');
    } finally { setSubmitting(false); }
  };

  const handleDelete = async () => {
    if (!lessonId || !selected) return;
    setSubmitting(true);
    try {
      await VocabularyService.deleteWord(lessonId, selected.word_id);
      flash('Word deleted.');
      closeModal();
      load();
    } catch (err) {
      setModalError(err?.message || 'Failed to delete word');
    } finally { setSubmitting(false); }
  };

  return (
    <div className="admin-layout">
      <AdminNav />
      <main className="admin-main" style={{ maxWidth: '100%' }}>
        <header className="admin-main__header">
          <div>
            <button className="btn btn--ghost btn--sm" style={{ marginBottom: 12 }} onClick={() => navigate('/lessons')}>
              ← Back to Lessons
            </button>
            <h1 className="admin-main__title">Vocabulary Words</h1>
            <p className="admin-main__subtitle">
              {lesson?.lesson_title ?? `Lesson ${lessonId?.slice(0, 8)}…`}
            </p>
            {lesson?.context_paragraph && (
              <div style={{ marginTop: 12, padding: 12, backgroundColor: '#F8FAFC', borderRadius: 8, border: '1px solid #E2E8F0' }}>
                <strong style={{ fontSize: 12, color: '#64748B', textTransform: 'uppercase' }}>Context Paragraph</strong>
                <p style={{ marginTop: 4, fontSize: 14, color: '#334155', fontStyle: 'italic' }}>
                  "{lesson.context_paragraph}"
                </p>
              </div>
            )}
          </div>
        </header>

        {error   && <div className="alert alert--error"   onClick={() => setError('')}>{error}</div>}
        {success && <div className="alert alert--success">{success}</div>}

        {isReadOnly && (
          <div style={{
            background: 'linear-gradient(135deg, rgba(100, 116, 139, 0.08), rgba(71, 85, 105, 0.04))',
            border: '1.5px solid rgba(100, 116, 139, 0.25)',
            borderRadius: 'var(--radius-lg)',
            padding: '12px 18px',
            marginBottom: 20,
            display: 'flex',
            alignItems: 'center',
            gap: 12,
          }}>
            <span style={{ fontSize: '1.3rem' }}>👁️</span>
            <div>
              <div style={{ fontWeight: 800, fontSize: '0.9rem', color: '#334155' }}>
                Teacher-Authored Classroom Lesson (View-Only Mode)
              </div>
              <div style={{ fontSize: '0.78rem', color: '#64748b', marginTop: 2 }}>
                This lesson is authored for a specific classroom. Administrators have view-only access to vocabulary words and cannot add, edit, or delete words.
              </div>
            </div>
          </div>
        )}

        <VocabularyTable
          words={words}
          lessonTitle={lesson?.lesson_title ?? ''}
          onAdd={() => !isReadOnly && openModal('add')}
          onEdit={w => !isReadOnly && openModal('edit', w)}
          onDelete={w => !isReadOnly && openModal('delete', w)}
          onBulkImport={() => !isReadOnly && openModal('bulk-import')}
          onConfusablePairs={() => !isReadOnly && openModal('confusable-pairs')}
          loading={loading}
          readOnly={isReadOnly}
        />

        {modal === 'bulk-import' && (
          <BulkImportModal
            lessonId={lessonId}
            lesson={lesson}
            onClose={closeModal}
            onSuccess={() => {
              load();
              flash('Vocabulary imported successfully!');
            }}
          />
        )}

        {modal === 'confusable-pairs' && (
          <ConfusablePairsModal
            lessonId={lessonId}
            lesson={lesson}
            onClose={() => {
              closeModal();
              load();
            }}
            onUpdated={() => {
              load();
            }}
            readOnly={isReadOnly}
          />
        )}

        {modal === 'add' && (
          <AddVocabularyModal
            lessonId={lessonId}
            onSubmit={handleAdd}
            onClose={closeModal}
            submitting={submitting}
            error={modalError}
          />
        )}
        {modal === 'edit' && selected && (
          <EditVocabularyModal
            lessonId={lessonId}
            wordId={selected.word_id}
            initial={{
              english_word: selected.english_word,
              cebuano_meaning: selected.cebuano_meaning,
              part_of_speech: selected.part_of_speech,
              grade_level: selected.grade_level,
              example_sentence_english: selected.example_sentence_english,
              example_sentence_cebuano: selected.example_sentence_cebuano ?? '',
              audio_asset_path: selected.audio_asset_path ?? '',
              image_asset_path: selected.image_asset_path ?? '',
              eligible_activity_types: selected.eligible_activity_types ?? 'MULTIPLE_CHOICE;FILL_IN_BLANK;MATCHING;WORD_SCRAMBLE;TRUE_OR_FALSE;HINT_TO_WORD',
              distractor_pool: selected.distractor_pool ?? '',
              fill_blank_sentence: selected.fill_blank_sentence ?? '',
              tile_sentence: selected.tile_sentence ?? '',
              explanation_text: selected.explanation_text ?? '',
              audio_text_cebuano: selected.audio_text_cebuano ?? '',
              audio_text_english: selected.audio_text_english ?? '',
              phonological_tip_key: selected.phonological_tip_key ?? '',
              is_confusable_pair_member: selected.is_confusable_pair_member ?? false,
              hint_definition: selected.hint_definition ?? '',
              hint_cebuano_sentence: selected.hint_cebuano_sentence ?? '',
            }}
            onSubmit={handleUpdate}
            onClose={closeModal}
            submitting={submitting}
            error={modalError}
          />
        )}
        {modal === 'delete' && selected && (
          <ConfirmDeleteDialog
            title="Delete Word"
            message={`Delete "${selected.english_word}" (${selected.cebuano_meaning})? This cannot be undone.`}
            onConfirm={handleDelete}
            onCancel={closeModal}
            loading={submitting}
          />
        )}
      </main>
    </div>
  );
}
