import { useState, useEffect } from 'react';
import AdminNav from '../components/AdminNav';
import { apiFetch } from '../services/AuthService';

// ─── Types ────────────────────────────────────────────────────────────────────

interface ConfusedPair {
  wordAId: string;
  wordAEnglish: string;
  wordACebuano: string;
  wordBId: string;
  wordBEnglish: string;
  wordBCebuano: string;
  lessonTitle: string;
  affectedLearners: number;
  totalErrors: number;
}

interface CurriculumGap {
  lessonId: string;
  lessonTitle: string;
  categoryName: string;
  affectedLearners: number;
  totalErrors: number;
  recommendation: string;
}

interface AnalysisData {
  totalClassErrors: number;
  learnersWithErrors: number;
  confusedPairs: ConfusedPair[];
  curriculumGaps: CurriculumGap[];
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function SeverityBar({ value, max }: { value: number; max: number }) {
  const pct = max > 0 ? Math.round((value / max) * 100) : 0;
  const color =
    pct >= 70 ? '#ef4444' : pct >= 40 ? '#f97316' : '#facc15';
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
      <div
        style={{
          flex: 1,
          height: '8px',
          borderRadius: '4px',
          background: 'rgba(255,255,255,0.06)',
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
      <span style={{ fontSize: '12px', color, fontWeight: 700, minWidth: '28px' }}>
        {value}
      </span>
    </div>
  );
}

function StatCard({
  icon,
  value,
  label,
  accent,
}: {
  icon: string;
  value: number | string;
  label: string;
  accent: string;
}) {
  return (
    <div
      style={{
        background: 'var(--color-surface)',
        borderRadius: '16px',
        border: `1.5px solid ${accent}33`,
        padding: '24px',
        display: 'flex',
        alignItems: 'center',
        gap: '16px',
        boxShadow: `0 4px 16px ${accent}1a`,
      }}
    >
      <div
        style={{
          width: '52px',
          height: '52px',
          borderRadius: '14px',
          background: `${accent}20`,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          fontSize: '24px',
          flexShrink: 0,
        }}
      >
        {icon}
      </div>
      <div>
        <div
          style={{
            fontSize: '32px',
            fontWeight: 800,
            color: accent,
            lineHeight: 1,
          }}
        >
          {value}
        </div>
        <div
          style={{
            fontSize: '13px',
            color: 'var(--color-text-muted)',
            marginTop: '4px',
          }}
        >
          {label}
        </div>
      </div>
    </div>
  );
}

// ─── Page ─────────────────────────────────────────────────────────────────────

export default function WrongAnswersAnalysisPage() {
  const [data, setData] = useState<AnalysisData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [activeTab, setActiveTab] = useState<'pairs' | 'gaps'>('pairs');

  useEffect(() => {
    apiFetch('/api/admin/reports/wrong-answers')
      .then((res) => {
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        return res.json() as Promise<AnalysisData>;
      })
      .then(setData)
      .catch((e: unknown) =>
        setError(e instanceof Error ? e.message : 'Failed to load analysis.')
      )
      .finally(() => setLoading(false));
  }, []);

  const maxPairErrors = data
    ? Math.max(...(data.confusedPairs.map((p) => p.totalErrors) || [1]))
    : 1;
  const maxGapErrors = data
    ? Math.max(...(data.curriculumGaps.map((g) => g.totalErrors) || [1]))
    : 1;

  return (
    <div className="admin-layout">
      <AdminNav />
      <main className="admin-main">
        {/* Header */}
        <header className="admin-main__header">
          <div>
            <h1 className="admin-main__title">Wrong Answer Analysis</h1>
            <p className="admin-main__subtitle">
              Class-wide error patterns and curriculum gaps
            </p>
          </div>
          <div className="admin-main__badge">ROLE_ADMIN</div>
        </header>

        {error && <div className="alert alert--error">{error}</div>}

        {loading ? (
          <div style={{ textAlign: 'center', padding: '60px', color: 'var(--color-text-muted)' }}>
            Loading analysis…
          </div>
        ) : data ? (
          <>
            {/* Summary stat cards */}
            <section
              style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
                gap: '16px',
                marginBottom: '32px',
              }}
            >
              <StatCard
                icon="❌"
                value={data.totalClassErrors}
                label="Total class errors"
                accent="#ef4444"
              />
              <StatCard
                icon="👥"
                value={data.learnersWithErrors}
                label="Learners with errors"
                accent="#f97316"
              />
              <StatCard
                icon="🔀"
                value={data.confusedPairs.length}
                label="Confused word pairs"
                accent="#a855f7"
              />
              <StatCard
                icon="📚"
                value={data.curriculumGaps.length}
                label="Lessons with gaps"
                accent="#3b82f6"
              />
            </section>

            {/* Tabs */}
            <div style={{ display: 'flex', gap: '8px', marginBottom: '20px' }}>
              {(['pairs', 'gaps'] as const).map((tab) => (
                <button
                  key={tab}
                  onClick={() => setActiveTab(tab)}
                  style={{
                    padding: '10px 22px',
                    borderRadius: '10px',
                    border: 'none',
                    cursor: 'pointer',
                    fontWeight: 700,
                    fontSize: '14px',
                    background:
                      activeTab === tab
                        ? 'var(--color-accent-1)'
                        : 'var(--color-surface)',
                    color:
                      activeTab === tab ? '#fff' : 'var(--color-text-muted)',
                    transition: 'all 0.2s',
                  }}
                >
                  {tab === 'pairs' ? '🔀 Confused Word Pairs' : '📚 Curriculum Gaps'}
                </button>
              ))}
            </div>

            {/* Confused Pairs Panel */}
            {activeTab === 'pairs' && (
              <section>
                {data.confusedPairs.length === 0 ? (
                  <div
                    style={{
                      padding: '48px',
                      textAlign: 'center',
                      color: 'var(--color-text-muted)',
                      background: 'var(--color-surface)',
                      borderRadius: '16px',
                    }}
                  >
                    🎉 No confused word pairs detected yet.
                  </div>
                ) : (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                    {data.confusedPairs.map((pair) => (
                      <div
                        key={`${pair.wordAId}-${pair.wordBId}`}
                        style={{
                          background: 'var(--color-surface)',
                          borderRadius: '16px',
                          border: '1.5px solid rgba(255,255,255,0.07)',
                          padding: '20px 24px',
                        }}
                      >
                        <div
                          style={{
                            display: 'flex',
                            alignItems: 'flex-start',
                            gap: '16px',
                            flexWrap: 'wrap',
                          }}
                        >
                          {/* Word A */}
                          <div style={{ flex: 1, minWidth: '140px' }}>
                            <div
                              style={{
                                fontSize: '16px',
                                fontWeight: 800,
                                color: 'var(--color-text)',
                              }}
                            >
                              {pair.wordAEnglish}
                            </div>
                            <div
                              style={{
                                fontSize: '13px',
                                color: 'var(--color-text-muted)',
                                fontStyle: 'italic',
                              }}
                            >
                              {pair.wordACebuano}
                            </div>
                          </div>

                          {/* VS divider */}
                          <div
                            style={{
                              alignSelf: 'center',
                              padding: '4px 12px',
                              borderRadius: '8px',
                              background: '#ef444420',
                              color: '#ef4444',
                              fontSize: '12px',
                              fontWeight: 800,
                            }}
                          >
                            VS
                          </div>

                          {/* Word B */}
                          <div style={{ flex: 1, minWidth: '140px' }}>
                            <div
                              style={{
                                fontSize: '16px',
                                fontWeight: 800,
                                color: 'var(--color-text)',
                              }}
                            >
                              {pair.wordBEnglish}
                            </div>
                            <div
                              style={{
                                fontSize: '13px',
                                color: 'var(--color-text-muted)',
                                fontStyle: 'italic',
                              }}
                            >
                              {pair.wordBCebuano}
                            </div>
                          </div>

                          {/* Error stats */}
                          <div style={{ flex: 2, minWidth: '180px' }}>
                            <div
                              style={{
                                fontSize: '12px',
                                color: 'var(--color-text-muted)',
                                marginBottom: '6px',
                              }}
                            >
                              <span style={{ color: 'var(--color-text)', fontWeight: 600 }}>
                                {pair.affectedLearners}
                              </span>{' '}
                              learner{pair.affectedLearners !== 1 ? 's' : ''} confused •{' '}
                              <span style={{ color: 'var(--color-text)', fontWeight: 600 }}>
                                {pair.lessonTitle}
                              </span>
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
                  <div
                    style={{
                      padding: '48px',
                      textAlign: 'center',
                      color: 'var(--color-text-muted)',
                      background: 'var(--color-surface)',
                      borderRadius: '16px',
                    }}
                  >
                    🎉 No curriculum gaps detected yet.
                  </div>
                ) : (
                  <table
                    style={{
                      width: '100%',
                      borderCollapse: 'separate',
                      borderSpacing: '0 10px',
                    }}
                  >
                    <thead>
                      <tr
                        style={{
                          color: 'var(--color-text-muted)',
                          fontSize: '12px',
                          fontWeight: 700,
                          textTransform: 'uppercase',
                          letterSpacing: '0.06em',
                        }}
                      >
                        <th style={{ textAlign: 'left', padding: '0 16px 4px' }}>Lesson</th>
                        <th style={{ textAlign: 'left', padding: '0 16px 4px' }}>Category</th>
                        <th style={{ textAlign: 'right', padding: '0 16px 4px' }}>Affected</th>
                        <th style={{ padding: '0 16px 4px', minWidth: '160px' }}>
                          Error severity
                        </th>
                        <th style={{ textAlign: 'left', padding: '0 16px 4px' }}>
                          Recommendation
                        </th>
                      </tr>
                    </thead>
                    <tbody>
                      {data.curriculumGaps.map((gap) => (
                        <tr
                          key={gap.lessonId}
                          style={{
                            background: 'var(--color-surface)',
                          }}
                        >
                          <td
                            style={{
                              padding: '14px 16px',
                              borderRadius: '12px 0 0 12px',
                              fontWeight: 700,
                              color: 'var(--color-text)',
                            }}
                          >
                            {gap.lessonTitle}
                          </td>
                          <td
                            style={{
                              padding: '14px 16px',
                              color: 'var(--color-text-muted)',
                              fontSize: '13px',
                            }}
                          >
                            {gap.categoryName}
                          </td>
                          <td
                            style={{
                              padding: '14px 16px',
                              textAlign: 'right',
                              fontWeight: 700,
                              color: '#f97316',
                            }}
                          >
                            {gap.affectedLearners}
                          </td>
                          <td style={{ padding: '14px 16px', minWidth: '160px' }}>
                            <SeverityBar value={gap.totalErrors} max={maxGapErrors} />
                          </td>
                          <td
                            style={{
                              padding: '14px 16px',
                              borderRadius: '0 12px 12px 0',
                              fontSize: '13px',
                              color: 'var(--color-text-muted)',
                              fontStyle: 'italic',
                            }}
                          >
                            {gap.recommendation}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                )}
              </section>
            )}
          </>
        ) : null}
      </main>
    </div>
  );
}
