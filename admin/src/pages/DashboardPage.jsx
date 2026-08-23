import { useState, useEffect, useCallback } from 'react';
import AdminNav from '../components/AdminNav';
import { AnalyticsService } from '../services/AnalyticsService';
import { SectionService } from '../services/SectionService';
import { ReportService } from '../services/ReportService';
import LearnerDetailModal from '../components/LearnerDetailModal';
import ResetProgressModal from '../components/ResetProgressModal';
import { LearnerService } from '../services/LearnerService';

function KpiCard({ title, value, subtitle, icon, trend, color = 'var(--color-primary)' }) {
  return (
    <div style={{
      background: 'var(--glass-bg)',
      borderRadius: 'var(--radius-md)',
      padding: '22px 24px',
      border: '1px solid var(--color-border)',
      display: 'flex',
      flexDirection: 'column',
      gap: '8px',
      position: 'relative',
      overflow: 'hidden',
      boxShadow: 'var(--shadow-card)',
    }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <span style={{ fontSize: '0.85rem', color: 'var(--color-text-muted)', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.5px' }}>
          {title}
        </span>
        <span style={{ fontSize: '1.5rem', opacity: 0.85 }}>{icon}</span>
      </div>
      <div style={{ fontSize: '2rem', fontWeight: 800, color, lineHeight: 1.1 }}>
        {value}
      </div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 4 }}>
        <span style={{ fontSize: '0.8rem', color: 'var(--color-text-dim)' }}>{subtitle}</span>
        {trend && (
          <span style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--color-success)', background: 'rgba(74, 222, 128, 0.1)', padding: '2px 6px', borderRadius: 4 }}>
            {trend}
          </span>
        )}
      </div>
    </div>
  );
}

function TrendLineChart({ data = [], label, color = '#7c4dff', unit = '%' }) {
  if (!data || data.length === 0) {
    return <div style={{ textAlign: 'center', color: 'var(--color-text-muted)', padding: 30 }}>No trend data available</div>;
  }

  const values = data.map(d => d.value ?? 0);
  const minVal = Math.min(...values);
  const maxVal = Math.max(...values, 100);
  const range = maxVal - minVal || 1;

  const width = 450;
  const height = 140;
  const padding = 20;

  const points = data.map((d, i) => {
    const x = padding + (i / Math.max(1, data.length - 1)) * (width - 2 * padding);
    const y = height - padding - (((d.value ?? 0) - minVal) / range) * (height - 2 * padding);
    return `${x},${y}`;
  }).join(' ');

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8, fontSize: '0.85rem' }}>
        <span style={{ fontWeight: 600, color: 'var(--color-text-main)' }}>{label}</span>
        <span style={{ color: 'var(--color-text-dim)' }}>Last {data.length} days</span>
      </div>
      <svg viewBox={`0 0 ${width} ${height}`} style={{ width: '100%', height: 'auto', overflow: 'visible' }}>
        <polyline
          fill="none"
          stroke={color}
          strokeWidth="3"
          strokeLinecap="round"
          strokeLinejoin="round"
          points={points}
        />
        {data.map((d, i) => {
          const x = padding + (i / Math.max(1, data.length - 1)) * (width - 2 * padding);
          const y = height - padding - (((d.value ?? 0) - minVal) / range) * (height - 2 * padding);
          return (
            <g key={i}>
              <circle cx={x} cy={y} r="4" fill={color} stroke="#fff" strokeWidth="2" />
              <text x={x} y={y - 8} textAnchor="middle" fontSize="10" fill="var(--color-text-muted)" fontWeight="600">
                {typeof d.value === 'number' ? `${d.value.toFixed(0)}${unit}` : ''}
              </text>
              <text x={x} y={height - 2} textAnchor="middle" fontSize="9" fill="var(--color-text-dim)">
                {d.date ? d.date.slice(5) : ''}
              </text>
            </g>
          );
        })}
      </svg>
    </div>
  );
}

