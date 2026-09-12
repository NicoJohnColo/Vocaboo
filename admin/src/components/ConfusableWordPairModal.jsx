import { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { ConfusableWordService } from '../services/ConfusableWordService';

function WordCombobox({
  id, label, badge, words, excludeId, selectedId,
  onSelect, onNotInLesson, onClearNotInLesson,
  loading, error,
}) {
  const [query, setQuery]     = useState('');
  const [open, setOpen]       = useState(false);
  const [touched, setTouched] = useState(false);
  const wrapRef = useRef(null);

  const available = words.filter(w => w.word_id !== excludeId);
  const filtered  = query.trim()
    ? available.filter(w =>
        w.english_word.toLowerCase().includes(query.trim().toLowerCase()) ||
        w.cebuano_meaning.toLowerCase().includes(query.trim().toLowerCase())
      )
    : available;

  const selected = available.find(w => w.word_id === selectedId);

  // Detect "not in lesson" whenever user has typed & no match found
  useEffect(() => {
    if (!touched) return;
    const term = query.trim();
    if (term && filtered.length === 0) {
      onNotInLesson(term);
    } else {
      onClearNotInLesson();
    }
  }, [query, filtered.length, touched, onNotInLesson, onClearNotInLesson]);

  // Close on outside click
  useEffect(() => {
    const handleClick = (e) => {
      if (wrapRef.current && !wrapRef.current.contains(e.target)) {
        setOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClick);
    return () => document.removeEventListener('mousedown', handleClick);
  }, []);

  const choose = (w) => {
    onSelect(w.word_id);
    setQuery('');
    setOpen(false);
    onClearNotInLesson();
  };

  const handleInputChange = (val) => {
    setQuery(val);
    setTouched(true);
    if (val) {
      setOpen(true);
      if (selectedId) onSelect('');
    }
  };

  const displayValue = selected && !query ? selected.english_word : query;
  const isNotInLesson = touched && query.trim() !== '' && filtered.length === 0;

  return (
    <div className="confusable-modal__word-block" ref={wrapRef}>
      <div className="confusable-modal__word-header">
        <span className={`confusable-modal__word-badge confusable-modal__word-badge--${badge}`}>
          {badge.toUpperCase()}
        </span>
        <label className="form-label" htmlFor={id}>{label} *</label>
      </div>

      {loading ? (
        <div className="confusable-modal__select-loading">
          <span className="spinner spinner--sm" />
        </div>
      ) : (
        <div className="word-combobox" style={{ position: 'relative' }}>
          <input
            id={id}
            type="text"
            className={`form-input word-combobox__input ${
              isNotInLesson ? 'form-input--error word-combobox__input--not-found' :
              selected ? 'word-combobox__input--selected' : ''
            }`}
            placeholder="Type to search lesson words…"
            value={displayValue}
            onChange={e => handleInputChange(e.target.value)}
            onFocus={() => { setOpen(true); setTouched(true); }}
            autoComplete="off"
          />

          {/* Dropdown list */}
          {open && (
            <div className="word-combobox__dropdown">
              {filtered.length === 0 && query.trim() ? (
                <div className="word-combobox__no-match">
                  No lesson words match <strong>"{query.trim()}"</strong>
                </div>
              ) : filtered.length === 0 ? (
                <div className="word-combobox__no-match">No words available</div>
              ) : (
                filtered.map(w => (
                  <button
                    key={w.word_id}
                    type="button"
                    className={`word-combobox__option ${w.word_id === selectedId ? 'word-combobox__option--active' : ''}`}
                    onMouseDown={e => { e.preventDefault(); choose(w); }}
                  >
                    <span className="word-combobox__option-en">{w.english_word}</span>
                    <span className="word-combobox__option-ceb">{w.cebuano_meaning}</span>
                    {w.is_confusable_pair_member && (
                      <span className="word-combobox__option-tag">🔗 paired</span>
                    )}
                  </button>
                ))
              )}
            </div>
          )}
        </div>
      )}

      {/* ❌ Not in lesson inline warning */}
      {isNotInLesson && (
        <div className="word-not-in-lesson">
          <span className="word-not-in-lesson__icon">❌</span>
          <div className="word-not-in-lesson__body">
            <span className="word-not-in-lesson__msg">
              <strong>"{query.trim()}"</strong> not in this lesson
            </span>
            <span className="word-not-in-lesson__suggestion">
              Suggestion: Add "{query.trim()}" first
            </span>
          </div>
        </div>
      )}

      {/* Validation error */}
      {!isNotInLesson && error && (
        <span className="form-error">{error}</span>
      )}

      {/* Selected word preview */}
      {selected && !query && (
        <div className="confusable-modal__word-preview">
          <span className="confusable-modal__word-preview-label">✓</span>
          <strong>{selected.english_word}</strong>
          <span style={{ color: 'var(--color-text-muted)' }}>— {selected.cebuano_meaning}</span>
        </div>
      )}
    </div>
  );
}

export default function ConfusableWordPairModal({
  lessonId, lessonTitle, onClose, onCreated,
}) {
  const navigate = useNavigate();

  const [words, setWords]             = useState([]);
  const [suggestions, setSuggestions] = useState([]);
  const [loadingWords, setLoadingWords]           = useState(true);
  const [loadingSuggestions, setLoadingSuggestions] = useState(true);

  const [wordAId, setWordAId]     = useState('');
  const [wordBId, setWordBId]     = useState('');
  const [sentenceA, setSentenceA] = useState('');
  const [sentenceB, setSentenceB] = useState('');

  const [notInLessonA, setNotInLessonA] = useState('');
  const [notInLessonB, setNotInLessonB] = useState('');

  const [submitting, setSubmitting]     = useState(false);
  const [globalError, setGlobalError]   = useState('');
  const [fieldErrors, setFieldErrors]   = useState({});

  useEffect(() => {
    let cancelled = false;
    ConfusableWordService.getWordSelector(lessonId)
      .then(d => { if (!cancelled) { setWords(d); setLoadingWords(false); } })
      .catch(() => { if (!cancelled) setLoadingWords(false); });
    ConfusableWordService.getSuggestions(lessonId)
      .then(d => { if (!cancelled) { setSuggestions(d); setLoadingSuggestions(false); } })
      .catch(() => { if (!cancelled) setLoadingSuggestions(false); });
    return () => { cancelled = true; };
  }, [lessonId]);

  const wordA = words.find(w => w.word_id === wordAId);
  const wordB = words.find(w => w.word_id === wordBId);

  const hasNoWords      = !loadingWords && words.length < 2;
  const notInLessonTerm = notInLessonA || notInLessonB;

  const applySuggestion = (s) => {
    setWordAId(s.word_a.word_id);
    setWordBId(s.word_b.word_id);
    setNotInLessonA('');
    setNotInLessonB('');
    setFieldErrors({});
    setGlobalError('');
  };

  const validate = () => {
    const errs = {};
    if (!wordAId) errs.wordA = 'Please select Word A from the lesson';
    if (!wordBId) errs.wordB = 'Please select Word B from the lesson';
    if (wordAId && wordBId && wordAId === wordBId)
      errs.wordB = 'Word B must be different from Word A';
    if (!sentenceA.trim() || sentenceA.trim().length < 5)
      errs.sentenceA = 'Contrastive sentence for Word A required (min 5 chars)';
    if (!sentenceB.trim() || sentenceB.trim().length < 5)
      errs.sentenceB = 'Contrastive sentence for Word B required (min 5 chars)';
    setFieldErrors(errs);
    return Object.keys(errs).length === 0;
  };

  const handleSubmit = async () => {
    if (!validate()) return;
    setSubmitting(true);
    setGlobalError('');
    try {
      const payload = {
        word_a_id: wordAId,
        word_b_id: wordBId,
        contrastive_sentence_a: sentenceA.trim(),
        contrastive_sentence_b: sentenceB.trim(),
      };
      await ConfusableWordService.createPair(lessonId, payload);
      onCreated();
    } catch (err) {
      setGlobalError(err?.message || 'Failed to create pair');
    } finally {
      setSubmitting(false);
    }
  };

  const goAddWord = () => {
    navigate(`/lessons/${lessonId}/vocabulary`, { state: { lesson: { lesson_title: lessonTitle }, autoAdd: true } });
    onClose();
  };

  const showAddWordFirst = hasNoWords || !!notInLessonTerm;
  const bothSelected     = !!wordAId && !!wordBId && wordAId !== wordBId;

  return (
    <div className="modal-overlay" onClick={onClose} style={{ zIndex: 120 }}>
      <div
        className="modal modal--lg modal--confusable"
        onClick={e => e.stopPropagation()}
        role="dialog"
        aria-modal="true"
        aria-labelledby="confusable-modal-title"
      >
        {/* Header */}
        <div className="confusable-modal__header">
          <div>
            <h2 id="confusable-modal-title" className="modal__title">
              🔗 Create Confusable Word Pair
            </h2>
            {lessonTitle && (
              <p className="confusable-modal__lesson-name">{lessonTitle}</p>
            )}
          </div>
          <button className="modal__close-btn" onClick={onClose} aria-label="Close">✕</button>
        </div>

        {/* Global error */}
        {globalError && (
          <div className="alert alert--error confusable-modal__global-error">
            ⚠️ {globalError}
          </div>
        )}

        {/* Empty state */}
        {hasNoWords ? (
          <div className="confusable-modal__empty-state">
            <div className="confusable-modal__empty-icon">📚</div>
            <p className="confusable-modal__empty-text">
              This lesson needs at least <strong>2 vocabulary words</strong> before
              you can create a confusable pair.
            </p>
          </div>
        ) : (
          <>
            {/* Suggestions */}
            {!loadingSuggestions && suggestions.length > 0 && (
              <div className="confusable-modal__suggestions">
                <p className="confusable-modal__suggestions-label">
                  💡 Suggested pairs — click to pre-fill:
                </p>
                <div className="confusable-modal__chips">
                  {suggestions.map((s, i) => (
                    <button
                      key={i}
                      className="suggestion-chip"
                      onClick={() => applySuggestion(s)}
                      title={s.reason}
                      type="button"
                    >
                      <span className="suggestion-chip__words">
                        {s.word_a.english_word} ↔ {s.word_b.english_word}
                      </span>
                      <span className="suggestion-chip__reason">{s.reason}</span>
                    </button>
                  ))}
                </div>
              </div>
            )}
            {loadingSuggestions && (
              <div className="confusable-modal__suggestions confusable-modal__suggestions--loading">
                <span className="spinner spinner--sm" />
                <span style={{ color: 'var(--color-text-muted)', fontSize: '0.85rem' }}>
                  Analyzing vocabulary for suggestions…
                </span>
              </div>
            )}

            {/* Word pair combobox row */}
            <div className="confusable-modal__pair-row">
              <WordCombobox
                id="word-a-combobox"
                label="Select Word A"
                badge="a"
                words={words}
                excludeId={wordBId}
                selectedId={wordAId}
                onSelect={id => { setWordAId(id); setFieldErrors(fe => ({ ...fe, wordA: '' })); }}
                onNotInLesson={term => setNotInLessonA(term)}
                onClearNotInLesson={() => setNotInLessonA('')}
                notInLessonTerm={notInLessonA}
                loading={loadingWords}
                error={fieldErrors.wordA}
              />

              <div className="pair-connector" aria-hidden="true">
                <div className="pair-connector__line" />
                <div className="pair-connector__icon">↔</div>
                <div className="pair-connector__line" />
              </div>

              <WordCombobox
                id="word-b-combobox"
                label="Select Word B"
                badge="b"
                words={words}
                excludeId={wordAId}
                selectedId={wordBId}
                onSelect={id => { setWordBId(id); setFieldErrors(fe => ({ ...fe, wordB: '' })); }}
                onNotInLesson={term => setNotInLessonB(term)}
                onClearNotInLesson={() => setNotInLessonB('')}
                notInLessonTerm={notInLessonB}
                loading={loadingWords}
                error={fieldErrors.wordB}
              />
            </div>

            {/* Contrastive sentences */}
            {bothSelected && !notInLessonTerm && (
              <div className="confusable-modal__sentences">
                <div className="confusable-modal__sentence-block">
                  <label className="form-label" htmlFor="sentence-a">
                    Contrastive sentence for <strong>{wordA?.english_word ?? 'Word A'}</strong> *
                  </label>
                  <textarea
                    id="sentence-a"
                    className={`form-textarea ${fieldErrors.sentenceA ? 'form-input--error' : ''}`}
                    rows={2}
                    placeholder={`e.g. I write with a ${wordA?.english_word?.toLowerCase() ?? 'pencil'}.`}
                    value={sentenceA}
                    onChange={e => { setSentenceA(e.target.value); setFieldErrors(fe => ({ ...fe, sentenceA: '' })); }}
                  />
                  {fieldErrors.sentenceA && <span className="form-error">{fieldErrors.sentenceA}</span>}
                </div>
                <div className="confusable-modal__sentence-block">
                  <label className="form-label" htmlFor="sentence-b">
                    Contrastive sentence for <strong>{wordB?.english_word ?? 'Word B'}</strong> *
                  </label>
                  <textarea
                    id="sentence-b"
                    className={`form-textarea ${fieldErrors.sentenceB ? 'form-input--error' : ''}`}
                    rows={2}
                    placeholder={`e.g. I write with a ${wordB?.english_word?.toLowerCase() ?? 'pen'}.`}
                    value={sentenceB}
                    onChange={e => { setSentenceB(e.target.value); setFieldErrors(fe => ({ ...fe, sentenceB: '' })); }}
                  />
                  {fieldErrors.sentenceB && <span className="form-error">{fieldErrors.sentenceB}</span>}
                </div>
              </div>
            )}
          </>
        )}

        {/* Action buttons */}
        <div className="modal__actions">
          {showAddWordFirst ? (
            <>
              <button className="btn btn--ghost" onClick={onClose}>
                Cancel
              </button>
              <button
                id="add-word-first-btn"
                className="btn btn--warning"
                onClick={goAddWord}
              >
                ➕ Add Word First
              </button>
            </>
          ) : (
            <>
              <button className="btn btn--ghost" onClick={onClose} disabled={submitting}>
                Cancel
              </button>
              <button
                id="create-confusable-pair-btn"
                className="btn btn--primary"
                onClick={handleSubmit}
                disabled={submitting || loadingWords || !bothSelected}
              >
                {submitting ? <span className="spinner spinner--sm" /> : '🔗 Create Pair'}
              </button>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
