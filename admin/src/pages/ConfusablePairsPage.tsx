import { useState, useEffect, useCallback } from 'react';
import { useNavigate, useParams, useLocation } from 'react-router-dom';
import AdminNav from '../components/AdminNav';
import ConfirmDeleteDialog from '../components/ConfirmDeleteDialog';
import ConfusableWordPairModal from '../components/ConfusableWordPairModal';
import {
  ConfusableWordService,
  type ConfusableWordPair,
} from '../services/ConfusableWordService';

export default function ConfusablePairsPage() {
  const { lessonId }   = useParams<{ lessonId: string }>();
  const navigate       = useNavigate();
  const location       = useLocation();
  const lesson = (location.state as { lesson?: { lesson_title: string } })?.lesson;

  const [pairs, setPairs]           = useState<ConfusableWordPair[]>([]);
  const [loading, setLoading]       = useState(true);
  const [error, setError]           = useState('');
  const [success, setSuccess]       = useState('');

  const [showCreate, setShowCreate]   = useState(false);
  const [deleteTarget, setDeleteTarget] = useState<ConfusableWordPair | null>(null);
  const [deleting, setDeleting]         = useState(false);
  const [deleteError, setDeleteError]   = useState('');

  const flash = (msg: string) => {
    setSuccess(msg);
    setTimeout(() => setSuccess(''), 3500);
  };

  const load = useCallback(async () => {
    if (!lessonId) return;
    setLoading(true);
    try {
      setPairs(await ConfusableWordService.getPairs(lessonId));
    } catch {
      setError('Failed to load confusable pairs.');
    } finally {
      setLoading(false);
    }
  }, [lessonId]);

  useEffect(() => { load(); }, [load]);

  const handleDelete = async () => {
    if (!lessonId || !deleteTarget) return;
    setDeleting(true);
    try {
      await ConfusableWordService.deletePair(lessonId, deleteTarget.pair_id);
      setDeleteTarget(null);
      flash('Confusable pair deleted.');
      load();
    } catch (err: unknown) {
      setDeleteError(err instanceof Error ? err.message : 'Failed to delete pair');
    } finally {
      setDeleting(false);
    }
  };

  return (
    <div className="admin-layout">
      <AdminNav />
      <main className="admin-main" style={{ maxWidth: '100%' }}>

        {/* Page header */}
        <header className="admin-main__header">
          <div>
            <button
              className="btn btn--ghost btn--sm"
              style={{ marginBottom: 12 }}
              onClick={() => navigate(`/lessons/${lessonId}/vocabulary`, { state: { lesson } })}
            >
              ← Back to Vocabulary
            </button>
            <h1 className="admin-main__title">🔗 Confusable Word Pairs</h1>
            <p className="admin-main__subtitle">
              {lesson?.lesson_title ?? `Lesson ${lessonId?.slice(0, 8)}…`}
            </p>
          </div>
          <button
            id="create-pair-btn"
            className="btn btn--primary"
            onClick={() => setShowCreate(true)}
          >
            + Create Pair
          </button>
        </header>

        {/* Alerts */}
        {error   && <div className="alert alert--error"   onClick={() => setError('')}>{error}</div>}
        {success && <div className="alert alert--success">{success}</div>}

        {/* Info callout */}
        <div className="confusable-info-banner">
          <span className="confusable-info-banner__icon">ℹ️</span>
          <div>
            <strong>What are confusable pairs?</strong>
            <p>
              Words that learners commonly mix up (e.g. <em>pencil</em> vs <em>pen</em>).
              Both words must already exist in this lesson's vocabulary.
              The contrastive sentences help learners distinguish between them during practice.
            </p>
          </div>
        </div>

        {/* Pairs table / empty state */}
        {loading ? (
          <div className="auth-loading" style={{ minHeight: 200 }}>
            <div className="spinner" />
          </div>
        ) : pairs.length === 0 ? (
          <div className="confusable-pairs-empty">
            <div className="confusable-pairs-empty__icon">🔗</div>
            <h3 className="confusable-pairs-empty__title">No confusable pairs yet</h3>
            <p className="confusable-pairs-empty__subtitle">
              Click <strong>+ Create Pair</strong> to define which words learners commonly confuse.
            </p>
            <button className="btn btn--primary" onClick={() => setShowCreate(true)}>
              + Create First Pair
            </button>
          </div>
        ) : (
          <>
            <div className="table-meta" style={{ marginBottom: 16 }}>
              {pairs.length} confusable pair{pairs.length !== 1 ? 's' : ''} in this lesson
            </div>
            <div className="confusable-pairs-grid">
              {pairs.map(pair => (
                <div key={pair.pair_id} className="confusable-pair-card">
                  <div className="confusable-pair-card__words">
                    <div className="confusable-pair-card__word">
                      <span className="confusable-modal__word-badge confusable-modal__word-badge--a">A</span>
                      <div>
                        <div className="confusable-pair-card__word-name">
                          {pair.word_a.english_word}
                        </div>
                        <div className="confusable-pair-card__cebuano">
                          {pair.word_a.cebuano_meaning}
                        </div>
                      </div>
                    </div>

                    <div className="confusable-pair-card__connector">↔</div>

                    <div className="confusable-pair-card__word">
                      <span className="confusable-modal__word-badge confusable-modal__word-badge--b">B</span>
                      <div>
                        <div className="confusable-pair-card__word-name">
                          {pair.word_b.english_word}
                        </div>
                        <div className="confusable-pair-card__cebuano">
                          {pair.word_b.cebuano_meaning}
                        </div>
                      </div>
                    </div>
                  </div>

                  <div className="confusable-pair-card__sentences">
                    <div className="confusable-pair-card__sentence">
                      <span className="confusable-pair-card__sentence-label">A:</span>
                      <span>{pair.contrastive_sentence_a}</span>
                    </div>
                    <div className="confusable-pair-card__sentence">
                      <span className="confusable-pair-card__sentence-label">B:</span>
                      <span>{pair.contrastive_sentence_b}</span>
                    </div>
                  </div>

                  <div className="confusable-pair-card__footer">
                    <span className="confusable-pair-card__date">
                      Created {new Date(pair.created_at).toLocaleDateString()}
                    </span>
                    <button
                      className="btn btn--sm btn--danger-ghost"
                      onClick={() => { setDeleteTarget(pair); setDeleteError(''); }}
                      aria-label={`Delete pair ${pair.word_a.english_word} ↔ ${pair.word_b.english_word}`}
                    >
                      🗑️ Delete
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </>
        )}

        {/* Create modal */}
        {showCreate && lessonId && (
          <ConfusableWordPairModal
            lessonId={lessonId}
            lessonTitle={lesson?.lesson_title}
            onClose={() => setShowCreate(false)}
            onCreated={() => {
              setShowCreate(false);
              flash('Confusable pair created successfully!');
              load();
            }}
          />
        )}

        {/* Delete confirmation */}
        {deleteTarget && (
          <ConfirmDeleteDialog
            title="Delete Confusable Pair"
            message={
              deleteError
                ? `⚠️ ${deleteError}`
                : `Delete the pair "${deleteTarget.word_a.english_word}" ↔ "${deleteTarget.word_b.english_word}"? The words will remain in the vocabulary, but the confusable pair link will be removed.`
            }
            onConfirm={handleDelete}
            onCancel={() => { setDeleteTarget(null); setDeleteError(''); }}
            loading={deleting}
          />
        )}
      </main>
    </div>
  );
}
