import { useState, useEffect, useCallback } from 'react';
import AdminNav from '../components/AdminNav';
import { LearnerService } from '../services/LearnerService';
import { SectionService } from '../services/SectionService';
import { ReportService } from '../services/ReportService';
import LearnerDetailModal from '../components/LearnerDetailModal';
import ResetProgressModal from '../components/ResetProgressModal';
import AssignSectionModal from '../components/AssignSectionModal';
import ConfirmDeleteDialog from '../components/ConfirmDeleteDialog';
import { useAdminAuth } from '../hooks/useAdminAuth';

export default function LearnerManagementPage() {
  const { admin } = useAdminAuth();
  const isTeacher = admin?.role === 'teacher';

  const [learners, setLearners] = useState([]);
  const [sections, setSections] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  // Search & Filter state
  const [activeTab, setActiveTab] = useState('roster'); // 'roster' | 'flagged'
  const [flaggedLearners, setFlaggedLearners] = useState([]);
  const [loadingFlagged, setLoadingFlagged] = useState(false);
  const [resolvingId, setResolvingId] = useState(null);

  const [search, setSearch] = useState('');
  const [cohortType, setCohortType] = useState(isTeacher ? 'ENROLLED' : ''); // '' | 'INDEPENDENT' | 'ENROLLED'
  const [sectionId, setSectionId] = useState('');
  const [gradeLevel, setGradeLevel] = useState('');
  const [isActive, setIsActive] = useState('');
  const [page, setPage] = useState(0);

  useEffect(() => {
    if (isTeacher) {
      setCohortType('ENROLLED');
    }
  }, [isTeacher]);
  const [totalPages, setTotalPages] = useState(1);
  const [totalElements, setTotalElements] = useState(0);

  // Selection for bulk actions
  const [selectedIds, setSelectedIds] = useState([]);

  // Modals & Export targets
  const [detailLearnerId, setDetailLearnerId] = useState(null);
  const [detailLearner, setDetailLearner] = useState(null);
  const [resetTarget, setResetTarget] = useState(null);
  const [assignTarget, setAssignTarget] = useState(null); // single learner or array
  const [statusTarget, setStatusTarget] = useState(null); // { id, name, active }
  const [deleteTarget, setDeleteTarget] = useState(null); // learner to permanently delete
  const [submitting, setSubmitting] = useState(false);

  // Student & Roster Export state
  const [exportStudentTarget, setExportStudentTarget] = useState(null);
  const [exportStudentEnrolledClasses, setExportStudentEnrolledClasses] = useState([]);
  const [loadingExportClasses, setLoadingExportClasses] = useState(false);
  const [exportStudentClassScope, setExportStudentClassScope] = useState('');
  const [exportStudentFormat, setExportStudentFormat] = useState('pdf');
  const [downloadingStudentExport, setDownloadingStudentExport] = useState(false);
  const [exportStudentError, setExportStudentError] = useState('');
  const [downloadingRoster, setDownloadingRoster] = useState(false);

  const flash = (msg) => { setSuccess(msg); setTimeout(() => setSuccess(''), 3500); };

  const loadFlaggedLearners = useCallback(async () => {
    setLoadingFlagged(true);
    try {
      const data = await LearnerService.getFlaggedLearners({
        sectionId: sectionId || undefined,
        gradeLevel: gradeLevel || undefined,
      });
      setFlaggedLearners(data || []);
    } catch (err) {
      console.error('Failed to load flagged learners', err);
    } finally {
      setLoadingFlagged(false);
    }
  }, [sectionId, gradeLevel]);

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

  useEffect(() => { 
    loadLearners(); 
    loadFlaggedLearners();
  }, [loadLearners, loadFlaggedLearners]);

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

  // Permanent student deletion handler (Admin only)
  const handleConfirmDelete = async () => {
    if (!deleteTarget) return;
    setSubmitting(true);
    try {
      const lid = deleteTarget.learner_id || deleteTarget.learnerId;
      const dName = deleteTarget.display_name || deleteTarget.displayName;
      await LearnerService.deleteLearner(lid);
      flash(`Student account for ${dName} permanently deleted.`);
      setDeleteTarget(null);
      loadLearners();
    } catch (err) {
      setError(err?.message || 'Failed to delete student account.');
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

  const handleResolveFlag = async (progressId, learnerName) => {
    setResolvingId(progressId);
    try {
      await LearnerService.resolveFlagged(progressId);
      flash(`Teacher review flag for ${learnerName} marked resolved.`);
      loadFlaggedLearners();
    } catch (err) {
      setError(err?.message || 'Failed to resolve review flag.');
    } finally {
      setResolvingId(null);
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

  // Open Export Modal for individual learner - fetches only active enrolled classes
  const handleOpenExportModal = async (l) => {
    setExportStudentTarget(l);
    setExportStudentFormat('pdf');
    setExportStudentError('');
    setLoadingExportClasses(true);
    setExportStudentEnrolledClasses([]);
    setExportStudentClassScope('');

    const lid = l.learner_id || l.learnerId;
    try {
      const detail = await LearnerService.getLearnerDetail(lid);
      const enrolled = (detail?.enrolled_classes || detail?.enrolledClasses || []).filter(c => c.class_id || c.classId);
      setExportStudentEnrolledClasses(enrolled);

      if (isTeacher) {
        if (enrolled.length === 1) {
          setExportStudentClassScope(enrolled[0].class_id || enrolled[0].classId);
        } else if (enrolled.length > 1) {
          const matchingSec = enrolled.find(c => (c.class_id || c.classId) === sectionId);
          setExportStudentClassScope(matchingSec ? (matchingSec.class_id || matchingSec.classId) : (enrolled[0].class_id || enrolled[0].classId));
        } else {
          setExportStudentClassScope('');
        }
      } else {
        // Admin: locked to universal global scope
        setExportStudentClassScope('');
      }
    } catch (err) {
      console.error('Failed to fetch student enrolled classes', err);
      const fallbackClass = l.section_id || l.sectionId || l.class_id || l.classId;
      if (fallbackClass && isTeacher) {
        setExportStudentEnrolledClasses([{
          class_id: fallbackClass,
          class_name: l.section_name || l.sectionName || 'Enrolled Class',
          class_code: '',
        }]);
        setExportStudentClassScope(fallbackClass);
      } else {
        setExportStudentClassScope('');
      }
    } finally {
      setLoadingExportClasses(false);
    }
  };

  // Execute Individual Report Download with chosen scope and format
  const handleExecuteStudentExport = async () => {
    if (!exportStudentTarget) return;
    const lid = exportStudentTarget.learner_id || exportStudentTarget.learnerId;
    const dName = exportStudentTarget.display_name || exportStudentTarget.displayName;
    setDownloadingStudentExport(true);
    setExportStudentError('');
    try {
      await ReportService.downloadIndividualReport(
        lid,
        exportStudentFormat,
        !isTeacher ? undefined : (exportStudentClassScope || undefined)
      );
      flash(`Generated ${exportStudentFormat.toUpperCase()} report for ${dName}.`);
      setExportStudentTarget(null);
    } catch (err) {
      const errorMsg = err?.message || 'Failed to generate student report.';
      setExportStudentError(errorMsg);
      setError(errorMsg);
    } finally {
      setDownloadingStudentExport(false);
    }
  };

  // Execute Roster Export (All or filtered Class) in PDF or CSV
  const handleDownloadRoster = async (format) => {
    if (!isTeacher && sectionId) {
      setError('Administrators can only export global school-wide rosters, not specific teacher classes.');
      return;
    }
    setDownloadingRoster(true);
    try {
      const targetClass = sectionId || undefined;
      const className = sections.find(s => (s.section_id || s.sectionId) === sectionId)?.section_name || 'All Classes';
      await ReportService.downloadClassReport(format, targetClass);
      flash(`Downloaded ${format.toUpperCase()} roster report for ${className}.`);
    } catch (err) {
      setError(err?.message || 'Failed to export class roster.');
    } finally {
      setDownloadingRoster(false);
    }
  };

  return (
    <div className="admin-layout">
      <AdminNav />
      <main className="admin-main" style={{ maxWidth: '100%' }}>
        <header className="admin-main__header" style={{ alignItems: 'flex-start' }}>
          <div>
            <h1 className="admin-main__title">
              {isTeacher ? 'Classroom Student Management' : 'Universal User Management'}
            </h1>
            <p className="admin-main__subtitle">
              {isTeacher
                ? 'Student roster overview, diagnostic profiles, and class assignments'
                : 'Roster overview, independent self-paced learners, diagnostic profiles, and class assignments'}
            </p>
          </div>
        </header>

        {error && <div className="alert alert--error" onClick={() => setError('')}>{error}</div>}
        {success && <div className="alert alert--success">{success}</div>}

        {/* Navigation Tabs */}
        <div style={{ display: 'flex', gap: 12, marginBottom: 20 }}>
          <button
            type="button"
            className={`btn ${activeTab === 'roster' ? 'btn--primary' : 'btn--ghost'}`}
            onClick={() => setActiveTab('roster')}
            style={{ fontWeight: 700 }}
          >
            👥 Student Roster ({totalElements})
          </button>
          <button
            type="button"
            className={`btn ${activeTab === 'flagged' ? 'btn--primary' : 'btn--ghost'}`}
            onClick={() => setActiveTab('flagged')}
            style={{
              fontWeight: 700,
              borderColor: flaggedLearners.length > 0 ? '#ef4444' : undefined,
              color: activeTab === 'flagged' ? '#ffffff' : (flaggedLearners.length > 0 ? '#ef4444' : undefined),
              backgroundColor: activeTab === 'flagged' ? (flaggedLearners.length > 0 ? '#ef4444' : undefined) : undefined,
            }}
          >
            🚩 Flagged for Review
            {flaggedLearners.length > 0 && (
              <span
                style={{
                  marginLeft: 8,
                  background: activeTab === 'flagged' ? '#ffffff' : '#ef4444',
                  color: activeTab === 'flagged' ? '#ef4444' : '#ffffff',
                  padding: '2px 8px',
                  borderRadius: 12,
                  fontSize: '0.75rem',
                  fontWeight: 800,
                }}
              >
                {flaggedLearners.length}
              </span>
            )}
          </button>
        </div>

        {activeTab === 'flagged' ? (
          <div>
            <div style={{
              background: '#fef2f2',
              border: '1.5px solid #fecaca',
              borderRadius: 'var(--radius-lg)',
              padding: '14px 18px',
              marginBottom: 16,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <span style={{ fontSize: '1.4rem' }}>🚩</span>
                <div>
                  <div style={{ fontWeight: 800, color: '#991b1b', fontSize: '0.95rem' }}>
                    {flaggedLearners.length} Student{flaggedLearners.length !== 1 ? 's' : ''} Requiring 1-on-1 Teacher Attention
                  </div>
                  <div style={{ fontSize: '0.8rem', color: '#b91c1c' }}>
                    These learners have triggered repeated visual reintroductions at the LEARNING tier or accumulated high consecutive error streaks.
                  </div>
                </div>
              </div>
              <button
                type="button"
                className="btn btn--sm btn--ghost"
                onClick={loadFlaggedLearners}
                disabled={loadingFlagged}
              >
                {loadingFlagged ? <span className="spinner spinner--sm" /> : '🔄 Refresh'}
              </button>
            </div>

            {loadingFlagged ? (
              <div className="auth-loading" style={{ minHeight: 250 }}><div className="spinner" /></div>
            ) : flaggedLearners.length === 0 ? (
              <div style={{
                textAlign: 'center',
                padding: '60px 20px',
                background: '#ffffff',
                border: '1.5px solid var(--color-border)',
                borderRadius: 'var(--radius-lg)',
              }}>
                <div style={{ fontSize: '2.5rem', marginBottom: 10 }}>🎉</div>
                <div style={{ fontWeight: 800, color: 'var(--color-text-main)', fontSize: '1.1rem' }}>No Flagged Students</div>
                <div style={{ color: 'var(--color-text-muted)', fontSize: '0.85rem', marginTop: 4 }}>
                  All learners are progressing within normal error thresholds!
                </div>
              </div>
            ) : (
              <div className="accounts-table-wrap">
                <table className="accounts-table">
                  <thead>
                    <tr>
                      <th>Student</th>
                      <th>Class / Cohort</th>
                      <th>Struggling Word</th>
                      <th>Lesson</th>
                      <th>Reintroductions</th>
                      <th>Error Streak</th>
                      <th>Accuracy</th>
                      <th>Flagged Date</th>
                      <th style={{ textAlign: 'right' }}>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {flaggedLearners.map(f => (
                      <tr key={f.progressId || f.learnerId + f.wordId}>
                        <td>
                          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                            <div style={{
                              width: 32, height: 32, borderRadius: '50%',
                              background: 'linear-gradient(135deg, #ef4444, #f97316)',
                              display: 'grid', placeItems: 'center',
                              color: '#fff', fontSize: '0.78rem', fontWeight: 700, flexShrink: 0,
                            }}>
                              {f.learnerName?.charAt(0)?.toUpperCase() || '?'}
                            </div>
                            <div>
                              <div style={{ fontWeight: 700, color: 'var(--color-text)', fontSize: '0.875rem' }}>{f.learnerName}</div>
                              <span style={{
                                fontFamily: 'monospace',
                                fontSize: '0.72rem',
                                fontWeight: 700,
                                color: '#1d4ed8',
                                background: '#eff6ff',
                                border: '1px solid #bfdbfe',
                                borderRadius: 4,
                                padding: '1px 5px',
                                display: 'inline-block',
                                marginTop: 2,
                                whiteSpace: 'nowrap',
                                flexShrink: 0,
                              }}>
                                {f.username || 'ID: —'}
                              </span>
                            </div>
                          </div>
                        </td>
                        <td>
                          <span className="text-muted">{f.sectionName || 'Independent'}</span>
                          {f.gradeLevel && <div style={{ fontSize: '0.72rem', color: 'var(--color-text-dim)' }}>{f.gradeLevel.replace('_', ' ')}</div>}
                        </td>
                        <td>
                          <div style={{ fontWeight: 800, color: '#1e293b' }}>{f.englishWord}</div>
                          <div style={{ fontSize: '0.78rem', color: '#64748b' }}>{f.cebuanoMeaning}</div>
                          {f.partOfSpeech && (
                            <span className="badge badge--sm" style={{ marginTop: 2 }}>{f.partOfSpeech}</span>
                          )}
                        </td>
                        <td>
                          <span style={{ fontSize: '0.85rem', fontWeight: 600, color: 'var(--color-text-main)' }}>{f.lessonTitle}</span>
                        </td>
                        <td>
                          <span className="status-pill status-pill--danger">
                            ⚠️ {f.reintroductionCount ?? 0}x Reintroduced
                          </span>
                        </td>
                        <td>
                          <span style={{ fontWeight: 700, color: '#dc2626' }}>
                            {f.consecutiveIncorrect ?? 0} errors
                          </span>
                        </td>
                        <td>
                          <span style={{ fontWeight: 700, color: (f.accuracy || 0) < 50 ? '#dc2626' : '#d97706' }}>
                            {Math.round(f.accuracy || 0)}%
                          </span>
                        </td>
                        <td>
                          <span style={{ fontSize: '0.78rem', color: 'var(--color-text-dim)' }}>
                            {f.flaggedAt ? new Date(f.flaggedAt).toLocaleDateString() : 'Recent'}
                          </span>
                        </td>
                        <td style={{ textAlign: 'right' }}>
                          <div style={{ display: 'flex', gap: 6, justifyContent: 'flex-end' }}>
                            <button
                              type="button"
                              className="btn btn--xs btn--ghost"
                              onClick={() => {
                                setDetailLearnerId(f.learnerId || f.learner_id);
                                setDetailLearner(f);
                              }}
                              title="View full diagnostic and performance details"
                            >
                              🔍 Profile
                            </button>
                            <button
                              type="button"
                              className="btn btn--xs btn--success"
                              onClick={() => handleResolveFlag(f.progressId, f.learnerName)}
                              disabled={resolvingId === f.progressId}
                              title="Acknowledge and mark as resolved"
                            >
                              {resolvingId === f.progressId ? <span className="spinner spinner--xs" /> : '✓ Resolved'}
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        ) : (
          <>
            {/* Toolbar & Filters */}
            <div className="table-toolbar" style={{ flexWrap: 'wrap', gap: 10 }}>
              <div className="toolbar-search-wrap">
                <svg width="15" height="15" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round">
                  <circle cx="11" cy="11" r="8" /><path d="M21 21l-4.35-4.35" />
                </svg>
                <input
                  className="toolbar-search"
                  placeholder="Search student name or ID (e.g. 26-1042-389)…"
                  value={search}
                  onChange={e => { setSearch(e.target.value); setPage(0); }}
                />
              </div>

              {/* Cohort Type Filter */}
              {!isTeacher && (
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
              )}

              <select
                className="toolbar-select"
                value={sectionId}
                onChange={e => {
                  setSectionId(e.target.value);
                  if (e.target.value) setCohortType(isTeacher ? 'ENROLLED' : '');
                  setPage(0);
                }}
              >
                <option value="">{isTeacher ? 'All My Classes / Sections' : 'All Classes / Sections'}</option>
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
                <option value="GRADE_4">Grade 4</option>
                <option value="GRADE_5">Grade 5</option>
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

              <div style={{ marginLeft: 'auto', display: 'flex', gap: 8, alignItems: 'center' }}>
                {(!sectionId || isTeacher) && (
                  <>
                    <button
                      type="button"
                      className="btn btn--sm btn--ghost"
                      onClick={() => handleDownloadRoster('pdf')}
                      disabled={downloadingRoster}
                      title={sectionId ? 'Download PDF roster report for current class' : 'Download PDF roster report for all classes'}
                      style={{ fontWeight: 600, display: 'inline-flex', alignItems: 'center', gap: 6 }}
                    >
                      {downloadingRoster ? <span className="spinner spinner--xs" /> : '📥'} {sectionId ? 'Class' : 'All'} Roster (PDF)
                    </button>
                    <button
                      type="button"
                      className="btn btn--sm btn--ghost"
                      onClick={() => handleDownloadRoster('csv')}
                      disabled={downloadingRoster}
                      title={sectionId ? 'Download CSV roster spreadsheet for current class' : 'Download CSV roster for all classes'}
                      style={{ fontWeight: 600, display: 'inline-flex', alignItems: 'center', gap: 6 }}
                    >
                      {downloadingRoster ? <span className="spinner spinner--xs" /> : '📊'} {sectionId ? 'Class' : 'All'} Roster (CSV)
                    </button>
                  </>
                )}
              </div>
            </div>

            {/* Bulk Action Bar */}
            {selectedIds.length > 0 && (
              <div className="bulk-action-bar">
                <span className="bulk-action-bar__count">
                  ✓ {selectedIds.length} student{selectedIds.length !== 1 ? 's' : ''} selected
                </span>
                <div style={{ display: 'flex', gap: 8 }}>
                  {isTeacher && (
                    <button className="btn btn--sm btn--primary" onClick={() => setAssignTarget(selectedIds)}>🏫 Assign Section</button>
                  )}
                  {!isTeacher && (
                    <>
                      <button className="btn btn--sm btn--success" onClick={handleBulkReactivate}>✓ Reactivate</button>
                      <button className="btn btn--sm btn--danger-ghost" onClick={handleBulkDeactivate}>🚫 Deactivate</button>
                    </>
                  )}
                </div>
              </div>
            )}

            {/* ── Active Class Scope Banner ─────────────────────────────────── */}
            {sectionId && (
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
                  <span style={{ fontSize: '1.4rem' }}>🏫</span>
                  <div>
                    <div style={{ fontWeight: 800, fontSize: '0.95rem', color: '#1e40af' }}>
                      Roster Filtered by Class: {sections.find(s => s.section_id === sectionId)?.section_name || 'Selected Class'}
                    </div>
                    <div style={{ fontSize: '0.8rem', color: '#3b82f6', marginTop: 2 }}>
                      Showing students enrolled in this classroom with their class-specific points, accuracy, and review statuses.
                    </div>
                  </div>
                </div>
                <div style={{ display: 'flex', gap: 8, alignItems: 'center', flexWrap: 'wrap' }}>
                  {isTeacher && (
                    <>
                      <button
                        type="button"
                        onClick={() => handleDownloadRoster('pdf')}
                        disabled={downloadingRoster}
                        style={{
                          padding: '6px 14px',
                          fontSize: '0.78rem',
                          fontWeight: 700,
                          color: '#1e40af',
                          background: '#fff',
                          border: '1px solid rgba(37,99,235,0.4)',
                          borderRadius: 8,
                          cursor: 'pointer',
                          display: 'inline-flex',
                          alignItems: 'center',
                          gap: 6,
                        }}
                      >
                        📄 Export Class PDF
                      </button>
                      <button
                        type="button"
                        onClick={() => handleDownloadRoster('csv')}
                        disabled={downloadingRoster}
                        style={{
                          padding: '6px 14px',
                          fontSize: '0.78rem',
                          fontWeight: 700,
                          color: '#1e40af',
                          background: '#fff',
                          border: '1px solid rgba(37,99,235,0.4)',
                          borderRadius: 8,
                          cursor: 'pointer',
                          display: 'inline-flex',
                          alignItems: 'center',
                          gap: 6,
                        }}
                      >
                        📊 Export Class CSV
                      </button>
                    </>
                  )}
                  <button
                    type="button"
                    onClick={() => setSectionId('')}
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
                  <th style={{ whiteSpace: 'nowrap' }}>Student Name</th>
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
                  const cumAvg = l.avg_cumulative_score ?? l.avgCumulativeScore;
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
                      <td style={{ whiteSpace: 'nowrap' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                          <div style={{
                            width: 32, height: 32, borderRadius: '50%',
                            background: 'linear-gradient(135deg, #3b82f6, #1d4ed8)',
                            display: 'grid', placeItems: 'center',
                            color: '#fff', fontSize: '0.78rem', fontWeight: 700, flexShrink: 0,
                          }}>
                            {dName?.charAt(0)?.toUpperCase() || '?'}
                          </div>
                          <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: 8, whiteSpace: 'nowrap' }}>
                              <span style={{ fontWeight: 700, color: 'var(--color-text)', fontSize: '0.875rem' }}>{dName}</span>
                              {struggling && (
                                <span className="status-pill status-pill--danger" style={{ whiteSpace: 'nowrap', flexShrink: 0, fontSize: '0.68rem', padding: '1px 6px' }}>
                                  ⚠️ Needs Support
                                </span>
                              )}
                            </div>
                            {(l.user_id || l.userId) && (
                              <span style={{
                                fontFamily: 'monospace',
                                fontSize: '0.72rem',
                                fontWeight: 700,
                                color: '#1d4ed8',
                                background: '#eff6ff',
                                border: '1px solid #bfdbfe',
                                borderRadius: 4,
                                padding: '1px 6px',
                                letterSpacing: '0.3px',
                                whiteSpace: 'nowrap',
                                flexShrink: 0,
                                width: 'fit-content',
                              }}>
                                {l.user_id || l.userId}
                              </span>
                            )}
                          </div>
                        </div>
                      </td>
                      <td>
                        {sName ? (
                          <span className="text-muted">{sName}</span>
                        ) : (
                          <span className="status-pill status-pill--info">Self-Paced</span>
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
                        {cumCompleted > 0 && cumAvg != null ? (
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
                          <span className="text-muted" style={{ fontSize: '0.8rem' }} title="Not attempted yet in mobile">—</span>
                        )}
                      </td>
                      <td>
                        <span className={`status-pill ${active ? 'status-pill--active' : 'status-pill--inactive'}`}>
                          {active ? 'Active' : 'Disabled'}
                        </span>
                      </td>
                      <td className="text-muted" style={{ fontSize: '0.8rem' }}>
                        {lastActive ? new Date(lastActive).toLocaleDateString() : 'Never'}
                      </td>
                      <td className="actions-cell">
                        <button
                          className="btn btn--sm btn--ghost"
                          onClick={() => {
                            setDetailLearnerId(lid);
                            setDetailLearner(l);
                          }}
                          title="View diagnostic profile"
                        >
                          🔍 Profile
                        </button>
                        <button
                          className="btn btn--sm btn--ghost"
                          onClick={() => handleOpenExportModal(l)}
                          title={!isTeacher ? 'Export global diagnostic report (Universal Lifetime)' : 'Export student diagnostic report (choose Class/All and PDF/CSV)'}
                        >
                          📄 Report
                        </button>
                        {isTeacher && (
                          <button
                            className="btn btn--sm btn--ghost"
                            onClick={() => setAssignTarget(l)}
                            title="Assign to class section"
                          >
                            🏫
                          </button>
                        )}
                        {!isTeacher && (
                          <>
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
                            <button
                              className="btn btn--sm btn--danger-ghost"
                              onClick={() => setDeleteTarget(l)}
                              title="Permanently delete student account"
                            >
                              🗑️
                            </button>
                          </>
                        )}
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
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 16, flexWrap: 'wrap', gap: 12 }}>
            <div className="table-meta" style={{ marginTop: 0 }}>
              Showing {learners.length} of {totalElements} students
            </div>
            <div className="pagination">
              <button
                className="pagination__btn"
                onClick={() => setPage(p => Math.max(0, p - 1))}
                disabled={page === 0}
              >
                ‹
              </button>
              <span className="pagination__info">Page {page + 1} of {Math.max(1, totalPages)}</span>
              <button
                className="pagination__btn"
                onClick={() => setPage(p => Math.min(totalPages - 1, p + 1))}
                disabled={page >= totalPages - 1}
              >
                ›
              </button>
            </div>
          </div>
        )}
        </>
        )}

        {/* Diagnostic Profile Modal */}
        {detailLearnerId && (
          <LearnerDetailModal
            learnerId={detailLearnerId}
            classContext={sectionId ? {
              classId: sectionId,
              className: sections.find(s => (s.section_id || s.sectionId) === sectionId)?.section_name || sections.find(s => (s.section_id || s.sectionId) === sectionId)?.sectionName,
            } : null}
            onClose={() => { setDetailLearnerId(null); setDetailLearner(null); }}
            onResetProgress={(l) => { setDetailLearnerId(null); setDetailLearner(null); setResetTarget(l); }}
            onEditProfile={() => { setDetailLearnerId(null); setDetailLearner(null); }}
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

        {/* Permanent Delete Student Confirmation Dialog (Admin only) */}
        {deleteTarget && (
          <ConfirmDeleteDialog
            title="Permanently Delete Student Account"
            message={`Permanently delete ${deleteTarget.display_name || deleteTarget.displayName}? All learning history, session progress, diagnostic records, and class enrollments will be permanently wiped. This action is irreversible.`}
            confirmLabel="Delete Permanently"
            danger={true}
            onConfirm={handleConfirmDelete}
            onCancel={() => setDeleteTarget(null)}
            loading={submitting}
          />
        )}

        {/* Student Diagnostic Export Modal with Scope Selection */}
        {exportStudentTarget && (
          <div className="modal-backdrop" style={{
            position: 'fixed', inset: 0, background: 'rgba(15,23,42,0.6)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            zIndex: 1050, padding: 16, backdropFilter: 'blur(4px)',
          }}>
            <div className="modal" style={{
              background: '#ffffff', borderRadius: 16, maxWidth: 500, width: '100%',
              boxShadow: '0 25px 50px -12px rgba(0,0,0,0.25)', overflow: 'hidden',
            }}>
              <div style={{
                padding: '20px 24px', borderBottom: '1px solid var(--color-border)',
                display: 'flex', alignItems: 'center', justifyContent: 'space-between',
              }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                  <span style={{ fontSize: '1.4rem' }}>📄</span>
                  <div>
                    <h3 style={{ margin: 0, fontSize: '1.1rem', fontWeight: 800, color: 'var(--color-text)' }}>
                      Export Diagnostic Report
                    </h3>
                    <p style={{ margin: 0, fontSize: '0.8rem', color: 'var(--color-text-muted)' }}>
                      {exportStudentTarget.display_name || exportStudentTarget.displayName}
                    </p>
                  </div>
                </div>
                <button
                  type="button"
                  className="btn btn--ghost btn--sm"
                  onClick={() => setExportStudentTarget(null)}
                  style={{ borderRadius: '50%', width: 32, height: 32, padding: 0, display: 'grid', placeItems: 'center' }}
                >
                  ✕
                </button>
              </div>

              <div style={{ padding: '24px', display: 'flex', flexDirection: 'column', gap: 20 }}>
                {exportStudentError && (
                  <div style={{
                    padding: '12px 14px',
                    background: '#fef2f2',
                    border: '1.5px solid #fecaca',
                    borderRadius: 8,
                    fontSize: '0.84rem',
                    color: '#991b1b',
                    display: 'flex',
                    alignItems: 'flex-start',
                    gap: 8,
                  }}>
                    <span style={{ fontSize: '1rem', lineHeight: 1 }}>⚠️</span>
                    <span style={{ flex: 1, lineHeight: 1.4 }}>{exportStudentError}</span>
                  </div>
                )}

                {/* Scope Selection */}
                <div>
                  <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: 'var(--color-text)', marginBottom: 6 }}>
                    1. Select Record Scope
                  </label>
                  <p style={{ margin: '0 0 8px 0', fontSize: '0.78rem', color: 'var(--color-text-muted)' }}>
                    {isTeacher
                      ? 'Select which of your active enrolled classrooms to generate this diagnostic report for.'
                      : 'Administrators export universal cumulative lifetime records across all classes and modules.'}
                  </p>

                  {!isTeacher ? (
                    <div style={{
                      padding: '12px 14px',
                      background: 'rgba(37,99,235,0.06)',
                      border: '1.5px solid rgba(37,99,235,0.25)',
                      borderRadius: 8,
                      fontSize: '0.85rem',
                      color: '#1e40af',
                      fontWeight: 700,
                      display: 'flex',
                      alignItems: 'center',
                      gap: 10,
                    }}>
                      <span style={{ fontSize: '1.25rem' }}>🌐</span>
                      <div>
                        <div>Universal Lifetime Record (Global School-wide)</div>
                        <div style={{ fontSize: '0.74rem', color: '#3b82f6', fontWeight: 500, marginTop: 2 }}>
                          Administrators export universal student records across all lessons. Specific classroom diagnostic reports are exported by class teachers.
                        </div>
                      </div>
                    </div>
                  ) : loadingExportClasses ? (
                    <div style={{ padding: '12px 14px', background: '#f8fafc', borderRadius: 8, fontSize: '0.82rem', color: '#64748b', display: 'flex', alignItems: 'center', gap: 8, border: '1px solid var(--color-border)' }}>
                      <span className="spinner spinner--xs" /> Verifying active class enrollments...
                    </div>
                  ) : exportStudentEnrolledClasses.length === 0 ? (
                    <div style={{
                      padding: '12px 14px',
                      background: '#fef2f2',
                      border: '1.5px solid #fecaca',
                      borderRadius: 8,
                      fontSize: '0.82rem',
                      color: '#991b1b',
                    }}>
                      <div style={{ fontWeight: 700, marginBottom: 4 }}>⚠️ Not Enrolled in Any Active Classroom</div>
                      <div>
                        This student has not joined or accepted enrollment in any of your classes yet. Individual classroom diagnostic reports can only be generated once the student is actively enrolled.
                      </div>
                    </div>
                  ) : (
                    <select
                      className="toolbar-select"
                      value={exportStudentClassScope}
                      onChange={(e) => setExportStudentClassScope(e.target.value)}
                      style={{ width: '100%', padding: '10px 12px', fontSize: '0.88rem' }}
                    >
                      {exportStudentEnrolledClasses.length > 1 ? (
                        <>
                          <option value="">🌟 All My Classes (Combined Student View)</option>
                          {exportStudentEnrolledClasses.map((c) => (
                            <option key={c.class_id || c.classId} value={c.class_id || c.classId}>
                              🏫 Class: {c.class_name || c.className} {c.class_code || c.classCode ? `(${c.class_code || c.classCode})` : ''}
                            </option>
                          ))}
                        </>
                      ) : (
                        <option value={exportStudentEnrolledClasses[0].class_id || exportStudentEnrolledClasses[0].classId}>
                          🏫 Class: {exportStudentEnrolledClasses[0].class_name || exportStudentEnrolledClasses[0].className} {exportStudentEnrolledClasses[0].class_code || exportStudentEnrolledClasses[0].classCode ? `(${exportStudentEnrolledClasses[0].class_code || exportStudentEnrolledClasses[0].classCode})` : ''}
                        </option>
                      )}
                    </select>
                  )}
                </div>

                {/* Active Scope Badge */}
                <div style={{
                  padding: '10px 14px',
                  borderRadius: 8,
                  fontSize: '0.8rem',
                  display: 'flex',
                  alignItems: 'center',
                  gap: 8,
                  background: exportStudentClassScope ? 'rgba(37,99,235,0.08)' : 'rgba(16,185,129,0.08)',
                  border: `1px solid ${exportStudentClassScope ? 'rgba(37,99,235,0.2)' : 'rgba(16,185,129,0.2)'}`,
                  color: exportStudentClassScope ? '#1d4ed8' : '#047857',
                  fontWeight: 600,
                }}>
                  <span>{exportStudentClassScope ? '🏫' : '🌐'}</span>
                  <span>
                    Record Scope: {exportStudentClassScope
                      ? (exportStudentEnrolledClasses.find(s => (s.class_id || s.classId) === exportStudentClassScope)?.class_name || exportStudentEnrolledClasses.find(s => (s.class_id || s.classId) === exportStudentClassScope)?.className || 'Specific Class')
                      : (isTeacher ? 'All My Classes (Combined)' : 'All Classes (Cumulative Lifetime Record)')}
                  </span>
                </div>

                {/* Format Selection */}
                <div>
                  <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: 'var(--color-text)', marginBottom: 8 }}>
                    2. Select Document Format
                  </label>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
                    <button
                      type="button"
                      onClick={() => setExportStudentFormat('pdf')}
                      style={{
                        padding: '12px',
                        borderRadius: 10,
                        border: exportStudentFormat === 'pdf' ? '2px solid var(--color-primary, #2563eb)' : '1px solid var(--color-border)',
                        background: exportStudentFormat === 'pdf' ? 'rgba(37,99,235,0.06)' : '#fff',
                        cursor: 'pointer',
                        textAlign: 'left',
                      }}
                    >
                      <div style={{ fontWeight: 700, fontSize: '0.9rem', color: exportStudentFormat === 'pdf' ? '#1d4ed8' : 'var(--color-text)' }}>
                        📄 PDF Document
                      </div>
                      <div style={{ fontSize: '0.74rem', color: 'var(--color-text-muted)', marginTop: 4 }}>
                        Printable diagnostic card with metrics & insights
                      </div>
                    </button>
                    <button
                      type="button"
                      onClick={() => setExportStudentFormat('csv')}
                      style={{
                        padding: '12px',
                        borderRadius: 10,
                        border: exportStudentFormat === 'csv' ? '2px solid var(--color-primary, #2563eb)' : '1px solid var(--color-border)',
                        background: exportStudentFormat === 'csv' ? 'rgba(37,99,235,0.06)' : '#fff',
                        cursor: 'pointer',
                        textAlign: 'left',
                      }}
                    >
                      <div style={{ fontWeight: 700, fontSize: '0.9rem', color: exportStudentFormat === 'csv' ? '#1d4ed8' : 'var(--color-text)' }}>
                        📊 CSV Spreadsheet
                      </div>
                      <div style={{ fontSize: '0.74rem', color: 'var(--color-text-muted)', marginTop: 4 }}>
                        Tabular word-by-word records & error streaks
                      </div>
                    </button>
                  </div>
                </div>
              </div>

              <div style={{
                padding: '16px 24px', background: '#f8fafc', borderTop: '1px solid var(--color-border)',
                display: 'flex', justifyContent: 'flex-end', gap: 10,
              }}>
                <button
                  type="button"
                  className="btn btn--ghost"
                  onClick={() => setExportStudentTarget(null)}
                  disabled={downloadingStudentExport}
                >
                  Cancel
                </button>
                <button
                  type="button"
                  className="btn btn--primary"
                  onClick={handleExecuteStudentExport}
                  disabled={downloadingStudentExport || loadingExportClasses || (isTeacher && exportStudentEnrolledClasses.length === 0)}
                  style={{ display: 'inline-flex', alignItems: 'center', gap: 8, fontWeight: 700 }}
                >
                  {downloadingStudentExport ? (
                    <>
                      <span className="spinner spinner--sm" />
                      <span>Generating...</span>
                    </>
                  ) : (
                    <>
                      <span>📥 Download {exportStudentFormat.toUpperCase()}</span>
                    </>
                  )}
                </button>
              </div>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
