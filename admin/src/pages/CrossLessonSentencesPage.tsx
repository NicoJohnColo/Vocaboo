import { useState, useEffect, useCallback } from 'react';
import AdminNav from '../components/AdminNav';
import CumulativeReviewService from '../services/CumulativeReviewService';
import { LessonService } from '../services/LessonService';
import type { AdminLesson } from '../services/LessonService';
import { VocabularyService } from '../services/VocabularyService';
import type { AdminVocabularyWord } from '../services/VocabularyService';
import type { CrossLessonSentence } from '../types';

export default function CrossLessonSentencesPage() {
  const [sentences, setSentences] = useState<CrossLessonSentence[]>([]);
  const [lessons, setLessons] = useState<AdminLesson[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  
  const [selectedLesson1, setSelectedLesson1] = useState('');
  const [selectedLesson2, setSelectedLesson2] = useState('');
  const [words1, setWords1] = useState<AdminVocabularyWord[]>([]);
  const [words2, setWords2] = useState<AdminVocabularyWord[]>([]);
  
  const [wordA, setWordA] = useState('');
  const [wordB, setWordB] = useState('');
  const [sentenceText, setSentenceText] = useState('');
  const [sentenceTranslation, setSentenceTranslation] = useState('');
  const [coverageGaps, setCoverageGaps] = useState<any[]>([]);
  const [importing, setImporting] = useState(false);
  const [importResult, setImportResult] = useState('');

  const loadSentences = useCallback(async () => {
    try {
      const data = await CumulativeReviewService.getAllCrossLessonSentences();
      setSentences(data);
    } catch (err: any) {
      setError(err.message);
    }
  }, []);

  const loadLessons = useCallback(async () => {
    try {
      setLoading(true);
      const data = await LessonService.getAll();
      setLessons(data);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadLessons();
    loadSentences();
  }, [loadLessons, loadSentences]);

  useEffect(() => {
    if (selectedLesson1) {
      VocabularyService.getWords(selectedLesson1).then(setWords1).catch(console.error);
    } else {
      setWords1([]);
    }
    setWordA('');
  }, [selectedLesson1]);

  useEffect(() => {
    if (selectedLesson2) {
      VocabularyService.getWords(selectedLesson2).then(setWords2).catch(console.error);
    } else {
      setWords2([]);
    }
    setWordB('');
  }, [selectedLesson2]);

  const loadCoverageGaps = useCallback(async () => {
    if (selectedLesson1 && selectedLesson2) {
      try {
        const gaps = await CumulativeReviewService.getCoverageGaps(selectedLesson1, selectedLesson2);
        setCoverageGaps(gaps);
      } catch (err) {
        console.error('Failed to load coverage gaps', err);
      }
    }
  }, [selectedLesson1, selectedLesson2]);

  useEffect(() => {
    loadCoverageGaps();
  }, [loadCoverageGaps, sentences]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!wordA || !wordB || !sentenceText || !selectedLesson1 || !selectedLesson2) return;

    const wA = words1.find(w => w.word_id === wordA);
    const wB = words2.find(w => w.word_id === wordB);
    if (!wA || !wB) return;

    try {
      await CumulativeReviewService.createCrossLessonSentence({
        sentenceText,
        sentenceTranslation,
        wordA: { wordId: wA.word_id, englishWord: wA.english_word, cebuanoMeaning: wA.cebuano_meaning },
        wordB: { wordId: wB.word_id, englishWord: wB.english_word, cebuanoMeaning: wB.cebuano_meaning },
        lessonPairId: `${selectedLesson1}_${selectedLesson2}`
      });
      setSentenceText('');
      setSentenceTranslation('');
      setWordA('');
      setWordB('');
      loadSentences();
    } catch (err: any) {
      alert(err.message);
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this sentence?')) return;
    try {
      await CumulativeReviewService.deleteCrossLessonSentence(id);
      loadSentences();
    } catch (err: any) {
      alert(err.message);
    }
  };

  const parseCsvLine = (text: string): string[] => {
    const p: string[] = [];
    let cur = '';
    let inQuotes = false;
    for (let i = 0; i < text.length; i++) {
      const c = text[i];
      if (c === '"') {
        inQuotes = !inQuotes;
      } else if (c === ',' && !inQuotes) {
        p.push(cur.trim().replace(/^"|"$/g, ''));
        cur = '';
      } else {
        cur += c;
      }
    }
    p.push(cur.trim().replace(/^"|"$/g, ''));
    return p;
  };

  const handleCsvImport = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !selectedLesson1 || !selectedLesson2) return;
    
    setImporting(true);
    setImportResult('');
    
    try {
      const text = await file.text();
      const lines = text.split(/\r?\n/).map(l => l.trim()).filter(l => l);
      
      let successCount = 0;
      let errorCount = 0;
      const errors: string[] = [];
      
      // Skip header if it exists
      const startIndex = lines[0].toLowerCase().includes('word_a') ? 1 : 0;
      
      for (let i = startIndex; i < lines.length; i++) {
        const parts = parseCsvLine(lines[i]);
        if (parts.length >= 4) {
          const wordAEng = parts[0].trim();
          const wordBEng = parts[1].trim();
          const sentText = parts[2].trim();
          const sentTrans = parts.slice(3).join(',').trim();
          
          let wA = words1.find(w => w.english_word.toLowerCase() === wordAEng.toLowerCase());
          let wB = words2.find(w => w.english_word.toLowerCase() === wordBEng.toLowerCase());
          
          if (!wA || !wB) {
            // Check if reversed (wordA in lesson2 and wordB in lesson1)
            const revA = words1.find(w => w.english_word.toLowerCase() === wordBEng.toLowerCase());
            const revB = words2.find(w => w.english_word.toLowerCase() === wordAEng.toLowerCase());
            if (revA && revB) {
              wA = revA;
              wB = revB;
            }
          }
          
          if (wA && wB) {
            try {
              await CumulativeReviewService.createCrossLessonSentence({
                sentenceText: sentText,
                sentenceTranslation: sentTrans,
                wordA: { wordId: wA.word_id, englishWord: wA.english_word, cebuanoMeaning: wA.cebuano_meaning },
                wordB: { wordId: wB.word_id, englishWord: wB.english_word, cebuanoMeaning: wB.cebuano_meaning },
                lessonPairId: `${selectedLesson1}_${selectedLesson2}`
              });
              successCount++;
            } catch (err: any) {
              errorCount++;
              errors.push(`Row ${i + 1} (${wordAEng}, ${wordBEng}): ${err.message}`);
            }
          } else {
            errorCount++;
            const missing = [];
            if (!words1.some(w => w.english_word.toLowerCase() === wordAEng.toLowerCase() || w.english_word.toLowerCase() === wordBEng.toLowerCase())) {
              missing.push(`neither '${wordAEng}' nor '${wordBEng}' found in Lesson 1`);
            }
            if (!words2.some(w => w.english_word.toLowerCase() === wordAEng.toLowerCase() || w.english_word.toLowerCase() === wordBEng.toLowerCase())) {
              missing.push(`neither '${wordAEng}' nor '${wordBEng}' found in Lesson 2`);
            }
            errors.push(`Row ${i + 1}: ${missing.join(', ')}`);
          }
        }
      }
      setImportResult(`Import complete: ${successCount} imported, ${errorCount} failed.` + (errors.length > 0 ? ` Errors: ${errors.slice(0, 3).join('; ')}` : ''));
      loadSentences();
    } catch (err: any) {
      alert('Error parsing CSV: ' + err.message);
    } finally {
      setImporting(false);
      if (e.target) e.target.value = '';
    }
  };

  return (
    <div className="admin-layout">
      <AdminNav />
      <main className="admin-main">
        <header className="admin-main__header">
          <h1>Cross-Lesson Sentences (Module 4)</h1>
        </header>

        {error && <div className="alert alert--error">{error}</div>}
        {loading && <p>Loading...</p>}

        {!loading && (
          <div className="form-group" style={{ display: 'flex', gap: '1rem', marginBottom: '2rem' }}>
            <div>
              <label>Lesson 1</label>
              <select value={selectedLesson1} onChange={e => setSelectedLesson1(e.target.value)} className="form-input">
                <option value="">Select Lesson 1</option>
                {lessons.map(l => <option key={l.lesson_id} value={l.lesson_id}>[{l.category_name}] {l.lesson_title}</option>)}
              </select>
            </div>
            <div>
              <label>Lesson 2</label>
              <select value={selectedLesson2} onChange={e => setSelectedLesson2(e.target.value)} className="form-input">
                <option value="">Select Lesson 2</option>
                {lessons.filter(l => l.lesson_id !== selectedLesson1).map(l => (
                  <option key={l.lesson_id} value={l.lesson_id}>[{l.category_name}] {l.lesson_title}</option>
                ))}
              </select>
            </div>
          </div>
        )}

        {selectedLesson1 && selectedLesson2 && (
          <div style={{ display: 'flex', gap: '2rem', alignItems: 'flex-start' }}>
            <div style={{ flex: 1 }}>
              <div className="card">
                <h2>Add Sentence Puzzle</h2>
                <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '1rem', marginTop: '1rem' }}>
                  <div>
                    <label>Word A (Lesson 1)</label>
                    <select value={wordA} onChange={e => setWordA(e.target.value)} className="form-input" required>
                      <option value="">Select Word</option>
                      {words1.map(w => <option key={w.word_id} value={w.word_id}>{w.english_word}</option>)}
                    </select>
                  </div>
                  <div>
                    <label>Word B (Lesson 2)</label>
                    <select value={wordB} onChange={e => setWordB(e.target.value)} className="form-input" required>
                      <option value="">Select Word</option>
                      {words2.map(w => <option key={w.word_id} value={w.word_id}>{w.english_word}</option>)}
                    </select>
                  </div>
                  <div>
                    <label>Sentence Text</label>
                    <textarea 
                      value={sentenceText} 
                      onChange={e => setSentenceText(e.target.value)} 
                      className="form-input" 
                      required 
                      rows={3}
                      placeholder="e.g. The sun is hot today."
                    />
                  </div>
                  <div>
                    <label>Cebuano Translation (Hint)</label>
                    <textarea 
                      value={sentenceTranslation} 
                      onChange={e => setSentenceTranslation(e.target.value)} 
                      className="form-input" 
                      required 
                      rows={2}
                      placeholder="e.g. Init ang adlaw karon."
                    />
                  </div>
                  <button type="submit" className="btn btn--primary">Save Sentence</button>
                </form>

                <div style={{ marginTop: '2rem', paddingTop: '1rem', borderTop: '1px solid #E2E8F0' }}>
                  <h3>Bulk Import (CSV)</h3>
                  <p style={{ fontSize: '0.875rem', color: '#64748B', marginBottom: '0.5rem' }}>
                    Format: <code>word_a, word_b, sentence_text, sentence_translation</code>
                  </p>
                  <input 
                    type="file" 
                    accept=".csv" 
                    onChange={handleCsvImport} 
                    disabled={importing}
                    className="form-input" 
                  />
                  {importing && <p style={{ color: '#0EA5E9', marginTop: '0.5rem' }}>Importing...</p>}
                  {importResult && <p style={{ color: '#10B981', marginTop: '0.5rem' }}>{importResult}</p>}
                </div>
              </div>

              <div className="card" style={{ marginTop: '2rem' }}>
                <h2>Authored Sentences for {selectedLesson1}_{selectedLesson2}</h2>
                <table className="data-table" style={{ width: '100%', marginTop: '1rem' }}>
                  <thead>
                    <tr>
                      <th>Sentence</th>
                      <th>Translation</th>
                      <th>Word A</th>
                      <th>Word B</th>
                      <th>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {sentences.filter(s => s.lessonPairId === `${selectedLesson1}_${selectedLesson2}`).map(s => (
                      <tr key={s.id}>
                        <td>{s.sentenceText}</td>
                        <td>{s.sentenceTranslation}</td>
                        <td>{s.wordA?.englishWord}</td>
                        <td>{s.wordB?.englishWord}</td>
                        <td>
                          <button onClick={() => handleDelete(s.id!)} className="btn btn--danger btn--small">Delete</button>
                        </td>
                      </tr>
                    ))}
                    {sentences.filter(s => s.lessonPairId === `${selectedLesson1}_${selectedLesson2}`).length === 0 && (
                      <tr><td colSpan={4}>No sentences found for this pair.</td></tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>

            <div style={{ width: '300px' }}>
              <div className="card" style={{ border: coverageGaps.length > 0 ? '2px solid #ef4444' : '2px solid #22c55e' }}>
                <h3 style={{ color: coverageGaps.length > 0 ? '#ef4444' : '#22c55e' }}>
                  Coverage Indicator
                </h3>
                <p style={{ fontSize: '0.875rem', color: '#666', marginBottom: '1rem' }}>
                  Words from these lessons with ZERO authored sentences.
                </p>
                {coverageGaps.length === 0 ? (
                  <p><strong>Excellent!</strong> All words have coverage.</p>
                ) : (
                  <ul style={{ paddingLeft: '1.25rem' }}>
                    {coverageGaps.map(gap => (
                      <li key={gap.wordId} style={{ marginBottom: '0.5rem' }}>
                        {gap.englishWord}
                        <span style={{ fontSize: '0.75rem', color: '#888', display: 'block' }}>
                          ({gap.lessonId === selectedLesson1 ? 'Lesson 1' : 'Lesson 2'})
                        </span>
                      </li>
                    ))}
                  </ul>
                )}
              </div>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
