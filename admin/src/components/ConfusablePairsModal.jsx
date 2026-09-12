import { useState, useEffect, useCallback } from 'react';
import ConfirmDeleteDialog from './ConfirmDeleteDialog';
import ConfusableWordPairModal from './ConfusableWordPairModal';
import { ConfusableWordService } from '../services/ConfusableWordService';

export default function ConfusablePairsModal({ lessonId, lesson, onClose, onUpdated, readOnly = false }) {
  const [pairs, setPairs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const [showCreate, setShowCreate] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState(null);
  const [deleting, setDeleting] = useState(false);
  const [deleteError, setDeleteError] = useState('');

  const flash = (msg) => {
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
      if (onUpdated) onUpdated();
    } catch (err) {
      setDeleteError(err?.message || 'Failed to delete pair');
    } finally {
      setDeleting(false);
    }
  };

  return (
    <div className="modal-overlay" onClick={onClose} style={{ zIndex: 100 }}>
      <div
        className="modal modal--confusable-pairs"
        onClick={e => e.stopPropagation()}
        style={{
          maxWidth: 880,
          width: '95vw',
          maxHeight: '92vh',
          display: 'flex',
          flexDirection: 'column',
          padding: '28px 32px'
        }}
        role="dialog"
        aria-modal="true"
        aria-labelledby="confusable-pairs-modal-title"
      >
        {/* Modal Header */}
        <div className="modal__header" style={{ alignItems: 'flex-start', marginBottom: 18 }}>
          <div>
            <h2 id="confusable-pairs-modal-title" className="modal__title" style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: '1.35rem' }}>
              <span>🔗</span> Confusable Word Pairs
            </h2>
            <p className="modal__subtitle" style={{ fontSize: '0.9rem', marginTop: 4 }}>
              {lesson?.lesson_title ?? `Lesson ${lessonId?.slice(0, 8)}…`}
            </p>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            {!readOnly && (
              <button
                id="modal-create-pair-btn"
                className="btn btn--primary btn--sm"
                onClick={() => setShowCreate(true)}
                type="button"
              >
                + Create Pair
              </button>
            )}
            <button className="modal__close-btn" onClick={onClose} aria-label="Close">✕</button>
          </div>
        </div>

        {/* Alerts */}
        {error && <div className="alert alert--error" onClick={() => setError('')} style={{ marginBottom: 16 }}>{error}</div>}
        {success && <div className="alert alert--success" style={{ marginBottom: 16 }}>{success}</div>}

        {/* Scrollable Modal Content */}
        <div style={{ overflowY: 'auto', flex: 1, paddingRight: 4 }}>
          {/* Info banner */}
          <div className="confusable-info-banner" style={{ marginBottom: 20 }}>
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
            <div className="auth-loading" style={{ minHeight: 180 }}>
              <div className="spinner" />
            </div>
          ) : pairs.length === 0 ? (
            <div className="confusable-pairs-empty" style={{ padding: '48px 24px' }}>
              <div className="confusable-pairs-empty__icon">🔗</div>
              <h3 className="confusable-pairs-empty__title">No confusable pairs yet</h3>
              <p className="confusable-pairs-empty__subtitle">
                Click <strong>+ Create Pair</strong> to define which words learners commonly confuse.
              </p>
              {!readOnly && (
                <button
                  className="btn btn--primary"
                  onClick={() => setShowCreate(true)}
                  type="button"
                >
                  + Create First Pair
                </button>
              )}
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
                      {!readOnly && (
                        <button
                          className="btn btn--sm btn--danger-ghost"
                          onClick={() => { setDeleteTarget(pair); setDeleteError(''); }}
                          aria-label={`Delete pair ${pair.word_a.english_word} ↔ ${pair.word_b.english_word}`}
                          type="button"
                        >
                          🗑️ Delete
                        </button>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </>
          )}
        </div>

        {/* Create modal sub-dialog */}
        {showCreate && lessonId && (
          <ConfusableWordPairModal
            lessonId={lessonId}
            lessonTitle={lesson?.lesson_title}
            onClose={() => setShowCreate(false)}
            onCreated={() => {
              setShowCreate(false);
              flash('Confusable pair created successfully!');
              load();
              if (onUpdated) onUpdated();
            }}
          />
        )}

        {/* Delete confirmation sub-dialog */}
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
      </div>
    </div>
  );
}
