import { useState, useEffect, useCallback } from 'react';
import { useNavigate, useParams, useLocation } from 'react-router-dom';
import AdminNav from '../components/AdminNav';
import VocabularyTable from '../components/VocabularyTable';
import { AddVocabularyModal, EditVocabularyModal } from '../components/VocabWordModals';
import ConfirmDeleteDialog from '../components/ConfirmDeleteDialog';
import { VocabularyService, type AdminVocabularyWord } from '../services/VocabularyService';

type ModalType = 'add' | 'edit' | 'delete' | null;

export default function VocabularyListPage() {
  const { lessonId } = useParams<{ lessonId: string }>();
  const navigate = useNavigate();
  const location = useLocation();
  const locationState = location.state as { lesson?: { lesson_title: string; context_paragraph?: string }; autoAdd?: boolean };
  const lesson = locationState?.lesson;

  const [words, setWords] = useState<AdminVocabularyWord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [modal, setModal] = useState<ModalType>(locationState?.autoAdd ? 'add' : null);

  useEffect(() => {
    if (locationState?.autoAdd) {
      // Clear autoAdd from history so it doesn't reopen on refresh
      navigate('.', { replace: true, state: { ...locationState, autoAdd: false } });
    }
  }, [locationState?.autoAdd, navigate, locationState]);
  const [selected, setSelected] = useState<AdminVocabularyWord | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [modalError, setModalError] = useState('');

  const flash = (msg: string) => { setSuccess(msg); setTimeout(() => setSuccess(''), 3500); };

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

  const openModal = (type: ModalType, word?: AdminVocabularyWord) => {
    setSelected(word ?? null);
    setModalError('');
    setModal(type);
  };
  const closeModal = () => { setModal(null); setSelected(null); setModalError(''); };

  const handleAdd = async (data: Parameters<typeof VocabularyService.addWord>[1]) => {
    if (!lessonId) return;
    setSubmitting(true);
    try {
      await VocabularyService.addWord(lessonId, data);
      flash('Word added successfully!');
      closeModal();
      load();
    } catch (err: unknown) {
      setModalError(err instanceof Error ? err.message : 'Failed to add word');
    } finally { setSubmitting(false); }
  };

  const handleUpdate = async (data: Parameters<typeof VocabularyService.updateWord>[2]) => {
    if (!lessonId || !selected) return;
    setSubmitting(true);
    try {
      await VocabularyService.updateWord(lessonId, selected.word_id, data);
      flash('Word updated successfully!');
      closeModal();
      load();
    } catch (err: unknown) {
      setModalError(err instanceof Error ? err.message : 'Failed to update word');
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
    } catch (err: unknown) {
      setModalError(err instanceof Error ? err.message : 'Failed to delete word');
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
          <div style={{ display: 'flex', gap: 8 }}>
            
          </div>
        </header>

        {error   && <div className="alert alert--error"   onClick={() => setError('')}>{error}</div>}
        {success && <div className="alert alert--success">{success}</div>}

        <VocabularyTable
          words={words}
          lessonTitle={lesson?.lesson_title ?? ''}
          onAdd={() => openModal('add')}
          onEdit={w => openModal('edit', w)}
          onDelete={w => openModal('delete', w)}
          onBulkImport={() => navigate(`/lessons/${lessonId}/bulk-import`, { state: { lesson } })}
          onConfusablePairs={() => navigate(`/lessons/${lessonId}/confusable-pairs`, { state: { lesson } })}
          loading={loading}
        />

        {modal === 'add' && (
          <AddVocabularyModal
            lessonId={lessonId!}
            onSubmit={handleAdd}
            onClose={closeModal}
            submitting={submitting}
            error={modalError}
          />
        )}
        {modal === 'edit' && selected && (
          <EditVocabularyModal
            lessonId={lessonId!}
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
