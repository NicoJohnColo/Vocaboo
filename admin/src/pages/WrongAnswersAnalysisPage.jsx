import { useState, useEffect, useCallback } from 'react';
import AdminNav from '../components/AdminNav';
import { apiFetch, AuthService } from '../services/AuthService';
import { SectionService } from '../services/SectionService';
import { useAdminAuth } from '../hooks/useAdminAuth';

function SeverityBar({ value, max }) {
  const pct = max > 0 ? Math.min(100, Math.round((value / max) * 100)) : 0;
  const color =
    pct >= 70 ? '#ef4444' : pct >= 40 ? '#f97316' : '#eab308';
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
      <div
        style={{
          flex: 1,
          height: '8px',
          borderRadius: '4px',
          background: 'var(--color-surface-2, #e2e8f0)',
          overflow: 'hidden',
        }}
      >
        <div
          style={{
            width: `${pct}%`,
            height: '100%',
            borderRadius: '4px',
            background: color,
            transition: 'width 0.6s ease',
          }}
        />
      </div>
      <span style={{ fontSize: '12px', color, fontWeight: 700, minWidth: '42px', textAlign: 'right' }}>
        {value} pts
      </span>
    </div>
  );
}

export default function WrongAnswersAnalysisPage() {
  const { admin } = useAdminAuth();
  const isTeacher = admin?.role === 'teacher';

  const [data, setData] = useState(null);
  const [sections, setSections] = useState([]);
  const [cohortType, setCohortType] = useState(isTeacher ? 'ENROLLED' : 'ALL');
  const [selectedSection, setSelectedSection] = useState('');
  const [selectedGrade, setSelectedGrade] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (isTeacher) {
      setCohortType('ENROLLED');
    }
  }, [isTeacher]);
  const [error, setError] = useState('');
  const [activeTab, setActiveTab] = useState('pairs');
  const [expandedLessons, setExpandedLessons] = useState({});

  const toggleLesson = (lessonId) => {
    setExpandedLessons((prev) => ({ ...prev, [lessonId]: !prev[lessonId] }));
  };

  const toggleAllLessons = () => {
    if (!data || !data.curriculumGaps) return;
    const allExpanded = data.curriculumGaps.every((g) => expandedLessons[g.lessonId]);
    const newState = {};
    if (!allExpanded) {
      data.curriculumGaps.forEach((g) => {
        newState[g.lessonId] = true;
      });
    }
    setExpandedLessons(newState);
  };

  useEffect(() => {
    SectionService.getAllSections()
      .then(setSections)
      .catch(() => setSections([]));
  }, []);

  const loadAnalysis = useCallback(() => {
    setLoading(true);
    setError('');
    const params = new URLSearchParams();
    if (selectedSection) {
      params.append('sectionId', selectedSection);
    } else if (cohortType && cohortType !== 'ALL') {
      params.append('cohortType', cohortType);
    }
    if (selectedGrade) {
      params.append('gradeLevel', selectedGrade);
    }

    const qs = params.toString() ? `?${params.toString()}` : '';
    apiFetch(`/api/admin/reports/wrong-answers${qs}`)
      .then((res) => {
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        return res.json();
      })
      .then(setData)
      .catch((e) =>
        setError(e?.message || 'Failed to load analysis.')
      )
      .finally(() => setLoading(false));
  }, [selectedSection, cohortType, selectedGrade]);

  useEffect(() => {
    loadAnalysis();
  }, [loadAnalysis]);

  const maxPairErrors = data && data.confusedPairs && data.confusedPairs.length > 0
    ? Math.max(...data.confusedPairs.map((p) => p.totalErrors), 1)
    : 1;
  const maxGapErrors = data && data.curriculumGaps && data.curriculumGaps.length > 0
    ? Math.max(...data.curriculumGaps.map((g) => g.totalErrors), 1)
    : 1;

  return (
    <div className="admin-layout">
      <AdminNav />
      <main className="admin-main">
        {/* Header */}
        <header className="admin-main__header" style={{ alignItems: 'flex-start', flexWrap: 'wrap', gap: 16 }}>
          <div>
            <h1 className="admin-main__title">📊 Wrong Answer Analysis</h1>
            <p className="admin-main__subtitle">
              Class-wide error patterns, confused word pairs, and curriculum gaps
            </p>
          </div>

          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center' }}>
            {/* Cohort Scope */}
            {!isTeacher && (
              <select
                className="toolbar-select"
                value={selectedSection ? '' : cohortType}
                onChange={(e) => {
                  setCohortType(e.target.value);
                  setSelectedSection('');
                }}
                style={{ minWidth: 170, fontWeight: 600 }}
              >
                <option value="ALL">🌍 Global (All Users)</option>
                <option value="INDEPENDENT">👤 Self-Paced Only</option>
                <option value="ENROLLED">🏫 Enrolled Classes Only</option>
              </select>
            )}

            {/* Class Section */}
            <select
              className="toolbar-select"
              value={selectedSection}
              onChange={(e) => {
                setSelectedSection(e.target.value);
                if (e.target.value) setCohortType(isTeacher ? 'ENROLLED' : 'ALL');
              }}
              style={{ minWidth: 155 }}
            >
              <option value="">{isTeacher ? 'All My Classes…' : 'Specific Section…'}</option>
              {sections.map((s) => (
                <option key={s.section_id} value={s.section_id}>
                  {s.section_name}
                </option>
              ))}
            </select>

            {/* Grade Level */}
            <select
              className="toolbar-select"
              value={selectedGrade}
              onChange={(e) => setSelectedGrade(e.target.value)}
              style={{ minWidth: 120 }}
            >
              <option value="">All Grades</option>
              <option value="GRADE_4">Grade 4</option>
              <option value="GRADE_5">Grade 5</option>
              <option value="GRADE_6">Grade 6</option>
            </select>

            <button
              className="btn btn--ghost btn--sm"
              onClick={loadAnalysis}
              title="Refresh analysis data"
            >
              🔄 Refresh
            </button>
          </div>
        </header>

        {error && <div className="alert alert--error" onClick={() => setError('')}>{error}</div>}

        {/* ── Active Class Scope Banner ─────────────────────────────────── */}
        {selectedSection && (
          <div style={{
            background: 'linear-gradient(135deg, rgba(37,99,235,0.08), rgba(29,78,216,0.04))',
            border: '1.5px solid rgba(37,99,235,0.3)',
            borderRadius: 'var(--radius-lg)',
            padding: '14px 20px',
            marginBottom: 20,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            flexWrap: 'wrap',
            gap: 12,
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <span style={{ fontSize: '1.4rem' }}>🔍</span>
              <div>
                <div style={{ fontWeight: 800, fontSize: '0.95rem', color: '#1e40af' }}>
                  Analysis Filtered by Class: {sections.find((s) => s.section_id === selectedSection)?.section_name || 'Selected Class'}
                </div>
                <div style={{ fontSize: '0.8rem', color: '#3b82f6', marginTop: 2 }}>
                  Showing error patterns, confused word pairs, and curriculum gaps strictly for students in this classroom.
                </div>
              </div>
            </div>
            <button
              type="button"
              onClick={() => setSelectedSection('')}
              style={{
                padding: '6px 14px',
                fontSize: '0.78rem',
                fontWeight: 700,
                color: '#1d4ed8',
                background: '#fff',
                border: '1px solid rgba(37,99,235,0.3)',
                borderRadius: 8,
                cursor: 'pointer',
              }}
            >
              ✕ Reset to All Classes
            </button>
          </div>
        )}

        {loading ? (
          <div className="auth-loading" style={{ minHeight: 300 }}>
            <div className="spinner" />
          </div>
        ) : data ? (
          <>
            {/* Summary stat cards */}
            <div className="kpi-grid" style={{ gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', marginBottom: 28 }}>
              <div className="kpi-card" style={{
                '--kpi-gradient': 'linear-gradient(135deg, #ef4444, #dc2626)',
                '--kpi-blob': 'rgba(239, 68, 68, 0.08)', '--kpi-color': '#dc2626', '--kpi-glow': 'rgba(239, 68, 68, 0.28)'
              }}>
                <div className="kpi-card__header">
                  <span className="kpi-card__label">Total Class Errors</span>
                  <div className="kpi-card__icon-bubble">❌</div>
                </div>
                <div className="kpi-card__value">{data.totalClassErrors?.toLocaleString() ?? 0}</div>
                <div className="kpi-card__footer">
                  <span className="kpi-card__subtitle">Across all activities</span>
                </div>
              </div>

              <div className="kpi-card" style={{
                '--kpi-gradient': 'linear-gradient(135deg, #f97316, #ea580c)',
                '--kpi-blob': 'rgba(249, 115, 22, 0.08)', '--kpi-color': '#ea580c', '--kpi-glow': 'rgba(249, 115, 22, 0.28)'
              }}>
                <div className="kpi-card__header">
                  <span className="kpi-card__label">Learners with Errors</span>
                  <div className="kpi-card__icon-bubble">👥</div>
                </div>
                <div className="kpi-card__value">{data.learnersWithErrors?.toLocaleString() ?? 0}</div>
                <div className="kpi-card__footer">
                  <span className="kpi-card__subtitle">Students needing support</span>
                </div>
              </div>

              <div className="kpi-card" style={{
                '--kpi-gradient': 'linear-gradient(135deg, #2563eb, #1d4ed8)',
                '--kpi-blob': 'rgba(37, 99, 235, 0.08)', '--kpi-color': '#2563eb', '--kpi-glow': 'rgba(37, 99, 235, 0.28)'
              }}>
                <div className="kpi-card__header">
                  <span className="kpi-card__label">Confused Word Pairs</span>
                  <div className="kpi-card__icon-bubble">🔀</div>
                </div>
                <div className="kpi-card__value">{data.confusedPairs.length}</div>
                <div className="kpi-card__footer">
                  <span className="kpi-card__subtitle">Distinct pairs identified</span>
                </div>
              </div>

              <div className="kpi-card" style={{
                '--kpi-gradient': 'linear-gradient(135deg, #3b82f6, #2563eb)',
                '--kpi-blob': 'rgba(59, 130, 246, 0.08)', '--kpi-color': '#2563eb', '--kpi-glow': 'rgba(59, 130, 246, 0.28)'
              }}>
                <div className="kpi-card__header">
                  <span className="kpi-card__label">Lessons with Gaps</span>
                  <div className="kpi-card__icon-bubble">📚</div>
                </div>
                <div className="kpi-card__value">{data.curriculumGaps.length}</div>
                <div className="kpi-card__footer">
                  <span className="kpi-card__subtitle">Requiring remediation</span>
                </div>
              </div>
            </div>

            {/* Tabs */}
            <div style={{
              display: 'inline-flex',
              background: 'var(--color-surface)',
              borderRadius: 'var(--radius-md)',
              padding: 4,
              border: '1.5px solid var(--color-border)',
              boxShadow: 'var(--shadow-xs)',
              marginBottom: 24,
            }}>
              {[
                { id: 'pairs', label: '🔀 Confused Word Pairs' },
                { id: 'gaps',  label: '📚 Curriculum Gaps' },
              ].map((tab) => (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  style={{
                    padding: '8px 18px',
                    borderRadius: 8,
                    border: 'none',
                    cursor: 'pointer',
                    fontWeight: 700,
                    fontSize: '0.875rem',
                    fontFamily: 'inherit',
                    background:
                      activeTab === tab.id
                        ? 'linear-gradient(135deg, #3b82f6, #1d4ed8)'
                        : 'transparent',
                    color:
                      activeTab === tab.id ? '#fff' : 'var(--color-text-muted)',
                    transition: 'all 0.18s',
                    boxShadow: activeTab === tab.id ? '0 2px 8px rgba(37,99,235,0.30)' : 'none',
                  }}
                >
                  {tab.label}
                </button>
              ))}
            </div>

            {/* Confused Pairs Panel */}
            {activeTab === 'pairs' && (
              <section>
                {data.confusedPairs.length === 0 ? (
                  <div className="coming-soon" style={{ padding: 48 }}>
                    <div className="coming-soon__icon">🎉</div>
                    <h2 className="coming-soon__title">No confused word pairs detected yet</h2>
                    <p className="coming-soon__text">Learner responses look accurate across current practice runs.</p>
                  </div>
                ) : (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
                    {data.confusedPairs.map((pair) => (
                      <div
                        key={`${pair.wordAId}-${pair.wordBId}`}
                        className="section-card"
                        style={{
                          padding: '20px 24px',
                          marginBottom: 0,
                        }}
                      >
                        <div
                          style={{
                            display: 'flex',
                            alignItems: 'center',
                            gap: '20px',
                            flexWrap: 'wrap',
                          }}
                        >
                          {/* Word A */}
                          <div style={{ flex: 1, minWidth: '150px' }}>
                            <div style={{ fontSize: '1.05rem', fontWeight: 800, color: 'var(--color-text-main)' }}>
                              {pair.wordAEnglish}
                            </div>
                            <div style={{ fontSize: '0.85rem', color: 'var(--color-text-muted)', fontStyle: 'italic', marginTop: 2 }}>
                              {pair.wordACebuano}
                            </div>
                          </div>

                          {/* VS divider */}
                          <div
                            style={{
                              padding: '5px 12px',
                              borderRadius: '8px',
                              background: 'rgba(239, 68, 68, 0.10)',
                              color: '#ef4444',
                              fontSize: '0.75rem',
                              fontWeight: 800,
                              border: '1px solid rgba(239, 68, 68, 0.20)',
                            }}
                          >
                            VS
                          </div>

                          {/* Word B */}
                          <div style={{ flex: 1, minWidth: '150px' }}>
                            <div style={{ fontSize: '1.05rem', fontWeight: 800, color: 'var(--color-text-main)' }}>
                              {pair.wordBEnglish}
                            </div>
                            <div style={{ fontSize: '0.85rem', color: 'var(--color-text-muted)', fontStyle: 'italic', marginTop: 2 }}>
                              {pair.wordBCebuano}
                            </div>
                          </div>

                          {/* Error stats */}
                          <div style={{ flex: 2, minWidth: '220px' }}>
                            <div
                              style={{
                                fontSize: '0.8rem',
                                color: 'var(--color-text-muted)',
                                marginBottom: '6px',
                              }}
                            >
                              <strong style={{ color: 'var(--color-text-main)' }}>{pair.affectedLearners}</strong>{' '}
                              learner{pair.affectedLearners !== 1 ? 's' : ''} confused · Lesson:{' '}
                              <strong style={{ color: 'var(--color-text-main)' }}>{pair.lessonTitle}</strong>
                            </div>
                            <SeverityBar value={pair.totalErrors} max={maxPairErrors} />
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </section>
            )}

            {/* Curriculum Gaps Panel */}
            {activeTab === 'gaps' && (
              <section>
                {data.curriculumGaps.length === 0 ? (
                  <div className="coming-soon" style={{ padding: 48 }}>
                    <div className="coming-soon__icon">🎉</div>
                    <h2 className="coming-soon__title">No curriculum gaps detected yet</h2>
                    <p className="coming-soon__text">All lessons meet expected class-wide comprehension rates.</p>
                  </div>
                ) : (
                  <div>
                    {/* Header with Expand All toggle */}
                    <div style={{
                      display: 'flex',
                      justifyContent: 'space-between',
                      alignItems: 'center',
                      marginBottom: 12,
                      flexWrap: 'wrap',
                      gap: 8,
                    }}>
                      <div style={{ fontSize: '0.9rem', color: 'var(--color-text-muted)', fontWeight: 600 }}>
                        Showing <strong>{data.curriculumGaps.length}</strong> lesson{data.curriculumGaps.length !== 1 ? 's' : ''} with identified comprehension gaps
                      </div>
                      <button
                        className="btn btn--ghost btn--sm"
                        onClick={toggleAllLessons}
                        style={{ fontSize: '0.8rem', padding: '5px 12px', fontWeight: 700 }}
                      >
                        {data.curriculumGaps.every((g) => expandedLessons[g.lessonId])
                          ? '📁 Collapse All Breakdowns'
                          : '📂 Expand All Breakdowns'}
                      </button>
                    </div>

                    <div className="section-card" style={{ padding: 0, overflow: 'hidden', marginBottom: 0 }}>
                      <div className="accounts-table-wrap" style={{ margin: 0 }}>
                        <table className="accounts-table" style={{ width: '100%' }}>
                          <thead>
                            <tr>
                              <th style={{ width: '38px' }}></th>
                              <th>Lesson</th>
                              <th>Category</th>
                              <th style={{ minWidth: '220px' }}>Top Struggling Words</th>
                              <th style={{ textAlign: 'right' }}>Affected Students</th>
                              <th style={{ minWidth: '150px' }}>Demerit Severity</th>
                              <th style={{ minWidth: '240px' }}>Curriculum Recommendation</th>
                            </tr>
                          </thead>
                          <tbody>
                            {data.curriculumGaps.map((gap) => {
                              const isExpanded = !!expandedLessons[gap.lessonId];
                              const words = gap.problemWords || [];
                              const topWords = words.slice(0, 3);
                              const remainingCount = Math.max(0, words.length - 3);

                              // Recommendation severity
                              const isSevereRec = gap.totalErrors >= 30 || (gap.recommendation && gap.recommendation.toLowerCase().includes('high'));
                              const isWarningRec = !isSevereRec && (gap.totalErrors >= 10 || (gap.recommendation && gap.recommendation.toLowerCase().includes('moderate')));

                              return (
                                <tr key={gap.lessonId} style={{ borderBottom: isExpanded ? 'none' : undefined }}>
                                  {/* Expand/Collapse toggle chevron */}
                                  <td
                                    style={{
                                      textAlign: 'center',
                                      cursor: 'pointer',
                                      color: 'var(--color-text-muted)',
                                      userSelect: 'none',
                                      paddingRight: 0,
                                    }}
                                    onClick={() => toggleLesson(gap.lessonId)}
                                    title={isExpanded ? 'Collapse breakdown' : 'Expand full word breakdown'}
                                  >
                                    <span style={{
                                      display: 'inline-block',
                                      transform: isExpanded ? 'rotate(90deg)' : 'rotate(0deg)',
                                      transition: 'transform 0.2s ease',
                                      fontSize: '0.85rem',
                                    }}>
                                      ▶
                                    </span>
                                  </td>

                                  {/* Lesson Name */}
                                  <td
                                    onClick={() => toggleLesson(gap.lessonId)}
                                    style={{ cursor: 'pointer' }}
                                  >
                                    <strong style={{ color: 'var(--color-text-main)', fontSize: '0.95rem' }}>
                                      {gap.lessonTitle}
                                    </strong>
                                  </td>

                                  {/* Category */}
                                  <td>
                                    <span
                                      style={{
                                        display: 'inline-block',
                                        padding: '2px 8px',
                                        borderRadius: '6px',
                                        background: 'var(--color-surface-2, #f1f5f9)',
                                        color: 'var(--color-text-muted)',
                                        fontSize: '0.78rem',
                                        fontWeight: 600,
                                      }}
                                    >
                                      {gap.categoryName || 'General'}
                                    </span>
                                  </td>

                                  {/* Compact Top 3 Struggling Words Preview */}
                                  <td>
                                    {words.length > 0 ? (
                                      <div style={{ display: 'flex', alignItems: 'center', flexWrap: 'wrap', gap: '6px' }}>
                                        {topWords.map((pw) => {
                                          const isHighErr = pw.errorCount >= 20;
                                          const isMedErr = pw.errorCount >= 5;
                                          return (
                                            <span
                                              key={pw.wordId || pw.englishWord}
                                              title={`${pw.englishWord} (${pw.cebuanoMeaning || 'Meaning'}) — ${pw.demeritPoints ?? pw.errorCount} demerit points (${pw.mistakeCount || Math.max(1, Math.round((pw.demeritPoints ?? pw.errorCount)/2))} mistakes) across ${pw.affectedLearners} student${pw.affectedLearners !== 1 ? 's' : ''}`}
                                              style={{
                                                display: 'inline-flex',
                                                alignItems: 'center',
                                                gap: '4px',
                                                padding: '3px 8px',
                                                borderRadius: '6px',
                                                fontSize: '0.76rem',
                                                fontWeight: 700,
                                                background: isHighErr ? '#fee2e2' : isMedErr ? '#fef3c7' : '#f1f5f9',
                                                color: isHighErr ? '#991b1b' : isMedErr ? '#92400e' : '#334155',
                                                border: `1px solid ${isHighErr ? '#fecaca' : isMedErr ? '#fde68a' : '#e2e8f0'}`,
                                                cursor: 'default',
                                                whiteSpace: 'nowrap',
                                              }}
                                            >
                                              <span>{pw.englishWord}</span>
                                              <span style={{ fontSize: '0.7rem', opacity: 0.9, fontWeight: 800 }}>
                                                ({pw.demeritPoints ?? pw.errorCount} pts)
                                              </span>
                                            </span>
                                          );
                                        })}

                                        {remainingCount > 0 && (
                                          <button
                                            type="button"
                                            onClick={(e) => {
                                              e.stopPropagation();
                                              toggleLesson(gap.lessonId);
                                            }}
                                            style={{
                                              display: 'inline-flex',
                                              alignItems: 'center',
                                              padding: '3px 8px',
                                              borderRadius: '6px',
                                              fontSize: '0.74rem',
                                              fontWeight: 700,
                                              background: isExpanded ? 'rgba(37, 99, 235, 0.12)' : 'var(--color-surface-2, #f1f5f9)',
                                              color: isExpanded ? '#2563eb' : 'var(--color-text-muted)',
                                              border: isExpanded ? '1px solid rgba(37, 99, 235, 0.35)' : '1px solid var(--color-border)',
                                              cursor: 'pointer',
                                              transition: 'all 0.15s ease',
                                            }}
                                            title="Click to expand full word breakdown"
                                          >
                                            {isExpanded ? '▲ Hide' : `+${remainingCount} more ▾`}
                                          </button>
                                        )}
                                      </div>
                                    ) : (
                                      <span className="text-muted" style={{ fontSize: '0.8rem' }}>None</span>
                                    )}
                                  </td>

                                  {/* Affected Students */}
                                  <td style={{ textAlign: 'right', fontWeight: 700, color: '#f97316' }}>
                                    {gap.affectedLearners} <span style={{ fontSize: '0.75rem', color: 'var(--color-text-muted)', fontWeight: 500 }}>learner{gap.affectedLearners !== 1 ? 's' : ''}</span>
                                  </td>

                                  {/* Error Severity */}
                                  <td style={{ minWidth: '150px' }}>
                                    <SeverityBar value={gap.totalErrors} max={maxGapErrors} />
                                  </td>

                                  {/* Recommendation */}
                                  <td>
                                    <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
                                      <div>
                                        <span
                                          className={`rec-badge ${
                                            isSevereRec
                                              ? 'rec-badge--severe'
                                              : isWarningRec
                                              ? 'rec-badge--warning'
                                              : 'rec-badge--ok'
                                          }`}
                                        >
                                          {isSevereRec
                                            ? '🚨 High Density'
                                            : isWarningRec
                                            ? '⚠️ Moderate Gap'
                                            : 'ℹ️ Remediation Needed'}
                                        </span>
                                      </div>
                                      <span style={{ fontSize: '0.82rem', color: 'var(--color-text-muted)', lineHeight: 1.35 }}>
                                        {gap.recommendation}
                                      </span>
                                    </div>
                                  </td>
                                </tr>
                              );
                            })}
                          </tbody>
                        </table>
                      </div>

                      {/* Expandable sub-drawers rendered outside the compact row for clean hierarchy */}
                      {data.curriculumGaps.map((gap) => {
                        const isExpanded = !!expandedLessons[gap.lessonId];
                        if (!isExpanded) return null;
                        const words = gap.problemWords || [];

                        return (
                          <div
                            key={`drawer-${gap.lessonId}`}
                            style={{
                              background: 'var(--color-surface-2, #f8fafc)',
                              borderTop: '1px solid var(--color-border)',
                              borderBottom: '2px solid var(--color-border)',
                              padding: '18px 24px',
                            }}
                          >
                            <div style={{
                              display: 'flex',
                              justifyContent: 'space-between',
                              alignItems: 'center',
                              marginBottom: 14,
                              flexWrap: 'wrap',
                              gap: 10,
                            }}>
                              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                                <span style={{ fontSize: '1.1rem' }}>📋</span>
                                <div>
                                  <div style={{ fontWeight: 800, fontSize: '0.92rem', color: 'var(--color-text-main)' }}>
                                    Struggling Words Breakdown — {gap.lessonTitle}
                                  </div>
                                  <div style={{ fontSize: '0.78rem', color: 'var(--color-text-muted)' }}>
                                    {words.length} word{words.length !== 1 ? 's' : ''} caused {gap.totalErrors} total struggle points across {gap.affectedLearners} student{gap.affectedLearners !== 1 ? 's' : ''}
                                  </div>
                                </div>
                              </div>

                              <button
                                className="btn btn--ghost btn--sm"
                                onClick={() => toggleLesson(gap.lessonId)}
                                style={{ fontSize: '0.78rem', padding: '3px 10px' }}
                              >
                                ✕ Close Details
                              </button>
                            </div>

                            {/* Structured Grid of Problem Words */}
                            <div style={{
                              display: 'grid',
                              gridTemplateColumns: 'repeat(auto-fill, minmax(260px, 1fr))',
                              gap: 12,
                            }}>
                              {words.map((pw) => {
                                const errorRatio = gap.totalErrors > 0
                                  ? Math.min(100, Math.round((pw.errorCount / gap.totalErrors) * 100))
                                  : 0;
                                const isHighErr = pw.errorCount >= 20;
                                const isMedErr = pw.errorCount >= 5;

                                return (
                                  <div
                                    key={pw.wordId || pw.englishWord}
                                    style={{
                                      background: 'var(--color-surface, #ffffff)',
                                      borderRadius: '8px',
                                      padding: '12px 14px',
                                      border: isHighErr
                                        ? '1.5px solid #fecaca'
                                        : isMedErr
                                        ? '1.5px solid #fde68a'
                                        : '1px solid var(--color-border)',
                                      boxShadow: '0 1px 3px rgba(0,0,0,0.04)',
                                    }}
                                  >
                                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 6 }}>
                                      <div>
                                        <div style={{ fontWeight: 800, fontSize: '0.95rem', color: 'var(--color-text-main)' }}>
                                          {pw.englishWord}
                                        </div>
                                        <div style={{ fontSize: '0.8rem', color: 'var(--color-text-muted)', fontStyle: 'italic' }}>
                                          {pw.cebuanoMeaning || 'Meaning'}
                                        </div>
                                      </div>

                                      <span
                                        style={{
                                          padding: '3px 8px',
                                          borderRadius: '6px',
                                          fontSize: '0.72rem',
                                          fontWeight: 800,
                                          background: isHighErr ? '#fee2e2' : isMedErr ? '#fef3c7' : '#f1f5f9',
                                          color: isHighErr ? '#991b1b' : isMedErr ? '#92400e' : '#475569',
                                          whiteSpace: 'nowrap',
                                        }}
                                      >
                                        {pw.demeritPoints ?? pw.errorCount} pts demerit ({pw.mistakeCount || Math.max(1, Math.round((pw.demeritPoints ?? pw.errorCount)/2))} mistakes)
                                      </span>
                                    </div>

                                    {/* Mini visual error ratio bar */}
                                    <div style={{ marginTop: 8 }}>
                                      <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.72rem', color: 'var(--color-text-muted)', marginBottom: 3 }}>
                                        <span>{pw.affectedLearners} student{pw.affectedLearners !== 1 ? 's' : ''} affected</span>
                                        <span>{errorRatio}% of lesson struggle</span>
                                      </div>
                                      <div style={{ height: 4, borderRadius: 2, background: '#e2e8f0', overflow: 'hidden' }}>
                                        <div
                                          style={{
                                            width: `${errorRatio}%`,
                                            height: '100%',
                                            background: isHighErr ? '#ef4444' : isMedErr ? '#f59e0b' : '#3b82f6',
                                            borderRadius: 2,
                                          }}
                                        />
                                      </div>
                                    </div>
                                  </div>
                                );
                              })}
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  </div>
                )}
              </section>
            )}
          </>
        ) : null}
      </main>
    </div>
  );
}
