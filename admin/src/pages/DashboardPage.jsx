import { useState, useEffect, useCallback } from 'react';
import AdminNav from '../components/AdminNav';
import { AnalyticsService } from '../services/AnalyticsService';
import { SectionService } from '../services/SectionService';
import { ReportService } from '../services/ReportService';
import LearnerDetailModal from '../components/LearnerDetailModal';
import ResetProgressModal from '../components/ResetProgressModal';
import ChartDetailModal from '../components/ChartDetailModal';
import { LearnerService } from '../services/LearnerService';
import { useAdminAuth } from '../hooks/useAdminAuth';

/* ─── Gradient KPI Card ─────────────────────────────────────────────────── */
function GradientKpiCard({
  title, value, subtitle, icon, trend, trendDir = 'neutral',
  gradient = 'linear-gradient(135deg, #3b82f6, #1d4ed8)',
  blob    = 'rgba(37,99,235,0.08)',
  color   = '#2563eb',
  glow    = 'rgba(37,99,235,0.28)',
}) {
  return (
    <div
      className="kpi-card"
      style={{ '--kpi-gradient': gradient, '--kpi-blob': blob, '--kpi-color': color, '--kpi-glow': glow }}
    >
      <div className="kpi-card__header">
        <span className="kpi-card__label">{title}</span>
        <div className="kpi-card__icon-bubble">{icon}</div>
      </div>
      <div className="kpi-card__value">{value}</div>
      <div className="kpi-card__footer">
        <span className="kpi-card__subtitle">{subtitle}</span>
        {trend && (
          <span className={`kpi-card__trend kpi-card__trend--${trendDir}`}>
            {trendDir === 'up' ? '↑' : trendDir === 'down' ? '↓' : '·'} {trend}
          </span>
        )}
      </div>
    </div>
  );
}

/* ─── Area Line Chart ────────────────────────────────────────────────────── */
function AreaLineChart({ data = [], label, color = '#2563eb', gradientId, unit = '%', onExpand }) {
  const [hoveredIdx, setHoveredIdx] = useState(null);

  if (!data || data.length === 0) {
    return (
      <div style={{
        display: 'flex', flexDirection: 'column', alignItems: 'center',
        justifyContent: 'center', padding: 40, gap: 10,
        color: 'var(--color-text-muted)', minHeight: 140,
      }}>
        <svg width="36" height="36" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="1.5" opacity="0.35">
          <polyline points="22 12 18 12 15 21 9 3 6 12 2 12" />
        </svg>
        <span style={{ fontSize: '0.82rem', fontWeight: 500 }}>No trend data available</span>
      </div>
    );
  }

  const values  = data.map(d => Number(d.value ?? 0));
  const minVal  = Math.min(...values);
  const maxVal  = Math.max(...values, 1);
  const range   = maxVal - minVal || 1;

  const W = 460, H = 140, PX = 26, PY = 20;

  const getX = (i) => PX + (i / Math.max(1, data.length - 1)) * (W - 2 * PX);
  const getY = (v) => H - PY - (((v ?? 0) - minVal) / range) * (H - 2 * PY);

  const linePts  = data.map((d, i) => `${getX(i)},${getY(d.value ?? 0)}`).join(' ');
  const areaPath = [
    `M ${getX(0)},${H - PY}`,
    ...data.map((d, i) => `L ${getX(i)},${getY(d.value ?? 0)}`),
    `L ${getX(data.length - 1)},${H - PY}`,
    'Z',
  ].join(' ');

  const uid = gradientId || `grad-${Math.random().toString(36).slice(2)}`;

  const handleMouseMove = (e) => {
    if (!data.length) return;
    const rect = e.currentTarget.getBoundingClientRect();
    const clientX = e.clientX - rect.left;
    const svgX = (clientX / rect.width) * W;
    const clampedX = Math.max(PX, Math.min(W - PX, svgX));
    const ratio = (clampedX - PX) / (W - 2 * PX);
    const nearest = Math.round(ratio * (data.length - 1));
    setHoveredIdx(Math.max(0, Math.min(data.length - 1, nearest)));
  };

  const handleMouseLeave = () => setHoveredIdx(null);

  const activeHover = hoveredIdx !== null && data[hoveredIdx] ? data[hoveredIdx] : null;
  const isDense = data.length > 8;
  const latestItem = data[data.length - 1];

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 10, alignItems: 'center', flexWrap: 'wrap', gap: 6 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <span style={{ fontWeight: 700, color: 'var(--color-text-main)', fontSize: '0.86rem' }}>{label}</span>
          {activeHover ? (
            <span style={{
              fontSize: '0.74rem', fontWeight: 800, color: color, background: `${color}15`,
              padding: '2px 8px', borderRadius: 12, border: `1px solid ${color}35`,
            }}>
              {activeHover.date?.slice(5)}: {Number(activeHover.value ?? 0).toFixed(0)}{unit}
            </span>
          ) : latestItem ? (
            <span style={{
              fontSize: '0.72rem', fontWeight: 700, color: 'var(--color-text-muted)',
              background: 'var(--color-surface-2)', padding: '2px 8px', borderRadius: 12, border: '1px solid var(--color-border)',
            }}>
              Latest: {Number(latestItem.value ?? 0).toFixed(0)}{unit}
            </span>
          ) : null}
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <span style={{ color: 'var(--color-text-dim)', fontSize: '0.72rem', background: 'var(--color-surface-2)', padding: '2px 8px', borderRadius: 20, border: '1px solid var(--color-border)' }}>
            {data.length} days
          </span>
        </div>
      </div>

      <div
        style={{ position: 'relative', cursor: onExpand ? 'pointer' : 'default' }}
        onClick={onExpand}
        title={onExpand ? 'Click to inspect in big modal' : undefined}
      >
        <svg
          viewBox={`0 0 ${W} ${H}`}
          style={{ width: '100%', height: 'auto', overflow: 'visible', display: 'block' }}
          onMouseMove={handleMouseMove}
          onMouseLeave={handleMouseLeave}
        >
          <defs>
            <linearGradient id={uid} x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%"   stopColor={color} stopOpacity="0.22" />
              <stop offset="100%" stopColor={color} stopOpacity="0.01" />
            </linearGradient>
          </defs>

          {/* Grid lines */}
          {[0.25, 0.5, 0.75, 1].map(t => {
            const y = PY + (1 - t) * (H - 2 * PY);
            return (
              <line key={t} x1={PX} y1={y} x2={W - PX} y2={y}
                stroke="var(--color-border)" strokeWidth="1" strokeDasharray="4 4" />
            );
          })}

          {/* Gradient area fill */}
          <path d={areaPath} fill={`url(#${uid})`} />

          {/* Line */}
          <polyline
            fill="none"
            stroke={color}
            strokeWidth="2.5"
            strokeLinecap="round"
            strokeLinejoin="round"
            points={linePts}
          />

          {/* X-axis date labels: only show start, middle, and end so they NEVER collide */}
          {data.length > 0 && (
            <>
              <text x={getX(0)} y={H - 2} textAnchor="start" fontSize="9" fontWeight="600" fill="var(--color-text-dim)" fontFamily="Inter, sans-serif">
                {data[0].date ? data[0].date.slice(5) : ''}
              </text>
              {data.length > 4 && (
                <text x={getX(Math.floor((data.length - 1) / 2))} y={H - 2} textAnchor="middle" fontSize="9" fontWeight="600" fill="var(--color-text-dim)" fontFamily="Inter, sans-serif">
                  {data[Math.floor((data.length - 1) / 2)].date ? data[Math.floor((data.length - 1) / 2)].date.slice(5) : ''}
                </text>
              )}
              <text x={getX(data.length - 1)} y={H - 2} textAnchor="end" fontSize="9" fontWeight="600" fill="var(--color-text-dim)" fontFamily="Inter, sans-serif">
                {data[data.length - 1].date ? data[data.length - 1].date.slice(5) : ''}
              </text>
            </>
          )}

          {/* Data points: ONLY show individual circles/labels when data is NOT dense (<= 8 items) */}
          {!isDense && data.map((d, i) => {
            const x = getX(i), y = getY(d.value ?? 0);
            return (
              <g key={i}>
                <circle cx={x} cy={y} r="3.5" fill={color} stroke="#fff" strokeWidth="2" />
                <text x={x} y={y - 7} textAnchor="middle" fontSize="9" fill={color} fontWeight="700" fontFamily="Inter, sans-serif">
                  {typeof d.value === 'number' ? `${d.value.toFixed(0)}${unit}` : ''}
                </text>
              </g>
            );
          })}

          {/* Interactive Hover Crosshair on Card Chart */}
          {hoveredIdx !== null && activeHover && (
            <g>
              <line
                x1={getX(hoveredIdx)}
                y1={PY}
                x2={getX(hoveredIdx)}
                y2={H - PY}
                stroke={color}
                strokeWidth="1.5"
                strokeDasharray="3 3"
              />
              <circle
                cx={getX(hoveredIdx)}
                cy={getY(activeHover.value ?? 0)}
                r="6"
                fill="#fff"
                stroke={color}
                strokeWidth="3"
              />
            </g>
          )}
        </svg>
      </div>
    </div>
  );
}

