import React, { useState, useCallback } from 'react';
import { VocabularyService } from '../services/VocabularyService';

const CSV_HEADERS = [
  'english_word', 'cebuano_meaning', 'part_of_speech', 'grade_level',
  'example_sentence_english', 'example_sentence_cebuano', 'audio_path', 'image_path',
  'distractor_pool', 'fill_blank_sentence', 'tile_sentence', 'explanation_text',
  'audio_text_cebuano', 'audio_text_english', 'context_paragraph', 'eligible_activity_types',
  'hint_definition', 'hint_cebuano_sentence'
];

function parseCsvLine(line) {
  const result = [];
  let inQuotes = false;
  let current = '';
  for (let i = 0; i < line.length; i++) {
    const c = line[i];
    if (c === '"') {
      if (inQuotes && line[i + 1] === '"') {
        current += '"';
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (c === ',' && !inQuotes) {
      result.push(current.trim());
      current = '';
    } else {
      current += c;
    }
  }
  result.push(current.trim());
  return result;
}

function parseCSV(text) {
  const lines = text.trim().split(/\r?\n/);
  if (lines.length < 2) return [];
  return lines.slice(1).filter(l => l.trim()).map(line => {
    const cols = parseCsvLine(line);
    return CSV_HEADERS.reduce((obj, key, i) => {
      let val = cols[i] ?? '';
      if (val.startsWith('"') && val.endsWith('"') && val.length >= 2) {
        val = val.slice(1, -1).replace(/""/g, '"');
      }
      obj[key] = val.trim();
      return obj;
    }, {});
  });
}

export default function BulkImportModal({ lessonId, lesson, onClose, onSuccess }) {
  const [file, setFile] = useState(null);
  const [preview, setPreview] = useState([]);
  const [importing, setImporting] = useState(false);
  const [result, setResult] = useState(null);
  const [error, setError] = useState('');
  const [showConfirmModal, setShowConfirmModal] = useState(false);
  const [validating, setValidating] = useState(false);
  const [hasErrors, setHasErrors] = useState(false);
  const [showGuide, setShowGuide] = useState(false);

  const validateFile = async (f) => {
    if (!lessonId) return;
    setValidating(true);
    setHasErrors(false);
    try {
      const res = await VocabularyService.bulkImport(lessonId, f, { dryRun: true });
      const backendErrors = res.errors || [];

      setPreview(prev => prev.map((row, index) => {
        const rowIndexStr = String(index + 1);
        const rowError = backendErrors.find(e => e.row === rowIndexStr);
        if (rowError) {
          return { ...row, _status: 'error', _error: rowError.error };
        }
        return { ...row, _status: 'ok' };
      }));

      if (backendErrors.length > 0) {
        setHasErrors(true);
      }
    } catch (err) {
      console.error('Validation error', err);
      setHasErrors(true);
    } finally {
      setValidating(false);
    }
  };

  const handleFileChange = (e) => {
    const f = e.target.files?.[0];
    if (!f) return;
    setFile(f);
    setResult(null);
    const reader = new FileReader();
    reader.onload = ev => {
      const text = ev.target?.result;
      setPreview(parseCSV(text));
      validateFile(f);
    };
    reader.readAsText(f);
  };

  const handleDrop = useCallback((e) => {
    e.preventDefault();
    const f = e.dataTransfer.files[0];
    if (f && f.name.endsWith('.csv')) {
      setFile(f);
      const reader = new FileReader();
      reader.onload = ev => {
        setPreview(parseCSV(ev.target?.result));
        validateFile(f);
      };
      reader.readAsText(f);
    }
  }, [lessonId]);

  const handleImport = async () => {
    if (!file || !lessonId) return;
    setImporting(true);
    setError('');
    try {
      const res = await VocabularyService.bulkImport(lessonId, file);
      setResult(res);
      if (onSuccess) {
        onSuccess(res);
      }
    } catch (err) {
      setError(err?.message || 'Import failed');
    } finally {
      setImporting(false);
    }
  };

  const downloadTemplate = () => {
    setShowConfirmModal(true);
  };

  const handleConfirmDownload = async () => {
    setShowConfirmModal(false);
    if (!lessonId) return;
    try {
      await VocabularyService.downloadTemplateFile(lessonId);
    } catch (err) {
      setError(err?.message || 'Failed to download template');
    }
  };

  return (
    <div className="modal-overlay" onClick={onClose} style={{ zIndex: 100 }}>
      <div
        className="modal modal--bulk-import"
        onClick={e => e.stopPropagation()}
        style={{
          maxWidth: 1060,
          width: '95vw',
          maxHeight: '92vh',
          display: 'flex',
          flexDirection: 'column',
          padding: '28px 32px'
        }}
        role="dialog"
        aria-modal="true"
        aria-labelledby="bulk-import-modal-title"
      >
        {/* Modal Header */}
        <div className="modal__header" style={{ alignItems: 'flex-start', marginBottom: 18 }}>
          <div>
            <h2 id="bulk-import-modal-title" className="modal__title" style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: '1.35rem' }}>
              <span>📥</span> Bulk Import Vocabulary
            </h2>
            <p className="modal__subtitle" style={{ fontSize: '0.9rem', marginTop: 4 }}>
              {lesson?.lesson_title ?? `Lesson ${lessonId?.slice(0, 8)}`}
            </p>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <button className="btn btn--ghost btn--sm" onClick={downloadTemplate} type="button">
              📄 Download CSV Template
            </button>
            <button className="modal__close-btn" onClick={onClose} aria-label="Close">✕</button>
          </div>
        </div>

        {error && <div className="alert alert--error" style={{ marginBottom: 16 }}>{error}</div>}

        {/* Scrollable Modal Content */}
        <div style={{ overflowY: 'auto', flex: 1, paddingRight: 4 }}>
          {result && (
            <div className="import-result" style={{ margin: '12px 0 20px' }}>
              <div className="import-result__stat import-result__stat--success">
                ✅ <strong>{result.success}</strong> imported
              </div>
              {result.skipped > 0 && (
                <div className="import-result__stat import-result__stat--warn">
                  ⚠️ <strong>{result.skipped}</strong> duplicates skipped
                </div>
              )}
              {result.errors && result.errors.length > 0 && (
                <div className="import-result__stat import-result__stat--error">
                  ❌ <strong>{result.errors.length}</strong> errors
                </div>
              )}
              <button
                className="btn btn--primary btn--sm"
                style={{ marginLeft: 'auto' }}
                onClick={onClose}
              >
                View Words →
              </button>
            </div>
          )}

          {!result && (
            <>
              <div
                className={`dropzone ${file ? 'dropzone--active' : ''}`}
                onDrop={handleDrop}
                onDragOver={e => e.preventDefault()}
                style={{ padding: file ? '24px' : '36px 24px' }}
              >
                {file ? (
                  <div className="dropzone__file">
                    <span className="dropzone__icon" style={{ fontSize: '2rem' }}>📄</span>
                    <span className="dropzone__filename">{file.name}</span>
                    <span className="dropzone__size">({(file.size / 1024).toFixed(1)} KB)</span>
                    <button
                      type="button"
                      className="btn btn--ghost btn--sm"
                      onClick={() => { setFile(null); setPreview([]); setHasErrors(false); }}
                    >
                      ✕ Remove
                    </button>
                  </div>
                ) : (
                  <div className="dropzone__prompt">
                    <div className="dropzone__icon" style={{ fontSize: '2.5rem' }}>📥</div>
                    <p style={{ fontSize: '0.95rem' }}>Drag &amp; drop a <strong>.csv</strong> file here, or</p>
                    <label className="btn btn--primary btn--sm" style={{ cursor: 'pointer' }}>
                      Choose File
                      <input type="file" accept=".csv" onChange={handleFileChange} style={{ display: 'none' }} />
                    </label>
                    <p className="dropzone__hint" style={{ lineHeight: 1.6, maxWidth: 750, margin: '10px auto 0' }}>
                      <strong>Required:</strong> <code>english_word</code>, <code>cebuano_meaning</code>, <code>part_of_speech</code>, <code>grade_level</code>, <code>example_sentence_english</code>, <code>example_sentence_cebuano</code>
                      <br />
                      <strong>Optional:</strong> <code>audio_path</code>, <code>image_path</code>, <code>distractor_pool</code>, <code>fill_blank_sentence</code>, <code>tile_sentence</code>, <code>explanation_text</code>, <code>audio_text_cebuano</code>, <code>audio_text_english</code>, <code>context_paragraph</code>, <code>eligible_activity_types</code>, <code>hint_definition</code>, <code>hint_cebuano_sentence</code>
                    </p>
                    <div style={{ marginTop: 12 }}>
                      <button
                        type="button"
                        onClick={() => setShowGuide(g => !g)}
                        style={{
                          fontSize: '0.82rem',
                          color: '#4f46e5',
                          textDecoration: 'underline',
                          cursor: 'pointer',
                          background: 'none',
                          border: 'none',
                          padding: '4px 8px',
                          fontWeight: 600,
                        }}
                      >
                        {showGuide ? '▲ Hide Column Reference Guide' : '📋 Show Column Reference Guide (16 Columns)'}
                      </button>
                    </div>

                    {showGuide && (
                      <div style={{
                        marginTop: 14,
                        textAlign: 'left',
                        background: '#ffffff',
                        border: '1px solid #e2e8f0',
                        borderRadius: 8,
                        padding: '14px 16px',
                        fontSize: '0.82rem',
                        lineHeight: 1.5,
                        maxHeight: 240,
                        overflowY: 'auto',
                        boxShadow: '0 2px 4px rgba(0,0,0,0.05)'
                      }}>
                        <div style={{ fontWeight: 700, marginBottom: 8, color: '#1e293b' }}>
                          CSV Template Column Reference:
                        </div>
                        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: 10 }}>
                          <div>
                            <div><strong>1. english_word</strong> <span className="pos-badge pos--noun" style={{ fontSize: '0.65rem', padding: '1px 5px' }}>REQUIRED</span></div>
                            <span className="text-muted">Dictionary word (2-100 chars), e.g. <code>Pencil</code>, <code>Write</code>, <code>Sharp</code></span>
                          </div>
                          <div>
                            <div><strong>2. cebuano_meaning</strong> <span className="pos-badge pos--noun" style={{ fontSize: '0.65rem', padding: '1px 5px' }}>REQUIRED</span></div>
                            <span className="text-muted">Cebuano translation, e.g. <code>Lapis</code>, <code>Sulat</code>, <code>Hait</code></span>
                          </div>
                          <div>
                            <div><strong>3. part_of_speech</strong> <span className="pos-badge pos--noun" style={{ fontSize: '0.65rem', padding: '1px 5px' }}>REQUIRED</span></div>
                            <span className="text-muted">Must be <code>NOUN</code>, <code>VERB</code>, or <code>ADJECTIVE</code></span>
                          </div>
                          <div>
                            <div><strong>4. grade_level</strong> <span className="pos-badge pos--noun" style={{ fontSize: '0.65rem', padding: '1px 5px' }}>REQUIRED</span></div>
                            <span className="text-muted"><code>GRADE_4</code>, <code>GRADE_5</code>, or <code>GRADE_6</code></span>
                          </div>
                          <div>
                            <div><strong>5. example_sentence_english</strong> <span className="pos-badge pos--noun" style={{ fontSize: '0.65rem', padding: '1px 5px' }}>REQUIRED</span></div>
                            <span className="text-muted">Natural English sentence (10-500 chars) using the word</span>
                          </div>
                          <div>
                            <div><strong>6. example_sentence_cebuano</strong> <span className="pos-badge pos--noun" style={{ fontSize: '0.65rem', padding: '1px 5px' }}>REQUIRED</span></div>
                            <span className="text-muted">Cebuano translation of the example sentence</span>
                          </div>
                          <div>
                            <div><strong>7. audio_path &amp; 8. image_path</strong> <span className="pos-badge" style={{ fontSize: '0.65rem', padding: '1px 5px', background: '#e2e8f0', color: '#475569' }}>OPTIONAL</span></div>
                            <span className="text-muted">e.g. <code>/assets/images/words/pencil.png</code> (Image enables Image Labeling)</span>
                          </div>
                          <div>
                            <div><strong>9. distractor_pool</strong> <span className="pos-badge" style={{ fontSize: '0.65rem', padding: '1px 5px', background: '#e2e8f0', color: '#475569' }}>OPTIONAL</span></div>
                            <span className="text-muted">3 wrong same-POS options for multiple choice and True/False match: <code>eraser;ruler;marker</code></span>
                          </div>
                          <div>
                            <div><strong>10. fill_blank_sentence</strong> <span className="pos-badge" style={{ fontSize: '0.65rem', padding: '1px 5px', background: '#e2e8f0', color: '#475569' }}>OPTIONAL</span></div>
                            <span className="text-muted">Must contain <code>{'{BLANK}'}</code> placeholder, e.g. <code>"I use a {'{BLANK}'} to write."</code></span>
                          </div>
                          <div>
                            <div><strong>11. tile_sentence</strong> <span className="pos-badge" style={{ fontSize: '0.65rem', padding: '1px 5px', background: '#e2e8f0', color: '#475569' }}>OPTIONAL</span></div>
                            <span className="text-muted">Full sentence to scramble for sentence tile arrangement</span>
                          </div>
                          <div>
                            <div><strong>12. explanation_text</strong> <span className="pos-badge" style={{ fontSize: '0.65rem', padding: '1px 5px', background: '#e2e8f0', color: '#475569' }}>OPTIONAL</span></div>
                            <span className="text-muted">Learning definition or contextual hint shown to learners</span>
                          </div>
                          <div>
                            <div><strong>13. audio_text_cebuano &amp; 14. audio_text_english</strong> <span className="pos-badge" style={{ fontSize: '0.65rem', padding: '1px 5px', background: '#e2e8f0', color: '#475569' }}>OPTIONAL</span></div>
                            <span className="text-muted">Exact phrase fed to Cebuano &amp; English TTS engines</span>
                          </div>
                          <div>
                            <div><strong>15. context_paragraph</strong> <span className="pos-badge" style={{ fontSize: '0.65rem', padding: '1px 5px', background: '#e2e8f0', color: '#475569' }}>OPTIONAL</span></div>
                            <span className="text-muted">Module 1 reading passage (one full interconnected story for the whole lesson, placed on Row 1 only; individual words do not have separate stories)</span>
                          </div>
                          <div>
                            <div><strong>16. eligible_activity_types</strong> <span className="pos-badge" style={{ fontSize: '0.65rem', padding: '1px 5px', background: '#e2e8f0', color: '#475569' }}>OPTIONAL</span></div>
                            <span className="text-muted">Semicolon-separated activities (includes HINT_TO_WORD; leave empty for all)</span>
                          </div>
                          <div>
                            <div><strong>17. hint_definition</strong> <span className="pos-badge" style={{ fontSize: '0.65rem', padding: '1px 5px', background: '#e2e8f0', color: '#475569' }}>OPTIONAL</span></div>
                            <span className="text-muted">English definition/synonym clue for Hint-to-Word at FAMILIAR/PROFICIENT</span>
                          </div>
                          <div>
                            <div><strong>18. hint_cebuano_sentence</strong> <span className="pos-badge" style={{ fontSize: '0.65rem', padding: '1px 5px', background: '#e2e8f0', color: '#475569' }}>OPTIONAL</span></div>
                            <span className="text-muted">Cebuano sentence clue for Hint-to-Word at LEARNING tier</span>
                          </div>
                        </div>
                      </div>
                    )}
                  </div>
                )}
              </div>

              {preview.length > 0 && (
                <>
                  {/* Lesson Context Story Banner if provided in the CSV */}
                  {preview.some(r => r.context_paragraph && r.context_paragraph.trim()) && (
                    <div style={{
                      margin: '16px 0 12px',
                      padding: '12px 16px',
                      background: 'rgba(59, 130, 246, 0.06)',
                      border: '1px solid rgba(59, 130, 246, 0.2)',
                      borderRadius: 8,
                    }}>
                      <div style={{ fontSize: '0.78rem', fontWeight: 700, color: '#1d4ed8', textTransform: 'uppercase', marginBottom: 4, display: 'flex', alignItems: 'center', gap: 6 }}>
                        <span>📖</span> Lesson Context Story (Interconnected Reading Passage for Module 1)
                      </div>
                      <div style={{ fontSize: '0.86rem', color: 'var(--color-text)', fontStyle: 'italic', lineHeight: 1.5 }}>
                        "{preview.find(r => r.context_paragraph && r.context_paragraph.trim())?.context_paragraph}"
                      </div>
                    </div>
                  )}

                  <div className="table-meta" style={{ margin: '12px 0 8px' }}>
                    Previewing <strong>{preview.length}</strong> vocabulary words — review before importing
                  </div>
                  <div className="accounts-table-wrap" style={{ maxHeight: 340, overflowY: 'auto' }}>
                    <table className="accounts-table csv-preview-table">
                      <thead>
                        <tr>
                          <th>#</th>
                          <th>English</th>
                          <th>Cebuano</th>
                          <th>POS</th>
                          <th>Grade</th>
                          <th>Example (EN)</th>
                          <th>Example (CEB)</th>
                          <th>Distractors</th>
                          <th>Fill Blank</th>
                          <th>Tile Sentence</th>
                          <th>Explanation</th>
                          <th>TTS (CEB)</th>
                          <th>TTS (EN)</th>
                          <th>Activities</th>
                          <th>Hint (EN)</th>
                          <th>Hint (CEB)</th>
                        </tr>
                      </thead>
                      <tbody>
                        {preview.map((row, i) => (
                          <React.Fragment key={i}>
                            <tr className={row._status === 'error' ? 'row--error' : ''} style={row._status === 'error' ? { backgroundColor: 'rgba(255,0,0,0.05)', outline: '1px solid rgba(255,0,0,0.2)' } : {}}>
                              <td className="text-muted">{i + 1}</td>
                              <td style={{ fontWeight: 600 }}>
                                {row.english_word || <span className="text-danger">—</span>}
                              </td>
                              <td className="text-muted">{row.cebuano_meaning}</td>
                              <td>
                                <span className={`pos-badge pos--${row.part_of_speech?.toLowerCase()}`}>
                                  {row.part_of_speech}
                                </span>
                              </td>
                              <td className="text-muted">{row.grade_level ? row.grade_level.replace('_', ' ') : ''}</td>
                              <td className="text-muted" style={{ fontSize: '0.8rem' }}>{row.example_sentence_english}</td>
                              <td className="text-muted" style={{ fontSize: '0.8rem' }}>{row.example_sentence_cebuano || <span style={{ opacity: 0.4 }}>—</span>}</td>
                              <td className="text-muted" style={{ fontSize: '0.8rem' }}>{row.distractor_pool || <span style={{ opacity: 0.4 }}>—</span>}</td>
                              <td className="text-muted" style={{ fontSize: '0.8rem' }}>{row.fill_blank_sentence || <span style={{ opacity: 0.4 }}>—</span>}</td>
                              <td className="text-muted" style={{ fontSize: '0.8rem' }}>{row.tile_sentence || <span style={{ opacity: 0.4 }}>—</span>}</td>
                              <td className="text-muted" style={{ fontSize: '0.8rem' }}>{row.explanation_text || <span style={{ opacity: 0.4 }}>—</span>}</td>
                              <td className="text-muted" style={{ fontSize: '0.8rem', maxWidth: 140 }}>
                                <span title={row.audio_text_cebuano} style={{ display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>
                                  {row.audio_text_cebuano || <span style={{ opacity: 0.4 }}>—</span>}
                                </span>
                              </td>
                              <td className="text-muted" style={{ fontSize: '0.8rem', maxWidth: 140 }}>
                                <span title={row.audio_text_english} style={{ display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>
                                  {row.audio_text_english || <span style={{ opacity: 0.4 }}>—</span>}
                                </span>
                              </td>
                              <td className="text-muted" style={{ fontSize: '0.75rem', maxWidth: 150 }}>
                                <span title={row.eligible_activity_types} style={{ display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>
                                  {row.eligible_activity_types || <span style={{ opacity: 0.4 }}>Default (All)</span>}
                                </span>
                              </td>
                              <td className="text-muted" style={{ fontSize: '0.78rem', maxWidth: 120 }}>
                                <span title={row.hint_definition} style={{ display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>
                                  {row.hint_definition || <span style={{ opacity: 0.4 }}>—</span>}
                                </span>
                              </td>
                              <td className="text-muted" style={{ fontSize: '0.78rem', maxWidth: 120 }}>
                                <span title={row.hint_cebuano_sentence} style={{ display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>
                                  {row.hint_cebuano_sentence || <span style={{ opacity: 0.4 }}>—</span>}
                                </span>
                              </td>
                            </tr>
                          </React.Fragment>
                        ))}
                      </tbody>
                    </table>
                  </div>

                  {hasErrors && (
                    <div style={{
                      marginTop: 16,
                      background: 'rgba(255,0,0,0.04)',
                      border: '1px solid rgba(255,0,0,0.25)',
                      borderRadius: 10,
                      padding: '14px 18px'
                    }}>
                      <div style={{ fontWeight: 700, color: 'var(--color-danger)', marginBottom: 10, fontSize: '0.9rem' }}>
                        ❌ Formatting errors found — fix these before importing:
                      </div>
                      {preview
                        .filter(row => row._status === 'error')
                        .map((row, i) => {
                          const rowNum = preview.indexOf(row) + 1;
                          return (row._error ?? '').split(' | ').map((msg, j) => (
                            <div key={`${i}-${j}`} style={{ fontSize: '0.85rem', color: 'var(--color-danger)', marginBottom: 4, paddingLeft: 8 }}>
                              <strong>Row {rowNum}:</strong> {msg}
                            </div>
                          ));
                        })
                      }
                    </div>
                  )}

                  <div className="modal__actions" style={{ marginTop: 20 }}>
                    <button
                      type="button"
                      className="btn btn--ghost"
                      onClick={() => { setFile(null); setPreview([]); setHasErrors(false); }}
                    >
                      Clear File
                    </button>
                    <button
                      type="button"
                      className="btn btn--primary"
                      onClick={handleImport}
                      disabled={importing || validating || hasErrors}
                    >
                      {validating ? (
                        <><span className="spinner spinner--sm" /> Validating…</>
                      ) : importing ? (
                        <><span className="spinner spinner--sm" /> Importing…</>
                      ) : hasErrors ? (
                        `Fix Errors Before Importing`
                      ) : (
                        `Import ${preview.length} Words`
                      )}
                    </button>
                  </div>
                </>
              )}
            </>
          )}
        </div>

        {/* Template download confirmation dialog */}
        {showConfirmModal && (
          <div className="modal-overlay" onClick={() => setShowConfirmModal(false)} style={{ zIndex: 130 }}>
            <div className="modal modal--md" onClick={e => e.stopPropagation()} style={{ maxWidth: 540 }}>
              <div className="modal__icon">📥</div>
              <h2 className="modal__title">Download Lesson Template</h2>
              <p className="modal__subtitle" style={{ fontSize: '0.88rem', color: 'var(--color-text-muted, #64748b)', marginTop: 2, marginBottom: 14 }}>
                Customized for <strong>{lesson?.lesson_title ?? `Lesson ${lessonId?.slice(0, 8)}`}</strong>
                {lesson?.grade_level && (
                  <span className="pos-badge pos--noun" style={{ marginLeft: 8, fontSize: '0.72rem' }}>
                    {lesson.grade_level.replace('GRADE_', 'Grade ')}
                  </span>
                )}
              </p>

              <div style={{
                background: 'var(--color-surface-hover, #f8fafc)',
                border: '1px solid var(--color-border, #e2e8f0)',
                borderRadius: 8,
                padding: '12px 16px',
                fontSize: '0.84rem',
                lineHeight: 1.5,
                color: 'var(--color-text, #1e293b)',
                marginBottom: 18,
                textAlign: 'left'
              }}>
                <div style={{ fontWeight: 600, marginBottom: 6, color: '#4f46e5' }}>
                  ✨ What’s included in this template:
                </div>
                <ul style={{ margin: 0, paddingLeft: 18, display: 'flex', flexDirection: 'column', gap: 4 }}>
                  <li><strong>Target Grade Level:</strong> Pre-set to <code>{lesson?.grade_level ?? 'GRADE_4'}</code>.</li>
                  <li><strong>Multi-POS Samples:</strong> Working examples for <code>NOUN</code> (Pencil), <code>VERB</code> (Write), and <code>ADJECTIVE</code> (Sharp).</li>
                  <li><strong>Hint-to-Word Clues:</strong> Includes <code>hint_definition</code> and <code>hint_cebuano_sentence</code> columns supporting the new 9th activity.</li>
                  <li><strong>Activity Fields:</strong> Same-POS distractors (semicolon separated), <code>{'{BLANK}'}</code> sentences, and full tile sentences.</li>
                  <li><strong>TTS &amp; Media:</strong> Cebuano/English pronunciation audio texts and image asset paths (enables Image Labeling).</li>
                  <li><strong>Context Story:</strong> Pre-filled on Row 1 as one full narrative paragraph interconnecting all lesson words for Module 1 (individual words do not have separate stories).</li>
                </ul>
              </div>

              <div className="modal__actions">
                <button className="btn btn--ghost" onClick={() => setShowConfirmModal(false)} type="button">
                  Cancel
                </button>
                <button
                  className="btn btn--primary"
                  onClick={handleConfirmDownload}
                  type="button"
                >
                  Download CSV Template
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
