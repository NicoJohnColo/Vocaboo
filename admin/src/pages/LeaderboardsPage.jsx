import { useState, useEffect, useCallback } from 'react';
import AdminNav from '../components/AdminNav';
import { AnalyticsService } from '../services/AnalyticsService';
import { SectionService } from '../services/SectionService';
import LearnerDetailModal from '../components/LearnerDetailModal';
import { useAdminAuth } from '../hooks/useAdminAuth';

function RankBadge({ rank }) {
  if (rank === 1) {
    return <span style={{ fontSize: '1.25rem', filter: 'drop-shadow(0 2px 4px rgba(234, 179, 8, 0.4))' }}>🥇</span>;
  }
  if (rank === 2) {
    return <span style={{ fontSize: '1.25rem', filter: 'drop-shadow(0 2px 4px rgba(148, 163, 184, 0.4))' }}>🥈</span>;
  }
  if (rank === 3) {
    return <span style={{ fontSize: '1.25rem', filter: 'drop-shadow(0 2px 4px rgba(180, 83, 9, 0.4))' }}>🥉</span>;
  }
  return <span style={{ fontWeight: 800, color: 'var(--color-text-dim)', fontSize: '0.95rem' }}>#{rank}</span>;
}

export default function LeaderboardsPage() {
  const { admin } = useAdminAuth();
  const isTeacher = admin?.role?.toLowerCase() === 'teacher' || admin?.role?.toUpperCase() === 'ROLE_TEACHER';

  const [range, setRange] = useState('weekly'); // 'weekly' | 'all_time'
  const [cohortType, setCohortType] = useState(isTeacher ? 'ENROLLED' : 'ALL'); // 'ALL' | 'INDEPENDENT' | 'ENROLLED'
  const [selectedSection, setSelectedSection] = useState('');
  const [sections, setSections] = useState([]);

  useEffect(() => {
    if (isTeacher) {
      setCohortType('ENROLLED');
    }
  }, [isTeacher]);
  
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [detailLearnerId, setDetailLearnerId] = useState(null);

  const loadData = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const [res, secList] = await Promise.all([
        AnalyticsService.getLeaderboardStats({
          range,
          cohortType: selectedSection ? undefined : cohortType,
          sectionId: selectedSection || undefined,
        }),
        SectionService.getAllSections().catch(() => []),
      ]);
      setData(res);
      setSections(secList);
    } catch (err) {
      setError(err?.message || 'Failed to load leaderboard statistics.');
    } finally {
      setLoading(false);
    }
  }, [range, cohortType, selectedSection]);

  useEffect(() => { loadData(); }, [loadData]);

  const top3 = data?.leaderboard ? data.leaderboard.slice(0, 3) : [];

  return (
    <div className="admin-layout">
      <AdminNav />
      <main className="admin-main" style={{ maxWidth: '100%' }}>
        <header className="admin-main__header" style={{ alignItems: 'flex-start', flexWrap: 'wrap', gap: 16 }}>
          <div>
            <h1 className="admin-main__title">
              {isTeacher ? '🏆 Classroom Leaderboard' : '🏆 Leaderboard'}
            </h1>
            <p className="admin-main__subtitle">
              {isTeacher
                ? 'Track top student rankings and points across your classroom cohorts'
                : 'Track point rankings, mastery tiers, and student performance'}
            </p>
          </div>

          <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
            <div style={{
              display: 'flex',
              background: 'var(--color-surface)',
              borderRadius: 'var(--radius-md)',
              padding: 4,
              border: '1.5px solid var(--color-border)',
              boxShadow: 'var(--shadow-xs)',
            }}>
              <button
                style={{
                  padding: '7px 16px', borderRadius: 8, border: 'none', cursor: 'pointer',
                  fontWeight: 700, fontSize: '0.845rem', fontFamily: 'inherit',
                  background: range === 'weekly'
                    ? 'linear-gradient(135deg, #3b82f6, #1d4ed8)'
                    : 'transparent',
                  color: range === 'weekly' ? '#fff' : 'var(--color-text-muted)',
                  transition: 'all 0.18s',
                  boxShadow: range === 'weekly' ? '0 2px 8px rgba(37,99,235,0.30)' : 'none',
                }}
                onClick={() => setRange('weekly')}
              >
                ⚡ This Week
              </button>
              <button
                style={{
                  padding: '7px 16px', borderRadius: 8, border: 'none', cursor: 'pointer',
                  fontWeight: 700, fontSize: '0.845rem', fontFamily: 'inherit',
                  background: range === 'all_time'
                    ? 'linear-gradient(135deg, #3b82f6, #1d4ed8)'
                    : 'transparent',
                  color: range === 'all_time' ? '#fff' : 'var(--color-text-muted)',
                  transition: 'all 0.18s',
                  boxShadow: range === 'all_time' ? '0 2px 8px rgba(37,99,235,0.30)' : 'none',
                }}
                onClick={() => setRange('all_time')}
              >
                🌟 All-Time
              </button>
            </div>

            {/* Cohort Selector */}
            {!isTeacher && (
              <select
                className="toolbar-select"
                value={selectedSection ? '' : cohortType}
                onChange={e => {
                  setCohortType(e.target.value);
                  setSelectedSection('');
                }}
                style={{ minWidth: 170 }}
              >
                <option value="ALL">🌍 Global (All Users)</option>
                <option value="INDEPENDENT">👤 Independent / Self-Paced</option>
                <option value="ENROLLED">🏫 Enrolled in Classes</option>
              </select>
            )}

            {/* Class Section Selector */}
            <select
              className="toolbar-select"
              value={selectedSection}
              onChange={e => {
                setSelectedSection(e.target.value);
                if (e.target.value) setCohortType(isTeacher ? 'ENROLLED' : 'ALL');
              }}
              style={{ minWidth: 160 }}
            >
              <option value="">{isTeacher ? '🌟 All My Classes' : (cohortType === 'INDEPENDENT' ? 'Classes N/A (Self-Paced)' : '🌐 All Classrooms')}</option>
              {sections.map(s => {
                const sId = s.section_id || s.sectionId;
                const sName = s.section_name || s.sectionName;
                return (
                  <option key={sId} value={sId}>{sName}</option>
                );
              })}
            </select>
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
              <span style={{ fontSize: '1.4rem' }}>🏆</span>
              <div>
                <div style={{ fontWeight: 800, fontSize: '0.95rem', color: '#1e40af' }}>
                  Leaderboard Filtered by: {sections.find(s => (s.section_id || s.sectionId) === selectedSection)?.section_name || sections.find(s => (s.section_id || s.sectionId) === selectedSection)?.sectionName || 'Selected Class'}
                </div>
                <div style={{ fontSize: '0.8rem', color: '#3b82f6', marginTop: 2 }}>
                  Showing class-scoped point totals, class accuracy rates, and rankings for students in this classroom.
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
              ✕ {isTeacher ? 'Reset to All My Classes' : 'Reset to Global View'}
            </button>
          </div>
        )}

        {loading ? (
          <div className="auth-loading" style={{ minHeight: 350 }}><div className="spinner" /></div>
        ) : data ? (
          <div>
            {/* Gamification Summary KPIs */}
            <div className="kpi-grid" style={{ gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))' }}>
              <div className="kpi-card" style={{
                '--kpi-gradient': 'linear-gradient(135deg, #3b82f6, #1d4ed8)',
                '--kpi-blob': 'rgba(59,130,246,0.07)', '--kpi-color': '#3b82f6', '--kpi-glow': 'rgba(59,130,246,0.28)'
              }}>
                <div className="kpi-card__header">
                  <span className="kpi-card__label">Total Points Earned</span>
                  <div className="kpi-card__icon-bubble">⭐</div>
                </div>
                <div className="kpi-card__value">{data.gamification_summary?.total_points_awarded?.toLocaleString() ?? 0}</div>
                <div className="kpi-card__footer">
                  <span className="kpi-card__subtitle">Avg {data.gamification_summary?.average_points_per_active_learner ?? 0} pts/student</span>
                </div>
              </div>

              <div className="kpi-card" style={{
                '--kpi-gradient': 'linear-gradient(135deg, #06b6d4, #0891b2)',
                '--kpi-blob': 'rgba(6,182,212,0.07)', '--kpi-color': '#0891b2', '--kpi-glow': 'rgba(6,182,212,0.28)'
              }}>
                <div className="kpi-card__header">
                  <span className="kpi-card__label">Practice Sessions</span>
                  <div className="kpi-card__icon-bubble">🎮</div>
                </div>
                <div className="kpi-card__value">{data.gamification_summary?.total_sessions_played?.toLocaleString() ?? 0}</div>
                <div className="kpi-card__footer">
                  <span className="kpi-card__subtitle">Total practice runs logged</span>
                </div>
              </div>

              <div className="kpi-card" style={{
                '--kpi-gradient': 'linear-gradient(135deg, #f59e0b, #d97706)',
                '--kpi-blob': 'rgba(245,158,11,0.07)', '--kpi-color': '#d97706', '--kpi-glow': 'rgba(245,158,11,0.28)'
              }}>
                <div className="kpi-card__header">
                  <span className="kpi-card__label">Badges Unlocked</span>
                  <div className="kpi-card__icon-bubble">🏅</div>
                </div>
                <div className="kpi-card__value">{data.gamification_summary?.total_badges_unlocked?.toLocaleString() ?? 0}</div>
                <div className="kpi-card__footer">
                  <span className="kpi-card__subtitle">
                    🥇 {data.gamification_summary?.badge_tier_counts?.PERFECT_GOLD || 0} Perfect
                    · 🥈 {data.gamification_summary?.badge_tier_counts?.GOLD || 0} Gold
                  </span>
                </div>
              </div>
            </div>

            {/* Top 3 Podium Highlights */}
            {top3.length > 0 && (
              <div style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))',
                gap: 16,
                marginBottom: 28,
              }}>
                {top3.map((entry) => (
                  <div
                    key={entry.learner_id}
                    onClick={() => setDetailLearnerId(entry.learner_id)}
                    style={{
                      background: entry.rank === 1
                        ? 'linear-gradient(135deg, rgba(234, 179, 8, 0.10) 0%, rgba(254, 240, 138, 0.04) 100%)'
                        : 'var(--color-surface)',
                      border: entry.rank === 1 ? '1.5px solid rgba(234,179,8,0.50)' : '1px solid var(--color-border)',
                      borderRadius: 'var(--radius-lg)',
                      padding: 20,
                      cursor: 'pointer',
                      display: 'flex',
                      alignItems: 'center',
                      gap: 16,
                      transition: 'all 0.18s',
                      boxShadow: 'var(--shadow-card)',
                    }}
                    onMouseEnter={e => e.currentTarget.style.transform = 'translateY(-3px)'}
                    onMouseLeave={e => e.currentTarget.style.transform = 'translateY(0)'}
                  >
                    <div style={{ fontSize: '2.4rem', filter: 'drop-shadow(0 2px 6px rgba(0,0,0,0.15))' }}>
                      {entry.rank === 1 ? '🥇' : entry.rank === 2 ? '🥈' : '🥉'}
                    </div>
                    <div style={{ flex: 1 }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
                        <span style={{ fontWeight: 800, fontSize: '1.0rem', color: 'var(--color-text-main)' }}>
                          {entry.display_name}
                        </span>
                        {entry.independent ? (
                          <span className="status-pill status-pill--info" style={{ fontSize: '0.68rem' }}>Self-Paced</span>
                        ) : (
                          <span className="status-pill status-pill--neutral" style={{ fontSize: '0.68rem' }}>{entry.section_name}</span>
                        )}
                      </div>
                      <div style={{ fontSize: '0.78rem', color: 'var(--color-text-muted)', marginTop: 4 }}>
                        Tier: <strong>{entry.tier}</strong> · {entry.overall_accuracy}% acc
                      </div>
                      <div style={{ fontSize: '1.1rem', fontWeight: 800, color: 'var(--primary-mid)', marginTop: 6 }}>
                        {entry.points?.toLocaleString()} pts
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}

            <div className="section-card" style={{ marginBottom: 0 }}>
              <div className="section-card__header">
                <div className="section-card__title">
                  📋 {range === 'weekly' ? "This Week's Top Learners" : (selectedSection ? 'Classroom Rankings' : 'All-Time Rankings')}
                  {selectedSection && ` — ${sections.find(s => (s.section_id || s.sectionId) === selectedSection)?.section_name || sections.find(s => (s.section_id || s.sectionId) === selectedSection)?.sectionName || 'Classroom'}`}
                </div>
                <span className="chart-card__period">Top {data.leaderboard?.length || 0} participants</span>
              </div>

              <div className="accounts-table-wrap" style={{ marginBottom: 0 }}>
                <table className="accounts-table">
                  <thead>
                    <tr>
                      <th style={{ width: 60, textAlign: 'center' }}>Rank</th>
                      <th>Student Name</th>
                      <th>Cohort / Section</th>
                      <th>Grade Level</th>
                      <th>Mastery Tier</th>
                      <th>Accuracy</th>
                      <th>Badges</th>
                      <th>Points</th>
                      <th>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {(!data.leaderboard || data.leaderboard.length === 0) && (
                      <tr>
                        <td colSpan={9} style={{ textAlign: 'center', color: 'var(--color-text-muted)', padding: 30 }}>
                          No point activity logged for this time range yet.
                        </td>
                      </tr>
                    )}
                    {data.leaderboard && data.leaderboard.map((entry) => (
                      <tr key={entry.learner_id}>
                        <td style={{ textAlign: 'center' }}>
                          <RankBadge rank={entry.rank} />
                        </td>
                        <td>
                          <div style={{ display: 'flex', alignItems: 'center', gap: 9 }}>
                            <div style={{
                              width: 30, height: 30, borderRadius: '50%',
                              background: 'linear-gradient(135deg, #3b82f6, #1d4ed8)',
                              display: 'grid', placeItems: 'center',
                              color: '#fff', fontSize: '0.75rem', fontWeight: 700, flexShrink: 0,
                            }}>
                              {entry.display_name?.charAt(0)?.toUpperCase() || '?'}
                            </div>
                            <strong style={{ color: 'var(--color-text)' }}>{entry.display_name}</strong>
                          </div>
                        </td>
                        <td>
                          {entry.independent ? (
                            <span className="status-pill status-pill--info">Self-Paced</span>
                          ) : (
                            <span className="text-muted">{entry.section_name}</span>
                          )}
                        </td>
                        <td className="text-muted">
                          {entry.grade_level ? entry.grade_level.replace('_', ' ') : '—'}
                        </td>
                        <td>
                          <span className={`status-pill ${
                            entry.tier === 'MASTERED' ? 'status-pill--success'
                            : entry.tier === 'PROGRESSING' ? 'status-pill--warning'
                            : 'status-pill--neutral'
                          }`}>
                            {entry.tier}
                          </span>
                        </td>
                        <td style={{ fontWeight: 700 }}>
                          {entry.overall_accuracy != null ? `${entry.overall_accuracy.toFixed(1)}%` : '0%'}
                        </td>
                        <td>
                          <span style={{ fontSize: '0.85rem', fontWeight: 600 }}>🏅 {entry.badges_count || 0}</span>
                        </td>
                        <td>
                          <span style={{ fontWeight: 800, color: 'var(--primary-mid)', fontSize: '1rem' }}>
                            {entry.points?.toLocaleString()} pts
                          </span>
                        </td>
                        <td className="actions-cell">
                          <button
                            className="btn btn--sm btn--ghost"
                            onClick={() => setDetailLearnerId(entry.learner_id)}
                          >
                            🔍 Profile
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        ) : null}

        {/* Diagnostic Profile Modal */}
        {detailLearnerId && (
          <LearnerDetailModal
            learnerId={detailLearnerId}
            classContext={selectedSection ? {
              classId: selectedSection,
              className: sections.find(s => (s.section_id || s.sectionId) === selectedSection)?.section_name || sections.find(s => (s.section_id || s.sectionId) === selectedSection)?.sectionName,
            } : null}
            onClose={() => setDetailLearnerId(null)}
            onResetProgress={() => { setDetailLearnerId(null); }}
            onEditProfile={() => { setDetailLearnerId(null); }}
          />
        )}
      </main>
    </div>
  );
}
