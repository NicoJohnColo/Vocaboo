import { useState, useEffect, useCallback } from 'react';
import AdminNav from '../components/AdminNav';
import { LearnerService } from '../services/LearnerService';
import { SectionService } from '../services/SectionService';
import { ReportService } from '../services/ReportService';
import LearnerDetailModal from '../components/LearnerDetailModal';
import ResetProgressModal from '../components/ResetProgressModal';
import AssignSectionModal from '../components/AssignSectionModal';
import ConfirmDeleteDialog from '../components/ConfirmDeleteDialog';

export default function LearnerManagementPage() {
  const [learners, setLearners] = useState([]);
  const [sections, setSections] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  // Search & Filter state
  const [search, setSearch] = useState('');
  const [cohortType, setCohortType] = useState(''); // '' | 'INDEPENDENT' | 'ENROLLED'
  const [sectionId, setSectionId] = useState('');
  const [gradeLevel, setGradeLevel] = useState('');
  const [isActive, setIsActive] = useState('');
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(1);
  const [totalElements, setTotalElements] = useState(0);

  // Selection for bulk actions
  const [selectedIds, setSelectedIds] = useState([]);

  // Modals
  const [detailLearnerId, setDetailLearnerId] = useState(null);
  const [resetTarget, setResetTarget] = useState(null);
  const [assignTarget, setAssignTarget] = useState(null); // single learner or array
  const [statusTarget, setStatusTarget] = useState(null); // { id, name, active }
  const [submitting, setSubmitting] = useState(false);

  const flash = (msg) => { setSuccess(msg); setTimeout(() => setSuccess(''), 3500); };

  const loadLearners = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const [res, secList] = await Promise.all([
        LearnerService.getLearners({
          search,
          sectionId: sectionId || undefined,
          cohortType: sectionId ? undefined : (cohortType || undefined),
          gradeLevel: gradeLevel || undefined,
          isActive: isActive !== '' ? isActive : undefined,
          page,
          size: 15,
        }),
        SectionService.getAllSections().catch(() => []),
      ]);
      setLearners(res.content || []);
      setTotalPages(res.totalPages || res.total_pages || 1);
      setTotalElements(res.totalElements || res.total_elements || 0);
      setSections(secList);
    } catch (err) {
      setError(err?.message || 'Failed to load learners list.');
    } finally {
      setLoading(false);
    }
  }, [search, sectionId, cohortType, gradeLevel, isActive, page]);

  useEffect(() => { loadLearners(); }, [loadLearners]);

  // Bulk select toggles
  const handleSelectAll = (e) => {
    if (e.target.checked) {
      setSelectedIds(learners.map(l => l.learner_id || l.learnerId));
    } else {
      setSelectedIds([]);
    }
  };

  const handleToggleSelect = (id) => {
    setSelectedIds(prev => prev.includes(id) ? prev.filter(x => x !== id) : [...prev, id]);
  };

  // Status toggle (soft deactivate/reactivate)
  const handleConfirmStatusChange = async () => {
    if (!statusTarget) return;
    setSubmitting(true);
    try {
      if (statusTarget.isActive) {
        await LearnerService.deactivateLearner(statusTarget.learnerId);
        flash(`Learner ${statusTarget.displayName} deactivated.`);
      } else {
        await LearnerService.reactivateLearner(statusTarget.learnerId);
        flash(`Learner ${statusTarget.displayName} reactivated.`);
      }
      setStatusTarget(null);
      loadLearners();
    } catch (err) {
      setError(err?.message || 'Failed to change learner status.');
    } finally {
      setSubmitting(false);
    }
  };

  // Progress reset handler
  const handleConfirmReset = async (learnerId, lessonId) => {
    setSubmitting(true);
    try {
      await LearnerService.resetProgress(learnerId, lessonId);
      flash('Learner progress reset successfully.');
      setResetTarget(null);
      loadLearners();
    } catch (err) {
      setError(err?.message || 'Failed to reset progress.');
    } finally {
      setSubmitting(false);
    }
  };

  // Section assignment handler
  const handleConfirmAssign = async (targetSectionId) => {
    if (!assignTarget) return;
    setSubmitting(true);
    try {
      if (Array.isArray(assignTarget)) {
        await LearnerService.executeBulkAction('ASSIGN_SECTION', assignTarget, targetSectionId);
        flash(`${assignTarget.length} learners assigned to section.`);
        setSelectedIds([]);
      } else {
        const lid = assignTarget.learner_id || assignTarget.learnerId;
        const dName = assignTarget.display_name || assignTarget.displayName;
        await LearnerService.assignClass(lid, targetSectionId);
        flash(`Assigned ${dName} to section.`);
      }
      setAssignTarget(null);
      loadLearners();
    } catch (err) {
      setError(err?.message || 'Failed to assign class section.');
    } finally {
      setSubmitting(false);
    }
  };

  // Bulk actions execution
  const handleBulkDeactivate = async () => {
    if (selectedIds.length === 0) return;
    if (!window.confirm(`Deactivate ${selectedIds.length} selected learners?`)) return;
    setSubmitting(true);
    try {
      await LearnerService.executeBulkAction('DEACTIVATE', selectedIds);
      flash(`${selectedIds.length} learners deactivated.`);
      setSelectedIds([]);
      loadLearners();
    } catch (err) {
      setError(err?.message || 'Bulk deactivation failed.');
    } finally {
      setSubmitting(false);
    }
  };

  const handleBulkReactivate = async () => {
    if (selectedIds.length === 0) return;
    setSubmitting(true);
    try {
      await LearnerService.executeBulkAction('REACTIVATE', selectedIds);
      flash(`${selectedIds.length} learners reactivated.`);
      setSelectedIds([]);
      loadLearners();
    } catch (err) {
      setError(err?.message || 'Bulk reactivation failed.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="admin-layout">
      <AdminNav />
      <main className="admin-main" style={{ maxWidth: '100%' }}>
        <header className="admin-main__header" style={{ alignItems: 'flex-start' }}>
          <div>
            <h1 className="admin-main__title">Universal User Management</h1>
            <p className="admin-main__subtitle">Roster overview, independent self-paced learners, diagnostic profiles, and class assignments</p>
          </div>
        </header>

        {error && <div className="alert alert--error" onClick={() => setError('')}>{error}</div>}
        {success && <div className="alert alert--success">{success}</div>}

        {/* Toolbar & Filters */}
        <div className="table-toolbar" style={{ flexWrap: 'wrap', gap: 10 }}>
          <input
            className="toolbar-search"
            placeholder="🔍  Search student name or ID..."
            value={search}
            onChange={e => { setSearch(e.target.value); setPage(0); }}
            style={{ minWidth: 220 }}
          />

          {/* Cohort Type Filter */}
          <select
            className="toolbar-select"
            value={sectionId ? '' : cohortType}
            onChange={e => {
              setCohortType(e.target.value);
              setSectionId('');
              setPage(0);
            }}
            style={{ minWidth: 160 }}
          >
            <option value="">All Cohorts (Global)</option>
            <option value="INDEPENDENT">👤 Independent / Self-Paced Only</option>
            <option value="ENROLLED">🏫 Enrolled in Classes Only</option>
          </select>

          <select
            className="toolbar-select"
            value={sectionId}
            onChange={e => {
              setSectionId(e.target.value);
              if (e.target.value) setCohortType('');
              setPage(0);
            }}
          >
            <option value="">All Classes / Sections</option>
            {sections.map(s => (
              <option key={s.section_id} value={s.section_id}>{s.section_name}</option>
            ))}
          </select>

          <select
            className="toolbar-select"
            value={gradeLevel}
            onChange={e => { setGradeLevel(e.target.value); setPage(0); }}
          >
            <option value="">All Grades</option>
            <option value="GRADE_3_4">Grade 3-4</option>
            <option value="GRADE_5_6">Grade 5-6</option>
            <option value="GRADE_6">Grade 6</option>
          </select>

          <select
            className="toolbar-select"
            value={isActive}
            onChange={e => { setIsActive(e.target.value); setPage(0); }}
          >
            <option value="">All Statuses</option>
            <option value="true">Active</option>
            <option value="false">Inactive (Disabled)</option>
          </select>
        </div>

        {/* Bulk Action Bar if items selected */}
        {selectedIds.length > 0 && (
          <div style={{
            background: 'var(--glass-bg)',
            borderRadius: 'var(--radius-sm)',
            padding: '10px 16px',
            border: '1px solid var(--color-primary)',
            marginBottom: 16,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            gap: 12
          }}>
            <span style={{ fontWeight: 600, color: 'var(--color-primary)' }}>
              ✓ {selectedIds.length} student{selectedIds.length !== 1 ? 's' : ''} selected
            </span>
            <div style={{ display: 'flex', gap: 8 }}>
              <button
                className="btn btn--sm btn--primary"
                onClick={() => setAssignTarget(selectedIds)}
              >
                🏫 Assign Section
              </button>
              <button
                className="btn btn--sm btn--ghost"
                onClick={handleBulkReactivate}
              >
                ✓ Reactivate
              </button>
              <button
                className="btn btn--sm btn--danger-ghost"
                onClick={handleBulkDeactivate}
              >
                🚫 Deactivate
              </button>
            </div>
          </div>
        )}

        {/* Student Roster Table */}
        {loading ? (
          <div className="auth-loading" style={{ minHeight: 300 }}><div className="spinner" /></div>
        ) : (
          <div className="accounts-table-wrap">
            <table className="accounts-table">
              <thead>
                <tr>
                  <th style={{ width: 40 }}>
                    <input
                      type="checkbox"
                      checked={learners.length > 0 && selectedIds.length === learners.length}
                      onChange={handleSelectAll}
                    />
                  </th>
                  <th>Student Name</th>
                  <th>Cohort / Class</th>
                  <th>Grade</th>
                  <th>Points</th>
                  <th>Overall Accuracy</th>
                  <th>Cumulative Retention</th>
                  <th>Status</th>
                  <th>Last Active</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {learners.length === 0 && (
                  <tr>
                    <td colSpan={10} style={{ textAlign: 'center', color: 'var(--color-text-muted)', padding: 40 }}>
                      No students found matching current filters.
                    </td>
                  </tr>
                )}
                {learners.map(l => {
                  const lid = l.learner_id || l.learnerId;
                  const dName = l.display_name || l.displayName;
                  const sName = l.section_name || l.sectionName;
                  const gLevel = l.grade_level || l.gradeLevel;
                  const pts = l.total_points ?? l.totalPoints ?? 0;
                  const acc = l.overall_accuracy ?? l.overallAccuracy ?? 0;
                  const cumCompleted = l.cumulative_reviews_completed ?? l.cumulativeReviewsCompleted ?? 0;
                  const cumAvg = l.avg_cumulative_score ?? l.avgCumulativeScore ?? 0;
                  const cumBadge = l.best_cumulative_badge || l.bestCumulativeBadge;
                  const active = l.is_active ?? l.isActive ?? true;
                  const struggling = l.is_struggling ?? l.struggling ?? false;
                  const lastActive = l.last_active_at || l.lastActiveAt;

                  return (
                    <tr key={lid} className={!active ? 'row--disabled' : ''}>
                      <td>
                        <input
                          type="checkbox"
                          checked={selectedIds.includes(lid)}
                          onChange={() => handleToggleSelect(lid)}
                        />
                      </td>
                      <td>
                        <span style={{ fontWeight: 700 }}>{dName}</span>
                        {struggling && (
                          <span style={{
                            marginLeft: 6,
                            fontSize: '0.72rem',
                            background: 'rgba(239, 68, 68, 0.15)',
                            color: 'var(--color-danger)',
                            padding: '1px 6px',
                            borderRadius: 4,
                            fontWeight: 700,
                          }}>
                            ⚠️ Needs Support
                          </span>
                        )}
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
                      <td className="text-muted">{gLevel ? gLevel.replace('_', ' ') : 'N/A'}</td>
                      <td style={{ fontWeight: 600 }}>{pts}</td>
                      <td>
                        <span style={{
                          fontWeight: 700,
                          color: Number(acc) >= 70 ? 'var(--color-success)' : 'var(--color-danger)',
                        }}>
                          {acc != null ? `${Number(acc).toFixed(1)}%` : '0%'}
                        </span>
                      </td>
                      <td>
                        {cumCompleted > 0 ? (
                          <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                            <span style={{ fontWeight: 700, color: Number(cumAvg) >= 70 ? 'var(--color-success)' : 'var(--color-accent-1)' }}>
                              {Number(cumAvg).toFixed(1)}%
                            </span>
                            <span style={{ fontSize: '0.72rem', color: 'var(--color-text-dim)' }}>
                              {cumBadge === 'PERFECT_GOLD' && '🏆 Perfect Gold'}
                              {cumBadge === 'GOLD' && '🥇 Gold'}
                              {cumBadge === 'SILVER' && '🥈 Silver'}
                              {cumBadge === 'BRONZE' && '🥉 Bronze'}
                              {!cumBadge && `${cumCompleted} session${cumCompleted > 1 ? 's' : ''}`}
                            </span>
                          </div>
                        ) : (
                          <span className="text-muted" style={{ fontSize: '0.8rem' }}>—</span>
                        )}
                      </td>
                      <td>
                        <span className={`status-dot ${active ? 'status-dot--active' : 'status-dot--inactive'}`}>
                          {active ? 'Active' : 'Disabled'}
                        </span>
                      </td>
                      <td className="text-muted" style={{ fontSize: '0.8rem' }}>
                        {lastActive ? new Date(lastActive).toLocaleDateString() : 'Never'}
                      </td>
                      <td className="actions-cell">
                        <button
                          className="btn btn--sm btn--ghost"
                          onClick={() => setDetailLearnerId(lid)}
                          title="View diagnostic profile"
                        >
                          🔍 Profile
                        </button>
                        <button
                          className="btn btn--sm btn--ghost"
                          onClick={() => ReportService.downloadIndividualReport(lid, 'pdf')}
                          title="Download PDF report card"
                        >
                          📄 Report
                        </button>
                        <button
                          className="btn btn--sm btn--ghost"
                          onClick={() => setAssignTarget(l)}
                          title="Assign to class section"
                        >
                          🏫
                        </button>
                        <button
                          className="btn btn--sm btn--danger-ghost"
                          onClick={() => setResetTarget(l)}
                          title="Reset progress"
                        >
                          ⚠️
                        </button>
                        <button
                          className={`btn btn--sm ${active ? 'btn--danger-ghost' : 'btn--ghost'}`}
                          onClick={() => setStatusTarget({ learnerId: lid, displayName: dName, isActive: active })}
                          title={active ? 'Deactivate learner' : 'Reactivate learner'}
                        >
                          {active ? '🚫' : '✓'}
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}

        {/* Pagination & Meta */}
        {!loading && (
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 16 }}>
            <div className="table-meta">
              Showing {learners.length} of {totalElements} students
            </div>
            <div style={{ display: 'flex', gap: 8 }}>
              <button
                className="btn btn--sm btn--ghost"
                onClick={() => setPage(p => Math.max(0, p - 1))}
                disabled={page === 0}
              >
                ← Previous
              </button>
              <span style={{ fontSize: '0.85rem', display: 'flex', alignItems: 'center', color: 'var(--color-text-muted)' }}>
                Page {page + 1} of {Math.max(1, totalPages)}
              </span>
              <button
                className="btn btn--sm btn--ghost"
                onClick={() => setPage(p => Math.min(totalPages - 1, p + 1))}
                disabled={page >= totalPages - 1}
              >
                Next →
              </button>
            </div>
          </div>
        )}

        {/* Diagnostic Profile Modal */}
        {detailLearnerId && (
          <LearnerDetailModal
            learnerId={detailLearnerId}
            onClose={() => setDetailLearnerId(null)}
            onResetProgress={(l) => { setDetailLearnerId(null); setResetTarget(l); }}
            onEditProfile={() => { setDetailLearnerId(null); }}
          />
        )}

        {/* Destructive Reset Modal */}
        {resetTarget && (
          <ResetProgressModal
            learner={resetTarget}
            onClose={() => setResetTarget(null)}
            onConfirm={handleConfirmReset}
            loading={submitting}
          />
        )}

        {/* Assign Section Modal */}
        {assignTarget && (
          <AssignSectionModal
            learners={assignTarget}
            onClose={() => setAssignTarget(null)}
            onConfirm={handleConfirmAssign}
            loading={submitting}
          />
        )}

        {/* Status Deactivate/Reactivate Confirmation Dialog */}
        {statusTarget && (
          <ConfirmDeleteDialog
            title={statusTarget.isActive ? 'Deactivate Student' : 'Reactivate Student'}
            message={
              statusTarget.isActive
                ? `Deactivate ${statusTarget.displayName}? The student will not be able to log in or practice lessons.`
                : `Reactivate ${statusTarget.displayName}? The student will regain login and learning access.`
            }
            confirmLabel={statusTarget.isActive ? 'Deactivate' : 'Reactivate'}
            danger={statusTarget.isActive}
            onConfirm={handleConfirmStatusChange}
            onCancel={() => setStatusTarget(null)}
            loading={submitting}
          />
        )}
      </main>
    </div>
  );
}
