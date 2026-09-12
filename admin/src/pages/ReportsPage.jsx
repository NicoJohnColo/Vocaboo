import { useState, useEffect, useMemo } from 'react';
import AdminNav from '../components/AdminNav';
import { ReportService } from '../services/ReportService';
import { SectionService } from '../services/SectionService';
import { LessonService } from '../services/LessonService';
import { LearnerService } from '../services/LearnerService';
import { CategoryService } from '../services/CategoryService';
import LearnerDetailModal from '../components/LearnerDetailModal';
import { useAdminAuth } from '../hooks/useAdminAuth';

export default function ReportsPage() {
  const { admin } = useAdminAuth();
  const isTeacher = admin?.role?.toLowerCase() === 'teacher' || admin?.role?.toUpperCase() === 'ROLE_TEACHER';

  const [sections, setSections] = useState([]);
  const [lessons, setLessons] = useState([]);
  const [learners, setLearners] = useState([]);
  const [categories, setCategories] = useState([]);
  const [loadingInitial, setLoadingInitial] = useState(true);

  // Active view tab: 'all' | 'class' | 'student' | 'word'
  const [activeTab, setActiveTab] = useState('all');

  // Preview modal state
  const [previewLearnerId, setPreviewLearnerId] = useState(null);

  // Form states - Card 1: Class Performance
  const [classSectionId, setClassSectionId] = useState('');
  const [classGrade, setClassGrade] = useState('');
  const [classFormat, setClassFormat] = useState('pdf');
  const [downloadingClass, setDownloadingClass] = useState(false);

  // Form states - Card 2: Student Report Card
  const [studentSectionFilter, setStudentSectionFilter] = useState('');
  const [selectedLearnerId, setSelectedLearnerId] = useState('');
  const [studentClassScope, setStudentClassScope] = useState('');
  const [studentFormat, setStudentFormat] = useState('pdf');
  const [downloadingStudent, setDownloadingStudent] = useState(false);
  const [studentEnrolledClasses, setStudentEnrolledClasses] = useState([]);
  const [loadingStudentClasses, setLoadingStudentClasses] = useState(false);

  // Form states - Card 3: Word & Curriculum
  const [wordSectionId, setWordSectionId] = useState('');
  const [wordCategoryId, setWordCategoryId] = useState('');
  const [wordLessonId, setWordLessonId] = useState('');
  const [wordFormat, setWordFormat] = useState('csv');
  const [downloadingWord, setDownloadingWord] = useState(false);

  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const flash = (msg) => {
    setSuccess(msg);
    setTimeout(() => setSuccess(''), 4000);
  };

  useEffect(() => {
    Promise.all([
      SectionService.getAllSections().catch(() => []),
      LessonService.getAll().catch(() => []),
      LearnerService.getLearners({ page: 0, size: 250 }).catch(() => ({ content: [] })),
      CategoryService.getAll().catch(() => []),
    ]).then(([secList, lesList, lrnPage, catList]) => {
      setSections(secList);
      setLessons(lesList);
      setCategories(catList);
      const rawLearners = lrnPage.content || [];
      setLearners(rawLearners);
      if (rawLearners.length > 0) {
        const firstId = rawLearners[0].learner_id || rawLearners[0].learnerId;
        setSelectedLearnerId(firstId);
      }
      setLoadingInitial(false);
    });
  }, []);

  // Filtered learners for student report card
  const filteredLearners = useMemo(() => {
    if (!studentSectionFilter) return learners;
    return learners.filter((l) => (l.section_id || l.sectionId) === studentSectionFilter);
  }, [learners, studentSectionFilter]);

  // Keep selectedLearnerId valid when class filter changes
  useEffect(() => {
    if (filteredLearners.length > 0) {
      const exists = filteredLearners.some(
        (l) => (l.learner_id || l.learnerId) === selectedLearnerId
      );
      if (!exists) {
        setSelectedLearnerId(filteredLearners[0].learner_id || filteredLearners[0].learnerId);
      }
    } else {
      setSelectedLearnerId('');
    }
  }, [filteredLearners, selectedLearnerId]);

  // Fetch student active enrolled classes when selectedLearnerId changes
  useEffect(() => {
    if (!selectedLearnerId) {
      setStudentEnrolledClasses([]);
      setStudentClassScope('');
      return;
    }
    let cancelled = false;
    setLoadingStudentClasses(true);
    LearnerService.getLearnerDetail(selectedLearnerId)
      .then((detail) => {
        if (cancelled) return;
        const rawEnrolled = detail?.enrolled_classes || detail?.enrolledClasses || [];
        const activeEnrolled = rawEnrolled.filter((c) => !c.status || c.status === 'ACTIVE');

        let validClasses = activeEnrolled;
        if (isTeacher) {
          const teacherClassIds = new Set(sections.map((s) => s.section_id || s.sectionId));
          validClasses = activeEnrolled.filter((c) => teacherClassIds.has(c.class_id || c.classId));
        }
        setStudentEnrolledClasses(validClasses);

        if (isTeacher) {
          if (validClasses.length > 0) {
            setStudentClassScope(validClasses[0].class_id || validClasses[0].classId);
          } else {
            setStudentClassScope('');
          }
        } else {
          setStudentClassScope('');
        }
      })
      .catch(() => {
        if (!cancelled) setStudentEnrolledClasses([]);
      })
      .finally(() => {
        if (!cancelled) setLoadingStudentClasses(false);
      });

    return () => {
      cancelled = true;
    };
  }, [selectedLearnerId, isTeacher, sections]);

  // Enforce global scope for administrators across all studios
  useEffect(() => {
    if (!isTeacher) {
      setClassSectionId('');
      setStudentClassScope('');
      setWordSectionId('');
    }
  }, [isTeacher]);

  // Active selected student object
  const currentSelectedStudent = useMemo(() => {
    return learners.find((l) => (l.learner_id || l.learnerId) === selectedLearnerId);
  }, [learners, selectedLearnerId]);

  // Filtered categories for Card 3 (Word & Curriculum)
  const availableWordCategories = useMemo(() => {
    const baseLessons = wordSectionId
      ? lessons.filter((l) => !l.class_id || l.class_id === wordSectionId)
      : (isTeacher
          ? lessons.filter((l) => !l.class_id || sections.some((s) => (s.section_id || s.sectionId) === l.class_id))
          : lessons.filter((l) => !l.class_id));

    const counts = {};
    baseLessons.forEach((l) => {
      const catId = l.category_id || l.categoryId;
      if (catId) counts[catId] = (counts[catId] || 0) + 1;
    });

    return categories
      .filter((c) => (counts[c.category_id] || 0) > 0)
      .map((c) => ({
        ...c,
        lessonCount: counts[c.category_id],
      }));
  }, [categories, lessons, wordSectionId, isTeacher, sections]);

  // Reset wordCategoryId if not available
  useEffect(() => {
    if (wordCategoryId) {
      const exists = availableWordCategories.some((c) => c.category_id === wordCategoryId);
      if (!exists) {
        setWordCategoryId('');
        setWordLessonId('');
      }
    }
  }, [availableWordCategories, wordCategoryId]);

  // Filtered lessons for Card 3 (Word & Curriculum)
  const filteredWordLessons = useMemo(() => {
    let list = lessons;
    if (wordSectionId) {
      list = list.filter((l) => !l.class_id || l.class_id === wordSectionId);
    } else if (isTeacher) {
      const teacherClassIds = new Set(sections.map((s) => s.section_id || s.sectionId));
      list = list.filter((l) => !l.class_id || teacherClassIds.has(l.class_id));
    } else {
      list = list.filter((l) => !l.class_id);
    }
    if (wordCategoryId) {
      list = list.filter((l) => (l.category_id || l.categoryId) === wordCategoryId);
    }
    return list;
  }, [lessons, wordSectionId, isTeacher, sections, wordCategoryId]);

  const handleDownloadClass = async () => {
    if (!isTeacher && classSectionId) {
      setError('Administrators can only export global school-wide reports, not specific teacher classes.');
      return;
    }
    setDownloadingClass(true);
    setError('');
    try {
      await ReportService.downloadClassReport(
        classFormat,
        !isTeacher ? null : (classSectionId || null),
        classGrade || null
      );
      flash(`Class report (${classFormat.toUpperCase()}) downloaded successfully!`);
    } catch (err) {
      setError(err?.message || 'Failed to download class report.');
    } finally {
      setDownloadingClass(false);
    }
  };

  const handleDownloadStudent = async () => {
    if (!selectedLearnerId) return;
    if (!isTeacher && studentClassScope) {
      setError('Administrators can only export global universal student reports, not specific teacher classes.');
      return;
    }
    setDownloadingStudent(true);
    setError('');
    try {
      await ReportService.downloadIndividualReport(
        selectedLearnerId,
        studentFormat,
        !isTeacher ? null : (studentClassScope || null)
      );
      flash(`Student report card (${studentFormat.toUpperCase()}) downloaded successfully!`);
    } catch (err) {
      setError(err?.message || 'Failed to download student report card.');
    } finally {
      setDownloadingStudent(false);
    }
  };

  const handleDownloadWord = async () => {
    if (!isTeacher && wordSectionId) {
      setError('Administrators can only export global curriculum reports, not specific teacher classes.');
      return;
    }
    setDownloadingWord(true);
    setError('');
    try {
      await ReportService.downloadWordPerformanceReport(
        wordFormat,
        !isTeacher ? null : (wordSectionId || null),
        wordLessonId || null,
        wordCategoryId || null
      );
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
      <main className="admin-main">
        <div style={{ maxWidth: 1320, width: '100%' }}>
        {/* Scoped Styles for Reports Hub */}
        <style>{`
          .reports-hub-stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 14px;
            margin-bottom: 24px;
          }
          .reports-stat-pill {
            background: var(--color-surface, #fff);
            border: 1px solid var(--color-border, rgba(15,23,42,0.08));
            border-radius: var(--radius-lg, 14px);
            padding: 12px 18px;
            display: flex;
            align-items: center;
            gap: 14px;
            box-shadow: var(--shadow-xs, 0 1px 3px rgba(15,23,42,0.04));
            transition: transform 0.2s ease, box-shadow 0.2s ease;
          }
          .reports-stat-pill:hover {
            transform: translateY(-1px);
            box-shadow: var(--shadow-card, 0 4px 16px rgba(15,23,42,0.06));
          }
          .reports-stat-icon {
            width: 40px;
            height: 40px;
            border-radius: 10px;
            display: grid;
            place-items: center;
            font-size: 1.25rem;
            flex-shrink: 0;
          }
          .reports-view-tabs {
            display: flex;
            gap: 8px;
            background: rgba(15, 23, 42, 0.04);
            padding: 5px;
            border-radius: 12px;
            margin-bottom: 24px;
            flex-wrap: wrap;
            border: 1px solid var(--color-border, rgba(15,23,42,0.08));
          }
          .reports-view-tab-btn {
            padding: 8px 16px;
            border-radius: 8px;
            border: none;
            background: transparent;
            font-size: 0.85rem;
            font-weight: 700;
            color: var(--color-text-muted, #64748b);
            cursor: pointer;
            transition: all 0.18s ease;
            display: flex;
            align-items: center;
            gap: 6px;
          }
          .reports-view-tab-btn.active {
            background: var(--color-surface, #fff);
            color: var(--primary-mid, #2563eb);
            box-shadow: 0 2px 8px rgba(15,23,42,0.08);
          }
          .segmented-toggle {
            display: flex;
            background: var(--color-surface-2, #f1f5f9);
            border-radius: 10px;
            padding: 3px;
            border: 1px solid var(--color-border, rgba(15,23,42,0.08));
            gap: 3px;
          }
          .segmented-toggle__btn {
            flex: 1;
            padding: 7px 12px;
            border: none;
            border-radius: 7px;
            background: transparent;
            font-size: 0.82rem;
            font-weight: 700;
            color: var(--color-text-muted, #64748b);
            cursor: pointer;
            transition: all 0.18s ease;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
          }
          .segmented-toggle__btn.active {
            background: var(--color-surface, #fff);
            color: var(--primary-mid, #2563eb);
            box-shadow: 0 1px 4px rgba(15,23,42,0.08);
          }
          .report-card-premium {
            background: var(--color-surface, #fff);
            border: 1px solid var(--color-border, rgba(15,23,42,0.08));
            border-radius: var(--radius-xl, 18px);
            padding: 22px;
            box-shadow: var(--shadow-card, 0 4px 16px rgba(15,23,42,0.06));
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            gap: 16px;
            position: relative;
            overflow: hidden;
            transition: transform 0.2s ease, box-shadow 0.2s ease;
          }
          .report-card-premium:hover {
            box-shadow: 0 8px 28px rgba(15,23,42,0.09);
          }
          .learner-detail-preview-box {
            background: linear-gradient(135deg, rgba(37,99,235,0.04), rgba(29,78,216,0.02));
            border: 1px solid rgba(37,99,235,0.18);
            border-radius: 12px;
            padding: 12px 14px;
            margin-top: 12px;
            margin-bottom: 6px;
          }
          .mockup-document-sheet {
            background: #ffffff;
            border: 1px solid #e2e8f0;
            border-radius: 14px;
            padding: 28px;
            box-shadow: 0 10px 30px rgba(15,23,42,0.08);
            font-family: var(--font-body);
          }
        `}</style>

        {/* Header */}
        <header className="admin-main__header" style={{ marginBottom: 20 }}>
          <div>
            <h1 className="admin-main__title">📊 Reports &amp; Data Export Hub</h1>
            <p className="admin-main__subtitle">
              Generate official grade-level performance tables, diagnostic report cards, and curriculum analytics
            </p>
          </div>
        </header>

        {error && (
          <div className="alert alert--error" onClick={() => setError('')} style={{ cursor: 'pointer' }}>
            {error}
          </div>
        )}
        {success && <div className="alert alert--success">{success}</div>}

        {/* Top Hub Quick-Stats Bar */}
        <div className="reports-hub-stats">
          <div className="reports-stat-pill">
            <div className="reports-stat-icon" style={{ background: 'rgba(37,99,235,0.12)', color: '#2563eb' }}>
              🏫
            </div>
            <div>
              <div style={{ fontSize: '0.74rem', fontWeight: 700, textTransform: 'uppercase', color: 'var(--color-text-muted)' }}>
                Class Cohorts
              </div>
              <div style={{ fontSize: '1.2rem', fontWeight: 800, color: 'var(--color-text)' }}>
                {sections.length} Sections
              </div>
            </div>
          </div>

          <div className="reports-stat-pill">
            <div className="reports-stat-icon" style={{ background: 'rgba(16,185,129,0.12)', color: '#059669' }}>
              👥
            </div>
            <div>
              <div style={{ fontSize: '0.74rem', fontWeight: 700, textTransform: 'uppercase', color: 'var(--color-text-muted)' }}>
                Enrolled Students
              </div>
              <div style={{ fontSize: '1.2rem', fontWeight: 800, color: 'var(--color-text)' }}>
                {learners.length} Active
              </div>
            </div>
          </div>

          <div className="reports-stat-pill">
            <div className="reports-stat-icon" style={{ background: 'rgba(245,158,11,0.12)', color: '#d97706' }}>
              📖
            </div>
            <div>
              <div style={{ fontSize: '0.74rem', fontWeight: 700, textTransform: 'uppercase', color: 'var(--color-text-muted)' }}>
                Curriculum Lessons
              </div>
              <div style={{ fontSize: '1.2rem', fontWeight: 800, color: 'var(--color-text)' }}>
                {lessons.length} Modules
              </div>
            </div>
          </div>

          <div className="reports-stat-pill">
            <div className="reports-stat-icon" style={{ background: 'rgba(139,92,246,0.12)', color: '#7c3aed' }}>
              ⚡
            </div>
            <div>
              <div style={{ fontSize: '0.74rem', fontWeight: 700, textTransform: 'uppercase', color: 'var(--color-text-muted)' }}>
                Export Engine
              </div>
              <div style={{ fontSize: '1.1rem', fontWeight: 800, color: 'var(--color-text)' }}>
                PDF &amp; CSV Ready
              </div>
            </div>
          </div>
        </div>

        {/* View Mode Switcher */}
        <div className="reports-view-tabs">
          <button
            type="button"
            className={`reports-view-tab-btn ${activeTab === 'all' ? 'active' : ''}`}
            onClick={() => {
              setActiveTab('all');
              setError('');
            }}
          >
            🗂️ All Reports (Deck)
          </button>
          <button
            type="button"
            className={`reports-view-tab-btn ${activeTab === 'class' ? 'active' : ''}`}
            onClick={() => {
              setActiveTab('class');
              setError('');
            }}
          >
            🏫 Class Performance
          </button>
          <button
            type="button"
            className={`reports-view-tab-btn ${activeTab === 'student' ? 'active' : ''}`}
            onClick={() => {
              setActiveTab('student');
              setError('');
            }}
          >
            👤 Student Report Card
          </button>
          <button
            type="button"
            className={`reports-view-tab-btn ${activeTab === 'word' ? 'active' : ''}`}
            onClick={() => {
              setActiveTab('word');
              setError('');
            }}
          >
            📚 Word &amp; Curriculum
          </button>
        </div>

        {loadingInitial ? (
          <div className="auth-loading" style={{ minHeight: 320 }}>
            <div className="spinner" />
          </div>
        ) : (
          <>
            {/* ════════════════════════════════════════════════════════════════════
                VIEW MODE: ALL REPORTS (BALANCED 3-COLUMN DECK)
               ════════════════════════════════════════════════════════════════════ */}
            {activeTab === 'all' && (
              <div
                style={{
                  display: 'grid',
                  gridTemplateColumns: 'repeat(auto-fit, minmax(350px, 1fr))',
                  gap: 22,
                  alignItems: 'stretch',
                }}
              >
                {/* ── CARD 1: Class Performance Report ── */}
                <div className="report-card-premium">
                  <div>
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                        <div
                          style={{
                            width: 44,
                            height: 44,
                            borderRadius: 12,
                            background: 'linear-gradient(135deg, #3b82f6, #1d4ed8)',
                            display: 'grid',
                            placeItems: 'center',
                            fontSize: '1.35rem',
                            boxShadow: '0 4px 12px rgba(37,99,235,0.25)',
                          }}
                        >
                          🏫
                        </div>
                        <div>
                          <h2 style={{ fontSize: '1.05rem', margin: 0, fontWeight: 800, color: 'var(--color-text)' }}>
                            Class Performance Report
                          </h2>
                          <span style={{ fontSize: '0.74rem', color: 'var(--color-text-muted)' }}>Roster &amp; Cohort Analytics</span>
                        </div>
                      </div>
                      <span className="admin-main__badge">ROSTER</span>
                    </div>

                    <p style={{ fontSize: '0.84rem', color: 'var(--color-text-muted)', lineHeight: 1.5, minHeight: 40, marginBottom: 16 }}>
                      Comprehensive cohort report with student names, points, overall accuracy %, completed lessons, and mastery tiers.
                    </p>

                    <div className="form-field" style={{ marginBottom: 10 }}>
                      <label className="form-label" style={{ fontSize: '0.78rem', fontWeight: 700 }}>
                        Class or Record Scope to Generate
                      </label>
                      <select
                        className="form-select"
                        value={classSectionId}
                        onChange={(e) => setClassSectionId(e.target.value)}
                        style={{ height: 40, fontSize: '0.875rem' }}
                      >
                        <option value="">{isTeacher ? '🌟 All My Classes (Cumulative Roster)' : '🌟 All Classes (School-wide All Learners)'}</option>
                        {isTeacher && sections.map((s) => (
                          <option key={s.section_id} value={s.section_id}>
                            🏫 Specific Class: {s.section_name}
                          </option>
                        ))}
                      </select>
                    </div>

                    {/* Scope Indicator Badge */}
                    <div style={{
                      fontSize: '0.74rem',
                      fontWeight: 700,
                      padding: '5px 10px',
                      borderRadius: 7,
                      background: classSectionId ? 'rgba(37,99,235,0.08)' : 'rgba(15,23,42,0.04)',
                      color: classSectionId ? '#2563eb' : '#64748b',
                      border: '1px solid ' + (classSectionId ? 'rgba(37,99,235,0.2)' : 'rgba(15,23,42,0.08)'),
                      marginBottom: 12,
                      display: 'flex',
                      alignItems: 'center',
                      gap: 6,
                    }}>
                      <span>{classSectionId ? '🎯 Generating Class Roster: ' + (sections.find(s => (s.section_id || s.sectionId) === classSectionId)?.section_name || 'Specific Class') : '🌐 Generating Comprehensive Cohort: All Classes'}</span>
                    </div>

                    <div className="form-field" style={{ marginBottom: 14 }}>
                      <label className="form-label" style={{ fontSize: '0.78rem', fontWeight: 700 }}>
                        Filter by Grade Level
                      </label>
                      <select
                        className="form-select"
                        value={classGrade}
                        onChange={(e) => setClassGrade(e.target.value)}
                        style={{ height: 40, fontSize: '0.875rem' }}
                      >
                        <option value="">All Grades</option>
                        <option value="GRADE_4">Grade 4</option>
                        <option value="GRADE_5">Grade 5</option>
                        <option value="GRADE_6">Grade 6</option>
                      </select>
                    </div>

                    <div className="form-field" style={{ marginBottom: 16 }}>
                      <label className="form-label" style={{ fontSize: '0.78rem', fontWeight: 700 }}>
                        Export Format
                      </label>
                      <div className="segmented-toggle">
                        <button
                          type="button"
                          className={`segmented-toggle__btn ${classFormat === 'pdf' ? 'active' : ''}`}
                          onClick={() => setClassFormat('pdf')}
                        >
                          📄 PDF Document
                        </button>
                        <button
                          type="button"
                          className={`segmented-toggle__btn ${classFormat === 'csv' ? 'active' : ''}`}
                          onClick={() => setClassFormat('csv')}
                        >
                          📊 CSV Spreadsheet
                        </button>
                      </div>
                    </div>
                  </div>

                  <div>
                    <div
                      style={{
                        fontSize: '0.74rem',
                        color: 'var(--color-text-dim)',
                        marginBottom: 10,
                        display: 'flex',
                        alignItems: 'center',
                        gap: 6,
                      }}
                    >
                      <span>✓ Includes: Student Rosters · Total Points · Accuracy % · Mastery</span>
                    </div>
                    <button
                      className="btn btn--primary"
                      onClick={handleDownloadClass}
                      disabled={downloadingClass}
                      style={{ width: '100%', height: 42, justifyContent: 'center' }}
                    >
                      {downloadingClass ? <span className="spinner spinner--sm" /> : `📥 Export ${classSectionId ? 'Class' : 'All Classes'} Report (${classFormat.toUpperCase()})`}
                    </button>
                  </div>
                </div>

                {/* ── CARD 2: Individual Student Report Card ── */}
                <div className="report-card-premium" style={{ border: '1.5px solid rgba(99,102,241,0.25)' }}>
                  <div>
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                        <div
                          style={{
                            width: 44,
                            height: 44,
                            borderRadius: 12,
                            background: 'linear-gradient(135deg, #6366f1, #4f46e5)',
                            display: 'grid',
                            placeItems: 'center',
                            fontSize: '1.35rem',
                            boxShadow: '0 4px 12px rgba(99,102,241,0.25)',
                          }}
                        >
                          👤
                        </div>
                        <div>
                          <h2 style={{ fontSize: '1.05rem', margin: 0, fontWeight: 800, color: 'var(--color-text)' }}>
                            Student Diagnostic Report Card
                          </h2>
                          <span style={{ fontSize: '0.74rem', color: 'var(--color-text-muted)' }}>Detailed Learner Profile</span>
                        </div>
                      </div>
                      <span className="admin-main__badge" style={{ background: 'rgba(99,102,241,0.1)', color: '#4f46e5', borderColor: 'rgba(99,102,241,0.2)' }}>
                        DIAGNOSTIC
                      </span>
                    </div>

                    <p style={{ fontSize: '0.84rem', color: 'var(--color-text-muted)', lineHeight: 1.5, minHeight: 40, marginBottom: 16 }}>
                      Personal report card with POS mastery breakdown, module progress, cumulative retention badges, and weak words.
                    </p>

                    {/* Class filter to narrow down students */}
                    <div className="form-field" style={{ marginBottom: 10 }}>
                      <label className="form-label" style={{ fontSize: '0.78rem', fontWeight: 700 }}>
                        1. Filter Student List by Cohort
                      </label>
                      <select
                        className="form-select"
                        value={studentSectionFilter}
                        onChange={(e) => {
                          const val = e.target.value;
                          setStudentSectionFilter(val);
                          if (isTeacher) {
                            setStudentClassScope(val);
                          }
                        }}
                        style={{ height: 40, fontSize: '0.875rem' }}
                      >
                        <option value="">{isTeacher ? `All My Classes (${learners.length} students)` : `All Classes (${learners.length} students)`}</option>
                        {sections.map((s) => (
                          <option key={s.section_id} value={s.section_id}>
                            {s.section_name}
                          </option>
                        ))}
                      </select>
                    </div>

                    {/* Student Selector */}
                    <div className="form-field" style={{ marginBottom: 10 }}>
                      <label className="form-label" style={{ fontSize: '0.78rem', fontWeight: 700 }}>
                        2. Select Student * ({filteredLearners.length} available)
                      </label>
                      <select
                        className="form-select"
                        value={selectedLearnerId}
                        onChange={(e) => setSelectedLearnerId(e.target.value)}
                        style={{ height: 40, fontSize: '0.875rem', fontWeight: 600 }}
                      >
                        {filteredLearners.length === 0 && <option value="">No students in this section</option>}
                        {filteredLearners.map((l) => {
                          const id = l.learner_id || l.learnerId;
                          const name = l.display_name || l.displayName || 'Student';
                          const sec = l.section_name || l.sectionName || 'Unassigned';
                          return (
                            <option key={id} value={id}>
                              {name} {l.user_id || l.userId ? `[${l.user_id || l.userId}]` : ''} — {sec}
                            </option>
                          );
                        })}
                      </select>
                    </div>

                    {/* Record Scope Selector */}
                    <div className="form-field" style={{ marginBottom: 10 }}>
                      <label className="form-label" style={{ fontSize: '0.78rem', fontWeight: 700 }}>
                        3. Record Scope for Generated Report
                      </label>
                      {loadingStudentClasses ? (
                        <div style={{ padding: '8px 12px', fontSize: '0.8rem', color: '#64748b', background: '#f8fafc', borderRadius: 8, border: '1px solid var(--color-border)' }}>
                          <span className="spinner spinner--xs" /> Verifying active enrolled classes...
                        </div>
                      ) : isTeacher && studentEnrolledClasses.length === 0 ? (
                        <div style={{ padding: '10px 12px', background: '#fef2f2', border: '1px solid #fecaca', borderRadius: 8, fontSize: '0.78rem', color: '#991b1b' }}>
                          ⚠️ Student is not enrolled in any of your active classes (pending mobile app acceptance or unassigned).
                        </div>
                      ) : (
                        <select
                          className="form-select"
                          value={studentClassScope}
                          onChange={(e) => setStudentClassScope(e.target.value)}
                          style={{ height: 40, fontSize: '0.875rem' }}
                        >
                          {!isTeacher ? (
                            <option value="">🌐 All Classes (Global Cumulative Lifetime Record)</option>
                          ) : studentEnrolledClasses.length > 1 ? (
                            <>
                              <option value="">🌟 All My Classes (Combined Student View)</option>
                              {studentEnrolledClasses.map((c) => (
                                <option key={c.class_id || c.classId} value={c.class_id || c.classId}>
                                  🏫 Class: {c.class_name || c.className} {c.class_code || c.classCode ? `(${c.class_code || c.classCode})` : ''}
                                </option>
                              ))}
                            </>
                          ) : (
                            <option value={studentEnrolledClasses[0]?.class_id || studentEnrolledClasses[0]?.classId}>
                              🏫 Class: {studentEnrolledClasses[0]?.class_name || studentEnrolledClasses[0]?.className} {studentEnrolledClasses[0]?.class_code || studentEnrolledClasses[0]?.classCode ? `(${studentEnrolledClasses[0]?.class_code || studentEnrolledClasses[0]?.classCode})` : ''}
                            </option>
                          )}
                        </select>
                      )}
                    </div>

                    {/* Scope Indicator Badge */}
                    <div style={{
                      fontSize: '0.74rem',
                      fontWeight: 700,
                      padding: '5px 10px',
                      borderRadius: 7,
                      background: (isTeacher && studentClassScope) ? 'rgba(99,102,241,0.08)' : 'rgba(15,23,42,0.04)',
                      color: (isTeacher && studentClassScope) ? '#4f46e5' : '#64748b',
                      border: '1px solid ' + ((isTeacher && studentClassScope) ? 'rgba(99,102,241,0.2)' : 'rgba(15,23,42,0.08)'),
                      marginBottom: 10,
                      display: 'flex',
                      alignItems: 'center',
                      gap: 6,
                    }}>
                      <span>
                        {(isTeacher && studentClassScope)
                          ? '🎯 Generating Class Record: ' + (studentEnrolledClasses.find(s => (s.class_id || s.classId) === studentClassScope)?.class_name || studentEnrolledClasses.find(s => (s.class_id || s.classId) === studentClassScope)?.className || 'Specific Class')
                          : (isTeacher ? '🌟 Generating All My Classes (Combined View)' : '🌐 Generating Global Record: All Classes (Cumulative)')}
                      </span>
                    </div>

                    {/* Integrated Learner Details Preview Card */}
                    {currentSelectedStudent && (
                      <div className="learner-detail-preview-box">
                        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
                          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                            <div
                              style={{
                                width: 28,
                                height: 28,
                                borderRadius: 8,
                                background: 'linear-gradient(135deg, #3b82f6, #1d4ed8)',
                                color: '#fff',
                                fontWeight: 800,
                                fontSize: '0.8rem',
                                display: 'grid',
                                placeItems: 'center',
                              }}
                            >
                              {(currentSelectedStudent.display_name || currentSelectedStudent.displayName || 'S').charAt(0).toUpperCase()}
                            </div>
                            <div>
                              <div style={{ fontWeight: 800, fontSize: '0.85rem', color: 'var(--color-text-main)' }}>
                                {currentSelectedStudent.display_name || currentSelectedStudent.displayName}
                              </div>
                              <div style={{ fontSize: '0.7rem', color: 'var(--color-text-muted)' }}>
                                {currentSelectedStudent.section_name || currentSelectedStudent.sectionName || 'Self-Paced'} · {currentSelectedStudent.grade_level ? currentSelectedStudent.grade_level.replace('_', ' ') : 'Grade 4'}
                              </div>
                            </div>
                          </div>
                          <button
                            type="button"
                            className="btn btn--xs btn--ghost"
                            onClick={() => setPreviewLearnerId(selectedLearnerId)}
                            style={{ fontSize: '0.72rem', padding: '3px 8px' }}
                            title="Inspect complete student profile"
                          >
                            🔍 Full Profile
                          </button>
                        </div>

                        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 6, textAlign: 'center' }}>
                          <div style={{ background: '#fff', padding: '4px 6px', borderRadius: 6, border: '1px solid rgba(15,23,42,0.06)' }}>
                            <div style={{ fontSize: '0.66rem', color: 'var(--color-text-muted)' }}>Score</div>
                            <div style={{ fontSize: '0.8rem', fontWeight: 800, color: 'var(--primary-mid)' }}>
                              {(currentSelectedStudent.total_points ?? currentSelectedStudent.totalPoints ?? 0).toLocaleString()}
                            </div>
                          </div>
                          <div style={{ background: '#fff', padding: '4px 6px', borderRadius: 6, border: '1px solid rgba(15,23,42,0.06)' }}>
                            <div style={{ fontSize: '0.66rem', color: 'var(--color-text-muted)' }}>Accuracy</div>
                            <div style={{ fontSize: '0.8rem', fontWeight: 800, color: '#10b981' }}>
                              {Number(currentSelectedStudent.overall_accuracy ?? currentSelectedStudent.overallAccuracy ?? 0).toFixed(1)}%
                            </div>
                          </div>
                          <div style={{ background: '#fff', padding: '4px 6px', borderRadius: 6, border: '1px solid rgba(15,23,42,0.06)' }}>
                            <div style={{ fontSize: '0.66rem', color: 'var(--color-text-muted)' }}>Mastered</div>
                            <div style={{ fontSize: '0.8rem', fontWeight: 800, color: '#f59e0b' }}>
                              {currentSelectedStudent.words_mastered_count ?? currentSelectedStudent.wordsMasteredCount ?? 0} words
                            </div>
                          </div>
                        </div>

                        {(currentSelectedStudent.is_struggling ?? currentSelectedStudent.isStruggling) && (
                          <div style={{ marginTop: 6, fontSize: '0.7rem', color: '#ef4444', fontWeight: 700, display: 'flex', alignItems: 'center', gap: 4 }}>
                            <span>⚠️ Flagged for Teacher Intervention</span>
                          </div>
                        )}
                      </div>
                    )}

                    <div className="form-field" style={{ marginBottom: 16 }}>
                      <label className="form-label" style={{ fontSize: '0.78rem', fontWeight: 700 }}>
                        Export Format
                      </label>
                      <div className="segmented-toggle">
                        <button
                          type="button"
                          className={`segmented-toggle__btn ${studentFormat === 'pdf' ? 'active' : ''}`}
                          onClick={() => setStudentFormat('pdf')}
                        >
                          📄 PDF Document
                        </button>
                        <button
                          type="button"
                          className={`segmented-toggle__btn ${studentFormat === 'csv' ? 'active' : ''}`}
                          onClick={() => setStudentFormat('csv')}
                        >
                          📊 CSV Spreadsheet
                        </button>
                      </div>
                    </div>
                  </div>

                  <div>
                    <div
                      style={{
                        fontSize: '0.74rem',
                        color: 'var(--color-text-dim)',
                        marginBottom: 10,
                        display: 'flex',
                        alignItems: 'center',
                        gap: 6,
                      }}
                    >
                      <span>✓ Matches Diagnostic Modal: POS Breakdown · M1-M4 Scores · Weak Words</span>
                    </div>
                    <button
                      className="btn btn--primary"
                      onClick={handleDownloadStudent}
                      disabled={downloadingStudent || !selectedLearnerId || (isTeacher && studentEnrolledClasses.length === 0)}
                      style={{
                        width: '100%',
                        height: 42,
                        justifyContent: 'center',
                        background: 'linear-gradient(135deg, #6366f1, #4f46e5)',
                      }}
                    >
                      {downloadingStudent ? <span className="spinner spinner--sm" /> : `📥 Export ${(isTeacher && studentClassScope) ? 'Class' : (isTeacher ? 'Enrolled' : 'Global')} Report Card (${studentFormat.toUpperCase()})`}
                    </button>
                  </div>
                </div>

                {/* ── CARD 3: Word & Curriculum Report ── */}
                <div className="report-card-premium">
                  <div>
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                        <div
                          style={{
                            width: 44,
                            height: 44,
                            borderRadius: 12,
                            background: 'linear-gradient(135deg, #f59e0b, #d97706)',
                            display: 'grid',
                            placeItems: 'center',
                            fontSize: '1.35rem',
                            boxShadow: '0 4px 12px rgba(245,158,11,0.25)',
                          }}
                        >
                          📚
                        </div>
                        <div>
                          <h2 style={{ fontSize: '1.05rem', margin: 0, fontWeight: 800, color: 'var(--color-text)' }}>
                            Word &amp; Curriculum Report
                          </h2>
                          <span style={{ fontSize: '0.74rem', color: 'var(--color-text-muted)' }}>Curriculum-Level Analytics</span>
                        </div>
                      </div>
                      <span className="admin-main__badge" style={{ background: 'rgba(245,158,11,0.1)', color: '#d97706', borderColor: 'rgba(245,158,11,0.2)' }}>
                        CURRICULUM
                      </span>
                    </div>

                    <p style={{ fontSize: '0.84rem', color: 'var(--color-text-muted)', lineHeight: 1.5, minHeight: 40, marginBottom: 16 }}>
                      Word-level metrics breakdown: total attempts, accuracy, demerit points, and Module 4 asset fallback triggers.
                    </p>

                    <div className="form-field" style={{ marginBottom: 10 }}>
                      <label className="form-label" style={{ fontSize: '0.78rem', fontWeight: 700 }}>
                        Class or Curriculum Scope
                      </label>
                      <select
                        className="form-select"
                        value={wordSectionId}
                        onChange={(e) => {
                          setWordSectionId(e.target.value);
                          setWordCategoryId('');
                          setWordLessonId('');
                        }}
                        style={{ height: 40, fontSize: '0.875rem' }}
                      >
                        <option value="">{isTeacher ? '🌟 All My Classes (Comprehensive Curriculum)' : '🌟 All Classes (School-wide Curriculum)'}</option>
                        {isTeacher && sections.map((s) => (
                          <option key={s.section_id} value={s.section_id}>
                            🏫 Specific Class: {s.section_name}
                          </option>
                        ))}
                      </select>
                    </div>

                    {/* Scope Indicator Badge */}
                    <div style={{
                      fontSize: '0.74rem',
                      fontWeight: 700,
                      padding: '5px 10px',
                      borderRadius: 7,
                      background: wordSectionId ? 'rgba(245,158,11,0.08)' : 'rgba(15,23,42,0.04)',
                      color: wordSectionId ? '#d97706' : '#64748b',
                      border: '1px solid ' + (wordSectionId ? 'rgba(245,158,11,0.2)' : 'rgba(15,23,42,0.08)'),
                      marginBottom: 12,
                      display: 'flex',
                      alignItems: 'center',
                      gap: 6,
                    }}>
                      <span>{wordSectionId ? '🎯 Generating Class Words: ' + (sections.find(s => (s.section_id || s.sectionId) === wordSectionId)?.section_name || 'Specific Class') : '🌐 Generating All Classes / School-wide Curriculum'}</span>
                    </div>

                    <div className="form-field" style={{ marginBottom: 14 }}>
                      <label className="form-label" style={{ fontSize: '0.78rem', fontWeight: 700 }}>
                        Filter by Category ({availableWordCategories.length} active)
                      </label>
                      <select
                        className="form-select"
                        value={wordCategoryId}
                        onChange={(e) => {
                          setWordCategoryId(e.target.value);
                          setWordLessonId('');
                        }}
                        style={{ height: 40, fontSize: '0.875rem' }}
                      >
                        <option value="">All Active Categories ({availableWordCategories.length})</option>
                        {availableWordCategories.map((c) => (
                          <option key={c.category_id} value={c.category_id}>
                            📁 {c.category_name} ({c.lessonCount} {c.lessonCount === 1 ? 'lesson' : 'lessons'})
                          </option>
                        ))}
                      </select>
                    </div>

                    <div className="form-field" style={{ marginBottom: 14 }}>
                      <label className="form-label" style={{ fontSize: '0.78rem', fontWeight: 700 }}>
                        Filter by Curriculum Lesson
                      </label>
                      <select
                        className="form-select"
                        value={wordLessonId}
                        onChange={(e) => setWordLessonId(e.target.value)}
                        style={{ height: 40, fontSize: '0.875rem' }}
                      >
                        <option value="">All Lessons ({filteredWordLessons.length} available)</option>
                        {filteredWordLessons.map((l) => (
                          <option key={l.lesson_id} value={l.lesson_id}>
                            {l.lesson_title}
                          </option>
                        ))}
                      </select>
                    </div>

                    <div className="form-field" style={{ marginBottom: 16 }}>
                      <label className="form-label" style={{ fontSize: '0.78rem', fontWeight: 700 }}>
                        Export Format
                      </label>
                      <div className="segmented-toggle">
                        <button
                          type="button"
                          className={`segmented-toggle__btn ${wordFormat === 'pdf' ? 'active' : ''}`}
                          onClick={() => setWordFormat('pdf')}
                        >
                          📄 PDF Document
                        </button>
                        <button
                          type="button"
                          className={`segmented-toggle__btn ${wordFormat === 'csv' ? 'active' : ''}`}
                          onClick={() => setWordFormat('csv')}
                        >
                          📊 CSV Spreadsheet
                        </button>
                      </div>
                    </div>
                  </div>

                  <div>
                    <div
                      style={{
                        fontSize: '0.74rem',
                        color: 'var(--color-text-dim)',
                        marginBottom: 10,
                        display: 'flex',
                        alignItems: 'center',
                        gap: 6,
                      }}
                    >
                      <span>✓ Includes: Word Attempts · Error Rates · Demerits · Fallbacks</span>
                    </div>
                    <button
                      className="btn btn--primary"
                      onClick={handleDownloadWord}
                      disabled={downloadingWord}
                      style={{
                        width: '100%',
                        height: 42,
                        justifyContent: 'center',
                        background: 'linear-gradient(135deg, #f59e0b, #d97706)',
                      }}
                    >
                      {downloadingWord ? <span className="spinner spinner--sm" /> : `📥 Export ${wordSectionId ? 'Class' : 'All Classes'} Word Report (${wordFormat.toUpperCase()})`}
                    </button>
                  </div>
                </div>
              </div>
            )}

            {/* ════════════════════════════════════════════════════════════════════
                VIEW MODE: FOCUSED STUDIO MODE (STUDENT / CLASS / WORD)
               ════════════════════════════════════════════════════════════════════ */}
            {activeTab === 'student' && (
              <div style={{ display: 'grid', gridTemplateColumns: 'minmax(320px, 420px) 1fr', gap: 24, alignItems: 'start' }}>
                {/* Left: Configurator */}
                <div className="report-card-premium" style={{ border: '1.5px solid rgba(99,102,241,0.3)' }}>
                  <div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 16 }}>
                      <div
                        style={{
                          width: 44,
                          height: 44,
                          borderRadius: 12,
                          background: 'linear-gradient(135deg, #6366f1, #4f46e5)',
                          display: 'grid',
                          placeItems: 'center',
                          fontSize: '1.35rem',
                          color: '#fff',
                        }}
                      >
                        👤
                      </div>
                      <div>
                        <h2 style={{ fontSize: '1.1rem', margin: 0, fontWeight: 800 }}>Student Report Card Generator</h2>
                        <span style={{ fontSize: '0.75rem', color: 'var(--color-text-muted)' }}>Configurator Studio</span>
                      </div>
                    </div>

                    <div className="form-field" style={{ marginBottom: 14 }}>
                      <label className="form-label" style={{ fontWeight: 700 }}>1. Filter by Classroom Cohort</label>
                      <select
                        className="form-select"
                        value={studentSectionFilter}
                        onChange={(e) => {
                          const val = e.target.value;
                          setStudentSectionFilter(val);
                          if (isTeacher) {
                            setStudentClassScope(val);
                          }
                        }}
                      >
                        <option value="">All Classes ({learners.length} students)</option>
                        {sections.map((s) => (
                          <option key={s.section_id} value={s.section_id}>
                            {s.section_name}
                          </option>
                        ))}
                      </select>
                    </div>

                    <div className="form-field" style={{ marginBottom: 14 }}>
                      <label className="form-label" style={{ fontWeight: 700 }}>2. Target Student *</label>
                      <select
                        className="form-select"
                        value={selectedLearnerId}
                        onChange={(e) => setSelectedLearnerId(e.target.value)}
                        style={{ fontWeight: 700 }}
                      >
                        {filteredLearners.length === 0 && <option value="">No students in selected class</option>}
                        {filteredLearners.map((l) => {
                          const id = l.learner_id || l.learnerId;
                          const name = l.display_name || l.displayName || 'Student';
                          const sec = l.section_name || l.sectionName || 'Unassigned';
                          return (
                            <option key={id} value={id}>
                              {name} ({sec})
                            </option>
                          );
                        })}
                      </select>
                    </div>

                    <div className="form-field" style={{ marginBottom: 14 }}>
                      <label className="form-label" style={{ fontWeight: 700 }}>3. Record Scope to Generate</label>
                      {loadingStudentClasses ? (
                        <div style={{ padding: '8px 12px', fontSize: '0.8rem', color: '#64748b', background: '#f8fafc', borderRadius: 8, border: '1px solid var(--color-border)' }}>
                          <span className="spinner spinner--xs" /> Verifying active enrolled classes...
                        </div>
                      ) : isTeacher && studentEnrolledClasses.length === 0 ? (
                        <div style={{ padding: '10px 12px', background: '#fef2f2', border: '1px solid #fecaca', borderRadius: 8, fontSize: '0.78rem', color: '#991b1b' }}>
                          ⚠️ Student is not enrolled in any of your active classes (pending mobile app acceptance or unassigned).
                        </div>
                      ) : (
                        <select
                          className="form-select"
                          value={studentClassScope}
                          onChange={(e) => setStudentClassScope(e.target.value)}
                          style={{ fontWeight: 700 }}
                        >
                          {!isTeacher ? (
                            <option value="">🌐 All Classes (Global Cumulative Lifetime Record)</option>
                          ) : studentEnrolledClasses.length > 1 ? (
                            <>
                              <option value="">🌟 All My Classes (Combined Student View)</option>
                              {studentEnrolledClasses.map((c) => (
                                <option key={c.class_id || c.classId} value={c.class_id || c.classId}>
                                  🏫 Class: {c.class_name || c.className} {c.class_code || c.classCode ? `(${c.class_code || c.classCode})` : ''}
                                </option>
                              ))}
                            </>
                          ) : (
                            <option value={studentEnrolledClasses[0]?.class_id || studentEnrolledClasses[0]?.classId}>
                              🏫 Class: {studentEnrolledClasses[0]?.class_name || studentEnrolledClasses[0]?.className} {studentEnrolledClasses[0]?.class_code || studentEnrolledClasses[0]?.classCode ? `(${studentEnrolledClasses[0]?.class_code || studentEnrolledClasses[0]?.classCode})` : ''}
                            </option>
                          )}
                        </select>
                      )}
                    </div>

                    {/* Scope Indicator Badge */}
                    <div style={{
                      fontSize: '0.74rem',
                      fontWeight: 700,
                      padding: '5px 10px',
                      borderRadius: 7,
                      background: (isTeacher && studentClassScope) ? 'rgba(99,102,241,0.08)' : 'rgba(15,23,42,0.04)',
                      color: (isTeacher && studentClassScope) ? '#4f46e5' : '#64748b',
                      border: '1px solid ' + ((isTeacher && studentClassScope) ? 'rgba(99,102,241,0.2)' : 'rgba(15,23,42,0.08)'),
                      marginBottom: 14,
                      display: 'flex',
                      alignItems: 'center',
                      gap: 6,
                    }}>
                      <span>
                        {(isTeacher && studentClassScope)
                          ? '🎯 Scope: ' + (studentEnrolledClasses.find(s => (s.class_id || s.classId) === studentClassScope)?.class_name || studentEnrolledClasses.find(s => (s.class_id || s.classId) === studentClassScope)?.className || 'Specific Class')
                          : (isTeacher ? '🌟 Scope: All My Classes (Combined)' : '🌐 Scope: All Classes / Cumulative Lifetime')}
                      </span>
                    </div>

                    <div className="form-field" style={{ marginBottom: 20 }}>
                      <label className="form-label" style={{ fontWeight: 700 }}>4. Export Document Format</label>
                      <div className="segmented-toggle">
                        <button
                          type="button"
                          className={`segmented-toggle__btn ${studentFormat === 'pdf' ? 'active' : ''}`}
                          onClick={() => setStudentFormat('pdf')}
                        >
                          📄 PDF Document (Official Format)
                        </button>
                        <button
                          type="button"
                          className={`segmented-toggle__btn ${studentFormat === 'csv' ? 'active' : ''}`}
                          onClick={() => setStudentFormat('csv')}
                        >
                          📊 CSV Spreadsheet
                        </button>
                      </div>
                    </div>
                  </div>

                  <div>
                    <button
                      className="btn btn--primary"
                      onClick={handleDownloadStudent}
                      disabled={downloadingStudent || !selectedLearnerId || (isTeacher && studentEnrolledClasses.length === 0)}
                      style={{
                        width: '100%',
                        height: 46,
                        justifyContent: 'center',
                        fontSize: '0.95rem',
                        background: 'linear-gradient(135deg, #6366f1, #4f46e5)',
                      }}
                    >
                      {downloadingStudent ? <span className="spinner spinner--sm" /> : `📥 Export ${(isTeacher && studentClassScope) ? 'Class' : (isTeacher ? 'Enrolled' : 'Global')} Report Card (${studentFormat.toUpperCase()})`}
                    </button>
                  </div>
                </div>

                {/* Right: Live Mockup Preview Matching Learner Details */}
                <div className="mockup-document-sheet">
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', borderBottom: '2px solid #3b82f6', paddingBottom: 14, marginBottom: 18 }}>
                    <div>
                      <div style={{ fontSize: '1.25rem', fontWeight: 800, color: '#1e3a8a', letterSpacing: '-0.02em' }}>
                        VOCABOO DIAGNOSTIC REPORT CARD
                      </div>
                      <div style={{ fontSize: '0.8rem', color: '#64748b', marginTop: 2 }}>
                        Official Student Competency &amp; Vocabulary Mastery Summary
                      </div>
                    </div>
                    <div style={{ textAlign: 'right' }}>
                      <span className="status-pill status-pill--success" style={{ fontWeight: 800, fontSize: '0.74rem' }}>
                        ● LIVE PREVIEW
                      </span>
                    </div>
                  </div>

                  {currentSelectedStudent ? (
                    <div>
                      {/* Student Banner */}
                      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', background: '#f8fafc', padding: '14px 18px', borderRadius: 10, border: '1px solid #e2e8f0', marginBottom: 18 }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
                          <div
                            style={{
                              width: 48,
                              height: 48,
                              borderRadius: 12,
                              background: 'linear-gradient(135deg, #3b82f6, #1d4ed8)',
                              color: '#fff',
                              fontSize: '1.3rem',
                              fontWeight: 800,
                              display: 'grid',
                              placeItems: 'center',
                            }}
                          >
                            {(currentSelectedStudent.display_name || currentSelectedStudent.displayName || 'S').charAt(0).toUpperCase()}
                          </div>
                          <div>
                            <div style={{ fontSize: '1.1rem', fontWeight: 800, color: '#0f172a' }}>
                              {currentSelectedStudent.display_name || currentSelectedStudent.displayName}
                            </div>
                            <div style={{ fontSize: '0.82rem', color: '#64748b' }}>
                              Cohort: <strong>{currentSelectedStudent.section_name || currentSelectedStudent.sectionName || 'Self-Paced'}</strong> · Grade: <strong>{currentSelectedStudent.grade_level ? currentSelectedStudent.grade_level.replace('_', ' ') : 'Grade 4'}</strong>
                            </div>
                          </div>
                        </div>

                        <button
                          type="button"
                          className="btn btn--sm btn--primary"
                          onClick={() => setPreviewLearnerId(selectedLearnerId)}
                        >
                          🔍 View Detailed Profile Modal
                        </button>
                      </div>

                      {/* Stat Metrics Grid */}
                      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12, marginBottom: 20 }}>
                        <div style={{ background: '#f1f5f9', padding: '10px 14px', borderRadius: 8 }}>
                          <div style={{ fontSize: '0.72rem', color: '#64748b', fontWeight: 700 }}>Global Score</div>
                          <div style={{ fontSize: '1.15rem', fontWeight: 800, color: '#2563eb' }}>
                            {(currentSelectedStudent.total_points ?? currentSelectedStudent.totalPoints ?? 0).toLocaleString()} pts
                          </div>
                        </div>
                        <div style={{ background: '#f1f5f9', padding: '10px 14px', borderRadius: 8 }}>
                          <div style={{ fontSize: '0.72rem', color: '#64748b', fontWeight: 700 }}>Overall Accuracy</div>
                          <div style={{ fontSize: '1.15rem', fontWeight: 800, color: '#10b981' }}>
                            {Number(currentSelectedStudent.overall_accuracy ?? currentSelectedStudent.overallAccuracy ?? 0).toFixed(1)}%
                          </div>
                        </div>
                        <div style={{ background: '#f1f5f9', padding: '10px 14px', borderRadius: 8 }}>
                          <div style={{ fontSize: '0.72rem', color: '#64748b', fontWeight: 700 }}>Words Mastered</div>
                          <div style={{ fontSize: '1.15rem', fontWeight: 800, color: '#f59e0b' }}>
                            {currentSelectedStudent.words_mastered_count ?? currentSelectedStudent.wordsMasteredCount ?? 0} words
                          </div>
                        </div>
                        <div style={{ background: '#f1f5f9', padding: '10px 14px', borderRadius: 8 }}>
                          <div style={{ fontSize: '0.72rem', color: '#64748b', fontWeight: 700 }}>Mastery Tier</div>
                          <div style={{ fontSize: '1.15rem', fontWeight: 800, color: '#7c3aed' }}>
                            {currentSelectedStudent.mastery_level || currentSelectedStudent.masteryLevel || 'EXPLORER'}
                          </div>
                        </div>
                      </div>

                      {/* Included Sections Notice */}
                      <div style={{ background: '#eff6ff', border: '1px solid #bfdbfe', borderRadius: 8, padding: '12px 16px', fontSize: '0.84rem', color: '#1e40af' }}>
                        <strong>📋 PDF Document Content Structure:</strong>
                        <ul style={{ margin: '6px 0 0 18px', lineHeight: 1.6 }}>
                          <li><strong>Part of Speech (POS) Mastery Breakdown</strong>: Noun, Verb, Adjective accuracy % and correct/attempt metrics</li>
                          <li><strong>Curriculum Lesson Progression</strong>: Module 1 (Intro), M2 (Practice), M3 (Sentence), M4 (Test) scores</li>
                          <li><strong>Cumulative Review Retention</strong>: Badges (🏆 Perfect Gold / 🥇 Gold / 🥈 Silver / 🥉 Bronze) &amp; review points</li>
                          <li><strong>Words Needing Practice &amp; Reinforcement</strong>: Weak words list with Cebuano meanings and demerit points</li>
                        </ul>
                      </div>
                    </div>
                  ) : (
                    <div style={{ textAlign: 'center', padding: 40, color: 'var(--color-text-muted)' }}>
                      Select a student to generate live report card preview.
                    </div>
                  )}
                </div>
              </div>
            )}

            {/* ════════════════════════════════════════════════════════════════════
                VIEW MODE: CLASS PERFORMANCE FOCUSED
               ════════════════════════════════════════════════════════════════════ */}
            {activeTab === 'class' && (
              <div style={{ maxWidth: 650, margin: '0 auto' }}>
                <div className="report-card-premium" style={{ padding: 28 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginBottom: 18 }}>
                    <div
                      style={{
                        width: 50,
                        height: 50,
                        borderRadius: 14,
                        background: 'linear-gradient(135deg, #3b82f6, #1d4ed8)',
                        display: 'grid',
                        placeItems: 'center',
                        fontSize: '1.5rem',
                      }}
                    >
                      🏫
                    </div>
                    <div>
                      <h2 style={{ fontSize: '1.25rem', margin: 0, fontWeight: 800 }}>Class Performance Roster Export</h2>
                      <p style={{ fontSize: '0.84rem', color: 'var(--color-text-muted)', margin: 0 }}>
                        Official class cohort roster with points, overall accuracy, completed modules, and mastery
                      </p>
                    </div>
                  </div>

                  <div className="form-field" style={{ marginBottom: 10 }}>
                    <label className="form-label" style={{ fontWeight: 700 }}>Class or Record Scope</label>
                    <select
                      className="form-select"
                      value={classSectionId}
                      onChange={(e) => setClassSectionId(e.target.value)}
                    >
                      <option value="">{isTeacher ? '🌟 All My Classes (Cumulative Roster)' : '🌟 All Classes (Global School-Wide Report)'}</option>
                      {isTeacher && sections.map((s) => (
                        <option key={s.section_id} value={s.section_id}>
                          🏫 Specific Class: {s.section_name}
                        </option>
                      ))}
                    </select>
                  </div>

                  {/* Scope Indicator Badge */}
                  <div style={{
                    fontSize: '0.74rem',
                    fontWeight: 700,
                    padding: '5px 10px',
                    borderRadius: 7,
                    background: (isTeacher && classSectionId) ? 'rgba(37,99,235,0.08)' : 'rgba(15,23,42,0.04)',
                    color: (isTeacher && classSectionId) ? '#2563eb' : '#64748b',
                    border: '1px solid ' + ((isTeacher && classSectionId) ? 'rgba(37,99,235,0.2)' : 'rgba(15,23,42,0.08)'),
                    marginBottom: 14,
                    display: 'flex',
                    alignItems: 'center',
                    gap: 6,
                  }}>
                    <span>{(isTeacher && classSectionId) ? '🎯 Generating Class Roster: ' + (sections.find(s => (s.section_id || s.sectionId) === classSectionId)?.section_name || 'Specific Class') : (isTeacher ? '🌟 Generating All My Classes: Cumulative Cohort' : '🌐 Generating School-Wide Cohort: All Classes')}</span>
                  </div>

                  <div className="form-field" style={{ marginBottom: 14 }}>
                    <label className="form-label" style={{ fontWeight: 700 }}>Grade Level Filter</label>
                    <select
                      className="form-select"
                      value={classGrade}
                      onChange={(e) => setClassGrade(e.target.value)}
                    >
                      <option value="">All Grades</option>
                      <option value="GRADE_4">Grade 4</option>
                      <option value="GRADE_5">Grade 5</option>
                      <option value="GRADE_6">Grade 6</option>
                    </select>
                  </div>

                  <div className="form-field" style={{ marginBottom: 20 }}>
                    <label className="form-label" style={{ fontWeight: 700 }}>Export Format</label>
                    <div className="segmented-toggle">
                      <button
                        type="button"
                        className={`segmented-toggle__btn ${classFormat === 'pdf' ? 'active' : ''}`}
                        onClick={() => setClassFormat('pdf')}
                      >
                        📄 PDF Document
                      </button>
                      <button
                        type="button"
                        className={`segmented-toggle__btn ${classFormat === 'csv' ? 'active' : ''}`}
                        onClick={() => setClassFormat('csv')}
                      >
                        📊 CSV Spreadsheet
                      </button>
                    </div>
                  </div>

                  <button
                    className="btn btn--primary"
                    onClick={handleDownloadClass}
                    disabled={downloadingClass}
                    style={{ width: '100%', height: 44, justifyContent: 'center' }}
                  >
                    {downloadingClass ? <span className="spinner spinner--sm" /> : `📥 Export ${classSectionId ? 'Class' : 'All Classes'} Report (${classFormat.toUpperCase()})`}
                  </button>
                </div>
              </div>
            )}

            {/* ════════════════════════════════════════════════════════════════════
                VIEW MODE: WORD & CURRICULUM FOCUSED
               ════════════════════════════════════════════════════════════════════ */}
            {activeTab === 'word' && (
              <div style={{ maxWidth: 650, margin: '0 auto' }}>
                <div className="report-card-premium" style={{ padding: 28 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginBottom: 18 }}>
                    <div
                      style={{
                        width: 50,
                        height: 50,
                        borderRadius: 14,
                        background: 'linear-gradient(135deg, #f59e0b, #d97706)',
                        display: 'grid',
                        placeItems: 'center',
                        fontSize: '1.5rem',
                      }}
                    >
                      📚
                    </div>
                    <div>
                      <h2 style={{ fontSize: '1.25rem', margin: 0, fontWeight: 800 }}>Word &amp; Curriculum Report Export</h2>
                      <p style={{ fontSize: '0.84rem', color: 'var(--color-text-muted)', margin: 0 }}>
                        Word error patterns, demerit points, attempt frequencies, and fallback triggers
                      </p>
                    </div>
                  </div>

                  <div className="form-field" style={{ marginBottom: 10 }}>
                    <label className="form-label" style={{ fontWeight: 700 }}>Class or Curriculum Scope</label>
                    <select
                      className="form-select"
                      value={wordSectionId}
                      onChange={(e) => {
                        setWordSectionId(e.target.value);
                        setWordCategoryId('');
                        setWordLessonId('');
                      }}
                    >
                      <option value="">{isTeacher ? '🌟 All My Classes (Comprehensive Curriculum)' : '🌟 All Classes (Global School-Wide Curriculum)'}</option>
                      {isTeacher && sections.map((s) => (
                        <option key={s.section_id} value={s.section_id}>
                          🏫 Specific Class: {s.section_name}
                        </option>
                      ))}
                    </select>
                  </div>

                  {/* Scope Indicator Badge */}
                  <div style={{
                    fontSize: '0.74rem',
                    fontWeight: 700,
                    padding: '5px 10px',
                    borderRadius: 7,
                    background: (isTeacher && wordSectionId) ? 'rgba(245,158,11,0.08)' : 'rgba(15,23,42,0.04)',
                    color: (isTeacher && wordSectionId) ? '#d97706' : '#64748b',
                    border: '1px solid ' + ((isTeacher && wordSectionId) ? 'rgba(245,158,11,0.2)' : 'rgba(15,23,42,0.08)'),
                    marginBottom: 14,
                    display: 'flex',
                    alignItems: 'center',
                    gap: 6,
                  }}>
                    <span>{(isTeacher && wordSectionId) ? '🎯 Generating Class Words: ' + (sections.find(s => (s.section_id || s.sectionId) === wordSectionId)?.section_name || 'Specific Class') : (isTeacher ? '🌟 Generating All My Classes Curriculum' : '🌐 Generating School-Wide Curriculum: All Classes')}</span>
                  </div>

                  <div className="form-field" style={{ marginBottom: 14 }}>
                    <label className="form-label" style={{ fontWeight: 700 }}>
                      Filter by Category ({availableWordCategories.length} active)
                    </label>
                    <select
                      className="form-select"
                      value={wordCategoryId}
                      onChange={(e) => {
                        setWordCategoryId(e.target.value);
                        setWordLessonId('');
                      }}
                    >
                      <option value="">All Active Categories ({availableWordCategories.length})</option>
                      {availableWordCategories.map((c) => (
                        <option key={c.category_id} value={c.category_id}>
                          📁 {c.category_name} ({c.lessonCount} {c.lessonCount === 1 ? 'lesson' : 'lessons'})
                        </option>
                      ))}
                    </select>
                  </div>

                  <div className="form-field" style={{ marginBottom: 14 }}>
                    <label className="form-label" style={{ fontWeight: 700 }}>Curriculum Lesson</label>
                    <select
                      className="form-select"
                      value={wordLessonId}
                      onChange={(e) => setWordLessonId(e.target.value)}
                    >
                      <option value="">All Lessons ({filteredWordLessons.length} available)</option>
                      {filteredWordLessons.map((l) => (
                        <option key={l.lesson_id} value={l.lesson_id}>
                          {l.lesson_title}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div className="form-field" style={{ marginBottom: 20 }}>
                    <label className="form-label" style={{ fontWeight: 700 }}>Export Format</label>
                    <div className="segmented-toggle">
                      <button
                        type="button"
                        className={`segmented-toggle__btn ${wordFormat === 'pdf' ? 'active' : ''}`}
                        onClick={() => setWordFormat('pdf')}
                      >
                        📄 PDF Document
                      </button>
                      <button
                        type="button"
                        className={`segmented-toggle__btn ${wordFormat === 'csv' ? 'active' : ''}`}
                        onClick={() => setWordFormat('csv')}
                      >
                        📊 CSV Spreadsheet
                      </button>
                    </div>
                  </div>

                  <button
                    className="btn btn--primary"
                    onClick={handleDownloadWord}
                    disabled={downloadingWord}
                    style={{
                      width: '100%',
                      height: 44,
                      justifyContent: 'center',
                      background: 'linear-gradient(135deg, #f59e0b, #d97706)',
                    }}
                  >
                    {downloadingWord ? <span className="spinner spinner--sm" /> : `📥 Export ${wordSectionId ? 'Class' : 'All Classes'} Word Report (${wordFormat.toUpperCase()})`}
                  </button>
                </div>
              </div>
            )}
          </>
        )}

        {/* Diagnostic Modal when teacher/admin clicks preview */}
        {previewLearnerId && (
          <LearnerDetailModal
            learnerId={previewLearnerId}
            classContext={
              (studentClassScope || studentSectionFilter)
                ? {
                    classId: studentClassScope || studentSectionFilter,
                    className: sections.find((s) => (s.section_id || s.sectionId) === (studentClassScope || studentSectionFilter))?.section_name,
                  }
                : null
            }
            onClose={() => setPreviewLearnerId(null)}
            onResetProgress={() => {}}
            onEditProfile={() => {}}
          />
        )}
        </div>
      </main>
    </div>
  );
}