import { useEffect, useState } from 'react';
import { LearnerService } from '../services/LearnerService';

export default function LearnerDetailModal({ learnerId, onClose, onResetProgress, onEditProfile }) {
  const [detail, setDetail] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError(null);
    LearnerService.getLearnerDetail(learnerId)
      .then(data => {
        if (!cancelled) {
          setDetail(data);
          setLoading(false);
        }
      })
      .catch(err => {
        if (!cancelled) {
          setError(err?.message || 'Failed to load learner details');
          setLoading(false);
        }
      });
    return () => { cancelled = true; };
  }, [learnerId]);

  const displayName = detail?.display_name || detail?.displayName || 'Student';
  const idVal = detail?.learner_id || detail?.learnerId || learnerId;
  const sectionName = detail?.section_name || detail?.sectionName || 'Unassigned (Self-Paced)';
  const gradeLevel = detail?.grade_level || detail?.gradeLevel;
  const overallAcc = detail?.overall_accuracy ?? detail?.overallAccuracy ?? 0;
  const totalPts = detail?.total_points ?? detail?.totalPoints ?? 0;
  const masteredWords = detail?.words_mastered_count ?? detail?.masteredWordsCount ?? 0;
  const lessons = detail?.lessons || detail?.lessonBreakdowns || [];
  const weakWords = detail?.weak_words || detail?.weakWords || [];
  const isStruggling = detail?.is_struggling ?? detail?.struggling ?? false;
  const strugglingReasons = detail?.struggling_reasons || detail?.strugglingReasons || [];

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal modal--lg modal--xl" onClick={e => e.stopPropagation()} style={{ maxHeight: '90vh', overflowY: 'auto' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
          <h2 className="modal__title" style={{ margin: 0 }}>👤 Learner Diagnostic Profile</h2>
          <button className="modal__close-btn" onClick={onClose}>✕</button>
        </div>

        {loading && (
          <div className="auth-loading" style={{ minHeight: 300 }}><div className="spinner" /></div>
        )}

        {error && (
          <div className="alert alert--error">{error}</div>
        )}

        {detail && !loading && (
          <div>
            {/* Header info */}
            <div style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
              gap: 16,
              padding: 16,
              background: 'var(--glass-bg)',
              borderRadius: 'var(--radius-sm)',
              border: '1px solid var(--color-border)',
              marginBottom: 20
            }}>
              <div>
                <div style={{ fontSize: '0.75rem', color: 'var(--color-text-muted)', textTransform: 'uppercase' }}>Learner Name</div>
                <div style={{ fontSize: '1.2rem', fontWeight: 700, color: 'var(--color-text-main)' }}>{displayName}</div>
                <div style={{ fontSize: '0.8rem', color: 'var(--color-text-dim)' }}>ID: {idVal}</div>
              </div>
              <div>
                <div style={{ fontSize: '0.75rem', color: 'var(--color-text-muted)', textTransform: 'uppercase' }}>Class / Section</div>
                <div style={{ fontSize: '1.1rem', fontWeight: 600 }}>{sectionName}</div>
                <div style={{ fontSize: '0.8rem', color: 'var(--color-text-muted)' }}>Grade: {gradeLevel ? gradeLevel.replace('_', ' ') : 'N/A'}</div>
              </div>
              <div>
                <div style={{ fontSize: '0.75rem', color: 'var(--color-text-muted)', textTransform: 'uppercase' }}>Overall Accuracy</div>
                <div style={{ fontSize: '1.2rem', fontWeight: 700, color: Number(overallAcc) >= 70 ? 'var(--color-success)' : 'var(--color-danger)' }}>
                  {Number(overallAcc).toFixed(1)}%
                </div>
                <div style={{ fontSize: '0.8rem', color: 'var(--color-text-muted)' }}>Points: {totalPts}</div>
              </div>
              <div>
                <div style={{ fontSize: '0.75rem', color: 'var(--color-text-muted)', textTransform: 'uppercase' }}>Mastered Words</div>
                <div style={{ fontSize: '1.2rem', fontWeight: 700, color: 'var(--color-primary)' }}>
                  {masteredWords}
                </div>
                <div style={{ fontSize: '0.8rem', color: 'var(--color-text-muted)' }}>Lessons Tracked: {lessons.length}</div>
              </div>
            </div>

            {/* Struggling warning banner if applicable */}
            {isStruggling && (
              <div className="alert alert--error" style={{ marginBottom: 20 }}>
                <strong>⚠️ Learner flagged as needing intervention:</strong>
                <ul style={{ margin: '8px 0 0 20px', padding: 0 }}>
                  {strugglingReasons.map((reason, idx) => (
                    <li key={idx}>{reason}</li>
                  ))}
                </ul>
              </div>
            )}

            {/* Lesson Progress Breakdown */}
            <div style={{ marginBottom: 24 }}>
              <h3 style={{ fontSize: '1rem', marginBottom: 12, display: 'flex', alignItems: 'center', gap: 8 }}>
                <span>📖 Lesson Progress</span>
                <span className="table-meta" style={{ margin: 0 }}>({lessons.length} lessons)</span>
              </h3>

              <div className="accounts-table-wrap">
                <table className="accounts-table">
                  <thead>
                    <tr>
                      <th>Lesson</th>
                      <th>Status</th>
                      <th>Mastery Score</th>
                      <th>M1 Intro</th>
                      <th>M2 Practice</th>
                      <th>M3 Review</th>
                      <th>M4 Test</th>
                      <th>Last Attempt</th>
                    </tr>
                  </thead>
                  <tbody>
                    {lessons.length === 0 && (
                      <tr>
                        <td colSpan={8} style={{ textAlign: 'center', color: 'var(--color-text-muted)', padding: 24 }}>
                          No lesson activity recorded yet.
                        </td>
                      </tr>
                    )}
                    {lessons.map(lb => {
                      const lesId = lb.lesson_id || lb.lessonId;
                      const lesTitle = lb.lesson_title || lb.lessonTitle;
                      const statusVal = lb.status;
                      const mScore = lb.mastery_score ?? lb.masteryScore;
                      
                      const modScores = lb.module_scores || lb.moduleScores || [];
                      const getModScore = (num) => {
                        const direct = [lb.module_1_score ?? lb.module1Score, lb.module_2_score ?? lb.module2Score, lb.module_3_score ?? lb.module3Score, lb.module_4_score ?? lb.module4Score][num - 1];
                        if (direct != null) return direct;
                        const found = modScores.find(m => (m.module_number ?? m.moduleNumber) === num);
                        return found ? (found.score ?? null) : null;
                      };

                      const isCompleted = (statusVal === 'COMPLETED');
                      const rawM1 = getModScore(1);
                      const rawM2 = getModScore(2);
                      const rawM3 = getModScore(3);
                      const rawM4 = getModScore(4);

                      // Module 1 is Intro exposure: If lesson completed or M2 reached, M1 was 100% completed
                      const m1 = rawM1 != null ? rawM1 : ((rawM2 != null || isCompleted) ? 100 : null);
                      const m2 = rawM2;
                      const m3 = rawM3;
                      // Module 4 is Test / Cumulative: If M4 score recorded use it, else if lesson is completed fallback to mastery score
                      const m4 = rawM4 != null ? rawM4 : (isCompleted ? (mScore ?? 100) : null);
                      const lastPracticed = lb.last_practiced_at || lb.lastPracticedAt || lb.completed_at || lb.completedAt || detail?.last_active_at || detail?.lastActiveAt;

                      return (
                        <tr key={lesId}>
                          <td>
                            <strong>{lesTitle}</strong>
                          </td>
                          <td>
                            <span className={`status-badge badge--${statusVal ? statusVal.toLowerCase() : 'draft'}`}>
                              {statusVal}
                            </span>
                          </td>
                          <td style={{ fontWeight: 600 }}>
                            {mScore != null ? `${Number(mScore).toFixed(0)}%` : '—'}
                          </td>
                          <td>{m1 != null ? `${Number(m1).toFixed(0)}%` : '—'}</td>
                          <td>{m2 != null ? `${Number(m2).toFixed(0)}%` : '—'}</td>
                          <td>{m3 != null ? `${Number(m3).toFixed(0)}%` : '—'}</td>
                          <td>{m4 != null ? `${Number(m4).toFixed(0)}%` : '—'}</td>
                          <td className="text-muted" style={{ fontSize: '0.8rem' }}>
                            {lastPracticed ? new Date(lastPracticed).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }) : '—'}
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </div>

            {/* Cumulative Review & Long-Term Retention Section */}
            <div style={{ marginBottom: 24 }}>
              <h3 style={{ fontSize: '1rem', marginBottom: 12, display: 'flex', alignItems: 'center', gap: 8 }}>
                <span>🌟 Cumulative Review & Retention Performance</span>
                <span className="table-meta" style={{ margin: 0 }}>
                  ({detail?.cumulative_reviews_completed ?? detail?.cumulativeReviewsCompleted ?? (detail?.cumulative_reviews || detail?.cumulativeReviews || []).length} completed sessions)
                </span>
              </h3>

              {/* Cumulative Summary Cards */}
              <div style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
                gap: 12,
                marginBottom: 16
              }}>
                <div style={{
                  background: 'var(--glass-bg)',
                  padding: '12px 16px',
                  borderRadius: 'var(--radius-sm)',
                  border: '1px solid var(--color-border)'
                }}>
                  <div style={{ fontSize: '0.75rem', color: 'var(--color-text-muted)', textTransform: 'uppercase' }}>Reviews Completed</div>
                  <div style={{ fontSize: '1.25rem', fontWeight: 700, color: 'var(--color-primary)', marginTop: 2 }}>
                    {detail?.cumulative_reviews_completed ?? detail?.cumulativeReviewsCompleted ?? (detail?.cumulative_reviews || detail?.cumulativeReviews || []).length}
                  </div>
                </div>
                <div style={{
                  background: 'var(--glass-bg)',
                  padding: '12px 16px',
                  borderRadius: 'var(--radius-sm)',
                  border: '1px solid var(--color-border)'
                }}>
                  <div style={{ fontSize: '0.75rem', color: 'var(--color-text-muted)', textTransform: 'uppercase' }}>Avg Retention Score</div>
                  <div style={{ fontSize: '1.25rem', fontWeight: 700, color: Number(detail?.avg_cumulative_score ?? detail?.avgCumulativeScore ?? 0) >= 70 ? 'var(--color-success)' : 'var(--color-accent-1)', marginTop: 2 }}>
                    {Number(detail?.avg_cumulative_score ?? detail?.avgCumulativeScore ?? 0).toFixed(1)}%
                  </div>
                </div>
                <div style={{
                  background: 'var(--glass-bg)',
                  padding: '12px 16px',
                  borderRadius: 'var(--radius-sm)',
                  border: '1px solid var(--color-border)'
                }}>
                  <div style={{ fontSize: '0.75rem', color: 'var(--color-text-muted)', textTransform: 'uppercase' }}>Best Badge Earned</div>
                  <div style={{ fontSize: '1.1rem', fontWeight: 700, marginTop: 2 }}>
                    {(detail?.best_cumulative_badge || detail?.bestCumulativeBadge) === 'PERFECT_GOLD' && '🏆 Perfect Gold (100%)'}
                    {(detail?.best_cumulative_badge || detail?.bestCumulativeBadge) === 'GOLD' && '🥇 Gold (90%+)'}
                    {(detail?.best_cumulative_badge || detail?.bestCumulativeBadge) === 'SILVER' && '🥈 Silver (80%+)'}
                    {(detail?.best_cumulative_badge || detail?.bestCumulativeBadge) === 'BRONZE' && '🥉 Bronze (70%+)'}
                    {!(detail?.best_cumulative_badge || detail?.bestCumulativeBadge) && <span className="text-muted" style={{ fontWeight: 500, fontSize: '0.95rem' }}>No badges yet</span>}
                  </div>
                </div>
              </div>

              {/* Cumulative Sessions Table */}
              <div className="accounts-table-wrap">
                <table className="accounts-table">
                  <thead>
                    <tr>
                      <th>Lesson Pair / Category</th>
                      <th>Accuracy</th>
                      <th>Badge</th>
                      <th>Points Earned</th>
                      <th>Questions</th>
                      <th>Date Completed</th>
                    </tr>
                  </thead>
                  <tbody>
                    {(!detail?.cumulative_reviews && !detail?.cumulativeReviews || (detail?.cumulative_reviews || detail?.cumulativeReviews).length === 0) ? (
                      <tr>
                        <td colSpan={6} style={{ textAlign: 'center', color: 'var(--color-text-muted)', padding: 20 }}>
                          No cumulative review sessions completed yet.
                        </td>
                      </tr>
                    ) : (
                      (detail?.cumulative_reviews || detail?.cumulativeReviews).map((cs, idx) => {
                        const sid = cs.session_id || cs.sessionId || idx;
                        const pairName = cs.category_name || cs.categoryName || cs.lesson_pair_id || cs.lessonPairId || 'Cumulative Review';
                        const acc = cs.accuracy_percent ?? cs.accuracyPercent;
                        const badge = cs.badge_awarded || cs.badgeAwarded;
                        const pts = cs.points_earned ?? cs.pointsEarned ?? 0;
                        const corr = cs.correct_count ?? cs.correctCount ?? 0;
                        const tot = cs.total_attempts ?? cs.totalAttempts ?? 0;
                        const compDate = cs.completed_at || cs.completedAt;

                        return (
                          <tr key={sid}>
                            <td><strong>{pairName}</strong></td>
                            <td style={{ fontWeight: 600, color: Number(acc) >= 80 ? 'var(--color-success)' : 'var(--color-text-main)' }}>
                              {acc != null ? `${Number(acc).toFixed(1)}%` : '—'}
                            </td>
                            <td>
                              {badge === 'PERFECT_GOLD' && <span style={{ color: '#d97706', fontWeight: 700 }}>🏆 Perfect Gold</span>}
                              {badge === 'GOLD' && <span style={{ color: '#eab308', fontWeight: 700 }}>🥇 Gold</span>}
                              {badge === 'SILVER' && <span style={{ color: '#94a3b8', fontWeight: 700 }}>🥈 Silver</span>}
                              {badge === 'BRONZE' && <span style={{ color: '#b45309', fontWeight: 700 }}>🥉 Bronze</span>}
                              {!badge && <span className="text-muted">—</span>}
                            </td>
                            <td style={{ fontWeight: 600, color: 'var(--color-primary)' }}>+{pts} pts</td>
                            <td className="text-muted">{corr} / {tot} correct</td>
                            <td className="text-muted" style={{ fontSize: '0.8rem' }}>
                              {compDate ? new Date(compDate).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }) : '—'}
                            </td>
                          </tr>
                        );
                      })
                    )}
                  </tbody>
                </table>
              </div>
            </div>

            {/* Weak Words Requiring Reinforcement */}
            <div style={{ marginBottom: 24 }}>
              <h3 style={{ fontSize: '1rem', marginBottom: 12, display: 'flex', alignItems: 'center', gap: 8 }}>
                <span>🎯 Reinforcement Focus (Weak Words)</span>
              </h3>

              <div className="accounts-table-wrap">
                <table className="accounts-table">
                  <thead>
                    <tr>
                      <th>Word</th>
                      <th>Cebuano Meaning</th>
                      <th>Lesson</th>
                      <th>Accuracy</th>
                      <th>Demerit Points</th>
                      <th>Attempts</th>
                    </tr>
                  </thead>
                  <tbody>
                    {weakWords.length === 0 && (
                      <tr>
                        <td colSpan={6} style={{ textAlign: 'center', color: 'var(--color-success)', padding: 20 }}>
                          ✓ No weak words identified. Learner is performing well!
                        </td>
                      </tr>
                    )}
                    {weakWords.map(w => {
                      const wid = w.word_id || w.wordId;
                      const eng = w.english_word || w.englishWord;
                      const ceb = w.cebuano_meaning || w.cebuanoMeaning;
                      const les = w.lesson_title || w.lessonTitle;
                      const acc = w.accuracy ?? w.avg_accuracy;
                      const dem = w.demerit_points ?? w.demeritPoints;
                      const att = w.total_attempts ?? w.totalAttempts ?? ((w.correct_count || 0) + (w.incorrect_count || 0));

                      return (
                        <tr key={wid}>
                          <td><strong>{eng}</strong></td>
                          <td className="text-muted">{ceb}</td>
                          <td className="text-muted">{les}</td>
                          <td style={{ color: Number(acc) < 70 ? 'var(--color-danger)' : 'var(--color-text-main)', fontWeight: 600 }}>
                            {acc != null ? `${Number(acc).toFixed(1)}%` : '0%'}
                          </td>
                          <td style={{ color: Number(dem) > 0 ? 'var(--color-danger)' : 'inherit' }}>
                            {dem || 0}
                          </td>
                          <td>{att || 0}</td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </div>

            {/* Actions footer */}
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10, marginTop: 24 }}>
              <button
                className="btn btn--danger-ghost"
                onClick={() => onResetProgress(detail)}
              >
                ⚠️ Reset Progress
              </button>
              <button
                className="btn btn--primary"
                onClick={onClose}
              >
                Done
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
