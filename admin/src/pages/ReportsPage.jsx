import { useState, useEffect } from 'react';
import AdminNav from '../components/AdminNav';
import { ReportService } from '../services/ReportService';
import { SectionService } from '../services/SectionService';
import { LessonService } from '../services/LessonService';
import { LearnerService } from '../services/LearnerService';

export default function ReportsPage() {
  const [sections, setSections] = useState([]);
  const [lessons, setLessons] = useState([]);
  const [learners, setLearners] = useState([]);
  const [loadingInitial, setLoadingInitial] = useState(true);

  // Form states
  const [classSectionId, setClassSectionId] = useState('');
  const [classGrade, setClassGrade] = useState('');
  const [classFormat, setClassFormat] = useState('pdf');
  const [downloadingClass, setDownloadingClass] = useState(false);

  const [selectedLearnerId, setSelectedLearnerId] = useState('');
  const [studentFormat, setStudentFormat] = useState('pdf');
  const [downloadingStudent, setDownloadingStudent] = useState(false);

  const [wordSectionId, setWordSectionId] = useState('');
  const [wordLessonId, setWordLessonId] = useState('');
  const [wordFormat, setWordFormat] = useState('csv');
  const [downloadingWord, setDownloadingWord] = useState(false);

  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const flash = (msg) => { setSuccess(msg); setTimeout(() => setSuccess(''), 4000); };

  useEffect(() => {
    Promise.all([
      SectionService.getAllSections().catch(() => []),
      LessonService.getAll().catch(() => []),
      LearnerService.getLearners({ page: 0, size: 100 }).catch(() => ({ content: [] })),
    ]).then(([secList, lesList, lrnPage]) => {
      setSections(secList);
      setLessons(lesList);
      setLearners(lrnPage.content || []);
      if (lrnPage.content?.length > 0) {
        setSelectedLearnerId(lrnPage.content[0].learnerId);
      }
      setLoadingInitial(false);
    });
  }, []);

  const handleDownloadClass = async () => {
    setDownloadingClass(true);
    setError('');
    try {
      await ReportService.downloadClassReport(classFormat, classSectionId || null, classGrade || null);
      flash(`Class report (${classFormat.toUpperCase()}) downloaded successfully!`);
    } catch (err) {
      setError(err?.message || 'Failed to download class report.');
    } finally {
      setDownloadingClass(false);
    }
  };

  const handleDownloadStudent = async () => {
    if (!selectedLearnerId) return;
    setDownloadingStudent(true);
    setError('');
    try {
      await ReportService.downloadIndividualReport(selectedLearnerId, studentFormat);
      flash(`Student report card (${studentFormat.toUpperCase()}) downloaded successfully!`);
    } catch (err) {
      setError(err?.message || 'Failed to download student report card.');
    } finally {
      setDownloadingStudent(false);
    }
  };

  const handleDownloadWord = async () => {
    setDownloadingWord(true);
    setError('');
    try {
      await ReportService.downloadWordPerformanceReport(wordFormat, wordSectionId || null, wordLessonId || null);
      flash(`Word performance report (${wordFormat.toUpperCase()}) downloaded successfully!`);
    } catch (err) {
      setError(err?.message || 'Failed to download word performance report.');
    } finally {
      setDownloadingWord(false);
    }
  };

  return (
    <div className="admin-layout">
      <AdminNav />
      <main className="admin-main" style={{ maxWidth: 1000 }}>
        <header className="admin-main__header">
          <div>
            <h1 className="admin-main__title">📊 Reports &amp; Data Export Hub</h1>
            <p className="admin-main__subtitle">Generate official grade-level performance tables, diagnostic report cards, and curriculum analytics</p>
          </div>
        </header>

        {error && <div className="alert alert--error" onClick={() => setError('')}>{error}</div>}
        {success && <div className="alert alert--success">{success}</div>}

        {loadingInitial ? (
          <div className="auth-loading" style={{ minHeight: 300 }}><div className="spinner" /></div>
        ) : (
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: 24 }}>
            
            {/* Card 1: Class Performance Report */}
            <div style={{
              background: 'var(--glass-bg)',
              borderRadius: 'var(--radius-md)',
              padding: 24,
              border: '1px solid var(--color-border)',
              display: 'flex',
              flexDirection: 'column',
              justifyContent: 'space-between',
            }}>
              <div>
                <div style={{ fontSize: '1.8rem', marginBottom: 8 }}>🏫</div>
                <h2 style={{ fontSize: '1.2rem', margin: '0 0 8px 0', color: 'var(--color-primary)' }}>
                  Class Performance Report
                </h2>
                <p style={{ fontSize: '0.85rem', color: 'var(--color-text-dim)', marginBottom: 20 }}>
                  Comprehensive roster report with student names, points, overall accuracy %, completed lesson counts, and mastery metrics.
                </p>

                <div className="form-field" style={{ marginBottom: 12 }}>
                  <label className="form-label">Filter by Class / Section</label>
                  <select
                    className="form-select"
                    value={classSectionId}
                    onChange={e => setClassSectionId(e.target.value)}
                  >
                    <option value="">All Classes (School-wide)</option>
                    {sections.map(s => (
                      <option key={s.section_id} value={s.section_id}>{s.section_name}</option>
                    ))}
                  </select>
                </div>

                <div className="form-field" style={{ marginBottom: 16 }}>
                  <label className="form-label">Filter by Grade Level</label>
                  <select
                    className="form-select"
                    value={classGrade}
                    onChange={e => setClassGrade(e.target.value)}
                  >
                    <option value="">All Grades</option>
                    <option value="GRADE_3_4">Grade 3-4</option>
                    <option value="GRADE_5_6">Grade 5-6</option>
                    <option value="GRADE_6">Grade 6</option>
                  </select>
                </div>

                <div className="form-field" style={{ marginBottom: 20 }}>
                  <label className="form-label">Export Format</label>
                  <div style={{ display: 'flex', gap: 16 }}>
                    <label style={{ display: 'flex', alignItems: 'center', gap: 6, cursor: 'pointer' }}>
                      <input
                        type="radio"
                        name="classFormat"
                        value="pdf"
                        checked={classFormat === 'pdf'}
                        onChange={() => setClassFormat('pdf')}
                      />
                      <span>PDF Document</span>
                    </label>
                    <label style={{ display: 'flex', alignItems: 'center', gap: 6, cursor: 'pointer' }}>
                      <input
                        type="radio"
                        name="classFormat"
                        value="csv"
                        checked={classFormat === 'csv'}
                        onChange={() => setClassFormat('csv')}
                      />
                      <span>CSV Spreadsheet</span>
                    </label>
                  </div>
                </div>
              </div>

              <button
                className="btn btn--primary"
                onClick={handleDownloadClass}
                disabled={downloadingClass}
                style={{ width: '100%' }}
              >
                {downloadingClass ? <span className="spinner spinner--sm" /> : `📥 Export Class Report (${classFormat.toUpperCase()})`}
              </button>
            </div>

            {/* Card 2: Individual Student Report Card */}
            <div style={{
              background: 'var(--glass-bg)',
              borderRadius: 'var(--radius-md)',
              padding: 24,
              border: '1px solid var(--color-border)',
              display: 'flex',
              flexDirection: 'column',
              justifyContent: 'space-between',
            }}>
              <div>
                <div style={{ fontSize: '1.8rem', marginBottom: 8 }}>👤</div>
                <h2 style={{ fontSize: '1.2rem', margin: '0 0 8px 0', color: 'var(--color-accent-2)' }}>
                  Individual Student Report Card
                </h2>
                <p style={{ fontSize: '0.85rem', color: 'var(--color-text-dim)', marginBottom: 20 }}>
                  Personal student report card complete with lesson breakdown table, mastery status, and weak words needing reinforcement.
                </p>

                <div className="form-field" style={{ marginBottom: 16 }}>
                  <label className="form-label">Select Student *</label>
                  <select
                    className="form-select"
                    value={selectedLearnerId}
                    onChange={e => setSelectedLearnerId(e.target.value)}
                  >
                    {learners.length === 0 && <option value="">No students available</option>}
                    {learners.map(l => (
                      <option key={l.learnerId} value={l.learnerId}>
                        {l.displayName} ({l.sectionName || 'Unassigned'})
                      </option>
                    ))}
                  </select>
                </div>

                <div className="form-field" style={{ marginBottom: 20 }}>
                  <label className="form-label">Export Format</label>
                  <div style={{ display: 'flex', gap: 16 }}>
                    <label style={{ display: 'flex', alignItems: 'center', gap: 6, cursor: 'pointer' }}>
                      <input
                        type="radio"
                        name="studentFormat"
                        value="pdf"
                        checked={studentFormat === 'pdf'}
                        onChange={() => setStudentFormat('pdf')}
                      />
                      <span>PDF Document</span>
                    </label>
                    <label style={{ display: 'flex', alignItems: 'center', gap: 6, cursor: 'pointer' }}>
                      <input
                        type="radio"
                        name="studentFormat"
                        value="csv"
                        checked={studentFormat === 'csv'}
                        onChange={() => setStudentFormat('csv')}
                      />
                      <span>CSV Spreadsheet</span>
                    </label>
                  </div>
                </div>
              </div>

              <button
                className="btn btn--primary"
                onClick={handleDownloadStudent}
                disabled={downloadingStudent || !selectedLearnerId}
                style={{ width: '100%' }}
              >
                {downloadingStudent ? <span className="spinner spinner--sm" /> : `📥 Export Report Card (${studentFormat.toUpperCase()})`}
              </button>
            </div>

            {/* Card 3: Curriculum & Word Performance */}
            <div style={{
              background: 'var(--glass-bg)',
              borderRadius: 'var(--radius-md)',
              padding: 24,
              border: '1px solid var(--color-border)',
              display: 'flex',
              flexDirection: 'column',
              justifyContent: 'space-between',
            }}>
              <div>
                <div style={{ fontSize: '1.8rem', marginBottom: 8 }}>📚</div>
                <h2 style={{ fontSize: '1.2rem', margin: '0 0 8px 0', color: '#f59e0b' }}>
                  Word &amp; Curriculum Report
                </h2>
                <p style={{ fontSize: '0.85rem', color: 'var(--color-text-dim)', marginBottom: 20 }}>
                  Word-level metrics breakdown: total attempts, overall accuracy, demerit points, and Module 4 fallback asset triggers.
                </p>

                <div className="form-field" style={{ marginBottom: 12 }}>
                  <label className="form-label">Filter by Lesson</label>
                  <select
                    className="form-select"
                    value={wordLessonId}
                    onChange={e => setWordLessonId(e.target.value)}
                  >
                    <option value="">All Lessons</option>
                    {lessons.map(l => (
                      <option key={l.lesson_id} value={l.lesson_id}>{l.lesson_title}</option>
                    ))}
                  </select>
                </div>

                <div className="form-field" style={{ marginBottom: 16 }}>
                  <label className="form-label">Filter by Class Section</label>
                  <select
                    className="form-select"
                    value={wordSectionId}
                    onChange={e => setWordSectionId(e.target.value)}
                  >
                    <option value="">All Classes</option>
                    {sections.map(s => (
                      <option key={s.section_id} value={s.section_id}>{s.section_name}</option>
                    ))}
                  </select>
                </div>

                <div className="form-field" style={{ marginBottom: 20 }}>
                  <label className="form-label">Export Format</label>
                  <div style={{ display: 'flex', gap: 16 }}>
                    <label style={{ display: 'flex', alignItems: 'center', gap: 6, cursor: 'pointer' }}>
                      <input
                        type="radio"
                        name="wordFormat"
                        value="csv"
                        checked={wordFormat === 'csv'}
                        onChange={() => setWordFormat('csv')}
                      />
                      <span>CSV Spreadsheet</span>
                    </label>
                    <label style={{ display: 'flex', alignItems: 'center', gap: 6, cursor: 'pointer' }}>
                      <input
                        type="radio"
                        name="wordFormat"
                        value="pdf"
                        checked={wordFormat === 'pdf'}
                        onChange={() => setWordFormat('pdf')}
                      />
                      <span>PDF Document</span>
                    </label>
                  </div>
                </div>
              </div>

              <button
                className="btn btn--primary"
                onClick={handleDownloadWord}
                disabled={downloadingWord}
                style={{ width: '100%' }}
              >
                {downloadingWord ? <span className="spinner spinner--sm" /> : `📥 Export Word Performance (${wordFormat.toUpperCase()})`}
              </button>
            </div>

          </div>
        )}
      </main>
    </div>
  );
}