export default function DashboardPage() {
  const [analytics, setAnalytics] = useState(null);
  const [demographics, setDemographics] = useState(null);
  const [sections, setSections] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  // Filters
  const [cohortType, setCohortType] = useState('ALL'); // 'ALL' | 'INDEPENDENT' | 'ENROLLED'
  const [selectedSection, setSelectedSection] = useState('');
  const [selectedGrade, setSelectedGrade] = useState('');
  const [timeRange, setTimeRange] = useState('7d');

  // Modals for quick intervention
  const [detailLearnerId, setDetailLearnerId] = useState(null);
  const [resetTarget, setResetTarget] = useState(null);
  const [resetLoading, setResetLoading] = useState(false);

  const flash = (msg) => { setSuccess(msg); setTimeout(() => setSuccess(''), 3500); };

  const loadData = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const [dashData, demoData, secList] = await Promise.all([
        AnalyticsService.getDashboardAnalytics({
          sectionId: selectedSection || undefined,
          gradeLevel: selectedGrade || undefined,
          timeRange,
          cohortType: selectedSection ? undefined : cohortType,
        }),
        AnalyticsService.getDemographics().catch(() => null),
        SectionService.getAllSections().catch(() => []),
      ]);
      setAnalytics(dashData);
      setDemographics(demoData);
      setSections(secList);
    } catch (err) {
      setError(err?.message || 'Failed to load analytics dashboard.');
    } finally {
      setLoading(false);
    }
  }, [selectedSection, selectedGrade, timeRange, cohortType]);

  useEffect(() => { loadData(); }, [loadData]);

  const handleConfirmReset = async (learnerId, lessonId) => {
    setResetLoading(true);
    try {
      await LearnerService.resetProgress(learnerId, lessonId);
      flash('Progress reset successfully.');
      setResetTarget(null);
      loadData();
    } catch (err) {
      setError(err?.message || 'Failed to reset progress.');
    } finally {
      setResetLoading(false);
    }
  };

  // Safe KPI resolution supporting both snake_case (Spring Boot) and camelCase
  const kpis = analytics?.kpis;
  const activeCount = kpis?.weekly_active_learners ?? kpis?.weeklyActiveLearners ?? 0;
  const totalCount = kpis?.total_learners ?? kpis?.totalLearners ?? 0;
  const avgAccuracyVal = kpis?.avg_accuracy ?? kpis?.averageAccuracy ?? 0;
  const completionsCount = kpis?.lessons_completed ?? kpis?.totalCompletions ?? 0;
  const wordsMasteredCount = kpis?.total_words_mastered ?? kpis?.totalWordsMastered ?? 0;
  const avgSessionSec = kpis?.avg_session_length_seconds ?? kpis?.averageSessionDurationSeconds ?? 0;

  // Safe trends resolution
  const accuracyTrendsData = analytics?.trends?.accuracy_trends || analytics?.accuracyTrend || [];
  const completionTrendsData = analytics?.trends?.completion_trends || analytics?.completionTrend || [];

  // Safe struggling students list
  const strugglingList = analytics?.struggling_learners || analytics?.strugglingLearners || [];

  // Safe curriculum analytics
  const hardestWords = analytics?.curriculum_analytics?.hardest_words || analytics?.hardestWords || [];
  const fallbackWords = analytics?.curriculum_analytics?.fallback_frequency || analytics?.fallbackWords || [];

  return (
    <div className="admin-layout">
      <AdminNav />
      <main className="admin-main" style={{ maxWidth: '100%' }}>
        <header className="admin-main__header" style={{ alignItems: 'flex-start', flexWrap: 'wrap', gap: 16 }}>
          <div>
            <h1 className="admin-main__title">Global &amp; Class Analytics</h1>
            <p className="admin-main__subtitle">Worldwide platform statistics, independent self-paced learners, and classroom diagnostics</p>
          </div>

          <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', alignItems: 'center' }}>
            {/* Cohort Scope Selector */}
            <select
              className="toolbar-select"
              value={selectedSection ? '' : cohortType}
              onChange={e => {
                setCohortType(e.target.value);
                setSelectedSection('');
              }}
              style={{ minWidth: 170, fontWeight: 600 }}
            >
              <option value="ALL">🌍 Global (All Users)</option>
              <option value="INDEPENDENT">👤 Independent / Self-Paced Only</option>
              <option value="ENROLLED">🏫 Enrolled in Classes Only</option>
            </select>

            {/* Class Section Selector */}
            <select
              className="toolbar-select"
              value={selectedSection}
              onChange={e => {
                setSelectedSection(e.target.value);
                if (e.target.value) setCohortType('ALL');
              }}
              style={{ minWidth: 150 }}
            >
              <option value="">Specific Class Section...</option>
              {sections.map(s => (
                <option key={s.section_id} value={s.section_id}>{s.section_name}</option>
              ))}
            </select>

            <select
              className="toolbar-select"
              value={selectedGrade}
              onChange={e => setSelectedGrade(e.target.value)}
              style={{ minWidth: 120 }}
            >
              <option value="">All Grades</option>
              <option value="GRADE_3_4">Grade 3-4</option>
              <option value="GRADE_5_6">Grade 5-6</option>
              <option value="GRADE_6">Grade 6</option>
            </select>

            <select
              className="toolbar-select"
              value={timeRange}
              onChange={e => setTimeRange(e.target.value)}
              style={{ minWidth: 100 }}
            >
              <option value="7d">Last 7 Days</option>
              <option value="30d">Last 30 Days</option>
              <option value="all">All Time</option>
            </select>

            <button
              className="btn btn--ghost btn--sm"
              onClick={() => ReportService.downloadClassReport('pdf', selectedSection, selectedGrade)}
              title="Download Class Performance PDF"
            >
              📄 Export PDF
            </button>
            <button
              className="btn btn--ghost btn--sm"
              onClick={() => ReportService.downloadClassReport('csv', selectedSection, selectedGrade)}
              title="Download Class Performance CSV"
            >
              📥 Export CSV
            </button>
          </div>
        </header>

        {error && <div className="alert alert--error" onClick={() => setError('')}>{error}</div>}
        {success && <div className="alert alert--success">{success}</div>}

        {/* Global Demographics Banner */}
        {demographics && !selectedSection && (
          <div style={{
            background: 'linear-gradient(135deg, rgba(124, 77, 255, 0.08) 0%, rgba(0, 229, 255, 0.08) 100%)',
            border: '1px solid var(--color-border)',
            borderRadius: 'var(--radius-md)',
            padding: '16px 20px',
            marginBottom: 24,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            flexWrap: 'wrap',
            gap: 16
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <span style={{ fontSize: '1.8rem' }}>🌐</span>
              <div>
                <strong style={{ fontSize: '0.95rem', color: 'var(--color-text-main)' }}>Platform Demographics Overview</strong>
                <div style={{ fontSize: '0.8rem', color: 'var(--color-text-dim)', marginTop: 2 }}>
                  Total registered: <strong>{demographics.total_learners ?? demographics.totalLearners ?? 0} learners</strong> across all modalities
                </div>
              </div>
            </div>

            <div style={{ display: 'flex', gap: 20, flexWrap: 'wrap' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <span style={{ width: 10, height: 10, borderRadius: '50%', background: 'var(--color-accent-1)' }} />
                <span style={{ fontSize: '0.85rem' }}>
                  <strong>{demographics.independent_learners_count ?? demographics.independentLearnersCount ?? 0}</strong> Independent / Self-Paced ({demographics.independent_percentage ?? demographics.independentPercentage ?? 0}%)
                </span>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <span style={{ width: 10, height: 10, borderRadius: '50%', background: 'var(--color-primary)' }} />
                <span style={{ fontSize: '0.85rem' }}>
                  <strong>{demographics.enrolled_learners_count ?? demographics.enrolledLearnersCount ?? 0}</strong> Enrolled in Classes ({demographics.enrolled_percentage ?? demographics.enrolledPercentage ?? 0}%)
                </span>
              </div>
            </div>
          </div>
        )}

        {loading ? (
          <div className="auth-loading" style={{ minHeight: 350 }}><div className="spinner" /></div>
        ) : analytics ? (
          <div>
            {/* KPI Cards Grid */}
            <div style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(210px, 1fr))',
              gap: 16,
              marginBottom: 28,
            }}>
              <KpiCard
                title="Active Students"
                value={activeCount}
                subtitle={`${totalCount} total ${cohortType === 'INDEPENDENT' ? 'independent' : 'enrolled'}`}
                icon="👥"
                color="var(--color-accent-1)"
                trend="7-day active"
              />
              <KpiCard
                title="Average Accuracy"
                value={`${Number(avgAccuracyVal).toFixed(1)}%`}
                subtitle="Across practice sessions"
                icon="🎯"
                color={Number(avgAccuracyVal) >= 70 ? 'var(--color-success)' : 'var(--color-danger)'}
              />
              <KpiCard
                title="Lessons Completed"
                value={completionsCount}
                subtitle="Milestone completions"
                icon="🏆"
                color="var(--color-accent-2)"
              />
              <KpiCard
                title="Words Mastered"
                value={wordsMasteredCount}
                subtitle="Mastery tier reached"
                icon="🌟"
                color="#f59e0b"
              />
              <KpiCard
                title="Avg Session Duration"
                value={`${Math.round(Number(avgSessionSec) / 60)} min`}
                subtitle="Per practice session"
                icon="⏱️"
                color="#06b6d4"
              />
            </div>

            {/* Engagement & Trend Charts Grid */}
            <div style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(380px, 1fr))',
              gap: 20,
              marginBottom: 32,
            }}>
              <div style={{
                background: 'var(--glass-bg)',
                borderRadius: 'var(--radius-md)',
                padding: 24,
                border: '1px solid var(--color-border)',
              }}>
                <h3 style={{ fontSize: '1.05rem', margin: '0 0 16px 0', color: 'var(--color-primary)' }}>
                  📈 Cohort Accuracy Trend
                </h3>
                <TrendLineChart
                  data={accuracyTrendsData}
                  label="Daily Average Accuracy"
                  color="#7c4dff"
                  unit="%"
                />
              </div>

              <div style={{
                background: 'var(--glass-bg)',
                borderRadius: 'var(--radius-md)',
                padding: 24,
                border: '1px solid var(--color-border)',
              }}>
                <h3 style={{ fontSize: '1.05rem', margin: '0 0 16px 0', color: 'var(--color-accent-2)' }}>
                  📊 Daily Lesson Completions
                </h3>
                <TrendLineChart
                  data={completionTrendsData}
                  label="Completed Lessons"
                  color="#00e5ff"
                  unit=""
                />
              </div>
            </div>

            {/* Struggling Students Section (Multi-signal Alerts) */}
            <div style={{
              background: 'var(--glass-bg)',
              borderRadius: 'var(--radius-md)',
              padding: 24,
              border: '1px solid var(--color-border)',
              marginBottom: 32,
            }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
                <div>
                  <h3 style={{ fontSize: '1.1rem', margin: 0, color: 'var(--color-danger)', display: 'flex', alignItems: 'center', gap: 8 }}>
                    <span>⚠️ Students Needing Support</span>
                    <span className="table-meta" style={{ margin: 0 }}>({strugglingList.length} flagged)</span>
                  </h3>
                  <p style={{ margin: '4px 0 0 0', fontSize: '0.8rem', color: 'var(--color-text-dim)' }}>
                    Flagged by multi-signal heuristics: accuracy &lt; 70%, high demerits (&gt;= 5), or frequent tier drops.
                  </p>
                </div>
              </div>

              <div className="accounts-table-wrap">
                <table className="accounts-table">
                  <thead>
                    <tr>
                      <th>Learner</th>
                      <th>Cohort / Section</th>
                      <th>Accuracy</th>
                      <th>Demerits</th>
                      <th>Tier Drops</th>
                      <th>Intervention Reasons</th>
                      <th>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {strugglingList.length === 0 && (
                      <tr>
                        <td colSpan={7} style={{ textAlign: 'center', color: 'var(--color-success)', padding: 30 }}>
                          🎉 Excellent! No struggling learners currently flagged in this cohort.
                        </td>
                      </tr>
                    )}
                    {strugglingList.map(sl => {
                      const lid = sl.learner_id || sl.learnerId;
                      const dName = sl.display_name || sl.displayName;
                      const sName = sl.section_name || sl.sectionName;
                      const acc = sl.overall_accuracy ?? sl.overallAccuracy ?? 0;
                      const demerits = sl.demerit_points ?? sl.demeritPoints ?? 0;
                      const drops = sl.tier_drop_count ?? sl.tierDropsCount ?? 0;
                      const reasons = sl.reasons || [];

                      return (
                        <tr key={lid}>
                          <td>
                            <strong>{dName}</strong>
                          </td>
                          <td>
                            {sName ? (
                              <span className="text-muted">{sName}</span>
                            ) : (
                              <span style={{
                                fontSize: '0.75rem',
                                background: 'rgba(6, 182, 212, 0.12)',
                                color: '#06b6d4',
                                padding: '2px 8px',
                                borderRadius: 4,
                                fontWeight: 600,
                              }}>
                                Self-Paced
                              </span>
                            )}
                          </td>
                          <td style={{ color: 'var(--color-danger)', fontWeight: 700 }}>
                            {Number(acc).toFixed(1)}%
                          </td>
                          <td style={{ color: demerits > 0 ? 'var(--color-danger)' : 'inherit' }}>
                            {demerits}
                          </td>
                          <td>{drops}</td>
                          <td>
                            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4 }}>
                              {reasons.map((r, i) => (
                                <span key={i} style={{
                                  fontSize: '0.72rem',
                                  background: 'rgba(239, 68, 68, 0.1)',
                                  color: 'var(--color-danger)',
                                  padding: '2px 8px',
                                  borderRadius: 4,
                                  fontWeight: 500,
                                }}>
                                  {r}
                                </span>
                              ))}
                            </div>
                          </td>
                          <td className="actions-cell">
                            <button
                              className="btn btn--sm btn--ghost"
                              onClick={() => setDetailLearnerId(lid)}
                            >
                              🔍 Diagnostic
                            </button>
                            <button
                              className="btn btn--sm btn--danger-ghost"
                              onClick={() => setResetTarget(sl)}
                            >
                              ⚠️ Reset
                            </button>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </div>

            {/* Curriculum Analytics Grid: Hardest Words & Fallback Frequency */}
            <div style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(420px, 1fr))',
              gap: 20,
              marginBottom: 32,
            }}>
              {/* Words Needing Curriculum Attention */}
              <div style={{
                background: 'var(--glass-bg)',
                borderRadius: 'var(--radius-md)',
                padding: 24,
                border: '1px solid var(--color-border)',
              }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 12 }}>
                  <div>
                    <h3 style={{ fontSize: '1.05rem', margin: '0 0 4px 0', color: 'var(--color-text-main)', display: 'flex', alignItems: 'center', gap: 8 }}>
                      📘 Words Needing Curriculum Attention
                    </h3>
                    <p style={{ margin: 0, fontSize: '0.8rem', color: 'var(--color-text-muted)', lineHeight: 1.4 }}>
                      Class-wide difficulty & content optimization signals to help teachers refine example sentences or verify visual/audio assets.
                    </p>
                  </div>
                </div>

                <div className="accounts-table-wrap">
                  <table className="accounts-table">
                    <thead>
                      <tr>
                        <th>Vocabulary Word</th>
                        <th>Lesson</th>
                        <th>Class Struggle Rate</th>
                        <th>Total Demerits</th>
                        <th>Accuracy</th>
                        <th>Curriculum Action</th>
                      </tr>
                    </thead>
                    <tbody>
                      {hardestWords.length === 0 && (
                        <tr><td colSpan={6} style={{ textAlign: 'center', color: 'var(--color-text-muted)', padding: 20 }}>No curriculum attention items flagged</td></tr>
                      )}
                      {hardestWords.map(w => {
                        const wid = w.word_id || w.wordId;
                        const eng = w.english_word || w.englishWord;
                        const ceb = w.cebuano_meaning || w.cebuanoMeaning;
                        const les = w.lesson_title || w.lessonTitle;
                        const acc = w.avg_accuracy ?? w.accuracy ?? 0;
                        const totalDem = w.total_demerits ?? w.avg_demerits ?? w.demeritPoints ?? 0;
                        const strugglePct = w.struggle_percentage ?? 0;
                        const strugglingCount = w.struggling_learner_count ?? w.strugglingLearnerCount;
                        const rawRec = w.curriculum_recommendation || w.curriculumRecommendation;
                        const recommendation = rawRec || (Number(acc) < 70 ? 'Review Example Sentence & Context' : (Number(acc) < 85 ? 'Review Distractor Choices' : 'Content Verified (Normal)'));

                        // Badge styling based on curriculum recommendation intent
                        const isSevere = recommendation.includes('Review Example') || Number(acc) < 70;
                        const isWarning = recommendation.includes('Distractor') || recommendation.includes('Verify') || (Number(acc) >= 70 && Number(acc) < 85);
                        const isNormal = recommendation.includes('Normal') || recommendation.includes('Verified') || Number(acc) >= 85;

                        const badgeBg = isSevere ? 'rgba(239, 68, 68, 0.12)' : isWarning ? 'rgba(249, 115, 22, 0.12)' : 'rgba(16, 185, 129, 0.12)';
                        const badgeColor = isSevere ? '#dc2626' : isWarning ? '#d97706' : '#059669';
                        const badgeBorder = isSevere ? 'rgba(239, 68, 68, 0.25)' : isWarning ? 'rgba(249, 115, 22, 0.25)' : 'rgba(16, 185, 129, 0.25)';

                        return (
                          <tr key={wid}>
                            <td>
                              <strong>{eng}</strong>
                              <div style={{ fontSize: '0.78rem', color: 'var(--color-text-muted)', fontStyle: 'italic' }}>{ceb}</div>
                            </td>
                            <td className="text-muted">{les}</td>
                            <td>
                              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                                <span style={{
                                  fontWeight: 700,
                                  color: isSevere ? '#dc2626' : isWarning ? '#d97706' : 'var(--color-text-main)',
                                }}>
                                  {Number(strugglePct).toFixed(1)}%
                                </span>
                                {strugglingCount != null && (
                                  <span style={{ fontSize: '0.75rem', color: 'var(--color-text-muted)' }}>
                                    ({strugglingCount} learner{strugglingCount === 1 ? '' : 's'})
                                  </span>
                                )}
                              </div>
                            </td>
                            <td>
                              <span style={{
                                fontWeight: totalDem > 0 ? 700 : 400,
                                color: totalDem >= 20 ? '#dc2626' : totalDem > 0 ? '#d97706' : 'inherit',
                              }}>
                                {totalDem} pts
                              </span>
                            </td>
                            <td style={{ color: Number(acc) < 70 ? '#dc2626' : Number(acc) < 85 ? '#d97706' : '#059669', fontWeight: 600 }}>
                              {Number(acc).toFixed(1)}%
                            </td>
                            <td>
                              <span style={{
                                display: 'inline-block',
                                padding: '3px 8px',
                                borderRadius: 6,
                                fontSize: '0.75rem',
                                fontWeight: 600,
                                background: badgeBg,
                                color: badgeColor,
                                border: `1px solid ${badgeBorder}`,
                              }}>
                                {recommendation}
                              </span>
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              </div>

              {/* Module 4 Fallback Frequency */}
              <div style={{
                background: 'var(--glass-bg)',
                borderRadius: 'var(--radius-md)',
                padding: 24,
                border: '1px solid var(--color-border)',
              }}>
                <h3 style={{ fontSize: '1.05rem', margin: '0 0 16px 0', color: 'var(--color-text-main)' }}>
                  🔄 Module 4 Asset Fallback Frequency
                </h3>
                <div className="accounts-table-wrap">
                  <table className="accounts-table">
                    <thead>
                      <tr>
                        <th>Word</th>
                        <th>Lesson</th>
                        <th>Fallbacks Triggered</th>
                        <th>Accuracy</th>
                      </tr>
                    </thead>
                    <tbody>
                      {fallbackWords.length === 0 && (
                        <tr><td colSpan={4} style={{ textAlign: 'center', color: 'var(--color-text-muted)', padding: 20 }}>No fallbacks triggered</td></tr>
                      )}
                      {fallbackWords.map(fw => {
                        const wid = fw.word_id || fw.wordId;
                        const eng = fw.english_word || fw.englishWord;
                        const les = fw.lesson_title || fw.lessonTitle;
                        const cnt = fw.fallback_count ?? fw.fallbackCount ?? 0;
                        const acc = fw.avg_accuracy ?? fw.accuracy ?? 0;

                        return (
                          <tr key={wid}>
                            <td><strong>{eng}</strong></td>
                            <td className="text-muted">{les}</td>
                            <td>
                              <span style={{
                                fontWeight: 700,
                                color: cnt > 2 ? 'var(--color-danger)' : 'var(--color-accent-1)',
                              }}>
                                {cnt} times
                              </span>
                            </td>
                            <td className="text-muted">
                              {Number(acc).toFixed(1)}%
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>

            {/* Cumulative Review & Long-Term Retention Cohort Overview */}
            {(() => {
              const cumSummary = analytics?.curriculum_analytics?.cumulative_summary || analytics?.curriculumAnalytics?.cumulativeSummary;
              const cumTotalSessions = cumSummary?.total_sessions_completed ?? cumSummary?.totalSessionsCompleted ?? 0;
              const cumAvgRetention = cumSummary?.avg_retention_score ?? cumSummary?.avgRetentionScore ?? 0;
              const cumPerfectGold = cumSummary?.perfect_gold_count ?? cumSummary?.perfectGoldCount ?? 0;
              const cumGold = cumSummary?.gold_count ?? cumSummary?.goldCount ?? 0;
              const cumSilver = cumSummary?.silver_count ?? cumSummary?.silverCount ?? 0;
              const cumBronze = cumSummary?.bronze_count ?? cumSummary?.bronzeCount ?? 0;

              return (
                <div style={{
                  background: 'var(--glass-bg)',
                  borderRadius: 'var(--radius-md)',
                  padding: 24,
                  border: '1px solid var(--color-border)',
                  marginBottom: 32,
                }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: 12, marginBottom: 16 }}>
                    <div>
                      <h3 style={{ fontSize: '1.05rem', margin: '0 0 4px 0', color: 'var(--color-text-main)', display: 'flex', alignItems: 'center', gap: 8 }}>
                        <span>🌟 Cumulative Review &amp; Retention Mastery</span>
                        <span className="table-meta" style={{ margin: 0 }}>({cumTotalSessions} total sessions completed)</span>
                      </h3>
                      <p style={{ margin: 0, fontSize: '0.8rem', color: 'var(--color-text-muted)', lineHeight: 1.4 }}>
                        Cross-lesson spaced repetition outcomes measuring vocabulary retention across lesson pairs and curriculum themes.
                      </p>
                    </div>
                  </div>

                  <div style={{
                    display: 'grid',
                    gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
                    gap: 16,
                  }}>
                    <div style={{
                      background: 'rgba(124, 77, 255, 0.05)',
                      border: '1px solid rgba(124, 77, 255, 0.2)',
                      borderRadius: 'var(--radius-sm)',
                      padding: '16px',
                    }}>
                      <div style={{ fontSize: '0.78rem', color: 'var(--color-text-muted)', textTransform: 'uppercase', fontWeight: 600 }}>Cohort Retention Accuracy</div>
                      <div style={{ fontSize: '1.6rem', fontWeight: 800, color: Number(cumAvgRetention) >= 70 ? 'var(--color-success)' : 'var(--color-primary)', marginTop: 4 }}>
                        {Number(cumAvgRetention).toFixed(1)}%
                      </div>
                      <div style={{ fontSize: '0.75rem', color: 'var(--color-text-dim)', marginTop: 4 }}>Average across all completed pair reviews</div>
                    </div>

                    <div style={{
                      background: 'rgba(234, 179, 8, 0.05)',
                      border: '1px solid rgba(234, 179, 8, 0.25)',
                      borderRadius: 'var(--radius-sm)',
                      padding: '16px',
                    }}>
                      <div style={{ fontSize: '0.78rem', color: 'var(--color-text-muted)', textTransform: 'uppercase', fontWeight: 600 }}>🏆 Perfect Gold Badges</div>
                      <div style={{ fontSize: '1.6rem', fontWeight: 800, color: '#d97706', marginTop: 4 }}>
                        {cumPerfectGold}
                      </div>
                      <div style={{ fontSize: '0.75rem', color: 'var(--color-text-dim)', marginTop: 4 }}>100% flawless cumulative score</div>
                    </div>

                    <div style={{
                      background: 'rgba(59, 130, 246, 0.05)',
                      border: '1px solid rgba(59, 130, 246, 0.2)',
                      borderRadius: 'var(--radius-sm)',
                      padding: '16px',
                    }}>
                      <div style={{ fontSize: '0.78rem', color: 'var(--color-text-muted)', textTransform: 'uppercase', fontWeight: 600 }}>🥇 Gold &amp; 🥈 Silver Badges</div>
                      <div style={{ fontSize: '1.6rem', fontWeight: 800, color: '#2563eb', marginTop: 4 }}>
                        {cumGold + cumSilver}
                      </div>
                      <div style={{ fontSize: '0.75rem', color: 'var(--color-text-dim)', marginTop: 4 }}>{cumGold} Gold (90%+) · {cumSilver} Silver (80%+)</div>
                    </div>

                    <div style={{
                      background: 'rgba(180, 83, 9, 0.05)',
                      border: '1px solid rgba(180, 83, 9, 0.2)',
                      borderRadius: 'var(--radius-sm)',
                      padding: '16px',
                    }}>
                      <div style={{ fontSize: '0.78rem', color: 'var(--color-text-muted)', textTransform: 'uppercase', fontWeight: 600 }}>🥉 Bronze Badges</div>
                      <div style={{ fontSize: '1.6rem', fontWeight: 800, color: '#b45309', marginTop: 4 }}>
                        {cumBronze}
                      </div>
                      <div style={{ fontSize: '0.75rem', color: 'var(--color-text-dim)', marginTop: 4 }}>70%+ passing retention score</div>
                    </div>
                  </div>
                </div>
              );
            })()}
          </div>
        ) : null}

        {/* Diagnostic Modal */}
        {detailLearnerId && (
          <LearnerDetailModal
            learnerId={detailLearnerId}
            onClose={() => setDetailLearnerId(null)}
            onResetProgress={(l) => { setDetailLearnerId(null); setResetTarget(l); }}
            onEditProfile={() => { setDetailLearnerId(null); }}
          />
        )}

        {/* Destructive Reset Confirmation Modal */}
        {resetTarget && (
          <ResetProgressModal
            learner={resetTarget}
            onClose={() => setResetTarget(null)}
            onConfirm={handleConfirmReset}
            loading={resetLoading}
          />
        )}
      </main>
    </div>
  );
}
