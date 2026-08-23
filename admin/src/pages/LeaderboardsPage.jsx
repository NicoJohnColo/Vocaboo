import { useState, useEffect, useCallback } from 'react';
import AdminNav from '../components/AdminNav';
import { AnalyticsService } from '../services/AnalyticsService';
import { SectionService } from '../services/SectionService';
import LearnerDetailModal from '../components/LearnerDetailModal';

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
  const [range, setRange] = useState('weekly'); // 'weekly' | 'all_time'
  const [cohortType, setCohortType] = useState('ALL'); // 'ALL' | 'INDEPENDENT' | 'ENROLLED'
  const [selectedSection, setSelectedSection] = useState('');
  const [sections, setSections] = useState([]);
  
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
            <h1 className="admin-main__title">🏆 Leaderboard &amp; Gamification Hub</h1>
            <p className="admin-main__subtitle">Track platform-wide point rankings, mastery tiers, and reward distributions</p>
          </div>

          <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', alignItems: 'center' }}>
            {/* Time Range Toggle */}
            <div style={{
              display: 'flex',
              background: 'var(--glass-bg)',
              borderRadius: 'var(--radius-sm)',
              padding: 4,
              border: '1px solid var(--color-border)',
            }}>
              <button
                style={{
                  padding: '6px 14px',
                  borderRadius: 6,
                  border: 'none',
                  cursor: 'pointer',
                  fontWeight: 700,
                  fontSize: '0.85rem',
                  background: range === 'weekly' ? 'var(--color-primary)' : 'transparent',
                  color: range === 'weekly' ? '#fff' : 'var(--color-text-dim)',
                  transition: 'all 0.2s',
                }}
                onClick={() => setRange('weekly')}
              >
                ⚡ This Week
              </button>
              <button
                style={{
                  padding: '6px 14px',
                  borderRadius: 6,
                  border: 'none',
                  cursor: 'pointer',
                  fontWeight: 700,
                  fontSize: '0.85rem',
                  background: range === 'all_time' ? 'var(--color-primary)' : 'transparent',
                  color: range === 'all_time' ? '#fff' : 'var(--color-text-dim)',
                  transition: 'all 0.2s',
                }}
                onClick={() => setRange('all_time')}
              >
                🌟 All-Time
              </button>
            </div>

            {/* Cohort Selector */}
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
              <option value="">Specific Section...</option>
              {sections.map(s => (
                <option key={s.section_id} value={s.section_id}>{s.section_name}</option>
              ))}
            </select>
          </div>
        </header>

        {error && <div className="alert alert--error" onClick={() => setError('')}>{error}</div>}

        {loading ? (
          <div className="auth-loading" style={{ minHeight: 350 }}><div className="spinner" /></div>
        ) : data ? (
          <div>
            {/* Gamification Summary KPIs */}
            <div style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(210px, 1fr))',
              gap: 16,
              marginBottom: 28,
            }}>
              <div style={{
                background: 'var(--glass-bg)',
                borderRadius: 'var(--radius-md)',
                padding: '20px 24px',
                border: '1px solid var(--color-border)',
                boxShadow: 'var(--shadow-card)',
              }}>
                <div style={{ fontSize: '0.8rem', color: 'var(--color-text-muted)', fontWeight: 600, textTransform: 'uppercase' }}>
                  Total Points Earned
                </div>
                <div style={{ fontSize: '1.8rem', fontWeight: 800, color: 'var(--color-accent-1)', marginTop: 4 }}>
                  {data.gamification_summary?.total_points_awarded?.toLocaleString() ?? 0}
                </div>
                <div style={{ fontSize: '0.75rem', color: 'var(--color-text-dim)', marginTop: 4 }}>
                  Avg {data.gamification_summary?.average_points_per_active_learner ?? 0} pts per student
                </div>
              </div>

              <div style={{
                background: 'var(--glass-bg)',
                borderRadius: 'var(--radius-md)',
                padding: '20px 24px',
                border: '1px solid var(--color-border)',
                boxShadow: 'var(--shadow-card)',
              }}>
                <div style={{ fontSize: '0.8rem', color: 'var(--color-text-muted)', fontWeight: 600, textTransform: 'uppercase' }}>
                  Practice Sessions Completed
                </div>
                <div style={{ fontSize: '1.8rem', fontWeight: 800, color: '#06b6d4', marginTop: 4 }}>
                  {data.gamification_summary?.total_sessions_played?.toLocaleString() ?? 0}
                </div>
                <div style={{ fontSize: '0.75rem', color: 'var(--color-text-dim)', marginTop: 4 }}>
                  Total practice runs logged
                </div>
              </div>

              <div style={{
                background: 'var(--glass-bg)',
                borderRadius: 'var(--radius-md)',
                padding: '20px 24px',
                border: '1px solid var(--color-border)',
                boxShadow: 'var(--shadow-card)',
              }}>
                <div style={{ fontSize: '0.8rem', color: 'var(--color-text-muted)', fontWeight: 600, textTransform: 'uppercase' }}>
                  Badges &amp; Medals Unlocked
                </div>
                <div style={{ fontSize: '1.8rem', fontWeight: 800, color: '#f59e0b', marginTop: 4 }}>
                  {data.gamification_summary?.total_badges_unlocked?.toLocaleString() ?? 0}
                </div>
                <div style={{ fontSize: '0.75rem', color: 'var(--color-text-dim)', marginTop: 4 }}>
                  🥇 {data.gamification_summary?.badge_tier_counts?.PERFECT_GOLD || 0} Perfect • 🥈 {data.gamification_summary?.badge_tier_counts?.GOLD || 0} Gold
                </div>
              </div>
            </div>

            {/* Top 3 Podium Highlights */}
            {top3.length > 0 && (
              <div style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))',
                gap: 16,
                marginBottom: 32,
              }}>
                {top3.map((entry) => (
                  <div
                    key={entry.learner_id}
                    onClick={() => setDetailLearnerId(entry.learner_id)}
                    style={{
                      background: entry.rank === 1
                        ? 'linear-gradient(135deg, rgba(234, 179, 8, 0.12) 0%, rgba(254, 240, 138, 0.04) 100%)'
                        : 'var(--glass-bg)',
                      border: entry.rank === 1 ? '1.5px solid #eab308' : '1px solid var(--color-border)',
                      borderRadius: 'var(--radius-md)',
                      padding: 20,
                      cursor: 'pointer',
                      display: 'flex',
                      alignItems: 'center',
                      gap: 16,
                      transition: 'transform 0.2s',
                    }}
                  >
                    <div style={{ fontSize: '2.4rem' }}>
                      {entry.rank === 1 ? '🥇' : entry.rank === 2 ? '🥈' : '🥉'}
                    </div>
                    <div style={{ flex: 1 }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                        <span style={{ fontWeight: 800, fontSize: '1.05rem', color: 'var(--color-text-main)' }}>
                          {entry.display_name}
                        </span>
                        {entry.independent ? (
                          <span style={{ fontSize: '0.7rem', background: 'rgba(6, 182, 212, 0.15)', color: '#06b6d4', padding: '1px 6px', borderRadius: 4, fontWeight: 600 }}>
                            Self-Paced
                          </span>
                        ) : (
                          <span style={{ fontSize: '0.7rem', background: 'rgba(124, 77, 255, 0.15)', color: 'var(--color-primary)', padding: '1px 6px', borderRadius: 4, fontWeight: 600 }}>
                            {entry.section_name}
                          </span>
                        )}
                      </div>
                      <div style={{ fontSize: '0.8rem', color: 'var(--color-text-dim)', marginTop: 4 }}>
                        Tier: <strong>{entry.tier}</strong> • {entry.overall_accuracy}% acc
                      </div>
                      <div style={{ fontSize: '1.15rem', fontWeight: 800, color: 'var(--color-accent-1)', marginTop: 6 }}>
                        {entry.points?.toLocaleString()} pts
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}

            {/* Complete Leaderboard Table */}
            <div style={{
              background: 'var(--glass-bg)',
              borderRadius: 'var(--radius-md)',
              padding: 24,
              border: '1px solid var(--color-border)',
            }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
                <h3 style={{ fontSize: '1.1rem', margin: 0, color: 'var(--color-text-main)' }}>
                  📋 {range === 'weekly' ? 'This Week’s Top Learners' : 'All-Time Global Rankings'}
                </h3>
                <span className="table-meta" style={{ margin: 0 }}>
                  Showing Top {data.leaderboard?.length || 0} participants
                </span>
              </div>

              <div className="accounts-table-wrap">
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
                          <strong>{entry.display_name}</strong>
                        </td>
                        <td>
                          {entry.independent ? (
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
                          ) : (
                            <span className="text-muted">{entry.section_name}</span>
                          )}
                        </td>
                        <td className="text-muted">
                          {entry.grade_level ? entry.grade_level.replace('_', ' ') : '—'}
                        </td>
                        <td>
                          <span style={{
                            fontSize: '0.75rem',
                            fontWeight: 700,
                            padding: '2px 8px',
                            borderRadius: 4,
                            background: entry.tier === 'MASTERED'
                              ? 'rgba(74, 222, 128, 0.15)'
                              : entry.tier === 'PROGRESSING'
                              ? 'rgba(250, 204, 21, 0.15)'
                              : 'rgba(148, 163, 184, 0.15)',
                            color: entry.tier === 'MASTERED'
                              ? 'var(--color-success)'
                              : entry.tier === 'PROGRESSING'
                              ? '#ca8a04'
                              : 'var(--color-text-muted)',
                          }}>
                            {entry.tier}
                          </span>
                        </td>
                        <td style={{ fontWeight: 600 }}>
                          {entry.overall_accuracy != null ? `${entry.overall_accuracy.toFixed(1)}%` : '0%'}
                        </td>
                        <td>
                          <span style={{ fontSize: '0.85rem' }}>🏅 {entry.badges_count || 0}</span>
                        </td>
                        <td>
                          <span style={{ fontWeight: 800, color: 'var(--color-accent-1)', fontSize: '1rem' }}>
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
            onClose={() => setDetailLearnerId(null)}
            onResetProgress={() => { setDetailLearnerId(null); }}
            onEditProfile={() => { setDetailLearnerId(null); }}
          />
        )}
      </main>
    </div>
  );
}
