import { useEffect, useState } from 'react';
import { LearnerService } from '../services/LearnerService';
import { useAdminAuth } from '../hooks/useAdminAuth';

export default function LearnerDetailModal({ learnerId, classContext, onClose, onResetProgress, onEditProfile }) {
  const { admin } = useAdminAuth();
  const isTeacher = admin?.role?.toLowerCase() === 'teacher' || admin?.role?.toUpperCase() === 'ROLE_TEACHER';
  const [detail, setDetail] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [selectedClassId, setSelectedClassId] = useState(classContext?.classId || null);
  const isClassScoped = Boolean(selectedClassId || isTeacher);

  useEffect(() => {
    setSelectedClassId(classContext?.classId || null);
  }, [classContext?.classId]);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError(null);
    LearnerService.getLearnerDetail(learnerId, selectedClassId)
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
  }, [learnerId, selectedClassId]);

  const enrolledClasses = detail?.enrolled_classes || detail?.enrolledClasses || [];
  const currentEnrolled = enrolledClasses.find(c => (c.class_id || c.classId) === selectedClassId);

  const displayName = detail?.display_name || detail?.displayName || 'Student';
  const idVal = detail?.learner_id || detail?.learnerId || learnerId;
  const isMultiClassCombined = isTeacher && enrolledClasses.length > 1 && !selectedClassId;
  const targetClassName = currentEnrolled?.class_name || currentEnrolled?.className || (selectedClassId ? (detail?.class_name || detail?.className || classContext?.className) : null);
  const targetClassCode = currentEnrolled?.class_code || currentEnrolled?.classCode || (selectedClassId ? (detail?.class_code || detail?.classCode || classContext?.classCode) : null);
  const sectionName = isClassScoped ? (targetClassName || 'Selected Class') : (detail?.section_name || detail?.sectionName || 'Unassigned (Self-Paced)');
  const gradeLevel = detail?.grade_level || detail?.gradeLevel;
  const overallAcc = detail?.overall_accuracy ?? detail?.overallAccuracy ?? 0;
  const totalPts = detail?.total_points ?? detail?.totalPoints ?? 0;
  const masteredWords = detail?.words_mastered_count ?? detail?.masteredWordsCount ?? 0;
  const classPts = detail?.class_points ?? detail?.classPoints;
  const classAcc = detail?.class_accuracy ?? detail?.classAccuracy;
  const classMastery = detail?.class_mastery_level ?? detail?.classMasteryLevel;
  const classSessions = detail?.class_sessions_played ?? detail?.classSessionsPlayed;
  const posBreakdown = detail?.pos_breakdown || detail?.posBreakdown || [];
  const allWords = detail?.all_words || detail?.allWords || [];
  const allLessonsRaw = detail?.lessons || detail?.lessonBreakdowns || [];
  const lessons = allLessonsRaw.filter(lb => lb.status && lb.status !== 'NOT_STARTED');
  const weakWords = detail?.weak_words || detail?.weakWords || [];
  const isStruggling = detail?.is_struggling ?? detail?.struggling ?? false;
  const strugglingReasons = detail?.struggling_reasons || detail?.strugglingReasons || [];

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal modal--xl" onClick={e => e.stopPropagation()} style={{ maxHeight: '90vh', overflowY: 'auto' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{
              width: 44, height: 44, borderRadius: 12,
              background: 'linear-gradient(135deg, #3b82f6, #1d4ed8)',
              display: 'grid', placeItems: 'center',
              color: '#fff', fontSize: '1.2rem', fontWeight: 800,
              boxShadow: '0 4px 12px rgba(37,99,235,0.30)',
            }}>
              {displayName?.charAt(0)?.toUpperCase() || 'S'}
            </div>
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, flexWrap: 'wrap' }}>
                <h2 className="modal__title" style={{ margin: 0, fontSize: '1.2rem' }}>{displayName}</h2>
                <span style={{
                  fontFamily: 'monospace',
                  fontSize: '0.78rem',
                  fontWeight: 700,
                  color: '#1d4ed8',
                  background: '#eff6ff',
                  border: '1px solid #bfdbfe',
                  borderRadius: 6,
                  padding: '2px 8px',
                  letterSpacing: '0.4px',
                  whiteSpace: 'nowrap',
                  flexShrink: 0,
                }}>
                  ID: {detail?.user_id || detail?.userId || '—'}
                </span>
              </div>
              <div className="modal__subtitle">Learner Diagnostic &amp; Performance Profile</div>
            </div>
          </div>
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
            {/* Active Classroom Context Scope Banner & Class Switcher */}
            <div style={{
              background: isClassScoped
                ? 'linear-gradient(135deg, rgba(16, 185, 129, 0.12), rgba(5, 150, 105, 0.05))'
                : 'linear-gradient(135deg, rgba(37, 99, 235, 0.08), rgba(29, 78, 216, 0.04))',
              border: isClassScoped
                ? '1.5px solid rgba(16, 185, 129, 0.40)'
                : '1.5px solid rgba(37, 99, 235, 0.25)',
              borderRadius: 12,
              padding: '12px 16px',
              marginBottom: 20,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              flexWrap: 'wrap',
              gap: 12,
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                <div style={{
                  width: 38, height: 38, borderRadius: 10,
                  background: isClassScoped ? '#10b981' : '#3b82f6', color: '#fff',
                  display: 'grid', placeItems: 'center',
                  fontSize: '1.1rem', fontWeight: 800, flexShrink: 0,
                  boxShadow: isClassScoped ? '0 2px 8px rgba(16, 185, 129, 0.3)' : '0 2px 8px rgba(37, 99, 235, 0.3)',
                }}>{isClassScoped ? '🏫' : '🌍'}</div>
                <div>
                  <div style={{ fontWeight: 800, color: isClassScoped ? '#065f46' : '#1e40af', fontSize: '0.92rem', display: 'flex', alignItems: 'center', gap: 8, flexWrap: 'wrap' }}>
                    {isClassScoped ? (
                      <span>Active Classroom Scope: <u>{targetClassName || (isTeacher ? 'All Assigned Classes (Combined Scope)' : 'Classroom Scope')}</u></span>
                    ) : (
                      <span>Active Scope: <u>Global (Platform-Wide &amp; Lifetime)</u></span>
                    )}
                    {targetClassCode && (
                      <span style={{
                        fontFamily: 'monospace', fontSize: '0.78rem',
                        background: 'rgba(5, 150, 105, 0.15)',
                        padding: '2px 8px', borderRadius: 6,
                        color: '#047857', fontWeight: 700
                      }}>
                        Code: {targetClassCode}
                      </span>
                    )}
                  </div>
                  <div style={{ fontSize: '0.78rem', color: isClassScoped ? '#047857' : '#2563eb', marginTop: 3 }}>
                    {isClassScoped
                      ? 'Showing performance metrics and lessons recorded strictly within this classroom context. Global activities and words are excluded.'
                      : 'Showing performance metrics, mastered words, and curriculum lessons across the entire global platform.'}
                  </div>
                </div>
              </div>

              {/* Class Switcher Dropdown */}
              {enrolledClasses.length > 0 && (
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, flexWrap: 'wrap' }}>
                  <label style={{ fontSize: '0.78rem', fontWeight: 800, color: isClassScoped ? '#065f46' : '#1e40af' }}>
                    Switch Scope:
                  </label>
                  <select
                    value={selectedClassId || ''}
                    onChange={(e) => setSelectedClassId(e.target.value || null)}
                    style={{
                      padding: '5px 12px',
                      borderRadius: 8,
                      border: isClassScoped ? '1.5px solid #10b981' : '1.5px solid #3b82f6',
                      background: '#fff',
                      fontWeight: 700,
                      fontSize: '0.82rem',
                      color: isClassScoped ? '#065f46' : '#1e40af',
                      cursor: 'pointer',
                      boxShadow: '0 1px 3px rgba(0,0,0,0.08)',
                    }}
                  >
                    <option value="">{isTeacher ? '🏫 All Classes (Combined View)' : '🌍 Global Scope (Platform Lifetime)'}</option>
                    {enrolledClasses.map(cls => (
                      <option key={cls.class_id || cls.classId} value={cls.class_id || cls.classId}>
                        🏫 {cls.class_name || cls.className} ({cls.class_code || cls.classCode})
                      </option>
                    ))}
                  </select>
                </div>
              )}
            </div>

            {/* Multi-Class Comparison Bar (When student is in multiple classes) */}
            {enrolledClasses.length > 1 && (
              <div style={{
                marginBottom: 20,
                background: 'var(--color-surface, #fff)',
                border: '1.5px solid var(--color-border)',
                borderRadius: 12,
                padding: '14px 16px',
              }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10, flexWrap: 'wrap', gap: 8 }}>
                  <div style={{ fontWeight: 800, fontSize: '0.9rem', color: 'var(--color-text-main)', display: 'flex', alignItems: 'center', gap: 6 }}>
                    <span>🏫 Multi-Class Comparison ({enrolledClasses.length} Classes)</span>
                  </div>
                  <span style={{ fontSize: '0.75rem', color: 'var(--color-text-muted)' }}>
                    Click a class card to isolate its lessons &amp; diagnostics
                  </span>
                </div>
                <div style={{
                  display: 'grid',
                  gridTemplateColumns: 'repeat(auto-fit, minmax(210px, 1fr))',
                  gap: 10,
                }}>
                  {enrolledClasses.map(cls => {
                    const cid = cls.class_id || cls.classId;
                    const cname = cls.class_name || cls.className;
                    const ccode = cls.class_code || cls.classCode;
                    const cpts = cls.class_points ?? cls.classPoints ?? 0;
                    const cacc = cls.class_accuracy ?? cls.classAccuracy ?? 0;
                    const csess = cls.class_sessions_played ?? cls.classSessionsPlayed ?? 0;
                    const isCurrent = (selectedClassId === cid);

                    return (
                      <div
                        key={cid}
                        onClick={() => setSelectedClassId(cid)}
                        style={{
                          padding: '10px 12px',
                          borderRadius: 10,
                          border: isCurrent ? '2px solid #10b981' : '1px solid var(--color-border)',
                          background: isCurrent ? 'rgba(16, 185, 129, 0.08)' : 'var(--color-surface-2, #f8fafc)',
                          cursor: 'pointer',
                          transition: 'all 0.15s ease-in-out',
                        }}
                      >
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 4 }}>
                          <strong style={{ fontSize: '0.85rem', color: isCurrent ? '#065f46' : 'var(--color-text-main)' }}>
                            {cname}
                          </strong>
                          {isCurrent && (
                            <span className="status-pill status-pill--success" style={{ fontSize: '0.65rem', padding: '1px 5px' }}>
                              SELECTED
                            </span>
                          )}
                        </div>
                        <div style={{ fontFamily: 'monospace', fontSize: '0.72rem', color: 'var(--color-text-muted)', marginBottom: 6 }}>
                          Code: {ccode}
                        </div>
                        <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.78rem' }}>
                          <span style={{ fontWeight: 700, color: '#059669' }}>{cpts.toLocaleString()} pts</span>
                          <span style={{ fontWeight: 700, color: Number(cacc) >= 70 ? 'var(--color-success)' : Number(cacc) > 0 ? 'var(--color-danger)' : 'var(--color-text-muted)' }}>
                            {Number(cacc) > 0 ? `${Number(cacc).toFixed(1)}%` : '—'}
                          </span>
                          <span style={{ color: 'var(--color-text-muted)' }}>{csess} sess</span>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            )}

            {/* Dual Score & Header info */}
            <div style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(170px, 1fr))',
              gap: 12,
              marginBottom: 20
            }}>
              {/* Score Card: Class-specific when scoped, Global when in global admin view */}
              {isClassScoped ? (
                <div className="retention-mini-card" style={{
                  background: 'linear-gradient(135deg, rgba(16, 185, 129, 0.08), rgba(5, 150, 105, 0.04))',
                  border: '1.5px solid rgba(16, 185, 129, 0.35)',
                }}>
                  <div className="retention-mini-card__label" style={{ color: '#059669', fontWeight: 800 }}>
                    🏫 In-Class Score {targetClassName ? `(${targetClassName})` : isMultiClassCombined ? '(All Classes)' : ''}
                  </div>
                  <div className="retention-mini-card__value" style={{ color: '#059669' }}>
                    {(classPts ?? totalPts)?.toLocaleString()} pts
                  </div>
                  <div className="retention-mini-card__sub" style={{ fontWeight: 600, color: '#047857' }}>
                    {(classAcc ?? overallAcc) != null ? `${Number(classAcc ?? overallAcc).toFixed(1)}% Class Acc` : '—'} · {(classSessions ?? detail?.total_sessions_played ?? 0)} sessions
                  </div>
                </div>
              ) : (
                <div className="retention-mini-card retention-mini-card--gold">
                  <div className="retention-mini-card__label">🌍 Global Score (All-Time Everywhere)</div>
                  <div className="retention-mini-card__value" style={{ color: Number(overallAcc) >= 70 ? 'var(--color-success)' : 'var(--color-danger)' }}>
                    {totalPts?.toLocaleString()} pts
                  </div>
                  <div className="retention-mini-card__sub">
                    {Number(overallAcc).toFixed(1)}% Overall Acc (All Activities)
                  </div>
                </div>
              )}

              <div className="retention-mini-card" style={{
                background: 'linear-gradient(135deg, rgba(37, 99, 235, 0.08), rgba(29, 78, 216, 0.04))',
                border: '1.5px solid rgba(37, 99, 235, 0.35)',
              }}>
                <div className="retention-mini-card__label" style={{ color: '#1d4ed8', fontWeight: 800 }}>
                  🆔 Student User ID
                </div>
                <div className="retention-mini-card__value" style={{ fontFamily: 'monospace', fontSize: '1.15rem', fontWeight: 800, color: '#1d4ed8' }}>
                  {detail?.user_id || detail?.userId || '—'}
                </div>
                <div className="retention-mini-card__sub" style={{ color: '#2563eb', fontWeight: 600 }}>
                  System ID (XX-XXXX-XXX)
                </div>
              </div>

              <div className="retention-mini-card retention-mini-card--blue">
                <div className="retention-mini-card__label">{isClassScoped ? 'Active Class' : 'Class / Section'}</div>
                <div className="retention-mini-card__value" style={{ fontSize: '1.1rem', fontWeight: 700 }}>
                  {sectionName}
                </div>
                <div className="retention-mini-card__sub">Grade: {gradeLevel ? gradeLevel.replace('_', ' ') : 'N/A'}</div>
              </div>

              <div className="retention-mini-card retention-mini-card--bronze">
                <div className="retention-mini-card__label">{isClassScoped ? 'Class Mastered Words' : 'Mastered Words'}</div>
                <div className="retention-mini-card__value" style={{ color: 'var(--primary-mid)' }}>
                  {masteredWords}
                </div>
                <div className="retention-mini-card__sub">{isClassScoped ? `Class Lessons: ${lessons.length}` : `Global Lessons: ${lessons.length}`}</div>
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

            {/* Part of Speech (POS) Accuracy Breakdown */}
            {posBreakdown.length > 0 && (
              <div style={{ marginBottom: 24 }}>
                <h3 style={{ fontSize: '0.95rem', fontWeight: 700, margin: '0 0 12px 0', color: 'var(--color-text-main)' }}>
                  🏷️ Accuracy by Part of Speech (POS)
                </h3>
                <div style={{
                  display: 'grid',
                  gridTemplateColumns: 'repeat(auto-fit, minmax(160px, 1fr))',
                  gap: 10,
                }}>
                  {posBreakdown.map((pb, idx) => {
                    const pos = pb.part_of_speech || pb.partOfSpeech || 'OTHER';
                    const acc = Number(pb.accuracy ?? 0);
                    const att = pb.total_attempts ?? pb.totalAttempts ?? 0;
                    const corr = pb.correct_count ?? pb.correctCount ?? 0;
                    const wordsCount = pb.total_words ?? pb.totalWords ?? 0;
                    const color = acc >= 85 ? '#10b981' : acc >= 70 ? '#3b82f6' : acc >= 50 ? '#f59e0b' : '#ef4444';

                    return (
                      <div
                        key={idx}
                        style={{
                          background: 'var(--color-surface, #fff)',
                          border: '1px solid var(--color-border)',
                          borderRadius: 10,
                          padding: '10px 12px',
                          display: 'flex',
                          flexDirection: 'column',
                          gap: 6,
                        }}
                      >
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                          <span style={{ fontSize: '0.78rem', fontWeight: 800, textTransform: 'uppercase', color: 'var(--color-text-main)' }}>
                            {pos}
                          </span>
                          <span style={{ fontSize: '0.85rem', fontWeight: 800, color: color }}>
                            {acc.toFixed(1)}%
                          </span>
                        </div>
                        <div style={{
                          height: 5,
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
                          }} />
                        </div>
                        <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.7rem', color: 'var(--color-text-muted)' }}>
                          <span>{wordsCount} words</span>
                          <span>{corr}/{att} correct</span>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            )}

            {/* Lesson Progress Breakdown */}
            <div style={{ marginBottom: 24 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
                <h3 style={{ fontSize: '0.95rem', fontWeight: 700, margin: 0, color: 'var(--color-text-main)' }}>
                  📖 Lesson Progress ({lessons.length} lessons)
                </h3>
              </div>

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
                          {isClassScoped ? 'No lessons published in this classroom yet.' : 'No lesson activity recorded yet.'}
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

                      const clampScore = (val) => {
                        if (val == null) return null;
                        const num = Number(val);
                        return isNaN(num) ? null : Math.min(100, Math.max(0, num));
                      };

                      const m1Completed = (rawM1 != null || rawM2 != null || isCompleted);
                      const m2 = clampScore(rawM2);
                      const m3 = clampScore(rawM3);
                      const m4 = clampScore(rawM4);
                      const safeMScore = clampScore(mScore);
                      const lastPracticed = lb.last_practiced_at || lb.lastPracticedAt || lb.completed_at || lb.completedAt || detail?.last_active_at || detail?.lastActiveAt;

                      return (
                        <tr key={lesId}>
                          <td>
                            <strong>{lesTitle}</strong>
                          </td>
                          <td>
                            <span className={`status-pill ${
                              statusVal === 'COMPLETED' ? 'status-pill--success'
                              : statusVal === 'IN_PROGRESS' ? 'status-pill--warning'
                              : 'status-pill--neutral'
                            }`}>
                              {statusVal || 'Not Started'}
                            </span>
                          </td>
                          <td style={{ fontWeight: 700 }}>
                            {safeMScore != null ? `${safeMScore.toFixed(0)}%` : '—'}
                          </td>
                          <td>
                            {m1Completed ? (
                              <span style={{ color: 'var(--color-success, #16a34a)', fontWeight: 600 }}>Done</span>
                            ) : '—'}
                          </td>
                          <td>{m2 != null ? `${m2.toFixed(0)}%` : '—'}</td>
                          <td>{m3 != null ? `${m3.toFixed(0)}%` : '—'}</td>
                          <td>{m4 != null ? `${m4.toFixed(0)}%` : '—'}</td>
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

            {/* Cumulative Review & Long-Term Retention Section (Only in Global Scope) */}
            {!isClassScoped && (detail?.cumulative_reviews || detail?.cumulativeReviews || []).length > 0 && (
              <div style={{ marginBottom: 24 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
                  <h3 style={{ fontSize: '0.95rem', fontWeight: 700, margin: 0, color: 'var(--color-text-main)' }}>
                    🌟 Cumulative Review &amp; Retention Performance
                  </h3>
                  <span className="table-meta" style={{ margin: 0 }}>
                    ({detail?.cumulative_reviews_completed ?? detail?.cumulativeReviewsCompleted ?? (detail?.cumulative_reviews || detail?.cumulativeReviews || []).length} completed sessions)
                  </span>
                </div>

                {/* Cumulative Summary Cards */}
                <div style={{
                  display: 'grid',
                  gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
                  gap: 12,
                  marginBottom: 16
                }}>
                  <div className="retention-mini-card retention-mini-card--blue-soft">
                    <div className="retention-mini-card__label">Reviews Completed</div>
                    <div className="retention-mini-card__value" style={{ color: 'var(--primary-mid)' }}>
                      {detail?.cumulative_reviews_completed ?? detail?.cumulativeReviewsCompleted ?? (detail?.cumulative_reviews || detail?.cumulativeReviews || []).length}
                    </div>
                  </div>
                  <div className="retention-mini-card retention-mini-card--blue">
                    <div className="retention-mini-card__label">Avg Retention Score</div>
                    <div className="retention-mini-card__value" style={{
                      color: ((detail?.cumulative_reviews_completed ?? detail?.cumulativeReviewsCompleted ?? (detail?.cumulative_reviews || detail?.cumulativeReviews || []).length) > 0 && (detail?.avg_cumulative_score ?? detail?.avgCumulativeScore) != null)
                        ? (Number(detail?.avg_cumulative_score ?? detail?.avgCumulativeScore) >= 70 ? 'var(--color-success)' : 'var(--primary-mid)')
                        : 'var(--color-text-dim)',
                    }}>
                      {((detail?.cumulative_reviews_completed ?? detail?.cumulativeReviewsCompleted ?? (detail?.cumulative_reviews || detail?.cumulativeReviews || []).length) > 0 && (detail?.avg_cumulative_score ?? detail?.avgCumulativeScore) != null)
                        ? `${Number(detail?.avg_cumulative_score ?? detail?.avgCumulativeScore).toFixed(1)}%`
                        : '—'}
                    </div>
                  </div>
                  <div className="retention-mini-card retention-mini-card--gold">
                    <div className="retention-mini-card__label">Best Badge Earned</div>
                    <div className="retention-mini-card__value" style={{ fontSize: '1.05rem', fontWeight: 700 }}>
                      {(detail?.best_cumulative_badge || detail?.bestCumulativeBadge) === 'PERFECT_GOLD' && '🏆 Perfect Gold'}
                      {(detail?.best_cumulative_badge || detail?.bestCumulativeBadge) === 'GOLD' && '🥇 Gold'}
                      {(detail?.best_cumulative_badge || detail?.bestCumulativeBadge) === 'SILVER' && '🥈 Silver'}
                      {(detail?.best_cumulative_badge || detail?.bestCumulativeBadge) === 'BRONZE' && '🥉 Bronze'}
                      {!(detail?.best_cumulative_badge || detail?.bestCumulativeBadge) && <span className="text-muted" style={{ fontWeight: 500, fontSize: '0.85rem' }}>No badges yet</span>}
                    </div>
                  </div>
                </div>

                {/* Cumulative Sessions Table */}
                <div className="accounts-table-wrap">
                  <table className="accounts-table">
                    <thead>
                      <tr>
                        <th>Lesson Pair / Category</th>
                        <th>Overall Accuracy</th>
                        <th>Session Accuracy</th>
                        <th>Badge</th>
                        <th>Points Earned</th>
                        <th>Questions</th>
                        <th>Date Completed</th>
                      </tr>
                    </thead>
                    <tbody>
                      {(!detail?.cumulative_reviews && !detail?.cumulativeReviews || (detail?.cumulative_reviews || detail?.cumulativeReviews).length === 0) ? (
                        <tr>
                          <td colSpan={7} style={{ textAlign: 'center', color: 'var(--color-text-muted)', padding: 20 }}>
                            No cumulative review sessions completed yet.
                          </td>
                        </tr>
                      ) : (
                        (detail?.cumulative_reviews || detail?.cumulativeReviews).map((cs, idx) => {
                          const sid = cs.session_id || cs.sessionId || idx;
                          const pairName = cs.category_name || cs.categoryName || cs.lesson_pair_id || cs.lessonPairId || 'Cumulative Review';
                          const lessonNames = cs.lesson_names || cs.lessonNames;
                          const overallAcc = cs.overall_accuracy ?? cs.overallAccuracy;
                          const acc = cs.accuracy_percent ?? cs.accuracyPercent;
                          const badge = cs.badge_awarded || cs.badgeAwarded;
                          const pts = cs.points_earned ?? cs.pointsEarned ?? 0;
                          const corr = cs.correct_count ?? cs.correctCount ?? 0;
                          const tot = cs.total_attempts ?? cs.totalAttempts ?? 0;
                          const compDate = cs.completed_at || cs.completedAt;

                          return (
                            <tr key={sid}>
                              <td>
                                <strong>{pairName}</strong>
                                {lessonNames && <div style={{ fontSize: '0.8rem', color: 'var(--color-text-muted)', marginTop: '4px' }}>{lessonNames}</div>}
                              </td>
                              <td style={{ fontWeight: 700, color: Number(overallAcc) >= 80 ? 'var(--color-success)' : 'var(--color-text-main)' }}>
                                {overallAcc != null ? `${Number(overallAcc).toFixed(2)}%` : '—'}
                              </td>
                              <td style={{ fontWeight: 700, color: Number(acc) >= 80 ? 'var(--color-success)' : 'var(--color-text-main)' }}>
                                {acc != null ? `${Number(acc).toFixed(1)}%` : '—'}
                              </td>
                              <td>
                                {badge === 'PERFECT_GOLD' && <span className="status-pill status-pill--warning">🏆 Perfect Gold</span>}
                                {badge === 'GOLD' && <span className="status-pill status-pill--warning">🥇 Gold</span>}
                                {badge === 'SILVER' && <span className="status-pill status-pill--neutral">🥈 Silver</span>}
                                {badge === 'BRONZE' && <span className="status-pill status-pill--neutral">🥉 Bronze</span>}
                                {!badge && <span className="text-muted">—</span>}
                              </td>
                              <td style={{ fontWeight: 700, color: 'var(--primary-mid)' }}>+{pts} pts</td>
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
            )}

            {/* All Words Practiced (Full Diagnostic Breakdown with POS & Accuracy) */}
            {allWords.length > 0 && (
              <div style={{ marginBottom: 24 }}>
                <h3 style={{ fontSize: '0.95rem', fontWeight: 700, marginBottom: 12, display: 'flex', alignItems: 'center', gap: 8, color: 'var(--color-text-main)' }}>
                  <span>📚 Per-Word Diagnostic &amp; Accuracy ({allWords.length} words practiced)</span>
                </h3>

                <div className="accounts-table-wrap" style={{ maxHeight: 300, overflowY: 'auto' }}>
                  <table className="accounts-table">
                    <thead>
                      <tr>
                        <th>Word</th>
                        <th>Part of Speech</th>
                        <th>Cebuano Meaning</th>
                        <th>Lesson</th>
                        <th title="Accuracy achieved in the learner's latest practice session">Session Accuracy</th>
                        <th title="Cumulative historical accuracy across all attempts and retries across all lessons">Lifetime Acc</th>
                        <th>Demerits</th>
                        <th>Attempts</th>
                      </tr>
                    </thead>
                    <tbody>
                      {allWords.map(w => {
                        const wid = w.word_id || w.wordId;
                        const eng = w.english_word || w.englishWord;
                        const pos = w.part_of_speech || w.partOfSpeech;
                        const ceb = w.cebuano_meaning || w.cebuanoMeaning;
                        const les = w.lesson_title || w.lessonTitle;
                        const dem = w.demerit_points ?? w.demeritPoints ?? 0;
                        const att = w.total_attempts ?? w.totalAttempts ?? ((w.correct_count || 0) + (w.incorrect_count || 0));
                        const corr = w.correct_count ?? w.correctCount ?? 0;
                        const rawSessionAcc = w.session_accuracy ?? w.sessionAccuracy ?? w.lesson_accuracy ?? w.lessonAccuracy;
                        const rawLifetimeAcc = w.lifetime_accuracy ?? w.lifetimeAccuracy;
                        const lifetimeAcc = rawLifetimeAcc != null
                          ? Number(rawLifetimeAcc)
                          : (att > 0 ? (corr * 100 / att) : (w.accuracy != null ? Number(w.accuracy) : 0));
                        const sessionAcc = rawSessionAcc != null
                          ? Number(rawSessionAcc)
                          : lifetimeAcc;
                        const sessionAtt = w.session_attempts ?? w.sessionAttempts ?? att;
                        const sessionCorr = w.session_correct ?? w.sessionCorrect ?? corr;

                        return (
                          <tr key={wid}>
                            <td><strong>{eng}</strong></td>
                            <td>
                              {pos ? (
                                <span style={{
                                  fontSize: '0.7rem', fontWeight: 800, padding: '2px 6px',
                                  borderRadius: 6, background: '#f1f5f9', color: '#475569',
                                  border: '1px solid #cbd5e1',
                                }}>
                                  {pos}
                                </span>
                              ) : <span className="text-muted">—</span>}
                            </td>
                            <td className="text-muted">{ceb}</td>
                            <td className="text-muted">{les}</td>
                            <td style={{ color: Number(sessionAcc) < 70 ? 'var(--color-danger)' : Number(sessionAcc) >= 85 ? 'var(--color-success)' : 'var(--color-text-main)', fontWeight: 700 }}>
                              <div>
                                {sessionAcc != null ? `${Number(sessionAcc).toFixed(1)}%` : '0.0%'}
                              </div>
                              <div style={{ fontSize: '0.68rem', fontWeight: 500, color: 'var(--color-text-muted)', marginTop: 2 }}>
                                {sessionAtt > 0 ? `${sessionCorr}/${sessionAtt} session` : 'No session'}
                              </div>
                            </td>
                            <td style={{ color: Number(lifetimeAcc) < 70 ? 'var(--color-danger)' : Number(lifetimeAcc) >= 85 ? 'var(--color-success)' : 'var(--color-text-main)', fontWeight: 600 }}>
                              <span title={`Lifetime cumulative: ${corr} / ${att} correct across all lessons and retries`}>
                                <div>
                                  {lifetimeAcc != null ? `${Number(lifetimeAcc).toFixed(1)}%` : '0.0%'}
                                </div>
                                <div style={{ fontSize: '0.68rem', fontWeight: 500, color: 'var(--color-text-muted)', marginTop: 2 }}>
                                  {att > 0 ? `${corr}/${att} lifetime` : '0 attempts'}
                                </div>
                              </span>
                            </td>
                            <td style={{ color: Number(dem) > 0 ? 'var(--color-danger)' : 'inherit', fontWeight: 600 }} title={`${Math.round(dem / 2)} errors (${dem} demerits)`}>
                              {dem || 0}
                            </td>
                            <td title={`${corr} correct out of ${att} total attempts`}>
                              {att || 0}
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              </div>
            )}

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