/* ─── Search icon ────────────────────────────────────────────────────────── */
const SearchIcon = () => (
  <svg width="15" height="15" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round">
    <circle cx="11" cy="11" r="8" />
    <path d="M21 21l-4.35-4.35" />
  </svg>
);

/* ─── Main Dashboard Component ──────────────────────────────────────────── */
export default function DashboardPage() {
  const { admin } = useAdminAuth();
  const isTeacher = admin?.role?.toLowerCase() === 'teacher' || admin?.role?.toUpperCase() === 'ROLE_TEACHER';

  const [analytics, setAnalytics]     = useState(null);
  const [demographics, setDemographics] = useState(null);
  const [sections, setSections]       = useState([]);
  const [flaggedCount, setFlaggedCount] = useState(0);
  const [loading, setLoading]         = useState(true);
  const [error, setError]             = useState('');
  const [success, setSuccess]         = useState('');

  // Filters
  const [cohortType, setCohortType]         = useState(isTeacher ? 'ENROLLED' : 'ALL');
  const [selectedSection, setSelectedSection] = useState('');
  const [selectedGrade, setSelectedGrade]   = useState('');
  const [timeRange, setTimeRange]           = useState('7d');

  useEffect(() => {
    if (isTeacher) {
      setCohortType('ENROLLED');
    }
  }, [isTeacher]);

  // Modals
  const [detailLearnerId, setDetailLearnerId] = useState(null);
  const [resetTarget, setResetTarget]         = useState(null);
  const [resetLoading, setResetLoading]       = useState(false);
  const [expandedChart, setExpandedChart]     = useState(null);
  const [downloadingReport, setDownloadingReport] = useState(false);

  const flash = (msg) => { setSuccess(msg); setTimeout(() => setSuccess(''), 3500); };

  const handleDownloadReport = async (format) => {
    setDownloadingReport(true);
    setError('');
    try {
      await ReportService.downloadClassReport(format, selectedSection || null, selectedGrade || null);
      flash(`Class performance report (${format.toUpperCase()}) downloaded successfully.`);
    } catch (err) {
      setError(err?.message || `Failed to download class report (${format.toUpperCase()}).`);
    } finally {
      setDownloadingReport(false);
    }
  };

  const loadData = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const [dashData, demoData, secList, flaggedList] = await Promise.all([
        AnalyticsService.getDashboardAnalytics({
          sectionId: selectedSection || undefined,
          gradeLevel: selectedGrade || undefined,
          timeRange,
          cohortType: selectedSection ? undefined : cohortType,
        }),
        AnalyticsService.getDemographics().catch(() => null),
        SectionService.getAllSections().catch(() => []),
        LearnerService.getFlaggedLearners({
          sectionId: selectedSection || undefined,
          gradeLevel: selectedGrade || undefined,
        }).catch(() => []),
      ]);
      setAnalytics(dashData);
      setDemographics(demoData);
      setSections(secList);
      setFlaggedCount(flaggedList ? flaggedList.length : 0);
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
  const kpis               = analytics?.kpis;
  const activeCount        = kpis?.weekly_active_learners   ?? kpis?.weeklyActiveLearners             ?? 0;
  const totalCount         = kpis?.total_learners           ?? kpis?.totalLearners                    ?? 0;
  const avgAccuracyVal     = kpis?.avg_accuracy             ?? kpis?.averageAccuracy                  ?? 0;
  const completionsCount   = kpis?.lessons_completed        ?? kpis?.totalCompletions                 ?? 0;
  const wordsMasteredCount = kpis?.total_words_mastered     ?? kpis?.totalWordsMastered               ?? 0;
  const avgSessionSec      = kpis?.avg_session_length_seconds ?? kpis?.averageSessionDurationSeconds  ?? 0;

  // Safe trends
  const accuracyTrendsData    = analytics?.trends?.accuracy_trends    || analytics?.accuracyTrend    || [];
  const completionTrendsData  = analytics?.trends?.completion_trends  || analytics?.completionTrend  || [];

  // Safe struggling students
  const strugglingList = analytics?.struggling_learners || analytics?.strugglingLearners || [];

  // Safe curriculum analytics
  const hardestWords    = analytics?.curriculum_analytics?.hardest_words    || analytics?.hardestWords  || [];
  const fallbackWords   = analytics?.curriculum_analytics?.fallback_frequency || analytics?.fallbackWords || [];
  const posBreakdown    = analytics?.curriculum_analytics?.pos_accuracy_breakdown || analytics?.curriculumAnalytics?.posAccuracyBreakdown || [];
  const lessonPassRates = analytics?.curriculum_analytics?.lesson_pass_rates || analytics?.curriculumAnalytics?.lessonPassRates || [];

  // Cumulative review
  const cumSummary      = analytics?.curriculum_analytics?.cumulative_summary || analytics?.curriculumAnalytics?.cumulativeSummary;
  const cumTotalSessions = cumSummary?.total_sessions_completed ?? cumSummary?.totalSessionsCompleted ?? 0;
  const cumAvgRetention  = cumSummary?.avg_retention_score      ?? cumSummary?.avgRetentionScore      ?? null;
  const cumPerfectGold   = cumSummary?.perfect_gold_count       ?? cumSummary?.perfectGoldCount       ?? 0;
  const cumGold          = cumSummary?.gold_count               ?? cumSummary?.goldCount              ?? 0;
  const cumSilver        = cumSummary?.silver_count             ?? cumSummary?.silverCount            ?? 0;
  const cumBronze        = cumSummary?.bronze_count             ?? cumSummary?.bronzeCount            ?? 0;

  const accuracyColor = Number(avgAccuracyVal) >= 70 ? '#10b981' : '#ef4444';

  return (
    <div className="admin-layout">
      <AdminNav />
      <main className="admin-main" style={{ maxWidth: '100%' }}>

        {/* ── Page Header ─────────────────────────────────────────────── */}
        <header className="admin-main__header" style={{ alignItems: 'flex-start', flexWrap: 'wrap', gap: 16 }}>
          <div>
            <h1 className="admin-main__title">
              {isTeacher ? 'Classroom & Student Analytics' : 'Global & Class Analytics'}
            </h1>
            <p className="admin-main__subtitle">
              {isTeacher
                ? 'Performance metrics and diagnostic insights for your classroom students'
                : 'Worldwide platform statistics, independent self-paced learners, and classroom diagnostics'}
            </p>
          </div>

          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center' }}>
            {/* Cohort Scope */}
            {!isTeacher && (
              <select
                className="toolbar-select"
                value={selectedSection ? '' : cohortType}
                onChange={e => { setCohortType(e.target.value); setSelectedSection(''); }}
                style={{ minWidth: 175, fontWeight: 600 }}
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
              onChange={e => {
                setSelectedSection(e.target.value);
                if (e.target.value) setCohortType(isTeacher ? 'ENROLLED' : 'ALL');
              }}
              style={{ minWidth: 155 }}
            >
              <option value="">{isTeacher ? 'All My Classes…' : 'Specific Section…'}</option>
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
              <option value="GRADE_4">Grade 4</option>
              <option value="GRADE_5">Grade 5</option>
              <option value="GRADE_6">Grade 6</option>
            </select>

            <select
              className="toolbar-select"
              value={timeRange}
              onChange={e => setTimeRange(e.target.value)}
              style={{ minWidth: 115 }}
            >
              <option value="7d">Last 7 Days</option>
              <option value="30d">Last 30 Days</option>
              <option value="all">All Time</option>
            </select>

            <button
              className="btn btn--ghost btn--sm"
              onClick={() => handleDownloadReport('pdf')}
              disabled={downloadingReport}
              title="Download Class Performance PDF"
            >
              {downloadingReport ? '⏳ PDF' : '📄 PDF'}
            </button>
            <button
              className="btn btn--ghost btn--sm"
              onClick={() => handleDownloadReport('csv')}
              disabled={downloadingReport}
              title="Download Class Performance CSV"
            >
              {downloadingReport ? '⏳ CSV' : '📥 CSV'}
            </button>
          </div>
        </header>

        {/* ── Alerts ──────────────────────────────────────────────────── */}
        {error   && <div className="alert alert--error"   onClick={() => setError('')}>{error}</div>}
        {success && <div className="alert alert--success">{success}</div>}

        {/* ── Active Class Scope Banner ─────────────────────────────────── */}
        {selectedSection && (
          <div style={{
            background: 'linear-gradient(135deg, rgba(37,99,235,0.08), rgba(29,78,216,0.04))',
            border: '1.5px solid rgba(37,99,235,0.3)',
            borderRadius: 'var(--radius-lg)',
            padding: '14px 20px',
            marginBottom: 24,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            flexWrap: 'wrap',
            gap: 12,
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <span style={{ fontSize: '1.4rem' }}>🏫</span>
              <div>
                <div style={{ fontWeight: 800, fontSize: '0.95rem', color: '#1e40af' }}>
                  Filtering by Class: {sections.find(s => s.section_id === selectedSection)?.section_name || 'Selected Class'}
                </div>
                <div style={{ fontSize: '0.8rem', color: '#3b82f6', marginTop: 2 }}>
                  All KPIs, accuracy trends, lesson completions, and student rankings below are isolated strictly to this classroom's performance.
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
                transition: 'all 0.15s ease',
              }}
            >
              ✕ Reset to All Classes
            </button>
          </div>
        )}

        {/* ── Flagged Learners Urgent Banner ── */}
        {flaggedCount > 0 && (
          <div style={{
            background: 'linear-gradient(135deg, #fef2f2 0%, #fee2e2 100%)',
            border: '1.5px solid #fca5a5',
            borderRadius: 'var(--radius-lg)',
            padding: '16px 20px',
            marginBottom: 24,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            boxShadow: '0 4px 12px rgba(239, 68, 68, 0.08)',
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
              <div style={{
                width: 42,
                height: 42,
                borderRadius: '50%',
                background: '#ef4444',
                color: '#fff',
                display: 'grid',
                placeItems: 'center',
                fontSize: '1.2rem',
                fontWeight: 800,
                flexShrink: 0,
              }}>
                🚩
              </div>
              <div>
                <div style={{ fontWeight: 800, color: '#991b1b', fontSize: '1rem' }}>
                  {flaggedCount} Learner{flaggedCount !== 1 ? 's' : ''} {flaggedCount === 1 ? 'Needs' : 'Need'} Immediate Teacher Attention
                </div>
                <div style={{ fontSize: '0.82rem', color: '#b91c1c', marginTop: 2 }}>
                  Students have triggered multiple visual reintroductions or exceeded error limits at the LEARNING tier.
                </div>
              </div>
            </div>
            <a
              href="/learners"
              className="btn btn--sm btn--danger"
              style={{ fontWeight: 700, whiteSpace: 'nowrap', textDecoration: 'none' }}
            >
              Review Flagged Students ➔
            </a>
          </div>
        )}

        {/* ── Loading / Content ────────────────────────────────────────── */}
        {loading ? (
          <div className="auth-loading" style={{ minHeight: 380 }}><div className="spinner" /></div>
        ) : analytics ? (
          <div>

            {/* KPI Cards */}
            <div className="kpi-grid">
              <GradientKpiCard
                title="Active Students"
                value={activeCount}
                subtitle={`${totalCount} total ${cohortType === 'INDEPENDENT' ? 'self-paced' : 'enrolled'}`}
                icon="👥"
                trend={timeRange === '7d' ? '7-day window' : timeRange === '30d' ? '30-day window' : 'All-time window'}
                trendDir="neutral"
                gradient="linear-gradient(135deg, #3b82f6, #1d4ed8)"
                blob="rgba(59,130,246,0.07)"
                color="#3b82f6"
                glow="rgba(59,130,246,0.28)"
              />
              <GradientKpiCard
                title="Average Accuracy"
                value={`${Number(avgAccuracyVal).toFixed(1)}%`}
                subtitle="Across practice sessions"
                icon="🎯"
                trend={Number(avgAccuracyVal) >= 70 ? 'On target' : 'Needs attention'}
                trendDir={Number(avgAccuracyVal) >= 70 ? 'up' : 'down'}
                gradient={Number(avgAccuracyVal) >= 70
                  ? 'linear-gradient(135deg, #10b981, #059669)'
                  : 'linear-gradient(135deg, #ef4444, #dc2626)'}
                blob={Number(avgAccuracyVal) >= 70 ? 'rgba(16,185,129,0.07)' : 'rgba(239,68,68,0.07)'}
                color={accuracyColor}
                glow={Number(avgAccuracyVal) >= 70 ? 'rgba(16,185,129,0.28)' : 'rgba(239,68,68,0.28)'}
              />
              <GradientKpiCard
                title="Lessons Completed"
                value={completionsCount}
                subtitle={timeRange === 'all' ? 'All-time milestones' : 'Milestones in period'}
                icon="🏆"
                trend={timeRange === '7d' ? 'Last 7 days' : timeRange === '30d' ? 'Last 30 days' : 'All-time'}
                trendDir="neutral"
                gradient="linear-gradient(135deg, #2563eb, #60a5fa)"
                blob="rgba(37,99,235,0.07)"
                color="#2563eb"
                glow="rgba(37,99,235,0.28)"
              />
              <GradientKpiCard
                title="Words Mastered"
                value={wordsMasteredCount}
                subtitle="Mastery tier reached"
                icon="🌟"
                trend="Mastered"
                trendDir="up"
                gradient="linear-gradient(135deg, #f59e0b, #d97706)"
                blob="rgba(245,158,11,0.07)"
                color="#d97706"
                glow="rgba(245,158,11,0.28)"
              />
              <GradientKpiCard
                title="Avg Session"
                value={`${Math.round(Number(avgSessionSec) / 60)} min`}
                subtitle="Per practice session"
                icon="⏱️"
                trend="Per session"
                trendDir="neutral"
                gradient="linear-gradient(135deg, #0284c7, #0369a1)"
                blob="rgba(2,132,199,0.07)"
                color="#0284c7"
                glow="rgba(2,132,199,0.28)"
              />
            </div>

            {/* Trend Charts */}
            <div style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(380px, 1fr))',
              gap: 20,
              marginBottom: 28,
            }}>
              <div className="chart-card">
                <div className="chart-card__header">
                  <div>
                    <div className="chart-card__title">
                      <svg width="16" height="16" fill="none" viewBox="0 0 24 24" stroke="#2563eb" strokeWidth="2.2" strokeLinecap="round">
                        <polyline points="22 12 18 12 15 21 9 3 6 12 2 12" />
                      </svg>
                      Cohort Accuracy Trend
                    </div>
                    <div className="chart-card__subtitle">Daily average accuracy over time</div>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <span className="chart-card__period">{timeRange === '7d' ? 'Last 7 Days' : timeRange === '30d' ? 'Last 30 Days' : 'All Time'}</span>
                    <button
                      type="button"
                      onClick={() => setExpandedChart({
                        title: 'Cohort Accuracy Trend',
                        subtitle: 'Daily average accuracy over time',
                        label: 'Daily Average Accuracy',
                        data: accuracyTrendsData,
                        color: '#2563eb',
                        unit: '%',
                      })}
                      style={{
                        display: 'inline-flex',
                        alignItems: 'center',
                        gap: 5,
                        padding: '4px 10px',
                        borderRadius: 8,
                        fontSize: '0.74rem',
                        fontWeight: 700,
                        color: '#2563eb',
                        background: 'rgba(37,99,235,0.08)',
                        border: '1px solid rgba(37,99,235,0.25)',
                        cursor: 'pointer',
                      }}
                      title="Open full view modal"
                    >
                      <svg width="11" height="11" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2.4">
                        <path d="M15 3h6v6M9 21H3v-6M21 3l-7 7M3 21l7-7" />
                      </svg>
                      Expand
                    </button>
                  </div>
                </div>
                <AreaLineChart
                  data={accuracyTrendsData}
                  label="Daily Average Accuracy"
                  color="#2563eb"
                  gradientId="accuracy-area"
                  unit="%"
                  onExpand={() => setExpandedChart({
                    title: 'Cohort Accuracy Trend',
                    subtitle: 'Daily average accuracy over time',
                    label: 'Daily Average Accuracy',
                    data: accuracyTrendsData,
                    color: '#2563eb',
                    unit: '%',
                  })}
                />
              </div>

              <div className="chart-card">
                <div className="chart-card__header">
                  <div>
                    <div className="chart-card__title">
                      <svg width="16" height="16" fill="none" viewBox="0 0 24 24" stroke="#06b6d4" strokeWidth="2.2" strokeLinecap="round">
                        <polyline points="22 12 18 12 15 21 9 3 6 12 2 12" />
                      </svg>
                      Daily Lesson Completions
                    </div>
                    <div className="chart-card__subtitle">Completed lessons per day</div>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <span className="chart-card__period">{timeRange === '7d' ? 'Last 7 Days' : timeRange === '30d' ? 'Last 30 Days' : 'All Time'}</span>
                    <button
                      type="button"
                      onClick={() => setExpandedChart({
                        title: 'Daily Lesson Completions',
                        subtitle: 'Completed lessons per day',
                        label: 'Completed Lessons',
                        data: completionTrendsData,
                        color: '#06b6d4',
                        unit: '',
                      })}
                      style={{
                        display: 'inline-flex',
                        alignItems: 'center',
                        gap: 5,
                        padding: '4px 10px',
                        borderRadius: 8,
                        fontSize: '0.74rem',
                        fontWeight: 700,
                        color: '#06b6d4',
                        background: '#06b6d414',
                        border: '1px solid #06b6d430',
                        cursor: 'pointer',
                      }}
                      title="Open full view modal"
                    >
                      <svg width="11" height="11" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2.4">
                        <path d="M15 3h6v6M9 21H3v-6M21 3l-7 7M3 21l7-7" />
                      </svg>
                      Expand
                    </button>
                  </div>
                </div>
                <AreaLineChart
                  data={completionTrendsData}
                  label="Completed Lessons"
                  color="#06b6d4"
                  gradientId="completion-area"
                  unit=""
                  onExpand={() => setExpandedChart({
                    title: 'Daily Lesson Completions',
                    subtitle: 'Completed lessons per day',
                    label: 'Completed Lessons',
                    data: completionTrendsData,
                    color: '#06b6d4',
                    unit: '',
                  })}
                />
              </div>
            </div>

            {/* Struggling Students */}
            <div className="section-card" style={{ marginBottom: 28 }}>
              <div className="section-card__header">
                <div>
                  <div className="section-card__title">
                    <span style={{
                      display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
                      width: 28, height: 28, borderRadius: 8,
                      background: 'var(--color-danger-bg)',
                      border: '1px solid var(--color-danger-border)',
                      fontSize: '0.85rem', marginRight: 4,
                    }}>⚠️</span>
                    Students Needing Support
                    <span style={{
                      fontSize: '0.72rem', fontWeight: 700,
                      background: 'var(--color-danger-bg)', color: 'var(--color-danger)',
                      border: '1px solid var(--color-danger-border)',
                      padding: '2px 8px', borderRadius: 20, marginLeft: 8,
                    }}>
                      {strugglingList.length} flagged
                    </span>
                  </div>
                  <div className="section-card__subtitle">
                    Flagged by multi-signal heuristics: accuracy &lt; 70%, high demerits (≥ 50), or frequent tier drops.
                  </div>
                </div>
              </div>

              <div className="accounts-table-wrap" style={{ marginBottom: 0 }}>
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
                        <td colSpan={7} style={{ textAlign: 'center', padding: 32 }}>
                          <span style={{
                            display: 'inline-flex', alignItems: 'center', gap: 8,
                            color: 'var(--color-success)', fontSize: '0.9rem', fontWeight: 600,
                          }}>
                            🎉 Excellent! No struggling learners flagged in this cohort.
                          </span>
                        </td>
                      </tr>
                    )}
                    {strugglingList.map(sl => {
                      const lid     = sl.learner_id  || sl.learnerId;
                      const dName   = sl.display_name || sl.displayName;
                      const sName   = sl.section_name || sl.sectionName;
                      const acc     = sl.overall_accuracy ?? sl.overallAccuracy ?? 0;
                      const demerits = sl.demerit_points ?? sl.demeritPoints ?? 0;
                      const drops   = sl.tier_drop_count ?? sl.tierDropsCount ?? 0;
                      const reasons = sl.reasons || [];

                      return (
                        <tr key={lid}>
                          <td>
                            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                              <div style={{
                                width: 32, height: 32, borderRadius: '50%',
                                background: 'linear-gradient(135deg, #ef4444, #dc2626)',
                                display: 'grid', placeItems: 'center',
                                color: '#fff', fontSize: '0.78rem', fontWeight: 700, flexShrink: 0,
                              }}>
                                {dName?.charAt(0)?.toUpperCase() || '?'}
                              </div>
                              <strong style={{ fontSize: '0.875rem', color: 'var(--color-text)' }}>{dName}</strong>
                            </div>
                          </td>
                          <td>
                            {sName ? (
                              <span className="text-muted">{sName}</span>
                            ) : (
                              <span className="status-pill status-pill--neutral">Self-Paced</span>
                            )}
                          </td>
                          <td>
                            <span style={{
                              fontWeight: 700, fontSize: '0.9rem',
                              color: Number(acc) >= 70 ? 'var(--color-success)' : 'var(--color-danger)',
                            }}>
                              {Number(acc).toFixed(1)}%
                            </span>
                          </td>
                          <td>
                            <span style={{
                              fontWeight: 700,
                              color: demerits > 0 ? 'var(--color-danger)' : 'var(--color-text-muted)',
                            }}>
                              {demerits}
                            </span>
                          </td>
                          <td style={{ color: drops > 0 ? 'var(--color-warning)' : 'var(--color-text-muted)', fontWeight: drops > 0 ? 700 : 400 }}>
                            {drops}
                          </td>
                          <td>
                            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4 }}>
                              {reasons.map((r, i) => (
                                <span key={i} style={{
                                  fontSize: '0.7rem',
                                  background: 'var(--color-danger-bg)',
                                  color: 'var(--color-danger)',
                                  border: '1px solid var(--color-danger-border)',
                                  padding: '2px 8px',
                                  borderRadius: 20,
                                  fontWeight: 600,
                                }}>
                                  {r}
                                </span>
                              ))}
                            </div>
                          </td>
                          <td className="actions-cell">
                            <button className="btn btn--sm btn--ghost" onClick={() => setDetailLearnerId(lid)}>
                              🔍 Diagnostic
                            </button>
                            <button className="btn btn--sm btn--danger-ghost" onClick={() => setResetTarget(sl)}>
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

            {/* Part of Speech (POS) Mastery Breakdown Widget */}
            {posBreakdown.length > 0 && (
              <div className="section-card" style={{ marginBottom: 24 }}>
                <div className="section-card__header">
                  <div>
                    <div className="section-card__title">🏷️ Part of Speech (POS) Mastery &amp; Accuracy Breakdown</div>
                    <div className="section-card__subtitle">
                      Diagnostic accuracy and attempt volumes segmented by syntactic categories (Nouns, Verbs, Adjectives, etc.).
                    </div>
                  </div>
                </div>
                <div style={{
                  display: 'grid',
                  gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
                  gap: 14,
                  padding: '4px 0',
                }}>
                  {posBreakdown.map((item, idx) => {
                    const posName = item.part_of_speech || item.partOfSpeech || 'OTHER';
                    const acc = Number(item.accuracy ?? 0);
                    const wordsCount = item.total_words ?? item.totalWords ?? 0;
                    const attempts = item.total_attempts ?? item.totalAttempts ?? 0;
                    const correct = item.correct_count ?? item.correctCount ?? 0;
                    const color = acc >= 85 ? '#10b981' : acc >= 70 ? '#3b82f6' : acc >= 50 ? '#f59e0b' : '#ef4444';

                    return (
                      <div
                        key={idx}
                        style={{
                          background: 'var(--color-surface)',
                          border: '1px solid var(--color-border)',
                          borderRadius: 'var(--radius-md, 12px)',
                          padding: '14px 16px',
                          display: 'flex',
                          flexDirection: 'column',
                          gap: 8,
                          boxShadow: '0 2px 6px rgba(0,0,0,0.02)',
                        }}
                      >
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                          <span style={{
                            fontSize: '0.82rem',
                            fontWeight: 800,
                            letterSpacing: '0.04em',
                            textTransform: 'uppercase',
                            color: 'var(--color-text-main)',
                          }}>
                            {posName}
                          </span>
                          <span style={{
                            fontSize: '0.92rem',
                            fontWeight: 800,
                            color: color,
                          }}>
                            {acc.toFixed(1)}%
                          </span>
                        </div>

                        {/* Progress Bar */}
                        <div style={{
                          height: 6,
                          width: '100%',
                          background: 'var(--color-surface-2, #e2e8f0)',
                          borderRadius: 3,
                          overflow: 'hidden',
                        }}>
                          <div style={{
                            height: '100%',
                            width: `${Math.min(100, Math.max(0, acc))}%`,
                            background: color,
                            borderRadius: 3,
                            transition: 'width 0.4s ease',
                          }} />
                        </div>

                        <div style={{
                          display: 'flex',
                          justifyContent: 'space-between',
                          fontSize: '0.72rem',
                          color: 'var(--color-text-muted)',
                        }}>
                          <span>{wordsCount} word{wordsCount !== 1 ? 's' : ''}</span>
                          <span>{correct}/{attempts} correct</span>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            )}

            {/* Curriculum Lesson Performance & Average Accuracy Card */}
            <div className="section-card" style={{ marginBottom: 24 }}>
              <div className="section-card__header">
                <div>
                  <div className="section-card__title">
                    📖 Curriculum Lesson Performance &amp; Average Accuracy
                    <span style={{
                      fontSize: '0.72rem', fontWeight: 600,
                      background: 'rgba(37,99,235,0.09)', color: 'var(--primary-mid)',
                      border: '1px solid rgba(37,99,235,0.20)',
                      padding: '2px 8px', borderRadius: 20, marginLeft: 8,
                    }}>
                      {lessonPassRates.length} lesson{lessonPassRates.length !== 1 ? 's' : ''}
                    </span>
                  </div>
                  <div className="section-card__subtitle">
                    Per-lesson diagnostic accuracy and student completion rates within the active cohort or classroom scope.
                  </div>
                </div>
              </div>

              <div className="accounts-table-wrap" style={{ marginBottom: 0 }}>
                <table className="accounts-table">
                  <thead>
                    <tr>
                      <th>Lesson Title</th>
                      <th>Scope</th>
                      <th>Grade</th>
                      <th>Average Accuracy</th>
                      <th>Class Completion Rate</th>
                      <th>Total Completed</th>
                    </tr>
                  </thead>
                  <tbody>
                    {lessonPassRates.length === 0 && (
                      <tr>
                        <td colSpan={6} style={{ textAlign: 'center', color: 'var(--color-text-muted)', padding: 24 }}>
                          No curriculum lessons found for this cohort or classroom.
                        </td>
                      </tr>
                    )}
                    {lessonPassRates.map(lpr => {
                      const lid = lpr.lesson_id || lpr.lessonId;
                      const title = lpr.lesson_title || lpr.lessonTitle;
                      const grade = lpr.grade_level || lpr.gradeLevel || '—';
                      const acc = Number(lpr.avg_score ?? lpr.avgScore ?? 0);
                      const compRate = Number(lpr.completion_rate ?? lpr.completionRate ?? 0);
                      const totalComp = lpr.total_completions ?? lpr.totalCompletions ?? 0;
                      const isClass = Boolean(lpr.is_class_lesson ?? lpr.isClassLesson ?? lpr.class_id ?? lpr.classId);
                      const className = lpr.class_name || lpr.className;

                      const accColor = acc >= 85 ? 'var(--color-success, #10b981)' : acc >= 70 ? 'var(--primary-mid, #3b82f6)' : acc >= 50 ? 'var(--color-warning, #f59e0b)' : 'var(--color-danger, #ef4444)';

                      return (
                        <tr key={lid}>
                          <td>
                            <strong style={{ color: 'var(--color-text)', fontSize: '0.875rem' }}>{title}</strong>
                          </td>
                          <td>
                            {isClass ? (
                              <span style={{
                                fontSize: '0.72rem', fontWeight: 700, padding: '2px 8px',
                                borderRadius: 12, background: 'rgba(59, 130, 246, 0.12)', color: '#2563eb',
                                border: '1px solid rgba(59, 130, 246, 0.25)',
                              }}>
                                🏫 Class: {className || 'Assigned'}
                              </span>
                            ) : (
                              <span style={{
                                fontSize: '0.72rem', fontWeight: 700, padding: '2px 8px',
                                borderRadius: 12, background: 'rgba(16, 185, 129, 0.12)', color: '#059669',
                                border: '1px solid rgba(16, 185, 129, 0.25)',
                              }}>
                                🌍 Standard Curriculum
                              </span>
                            )}
                          </td>
                          <td>
                            <span className="text-muted" style={{ fontSize: '0.82rem' }}>
                              {grade ? grade.replace('_', ' ') : '—'}
                            </span>
                          </td>
                          <td>
                            <span style={{
                              fontWeight: 800, fontSize: '0.88rem',
                              color: accColor,
                              background: `${accColor}15`,
                              padding: '2px 8px',
                              borderRadius: 12,
                              border: `1px solid ${accColor}35`,
                            }}>
                              {acc.toFixed(1)}%
                            </span>
                          </td>
                          <td>
                            <div style={{ display: 'flex', alignItems: 'center', gap: 8, minWidth: 140 }}>
                              <div style={{
                                flex: 1, height: 6, background: 'var(--color-surface-2, #e2e8f0)',
                                borderRadius: 3, overflow: 'hidden'
                              }}>
                                <div style={{
                                  width: `${Math.min(100, Math.max(0, compRate))}%`,
                                  height: '100%',
                                  background: compRate >= 80 ? '#10b981' : compRate >= 50 ? '#3b82f6' : '#f59e0b',
                                  borderRadius: 3,
                                }} />
                              </div>
                              <span style={{ fontSize: '0.78rem', fontWeight: 700, minWidth: 38 }}>
                                {compRate.toFixed(0)}%
                              </span>
                            </div>
                          </td>
                          <td>
                            <span style={{ fontWeight: 600, fontSize: '0.85rem' }}>
                              {totalComp} {totalComp === 1 ? 'learner' : 'learners'}
                            </span>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </div>

            {/* Curriculum Analytics Grid */}
            <div style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(420px, 1fr))',
              gap: 20,
              marginBottom: 28,
            }}>
              {/* Hardest Words */}
              <div className="section-card" style={{ marginBottom: 0 }}>
                <div className="section-card__header">
                  <div>
                    <div className="section-card__title">📘 Words Needing Curriculum Attention</div>
                    <div className="section-card__subtitle">
                      Class-wide difficulty &amp; content optimization signals — helps refine example sentences or verify visual/audio assets.
                    </div>
                  </div>
                </div>
                <div className="accounts-table-wrap" style={{ marginBottom: 0 }}>
                  <table className="accounts-table">
                    <thead>
                      <tr>
                        <th>Vocabulary Word</th>
                        <th>Lesson</th>
                        <th>Struggle Rate</th>
                        <th>Demerits</th>
                        <th>Accuracy</th>
                        <th>Curriculum Action</th>
                      </tr>
                    </thead>
                    <tbody>
                      {hardestWords.length === 0 && (
                        <tr><td colSpan={6} style={{ textAlign: 'center', color: 'var(--color-text-muted)', padding: 24 }}>No curriculum attention items flagged</td></tr>
                      )}
                      {hardestWords.map(w => {
                        const wid            = w.word_id || w.wordId;
                        const eng            = w.english_word || w.englishWord;
                        const ceb            = w.cebuano_meaning || w.cebuanoMeaning;
                        const les            = w.lesson_title || w.lessonTitle;
                        const acc            = w.avg_accuracy ?? w.accuracy ?? 0;
                        const totalDem       = w.total_demerits ?? w.avg_demerits ?? w.demeritPoints ?? 0;
                        const strugglePct    = w.struggle_percentage ?? 0;
                        const strugglingCount = w.struggling_learner_count ?? w.strugglingLearnerCount;
                        const rawRec         = w.curriculum_recommendation || w.curriculumRecommendation;
                        const recommendation = rawRec || (Number(acc) < 70 ? 'Review Example Sentence & Context' : (Number(acc) < 85 ? 'Review Distractor Choices' : 'Content Verified (Normal)'));

                        const isSevere  = recommendation.includes('Review Example') || Number(acc) < 70;
                        const isWarning = recommendation.includes('Distractor') || recommendation.includes('Verify') || (Number(acc) >= 70 && Number(acc) < 85);
                        const isNormal  = !isSevere && !isWarning;

                        const badgeClass = isSevere ? 'rec-badge--severe' : isWarning ? 'rec-badge--warning' : 'rec-badge--ok';

                        return (
                          <tr key={wid}>
                            <td>
                              <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                                <strong style={{ color: 'var(--color-text)', fontSize: '0.875rem' }}>{eng}</strong>
                                {w.part_of_speech && (
                                  <span style={{
                                    fontSize: '0.68rem', fontWeight: 800, padding: '1px 6px',
                                    borderRadius: 6, background: '#f1f5f9', color: '#475569',
                                    border: '1px solid #cbd5e1',
                                  }}>
                                    {w.part_of_speech}
                                  </span>
                                )}
                              </div>
                              <div style={{ fontSize: '0.77rem', color: 'var(--color-text-muted)', fontStyle: 'italic', marginTop: 2 }}>{ceb}</div>
                            </td>
                            <td className="text-muted">{les}</td>
                            <td>
                              <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                                <span style={{
                                  fontWeight: 700,
                                  color: isSevere ? 'var(--color-danger)' : isWarning ? 'var(--color-warning)' : 'var(--color-text-main)',
                                  fontSize: '0.875rem',
                                }}>
                                  {Number(strugglePct).toFixed(1)}%
                                </span>
                                {strugglingCount != null && (
                                  <span style={{ fontSize: '0.73rem', color: 'var(--color-text-muted)' }}>
                                    ({strugglingCount} learner{strugglingCount === 1 ? '' : 's'})
                                  </span>
                                )}
                              </div>
                            </td>
                            <td>
                              <span style={{
                                fontWeight: totalDem > 0 ? 700 : 400,
                                color: totalDem >= 20 ? 'var(--color-danger)' : totalDem > 0 ? 'var(--color-warning)' : 'var(--color-text-muted)',
                              }}>
                                {totalDem} pts
                              </span>
                            </td>
                            <td>
                              <span style={{
                                fontWeight: 700, fontSize: '0.9rem',
                                color: Number(acc) < 70 ? 'var(--color-danger)' : Number(acc) < 85 ? 'var(--color-warning)' : 'var(--color-success)',
                              }}>
                                {Number(acc).toFixed(1)}%
                              </span>
                            </td>
                            <td>
                              <span className={`rec-badge ${badgeClass}`}>{recommendation}</span>
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              </div>

              {/* Fallback Frequency */}
              <div className="section-card" style={{ marginBottom: 0 }}>
                <div className="section-card__header">
                  <div>
                    <div className="section-card__title">🔄 Module 4 Asset Fallback Frequency</div>
                    <div className="section-card__subtitle">Words triggering image/audio fallback — may indicate missing or broken assets.</div>
                  </div>
                </div>
                <div className="accounts-table-wrap" style={{ marginBottom: 0 }}>
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
                        <tr><td colSpan={4} style={{ textAlign: 'center', color: 'var(--color-text-muted)', padding: 24 }}>No fallbacks triggered</td></tr>
                      )}
                      {fallbackWords.map(fw => {
                        const wid = fw.word_id || fw.wordId;
                        const eng = fw.english_word || fw.englishWord;
                        const les = fw.lesson_title || fw.lessonTitle;
                        const cnt = fw.fallback_count ?? fw.fallbackCount ?? 0;
                        const acc = fw.avg_accuracy ?? fw.accuracy ?? 0;
                        return (
                          <tr key={wid}>
                            <td><strong style={{ color: 'var(--color-text)' }}>{eng}</strong></td>
                            <td className="text-muted">{les}</td>
                            <td>
                              <span style={{
                                fontWeight: 700,
                                color: cnt > 2 ? 'var(--color-danger)' : cnt > 0 ? 'var(--color-warning)' : 'var(--color-text-muted)',
                              }}>
                                {cnt} {cnt === 1 ? 'time' : 'times'}
                              </span>
                            </td>
                            <td>
                              <span style={{
                                color: Number(acc) < 70 ? 'var(--color-danger)' : 'var(--color-text-muted)',
                                fontWeight: Number(acc) < 70 ? 700 : 400,
                              }}>
                                {Number(acc).toFixed(1)}%
                              </span>
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>

            {/* Cumulative Review & Retention (Admin Global Only) */}
            {!isTeacher && (
              <div className="section-card">
                <div className="section-card__header">
                  <div>
                    <div className="section-card__title">
                      🌟 Cumulative Review &amp; Retention Mastery
                      <span style={{
                        fontSize: '0.72rem', fontWeight: 600,
                        background: 'rgba(37,99,235,0.09)', color: 'var(--primary-mid)',
                        border: '1px solid rgba(37,99,235,0.20)',
                        padding: '2px 8px', borderRadius: 20, marginLeft: 8,
                      }}>
                        {cumTotalSessions} sessions completed
                      </span>
                    </div>
                    <div className="section-card__subtitle">
                      Cross-lesson spaced repetition outcomes measuring vocabulary retention across lesson pairs and curriculum themes.
                    </div>
                  </div>
                </div>

                <div style={{
                  display: 'grid',
                  gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
                  gap: 14,
                }}>
                  <div className="retention-mini-card retention-mini-card--blue-soft">
                    <div className="retention-mini-card__label">Cohort Retention Accuracy</div>
                    <div className="retention-mini-card__value" style={{
                      color: (cumTotalSessions > 0 && cumAvgRetention != null)
                        ? (Number(cumAvgRetention) >= 70 ? 'var(--color-success)' : 'var(--primary-mid)')
                        : 'var(--color-text-dim)',
                    }}>
                      {(cumTotalSessions > 0 && cumAvgRetention != null) ? `${Number(cumAvgRetention).toFixed(1)}%` : '—'}
                    </div>
                    <div className="retention-mini-card__sub">
                      {(cumTotalSessions > 0 && cumAvgRetention != null)
                        ? 'Average across completed pair reviews'
                        : 'Not yet attempted in mobile'}
                    </div>
                  </div>

                  <div className="retention-mini-card retention-mini-card--gold">
                    <div className="retention-mini-card__label">🏆 Perfect Gold Badges</div>
                    <div className="retention-mini-card__value" style={{ color: cumTotalSessions > 0 ? '#d97706' : 'var(--color-text-dim)' }}>
                      {cumTotalSessions > 0 ? cumPerfectGold : '—'}
                    </div>
                    <div className="retention-mini-card__sub">100% flawless cumulative score</div>
                  </div>

                  <div className="retention-mini-card retention-mini-card--blue">
                    <div className="retention-mini-card__label">🥇 Gold &amp; 🥈 Silver Badges</div>
                    <div className="retention-mini-card__value" style={{ color: '#2563eb' }}>{cumGold + cumSilver}</div>
                    <div className="retention-mini-card__sub">{cumGold} Gold (90%+) · {cumSilver} Silver (80%+)</div>
                  </div>

                  <div className="retention-mini-card retention-mini-card--bronze">
                    <div className="retention-mini-card__label">🥉 Bronze Badges</div>
                    <div className="retention-mini-card__value" style={{ color: '#b45309' }}>{cumBronze}</div>
                    <div className="retention-mini-card__sub">70%+ passing retention score</div>
                  </div>
                </div>
              </div>
            )}

          </div>
        ) : null}

        {/* Modals */}
        {detailLearnerId && (
          <LearnerDetailModal
            learnerId={detailLearnerId}
            classContext={selectedSection ? {
              classId: selectedSection,
              className: sections.find(s => s.section_id === selectedSection)?.section_name,
            } : null}
            onClose={() => setDetailLearnerId(null)}
            onResetProgress={(l) => { setDetailLearnerId(null); setResetTarget(l); }}
            onEditProfile={() => { setDetailLearnerId(null); }}
          />
        )}

        {resetTarget && (
          <ResetProgressModal
            learner={resetTarget}
            onClose={() => setResetTarget(null)}
            onConfirm={handleConfirmReset}
            loading={resetLoading}
          />
        )}

        {expandedChart && (
          <ChartDetailModal
            chart={expandedChart}
            onClose={() => setExpandedChart(null)}
          />
        )}
      </main>
    </div>
  );
}
