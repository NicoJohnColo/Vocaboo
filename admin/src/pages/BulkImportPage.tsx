import React, { useState, useCallback } from 'react';
import { useNavigate, useParams, useLocation } from 'react-router-dom';
import AdminNav from '../components/AdminNav';
import { VocabularyService } from '../services/VocabularyService';

interface ImportRow {
  english_word: string;
  cebuano_meaning: string;
  part_of_speech: string;
  grade_level: string;
  example_sentence_english: string;
  example_sentence_cebuano: string;
  audio_path: string;
  image_path: string;
  // Per-word activity content fields
  distractor_pool: string;
  fill_blank_sentence: string;
  tile_sentence: string;
  hint_text: string;
  audio_text_cebuano: string;
  audio_text_english: string;
  _status?: 'ok' | 'error' | 'duplicate';
  _error?: string;
}

const CSV_HEADERS = [
  'english_word', 'cebuano_meaning', 'part_of_speech', 'grade_level',
  'example_sentence_english', 'example_sentence_cebuano', 'audio_path', 'image_path',
  'distractor_pool', 'fill_blank_sentence', 'tile_sentence', 'hint_text',
  'audio_text_cebuano', 'audio_text_english', 'context_paragraph', 'eligible_activity_types'
];

function parseCSV(text: string): ImportRow[] {
  const lines = text.trim().split('\n');
  if (lines.length < 2) return [];
  return lines.slice(1).filter(l => l.trim()).map(line => {
    const cols = line.split(',').map(c => c.replace(/^"|"$/g, '').trim());
    return CSV_HEADERS.reduce((obj, key, i) => {
      (obj as unknown as Record<string, string>)[key] = cols[i] ?? '';
      return obj;
    }, {} as ImportRow);
  });
}

