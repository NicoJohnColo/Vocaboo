import { useState, useEffect, useCallback } from 'react';
import AdminNav from '../components/AdminNav';
import LearnerDetailModal from '../components/LearnerDetailModal';
import { TeacherClassService } from '../services/TeacherClassService';
import { useAdminAuth } from '../hooks/useAdminAuth';

export default function TeacherClassManagementPage() {
  const { admin } = useAdminAuth();
  const isTeacher = admin?.role === 'teacher';

  const [classes, setClasses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  // Modals
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [newClassName, setNewClassName] = useState('');
  const [newClassGrade, setNewClassGrade] = useState('GRADE_4');
  const [creating, setCreating] = useState(false);

  const [selectedClassId, setSelectedClassId] = useState(null);
  const [classDetail, setClassDetail] = useState(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [detailTab, setDetailTab] = useState('roster'); // 'roster' | 'requests' | 'invitations' | 'lessons'
  const [selectedLearnerForModal, setSelectedLearnerForModal] = useState(null);
  const [studentToUnenroll, setStudentToUnenroll] = useState(null);
  const [unenrolling, setUnenrolling] = useState(false);

  // Invitation Form
  const [inviteLearnerId, setInviteLearnerId] = useState('');
  const [inviting, setInviting] = useState(false);

  const flash = (msg) => {
    setSuccess(msg);
    setTimeout(() => setSuccess(''), 3500);
  };

  const loadClasses = useCallback(async () => {
    setLoading(true);
    try {
      const list = await TeacherClassService.getClasses();
      setClasses(list);
    } catch {
      setError('Failed to load classes.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadClasses();
  }, [loadClasses]);

  const loadClassDetail = async (id) => {
    setSelectedClassId(id);
    setDetailLoading(true);
    try {
      const detail = await TeacherClassService.getClassDetail(id);
      setClassDetail(detail);
    } catch {
      setError('Failed to load class details.');
    } finally {
      setDetailLoading(false);
    }
  };

  const handleCreateClass = async (e) => {
    e.preventDefault();
    if (!newClassName.trim()) return;
    setCreating(true);
    try {
      const created = await TeacherClassService.createClass(newClassName.trim(), newClassGrade);
      flash(`Class "${created.name}" (${created.gradeLevel ? created.gradeLevel.replace('_', ' ') : newClassGrade.replace('_', ' ')}) created! Code: ${created.classCode}`);
      setNewClassName('');
      setNewClassGrade('GRADE_4');
      setShowCreateModal(false);
      loadClasses();
    } catch (err) {
      setError(err.message || 'Failed to create class');
    } finally {
      setCreating(false);
    }
  };

  const handleUnenrollStudent = async () => {
    if (!studentToUnenroll || !selectedClassId) return;
    setUnenrolling(true);
    try {
      await TeacherClassService.unenrollStudent(selectedClassId, studentToUnenroll.learnerId);
      flash(`Unenrolled ${studentToUnenroll.displayName} from class.`);
      setStudentToUnenroll(null);
      loadClassDetail(selectedClassId);
      loadClasses();
    } catch (err) {
      setError(err.message || 'Failed to unenroll student');
    } finally {
      setUnenrolling(false);
    }
  };

  const handleReviewRequest = async (requestId, status) => {
    try {
      await TeacherClassService.reviewJoinRequest(selectedClassId, requestId, status);
      flash(`Request ${status.toLowerCase()}!`);
      loadClassDetail(selectedClassId);
      loadClasses();
    } catch (err) {
      setError(err.message || 'Failed to review request');
    }
  };

  const handleInviteLearner = async (e) => {
    e.preventDefault();
    if (!inviteLearnerId.trim()) return;
    setInviting(true);
    try {
      await TeacherClassService.inviteLearner(selectedClassId, inviteLearnerId.trim());
      flash('Invitation sent successfully!');
      setInviteLearnerId('');
      loadClassDetail(selectedClassId);
    } catch (err) {
      setError(err.message || 'Failed to invite learner');
    } finally {
      setInviting(false);
    }
  };

  const copyCode = (code) => {
    navigator.clipboard.writeText(code);
    flash(`Copied ${code} to clipboard!`);
  };

  return (
    <div className="admin-layout">
      <AdminNav />
      <main className="admin-main">
        {/* Header */}
        <header className="admin-main__header">
          <div>
            <h1 className="admin-main__title">
              {isTeacher ? '🏫 My Classes' : '🏫 Teacher Classrooms & Rosters (View Only)'}
            </h1>
            <p className="admin-main__subtitle">
              {isTeacher
                ? 'Manage classroom cohorts, unique student join codes, invitations, and class-specific lessons'
                : 'View teacher classroom cohorts, student rosters, performance metrics, and class lessons'}
            </p>
          </div>
          {isTeacher && (
            <button
              type="button"
              className="btn btn--primary"
              onClick={() => setShowCreateModal(true)}
              style={{ display: 'flex', alignItems: 'center', gap: 8 }}
            >
              <span>+</span> Create New Class
            </button>
          )}
        </header>

        {/* Alerts */}
        {error && (
          <div className="alert alert--error" onClick={() => setError('')} style={{ cursor: 'pointer' }}>
            {error}
          </div>
        )}
        {success && (
          <div className="alert alert--success">
            {success}
          </div>
        )}

        {/* Main Content */}
        {loading ? (
          <div className="auth-loading" style={{ minHeight: 300 }}>
            <div className="spinner" />
          </div>
        ) : classes.length === 0 ? (
          <div className="coming-soon" style={{ margin: '40px 0' }}>
            <div className="coming-soon__icon">🏫</div>
            <div className="coming-soon__title">No classes created yet</div>
            <p className="coming-soon__text">
              Create your first classroom to generate a unique <strong>VOC-XXXX</strong> code for students to join.
            </p>
            <button
              type="button"
              className="btn btn--primary"
              onClick={() => setShowCreateModal(true)}
              style={{ marginTop: 16 }}
            >
              + Create First Class
            </button>
          </div>
        ) : (
          <div>
            {/* Quick Stats Summary */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: 16, marginBottom: 24 }}>
              <div style={{
                background: 'var(--color-surface)',
                border: '1px solid var(--color-border)',
                borderRadius: 'var(--radius-lg)',
                padding: '16px 20px',
                display: 'flex',
                alignItems: 'center',
                gap: 14,
              }}>
                <div style={{
                  width: 44, height: 44, borderRadius: 12,
                  background: 'rgba(37, 99, 235, 0.1)',
                  color: 'var(--primary-mid)',
                  display: 'grid', placeItems: 'center',
                  fontSize: '1.3rem', flexShrink: 0,
                }}>🏫</div>
                <div>
                  <div style={{ fontSize: '0.8rem', color: 'var(--color-text-muted)', fontWeight: 600 }}>Active Classes</div>
                  <div style={{ fontSize: '1.4rem', fontWeight: 800, color: 'var(--color-text)' }}>{classes.length}</div>
                </div>
              </div>

              <div style={{
                background: 'var(--color-surface)',
                border: '1px solid var(--color-border)',
                borderRadius: 'var(--radius-lg)',
                padding: '16px 20px',
                display: 'flex',
                alignItems: 'center',
                gap: 14,
              }}>
                <div style={{
                  width: 44, height: 44, borderRadius: 12,
                  background: 'rgba(16, 185, 129, 0.1)',
                  color: '#10b981',
                  display: 'grid', placeItems: 'center',
                  fontSize: '1.3rem', flexShrink: 0,
                }}>👥</div>
                <div>
                  <div style={{ fontSize: '0.8rem', color: 'var(--color-text-muted)', fontWeight: 600 }}>Total Enrolled Students</div>
                  <div style={{ fontSize: '1.4rem', fontWeight: 800, color: 'var(--color-text)' }}>
                    {classes.reduce((sum, c) => sum + (Number(c.studentCount) || 0), 0)}
                  </div>
                </div>
              </div>
            </div>

            {/* Classes Table */}
            <div className="accounts-table-wrap">
              <table className="accounts-table">
                <thead>
                  <tr>
                    <th>Class Name</th>
                    <th>Grade Level</th>
                    <th>Student Join Code</th>
                    {!isTeacher && <th>Teacher & School</th>}
                    <th>Students</th>
                    <th>Created Date</th>
                    <th style={{ textAlign: 'right' }}>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {classes.map((cls) => (
                    <tr key={cls.classId}>
                      <td>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                          <div style={{
                            width: 34, height: 34, borderRadius: 10,
                            background: 'linear-gradient(135deg, #3b82f6, #1d4ed8)',
                            display: 'grid', placeItems: 'center',
                            fontSize: '1rem', flexShrink: 0,
                            boxShadow: '0 2px 8px rgba(37, 99, 235, 0.25)',
                          }}>🏫</div>
                          <div>
                            <span style={{ fontSize: '0.95rem', fontWeight: 700, color: 'var(--color-text)' }}>
                              {cls.name}
                            </span>
                          </div>
                        </div>
                      </td>
                      <td>
                        <span style={{
                          padding: '3px 10px',
                          borderRadius: 12,
                          fontSize: '0.78rem',
                          fontWeight: 700,
                          background: 'rgba(59, 130, 246, 0.1)',
                          color: '#2563eb',
                          border: '1px solid rgba(59, 130, 246, 0.25)',
                          display: 'inline-block',
                          whiteSpace: 'nowrap',
                        }}>
                          {cls.gradeLevel ? cls.gradeLevel.replace('_', ' ') : 'GRADE 4'}
                        </span>
                      </td>
                      <td>
                        <button
                          type="button"
                          onClick={() => copyCode(cls.classCode)}
                          className="status-pill status-pill--neutral"
                          style={{
                            display: 'inline-flex',
                            alignItems: 'center',
                            gap: 6,
                            fontFamily: 'monospace',
                            fontSize: '0.85rem',
                            fontWeight: 800,
                            background: 'rgba(37, 99, 235, 0.08)',
                            color: 'var(--primary-mid)',
                            borderColor: 'rgba(37, 99, 235, 0.25)',
                            cursor: 'pointer',
                            padding: '4px 10px',
                          }}
                          title="Click to copy code"
                        >
                          {cls.classCode} 📋
                        </button>
                      </td>
                      {!isTeacher && (
                        <td>
                          <span style={{ fontWeight: 600, color: 'var(--color-text)' }}>{cls.teacherName}</span>
                          {cls.teacherSchool && (
                            <div style={{ fontSize: '0.75rem', color: 'var(--color-text-muted)' }}>
                              {cls.teacherSchool}
                            </div>
                          )}
                        </td>
                      )}
                      <td>
                        <span className="status-pill status-pill--success" style={{ fontWeight: 700 }}>
                          {cls.studentCount} student{cls.studentCount === 1 ? '' : 's'}
                        </span>
                      </td>
                      <td>
                        <span style={{ fontSize: '0.82rem', color: 'var(--color-text-muted)' }}>
                          {cls.createdAt ? new Date(cls.createdAt).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }) : '—'}
                        </span>
                      </td>
                      <td style={{ textAlign: 'right' }}>
                        <button
                          type="button"
                          className="btn btn--sm btn--primary"
                          onClick={() => loadClassDetail(cls.classId)}
                        >
                          {isTeacher ? 'Manage Roster & Lessons →' : 'View Roster & Lessons →'}
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* ── CREATE CLASS MODAL ─────────────────────────────────────────── */}
        {showCreateModal && (
          <div className="modal-overlay" onClick={() => setShowCreateModal(false)}>
            <div className="modal modal--sm" onClick={(e) => e.stopPropagation()}>
              <div className="modal__header">
                <div>
                  <h2 className="modal__title">➕ Create New Class</h2>
                  <p className="modal__subtitle">Generate a unique classroom cohort and join code</p>
                </div>
                <button
                  type="button"
                  className="modal__close-btn"
                  onClick={() => setShowCreateModal(false)}
                >
                  ✕
                </button>
              </div>

              <form onSubmit={handleCreateClass}>
                <div className="form-field">
                  <label className="form-label">Class Name *</label>
                  <input
                    type="text"
                    className="form-input"
                    placeholder="e.g. Grade 4 - Rizal"
                    value={newClassName}
                    onChange={(e) => setNewClassName(e.target.value)}
                    required
                    autoFocus
                  />
                  <span className="form-hint" style={{ fontSize: '0.78rem', color: 'var(--color-text-muted)', marginTop: 4 }}>
                    A unique join code (e.g. <code>VOC-XXXX</code>) will be generated automatically for students to join.
                  </span>
                </div>

                <div className="form-field">
                  <label className="form-label">Grade Level *</label>
                  <select
                    className="form-input"
                    value={newClassGrade}
                    onChange={(e) => setNewClassGrade(e.target.value)}
                    required
                  >
                    <option value="GRADE_4">Grade 4</option>
                    <option value="GRADE_5">Grade 5</option>
                    <option value="GRADE_6">Grade 6</option>
                  </select>
                  <span className="form-hint" style={{ fontSize: '0.78rem', color: 'var(--color-text-muted)', marginTop: 4 }}>
                    Only learners belonging to this grade level can join this class and access its curriculum.
                  </span>
                </div>

                <div className="modal__actions" style={{ marginTop: 24 }}>
                  <button
                    type="button"
                    className="btn btn--ghost"
                    onClick={() => setShowCreateModal(false)}
                    disabled={creating}
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    className="btn btn--primary"
                    disabled={creating || !newClassName.trim()}
                  >
                    {creating ? <span className="spinner spinner--sm" /> : 'Create Class'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* ── CLASS DETAIL MODAL ─────────────────────────────────────────── */}
        {selectedClassId && (
          <div className="modal-overlay" onClick={() => setSelectedClassId(null)}>
            <div
              className="modal modal--xl"
              onClick={(e) => e.stopPropagation()}
            >
              {/* Modal Header */}
              <div className="modal__header">
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 10, flexWrap: 'wrap' }}>
                    <h2 className="modal__title" style={{ margin: 0, fontSize: '1.25rem', fontWeight: 800 }}>
                      {classDetail?.name || 'Class Details'}
                    </h2>
                    {classDetail?.gradeLevel && (
                      <span style={{
                        padding: '3px 10px',
                        borderRadius: 12,
                        fontSize: '0.75rem',
                        fontWeight: 700,
                        background: 'rgba(59, 130, 246, 0.1)',
                        color: '#2563eb',
                        border: '1px solid rgba(59, 130, 246, 0.25)',
                      }}>
                        {classDetail.gradeLevel.replace('_', ' ')}
                      </span>
                    )}
                    {!isTeacher && (
                      <span style={{
                        padding: '3px 8px',
                        borderRadius: 6,
                        fontSize: '0.72rem',
                        fontWeight: 700,
                        background: 'rgba(100, 116, 139, 0.12)',
                        color: '#475569',
                        border: '1px solid rgba(100, 116, 139, 0.25)',
                      }}>
                        👁️ View-Only Mode for Admin
                      </span>
                    )}
                    {classDetail?.classCode && (
                      <button
                        type="button"
                        onClick={() => copyCode(classDetail.classCode)}
                        className="status-pill status-pill--neutral"
                        style={{
                          display: 'inline-flex',
                          alignItems: 'center',
                          gap: 6,
                          fontFamily: 'monospace',
                          fontWeight: 800,
                          fontSize: '0.85rem',
                          background: 'rgba(37, 99, 235, 0.08)',
                          color: 'var(--primary-mid)',
                          borderColor: 'rgba(37, 99, 235, 0.25)',
                          cursor: 'pointer',
                        }}
                        title="Click to copy code"
                      >
                        Code: {classDetail.classCode} 📋
                      </button>
                    )}
                  </div>
                  <p className="modal__subtitle" style={{ marginTop: 4 }}>
                    Teacher: <strong>{classDetail?.teacherName}</strong>
                    {classDetail?.teacherSchool && ` • ${classDetail.teacherSchool}`}
                  </p>
                </div>
                <button
                  type="button"
                  className="modal__close-btn"
                  onClick={() => setSelectedClassId(null)}
                >
                  ✕
                </button>
              </div>

              {/* Detail Tabs */}
              <div style={{ display: 'flex', gap: 10, marginBottom: 20, flexWrap: 'wrap' }}>
                <button
                  type="button"
                  className={`btn btn--sm ${detailTab === 'roster' ? 'btn--primary' : 'btn--ghost'}`}
                  onClick={() => setDetailTab('roster')}
                  style={{ fontWeight: 700 }}
                >
                  👥 Student Roster ({classDetail?.enrolledLearners?.length || 0})
                </button>
                <button
                  type="button"
                  className={`btn btn--sm ${detailTab === 'requests' ? 'btn--primary' : 'btn--ghost'}`}
                  onClick={() => setDetailTab('requests')}
                  style={{
                    fontWeight: 700,
                    borderColor: (classDetail?.pendingJoinRequests?.length || 0) > 0 ? '#f59e0b' : undefined,
                  }}
                >
                  📩 Join Requests
                  {(classDetail?.pendingJoinRequests?.length || 0) > 0 && (
                    <span style={{
                      marginLeft: 6,
                      background: '#f59e0b',
                      color: '#ffffff',
                      padding: '2px 6px',
                      borderRadius: 10,
                      fontSize: '0.72rem',
                      fontWeight: 800,
                    }}>
                      {classDetail.pendingJoinRequests.length}
                    </span>
                  )}
                </button>
                <button
                  type="button"
                  className={`btn btn--sm ${detailTab === 'invitations' ? 'btn--primary' : 'btn--ghost'}`}
                  onClick={() => setDetailTab('invitations')}
                  style={{ fontWeight: 700 }}
                >
                  ✉️ Invitations ({classDetail?.pendingInvitations?.length || 0})
                </button>
                <button
                  type="button"
                  className={`btn btn--sm ${detailTab === 'lessons' ? 'btn--primary' : 'btn--ghost'}`}
                  onClick={() => setDetailTab('lessons')}
                  style={{ fontWeight: 700 }}
                >
                  📚 Class Lessons ({classDetail?.lessons?.length || 0})
                </button>
              </div>

              {detailLoading ? (
                <div className="auth-loading" style={{ minHeight: 200 }}>
                  <div className="spinner" />
                </div>
              ) : (
                <>
                  {/* TAB 1: Roster */}
                  {detailTab === 'roster' && (
                    <div>
                      {classDetail?.enrolledLearners?.length === 0 ? (
                        <div style={{
                          padding: 32,
                          textAlign: 'center',
                          color: 'var(--color-text-muted)',
                          background: 'var(--color-surface-2)',
                          borderRadius: 'var(--radius-lg)',
                          border: '1px solid var(--color-border)',
                        }}>
                          <p style={{ margin: '0 0 6px 0', fontWeight: 600, color: 'var(--color-text)' }}>
                            No students have joined this class yet
                          </p>
                          <p style={{ margin: 0, fontSize: '0.85rem' }}>
                            Give code <strong>{classDetail?.classCode}</strong> to your students so they can join via their Vocaboo mobile app!
                          </p>
                        </div>
                      ) : (
                        <div className="accounts-table-wrap">
                          <table className="accounts-table">
                            <thead>
                              <tr>
                                <th>Student</th>
                                <th>Grade</th>
                                <th>Age</th>
                                <th>Class Points</th>
                                <th>Class Accuracy</th>
                                <th>Sessions</th>
                                <th>Enrolled Date</th>
                                <th style={{ textAlign: 'right' }}>Actions</th>
                              </tr>
                            </thead>
                            <tbody>
                              {classDetail?.enrolledLearners?.map((st) => {
                                const pts = st.classPoints ?? 0;
                                const acc = st.classAccuracy ?? 0;
                                const sess = st.classSessionsPlayed ?? 0;

                                return (
                                  <tr key={st.enrollmentId}>
                                    <td style={{ minWidth: 200 }}>
                                      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                                        <div style={{
                                          width: 32, height: 32, borderRadius: '50%',
                                          background: 'linear-gradient(135deg, #3b82f6, #1d4ed8)',
                                          display: 'grid', placeItems: 'center',
                                          color: '#fff', fontSize: '0.82rem', fontWeight: 700, flexShrink: 0,
                                        }}>
                                          {st.displayName?.charAt(0)?.toUpperCase() || '?'}
                                        </div>
                                        <div style={{ display: 'flex', flexDirection: 'column' }}>
                                          <strong style={{ color: 'var(--color-text)' }}>{st.displayName}</strong>
                                          {(st.user_id || st.userId) && (
                                            <span style={{
                                              fontFamily: 'monospace',
                                              fontSize: '0.74rem',
                                              fontWeight: 700,
                                              color: '#1d4ed8',
                                              background: '#eff6ff',
                                              border: '1px solid #bfdbfe',
                                              borderRadius: 4,
                                              padding: '1px 6px',
                                              display: 'inline-block',
                                              marginTop: 2,
                                              width: 'fit-content',
                                              whiteSpace: 'nowrap',
                                              flexShrink: 0,
                                            }}>
                                              {st.user_id || st.userId}
                                            </span>
                                          )}
                                        </div>
                                      </div>
                                    </td>
                                    <td>
                                      {st.gradeLevel ? (
                                        <span style={{
                                          padding: '2px 8px',
                                          borderRadius: 10,
                                          fontSize: '0.74rem',
                                          fontWeight: 700,
                                          background: 'rgba(59, 130, 246, 0.1)',
                                          color: '#2563eb',
                                          border: '1px solid rgba(59, 130, 246, 0.25)',
                                          whiteSpace: 'nowrap',
                                        }}>
                                          {st.gradeLevel.replace('_', ' ')}
                                        </span>
                                      ) : '—'}
                                    </td>
                                    <td>{st.age ? `${st.age} yrs` : '—'}</td>
                                    <td style={{ fontWeight: 700, color: '#059669' }}>
                                      {pts.toLocaleString()} pts
                                    </td>
                                    <td>
                                      <span style={{
                                        fontWeight: 700,
                                        color: Number(acc) >= 70 ? 'var(--color-success)' : Number(acc) > 0 ? 'var(--color-danger)' : 'var(--color-text-muted)'
                                      }}>
                                        {Number(acc) > 0 ? `${Number(acc).toFixed(1)}%` : '—'}
                                      </span>
                                    </td>
                                    <td style={{ color: 'var(--color-text-muted)', fontWeight: 600 }}>
                                      {sess}
                                    </td>
                                    <td style={{ fontSize: '0.82rem', color: 'var(--color-text-muted)' }}>
                                      {st.enrolledAt ? new Date(st.enrolledAt).toLocaleDateString() : '—'}
                                    </td>
                                    <td style={{ textAlign: 'right', whiteSpace: 'nowrap' }}>
                                      <div style={{ display: 'inline-flex', gap: 6, justifyContent: 'flex-end', alignItems: 'center' }}>
                                        <button
                                          type="button"
                                          className="btn btn--sm btn--primary"
                                          style={{ display: 'inline-flex', alignItems: 'center', gap: 4, padding: '4px 10px', fontSize: '0.8rem' }}
                                          onClick={() => setSelectedLearnerForModal({
                                            learnerId: st.learnerId,
                                            classContext: {
                                              classId: selectedClassId,
                                              className: classDetail?.name,
                                              classCode: classDetail?.classCode
                                            }
                                          })}
                                          title="View student profile, word accuracy, and diagnostic breakdown"
                                        >
                                          🔍 Profile
                                        </button>
                                        {isTeacher && (
                                          <button
                                            type="button"
                                            className="btn btn--sm btn--ghost"
                                            style={{
                                              display: 'inline-flex',
                                              alignItems: 'center',
                                              gap: 4,
                                              padding: '4px 8px',
                                              fontSize: '0.8rem',
                                              color: '#dc2626',
                                              borderColor: 'rgba(220, 38, 38, 0.3)',
                                              background: 'rgba(220, 38, 38, 0.05)',
                                            }}
                                            onClick={() => setStudentToUnenroll(st)}
                                            title="Unenroll student from this class"
                                          >
                                            ✕ Unenroll
                                          </button>
                                        )}
                                      </div>
                                    </td>
                                  </tr>
                                );
                              })}
                            </tbody>
                          </table>
                        </div>
                      )}
                    </div>
                  )}

                  {/* TAB 2: Join Requests */}
                  {detailTab === 'requests' && (
                    <div>
                      {classDetail?.pendingJoinRequests?.length === 0 ? (
                        <div style={{
                          padding: 32,
                          textAlign: 'center',
                          color: 'var(--color-text-muted)',
                          background: 'var(--color-surface-2)',
                          borderRadius: 'var(--radius-lg)',
                          border: '1px solid var(--color-border)',
                        }}>
                          No pending join requests at this time.
                        </div>
                      ) : (
                        <div className="accounts-table-wrap">
                          <table className="accounts-table">
                            <thead>
                              <tr>
                                <th>Student</th>
                                <th>Age</th>
                                <th>Requested At</th>
                                <th style={{ textAlign: 'right' }}>Actions</th>
                              </tr>
                            </thead>
                            <tbody>
                              {classDetail?.pendingJoinRequests?.map((req) => (
                                <tr key={req.requestId}>
                                  <td>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                                      <div style={{
                                        width: 32, height: 32, borderRadius: '50%',
                                        background: 'linear-gradient(135deg, #f59e0b, #d97706)',
                                        display: 'grid', placeItems: 'center',
                                        color: '#fff', fontSize: '0.82rem', fontWeight: 700, flexShrink: 0,
                                      }}>
                                        {req.displayName?.charAt(0)?.toUpperCase() || '?'}
                                      </div>
                                      <div style={{ display: 'flex', flexDirection: 'column' }}>
                                        <strong style={{ color: 'var(--color-text)' }}>{req.displayName}</strong>
                                        {(req.user_id || req.userId) && (
                                          <span style={{
                                            fontFamily: 'monospace',
                                            fontSize: '0.74rem',
                                            fontWeight: 700,
                                            color: '#1d4ed8',
                                            background: '#eff6ff',
                                            border: '1px solid #bfdbfe',
                                            borderRadius: 4,
                                            padding: '1px 6px',
                                            display: 'inline-block',
                                            marginTop: 2,
                                            width: 'fit-content',
                                            whiteSpace: 'nowrap',
                                            flexShrink: 0,
                                          }}>
                                            {req.user_id || req.userId}
                                          </span>
                                        )}
                                      </div>
                                    </div>
                                  </td>
                                  <td>{req.age ? `${req.age} yrs` : '—'}</td>
                                  <td style={{ fontSize: '0.82rem', color: 'var(--color-text-muted)' }}>
                                    {req.createdAt ? new Date(req.createdAt).toLocaleString() : '—'}
                                  </td>
                                  <td style={{ textAlign: 'right' }}>
                                    {isTeacher ? (
                                      <div style={{ display: 'flex', gap: 8, justifyContent: 'flex-end' }}>
                                        <button
                                          type="button"
                                          className="btn btn--xs btn--primary"
                                          style={{ background: '#10b981', borderColor: '#10b981' }}
                                          onClick={() => handleReviewRequest(req.requestId, 'APPROVED')}
                                        >
                                          ✓ Approve
                                        </button>
                                        <button
                                          type="button"
                                          className="btn btn--xs btn--danger-ghost"
                                          onClick={() => handleReviewRequest(req.requestId, 'REJECTED')}
                                        >
                                          ✕ Reject
                                        </button>
                                      </div>
                                    ) : (
                                      <span className="status-pill status-pill--warning">
                                        Pending Review
                                      </span>
                                    )}
                                  </td>
                                </tr>
                              ))}
                            </tbody>
                          </table>
                        </div>
                      )}
                    </div>
                  )}

                  {/* TAB 3: Invitations */}
                  {detailTab === 'invitations' && (
                    <div>
                      {/* Invite Learner Form */}
                      {isTeacher ? (
                        <form onSubmit={handleInviteLearner} style={{ display: 'flex', gap: 10, marginBottom: 20 }}>
                          <input
                            type="text"
                            className="form-input"
                            placeholder="Enter student user ID (e.g. 26-0001-290) or UUID..."
                            value={inviteLearnerId}
                            onChange={(e) => setInviteLearnerId(e.target.value)}
                            style={{ flex: 1 }}
                          />
                          <button
                            type="submit"
                            className="btn btn--primary"
                            disabled={inviting || !inviteLearnerId.trim()}
                          >
                            {inviting ? <span className="spinner spinner--sm" /> : 'Send Invitation'}
                          </button>
                        </form>
                      ) : (
                        <p style={{ fontSize: '0.85rem', color: 'var(--color-text-muted)', marginBottom: 16 }}>
                          Student invitations are authored and managed exclusively by the assigned classroom teacher.
                        </p>
                      )}

                      {classDetail?.pendingInvitations?.length === 0 ? (
                        <div style={{
                          padding: 32,
                          textAlign: 'center',
                          color: 'var(--color-text-muted)',
                          background: 'var(--color-surface-2)',
                          borderRadius: 'var(--radius-lg)',
                          border: '1px solid var(--color-border)',
                        }}>
                          No pending invitations.
                        </div>
                      ) : (
                        <div className="accounts-table-wrap">
                          <table className="accounts-table">
                            <thead>
                              <tr>
                                <th>Student</th>
                                <th>Status</th>
                                <th>Sent Date</th>
                              </tr>
                            </thead>
                            <tbody>
                              {classDetail?.pendingInvitations?.map((inv) => (
                                <tr key={inv.invitationId}>
                                  <td>
                                    <div style={{ display: 'flex', flexDirection: 'column' }}>
                                      <strong style={{ color: 'var(--color-text)' }}>{inv.displayName || inv.learnerId}</strong>
                                      {(inv.user_id || inv.userId) && (
                                        <span style={{
                                          fontFamily: 'monospace',
                                          fontSize: '0.74rem',
                                          fontWeight: 700,
                                          color: '#1d4ed8',
                                          background: '#eff6ff',
                                          border: '1px solid #bfdbfe',
                                          borderRadius: 4,
                                          padding: '1px 6px',
                                          display: 'inline-block',
                                          marginTop: 2,
                                          width: 'fit-content',
                                          whiteSpace: 'nowrap',
                                          flexShrink: 0,
                                        }}>
                                          {inv.user_id || inv.userId}
                                        </span>
                                      )}
                                    </div>
                                  </td>
                                  <td>
                                    <span className="status-pill status-pill--warning">
                                      {inv.status}
                                    </span>
                                  </td>
                                  <td style={{ fontSize: '0.82rem', color: 'var(--color-text-muted)' }}>
                                    {inv.createdAt ? new Date(inv.createdAt).toLocaleString() : '—'}
                                  </td>
                                </tr>
                              ))}
                            </tbody>
                          </table>
                        </div>
                      )}
                    </div>
                  )}

                  {/* TAB 4: Class Lessons */}
                  {detailTab === 'lessons' && (
                    <div>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
                        <span style={{ fontSize: '0.85rem', color: 'var(--color-text-muted)' }}>
                          Lessons authored specifically for this classroom cohort.
                        </span>
                        <a
                          href="/lessons"
                          className="btn btn--sm btn--ghost"
                        >
                          Open Lesson Builder →
                        </a>
                      </div>

                      {classDetail?.lessons?.length === 0 ? (
                        <div style={{
                          padding: 32,
                          textAlign: 'center',
                          color: 'var(--color-text-muted)',
                          background: 'var(--color-surface-2)',
                          borderRadius: 'var(--radius-lg)',
                          border: '1px solid var(--color-border)',
                        }}>
                          No custom lessons added to this class yet.
                        </div>
                      ) : (
                        <div className="accounts-table-wrap">
                          <table className="accounts-table">
                            <thead>
                              <tr>
                                <th>Order</th>
                                <th>Lesson Title</th>
                                <th>Words</th>
                                <th>Status</th>
                              </tr>
                            </thead>
                            <tbody>
                              {classDetail?.lessons?.map((ls) => (
                                <tr key={ls.lessonId}>
                                  <td>#{ls.lessonOrder}</td>
                                  <td>
                                    <strong style={{ color: 'var(--color-text)' }}>{ls.lessonTitle}</strong>
                                  </td>
                                  <td>{ls.totalWordCount} words</td>
                                  <td>
                                    <span className="status-pill status-pill--success">
                                      {ls.contentStatus}
                                    </span>
                                  </td>
                                </tr>
                              ))}
                            </tbody>
                          </table>
                        </div>
                      )}
                    </div>
                  )}
                </>
              )}
            </div>
          </div>
        )}

        {/* ── LEARNER DETAIL MODAL ─────────────────────────────────────── */}
        {selectedLearnerForModal && (
          <LearnerDetailModal
            learnerId={selectedLearnerForModal.learnerId}
            classContext={selectedLearnerForModal.classContext}
            onClose={() => setSelectedLearnerForModal(null)}
            onResetProgress={() => {}}
            onEditProfile={() => {}}
          />
        )}

        {/* ── UNENROLL CONFIRMATION MODAL ─────────────────────────────────────── */}
        {studentToUnenroll && (
          <div className="modal-overlay" style={{ zIndex: 1100 }} onClick={() => !unenrolling && setStudentToUnenroll(null)}>
            <div className="modal modal--sm" onClick={(e) => e.stopPropagation()}>
              <div className="modal__header">
                <div>
                  <h2 className="modal__title" style={{ color: '#dc2626', display: 'flex', alignItems: 'center', gap: 6 }}>
                    <span>⚠️</span> Unenroll Student
                  </h2>
                  <p className="modal__subtitle">Remove student from classroom cohort</p>
                </div>
                <button
                  type="button"
                  className="modal__close-btn"
                  onClick={() => !unenrolling && setStudentToUnenroll(null)}
                  disabled={unenrolling}
                >
                  ✕
                </button>
              </div>

              <div style={{ padding: '16px 0', fontSize: '0.9rem', lineHeight: 1.5 }}>
                <p style={{ margin: '0 0 10px 0' }}>
                  Are you sure you want to remove <strong>{studentToUnenroll.displayName}</strong> from <strong>{classDetail?.name}</strong>?
                </p>
                <div style={{
                  padding: 12,
                  background: 'rgba(239, 68, 68, 0.08)',
                  border: '1px solid rgba(239, 68, 68, 0.25)',
                  borderRadius: 8,
                  fontSize: '0.8rem',
                  color: '#b91c1c',
                }}>
                  Removing this student unenrolls them from this class roster. They will no longer see or access this class or its custom lessons, but their individual lifetime vocabulary points and progress will remain intact.
                </div>
              </div>

              <div className="modal__actions" style={{ marginTop: 20 }}>
                <button
                  type="button"
                  className="btn btn--ghost"
                  onClick={() => setStudentToUnenroll(null)}
                  disabled={unenrolling}
                >
                  Cancel
                </button>
                <button
                  type="button"
                  className="btn btn--danger"
                  style={{ background: '#dc2626', color: '#fff', borderColor: '#dc2626' }}
                  onClick={handleUnenrollStudent}
                  disabled={unenrolling}
                >
                  {unenrolling ? <span className="spinner spinner--sm" /> : 'Confirm Unenroll'}
                </button>
              </div>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