export default function BulkImportPage() {
  const { lessonId } = useParams<{ lessonId: string }>();
  const navigate = useNavigate();
  const location = useLocation();
  const lesson = (location.state as { lesson?: { lesson_title: string } })?.lesson;

  const [file, setFile] = useState<File | null>(null);
  const [preview, setPreview] = useState<ImportRow[]>([]);
  const [importing, setImporting] = useState(false);
  const [result, setResult] = useState<{ success: number; skipped: number; errors: unknown[] } | null>(null);
  const [error, setError] = useState('');
  const [showConfirmModal, setShowConfirmModal] = useState(false);
  const [validating, setValidating] = useState(false);
  const [hasErrors, setHasErrors] = useState(false);

  const validateFile = async (f: File) => {
    if (!lessonId) return;
    setValidating(true);
    setHasErrors(false);
    try {
      const res = await VocabularyService.bulkImport(lessonId, f, { dryRun: true });
      const backendErrors = (res.errors as Array<{ row: string, error: string }> || []);
      
      setPreview(prev => prev.map((row, index) => {
        const rowIndexStr = String(index + 1); // backend uses 1-based index (not counting header)
        const rowError = backendErrors.find(e => e.row === rowIndexStr);
        if (rowError) {
          return { ...row, _status: 'error', _error: rowError.error };
        }
        return { ...row, _status: 'ok' };
      }));

      if (backendErrors.length > 0) {
        setHasErrors(true);
      }
    } catch (err: unknown) {
      console.error("Validation error", err);
      setHasErrors(true);
    } finally {
      setValidating(false);
    }
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const f = e.target.files?.[0];
    if (!f) return;
    setFile(f);
    setResult(null);
    const reader = new FileReader();
    reader.onload = ev => {
      const text = ev.target?.result as string;
      setPreview(parseCSV(text));
      validateFile(f);
    };
    reader.readAsText(f);
  };

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    const f = e.dataTransfer.files[0];
    if (f && f.name.endsWith('.csv')) {
      setFile(f);
      const reader = new FileReader();
      reader.onload = ev => {
        setPreview(parseCSV(ev.target?.result as string));
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
      setResult(res as { success: number; skipped: number; errors: unknown[] });
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Import failed');
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
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed to download template');
    }
  };

  return (
    <div className="admin-layout">
      <AdminNav />
      <main className="admin-main" style={{ maxWidth: 1100 }}>
        <header className="admin-main__header">
          <div>
            <button className="btn btn--ghost btn--sm" style={{ marginBottom: 12 }}
              onClick={() => navigate(`/lessons/${lessonId}/vocabulary`, { state: { lesson } })}>
              ← Back to Vocabulary
            </button>
            <h1 className="admin-main__title">📥 Bulk Import Vocabulary</h1>
            <p className="admin-main__subtitle">{lesson?.lesson_title ?? `Lesson ${lessonId?.slice(0, 8)}`}</p>
          </div>
          <button className="btn btn--ghost btn--sm" onClick={downloadTemplate}>
            📄 Download CSV Template
          </button>
        </header>

        {error && <div className="alert alert--error">{error}</div>}

        {/* Result banner */}
        {result && (
          <div className="import-result">
            <div className="import-result__stat import-result__stat--success">
              ✅ <strong>{result.success}</strong> imported
            </div>
            {result.skipped > 0 && (
              <div className="import-result__stat import-result__stat--warn">
                ⚠️ <strong>{result.skipped}</strong> duplicates skipped
              </div>
            )}
            {result.errors.length > 0 && (
              <div className="import-result__stat import-result__stat--error">
                ❌ <strong>{result.errors.length}</strong> errors
              </div>
            )}
            <button className="btn btn--primary btn--sm" style={{ marginLeft: 'auto' }}
              onClick={() => navigate(`/lessons/${lessonId}/vocabulary`, { state: { lesson } })}>
              View Words →
            </button>
          </div>
        )}

        {/* Upload zone */}
        {!result && (
          <>
            <div
              className={`dropzone ${file ? 'dropzone--active' : ''}`}
              onDrop={handleDrop}
              onDragOver={e => e.preventDefault()}
            >
              {file ? (
                <div className="dropzone__file">
                  <span className="dropzone__icon">📄</span>
                  <span className="dropzone__filename">{file.name}</span>
                  <span className="dropzone__size">({(file.size / 1024).toFixed(1)} KB)</span>
                  <button className="btn btn--ghost btn--sm" onClick={() => { setFile(null); setPreview([]); }}>
                    ✕ Remove
                  </button>
                </div>
              ) : (
                <div className="dropzone__prompt">
                  <div className="dropzone__icon">📥</div>
                  <p>Drag &amp; drop a <strong>.csv</strong> file here, or</p>
                  <label className="btn btn--primary btn--sm" style={{ cursor: 'pointer' }}>
                    Choose File
                    <input type="file" accept=".csv" onChange={handleFileChange} style={{ display: 'none' }} />
                  </label>
                  <p className="dropzone__hint">Required: english_word, cebuano_meaning, part_of_speech, grade_level, example_en, example_ceb<br/>Optional: audio_path, image_path, distractor_pool, fill_blank_sentence, tile_sentence, hint_text, audio_text_cebuano, audio_text_english</p>
                </div>
              )}
            </div>

            {/* Preview table */}
            {preview.length > 0 && (
              <>
                <div className="table-meta" style={{ margin: '16px 0 8px' }}>
                  Previewing <strong>{preview.length}</strong> rows — review before importing
                </div>
                <div className="accounts-table-wrap" style={{ maxHeight: 400, overflowY: 'auto' }}>
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
                        <th>Hint</th>
                        <th>TTS (CEB)</th>
                        <th>TTS (EN)</th>
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
                            <td className="text-muted">{row.grade_level?.replace('_', ' ')}</td>
                            <td className="text-muted" style={{ fontSize: '0.8rem' }}>{row.example_sentence_english}</td>
                            <td className="text-muted" style={{ fontSize: '0.8rem' }}>{row.example_sentence_cebuano || <span style={{ opacity: 0.4 }}>—</span>}</td>
                            <td className="text-muted" style={{ fontSize: '0.8rem' }}>{row.distractor_pool || <span style={{ opacity: 0.4 }}>—</span>}</td>
                            <td className="text-muted" style={{ fontSize: '0.8rem' }}>{row.fill_blank_sentence || <span style={{ opacity: 0.4 }}>—</span>}</td>
                            <td className="text-muted" style={{ fontSize: '0.8rem' }}>{row.tile_sentence || <span style={{ opacity: 0.4 }}>—</span>}</td>
                            <td className="text-muted" style={{ fontSize: '0.8rem' }}>{row.hint_text || <span style={{ opacity: 0.4 }}>—</span>}</td>
                            <td className="text-muted" style={{ fontSize: '0.8rem', maxWidth: 160 }}>
                              <span title={row.audio_text_cebuano} style={{ display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>
                                {row.audio_text_cebuano || <span style={{ opacity: 0.4 }}>—</span>}
                              </span>
                            </td>
                            <td className="text-muted" style={{ fontSize: '0.8rem', maxWidth: 160 }}>
                              <span title={row.audio_text_english} style={{ display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>
                                {row.audio_text_english || <span style={{ opacity: 0.4 }}>—</span>}
                              </span>
                            </td>
                          </tr>
                        </React.Fragment>
                      ))}
                    </tbody>
                  </table>
                </div>

                {/* Error summary panel */}
                {hasErrors && (
                  <div style={{
                    marginTop: 16,
                    background: 'rgba(255,0,0,0.04)',
                    border: '1px solid rgba(255,0,0,0.25)',
                    borderRadius: 10,
                    padding: '14px 18px'
                  }}>
                    <div style={{ fontWeight: 700, color: 'var(--color-danger)', marginBottom: 10, fontSize: '0.9rem' }}>❌ Formatting errors found — fix these before importing:</div>
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
                  <button className="btn btn--ghost" onClick={() => { setFile(null); setPreview([]); setHasErrors(false); }}>
                    Cancel
                  </button>
                  <button className="btn btn--primary" onClick={handleImport} disabled={importing || validating || hasErrors}>
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

        {showConfirmModal && (
          <div className="modal-overlay" onClick={() => setShowConfirmModal(false)}>
            <div className="modal modal--sm" onClick={e => e.stopPropagation()}>
              <div className="modal__icon">📄</div>
              <h2 className="modal__title">Download Template</h2>
              <p className="modal__note">Are you sure you want to download the CSV template?</p>
              <div className="modal__actions">
                <button className="btn btn--ghost" onClick={() => setShowConfirmModal(false)}>
                  Cancel
                </button>
                <button
                  className="btn btn--primary"
                  onClick={handleConfirmDownload}
                >
                  Download
                </button>
              </div>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
