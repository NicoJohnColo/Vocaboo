import { useEffect, useMemo } from 'react';
import LessonStatusBadge from './LessonStatusBadge';

export default function LessonTable({
  lessons, categories, searchQuery, onSearchChange,
  filterCategory, onFilterCategory, filterGrade, onFilterGrade,
  classes = [], filterClass = '', onFilterClass, isTeacher = false,
  onCreate, onEdit, onDelete, onViewWords, onPublish, onTogglePublish, togglingId, loading
}) {
  // Lessons matching the active class scope (before category/search filtering)
  const scopedLessons = useMemo(() => {
    return lessons.filter(l => {
      if (!filterClass) return true;
      if (filterClass === 'GLOBAL') return !l.class_id;
      return l.class_id === filterClass;
    });
  }, [lessons, filterClass]);

  // Categories filtered to only those with >0 lessons in the active classroom/teacher scope
  const visibleCategories = useMemo(() => {
    const counts = {};
    const catMap = new Map();
    // Register categories passed in props
    (categories || []).forEach(c => {
      if (c && c.category_id) catMap.set(c.category_id, { ...c, lessonCount: 0 });
    });
    // Add any category present in scopedLessons that wasn't in categories prop
    scopedLessons.forEach(l => {
      const cid = l.category_id || l.categoryId;
      const cname = l.category_name || l.categoryName || 'General';
      if (cid) {
        counts[cid] = (counts[cid] || 0) + 1;
        if (!catMap.has(cid)) {
          catMap.set(cid, { category_id: cid, category_name: cname, lessonCount: 0 });
        }
      }
    });
    return Array.from(catMap.values())
      .filter(c => (counts[c.category_id] || 0) > 0)
      .map(c => ({
        ...c,
        lessonCount: counts[c.category_id] || 0,
      }));
  }, [categories, scopedLessons]);

  // Auto-reset category filter if it no longer exists in this scope
  useEffect(() => {
    if (filterCategory && visibleCategories.length > 0) {
      const exists = visibleCategories.some(c => c.category_id === filterCategory);
      if (!exists) onFilterCategory('');
    }
  }, [visibleCategories, filterCategory, onFilterCategory]);

  const filtered = lessons.filter(l => {
    const q = searchQuery.toLowerCase();
    const matchSearch = !q || l.lesson_title.toLowerCase().includes(q) || (l.category_name && l.category_name.toLowerCase().includes(q)) || (l.class_name && l.class_name.toLowerCase().includes(q));
    const matchCat = !filterCategory || l.category_id === filterCategory;
    const matchGrade = !filterGrade || l.grade_level === filterGrade;
    const matchClass = !filterClass
      ? true
      : filterClass === 'GLOBAL'
        ? !l.class_id
        : l.class_id === filterClass;
    return matchSearch && matchCat && matchGrade && matchClass;
  });

  return (
    <div>
      {/* Toolbar */}
      <div className="table-toolbar">
        <div className="toolbar-search-wrap">
          <svg width="15" height="15" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round">
            <circle cx="11" cy="11" r="8" /><path d="M21 21l-4.35-4.35" />
          </svg>
          <input
            id="lesson-search"
            className="toolbar-search"
            placeholder="Search lessons…"
            value={searchQuery}
            onChange={e => onSearchChange(e.target.value)}
          />
        </div>

        <select
          id="lesson-filter-class"
          className="toolbar-select"
          value={filterClass}
          onChange={e => onFilterClass && onFilterClass(e.target.value)}
        >
          {isTeacher ? (
            <option value="">All My Classes</option>
          ) : (
            <>
              <option value="">All Cohorts (Global & Classes)</option>
              <option value="GLOBAL">🌍 Global Curriculum Only</option>
            </>
          )}
          {classes.map(c => (
            <option key={c.section_id} value={c.section_id}>
              🏫 Class: {c.section_name} {c.section_code ? `(${c.section_code})` : ''}
            </option>
          ))}
        </select>

        <select
          id="lesson-filter-category"
          className="toolbar-select"
          value={filterCategory}
          onChange={e => onFilterCategory(e.target.value)}
        >
          <option value="">All Active Categories ({visibleCategories.length})</option>
          {visibleCategories.map(c => (
            <option key={c.category_id} value={c.category_id}>
              {c.category_name} ({c.lessonCount} {c.lessonCount === 1 ? 'lesson' : 'lessons'})
            </option>
          ))}
        </select>
        <select
          id="lesson-filter-grade"
          className="toolbar-select"
          value={filterGrade}
          onChange={e => onFilterGrade(e.target.value)}
        >
          <option value="">All Grades</option>
          <option value="GRADE_4">Grade 4</option>
          <option value="GRADE_5">Grade 5</option>
          <option value="GRADE_6">Grade 6</option>
        </select>
        <button id="create-lesson-btn" className="btn btn--primary btn--sm" onClick={onCreate}>
          {isTeacher ? '+ New Class Lesson' : '+ New Lesson'}
        </button>
      </div>

      {/* Table */}
      {loading ? (
        <div className="auth-loading" style={{ minHeight: 300 }}><div className="spinner" /></div>
      ) : (
        <div className="lesson-table-wrap">
          <table className="lesson-table">
            <thead>
              <tr>
                <th style={{ width: 44, textAlign: 'center' }}>#</th>
                <th style={{ minWidth: 160 }}>Lesson Title</th>
                <th style={{ minWidth: 165 }}>Target Class / Cohort</th>
                <th style={{ minWidth: 100 }}>Category</th>
                <th style={{ minWidth: 90 }}>Grade</th>
                <th style={{ width: 65, textAlign: 'center' }}>Words</th>
                <th style={{ minWidth: 140 }}>Status</th>
                <th style={{ width: 95 }}>Created</th>
                <th style={{ width: 175, textAlign: 'right' }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 && (
                <tr>
                  <td colSpan={9} style={{ textAlign: 'center', color: 'var(--color-text-muted)', padding: '40px' }}>
                    No lessons found. {!searchQuery && !filterCategory && <span>Click <strong>+ New Lesson</strong> to get started.</span>}
                  </td>
                </tr>
              )}
              {filtered.map(lesson => {
                const isPublished = lesson.content_status === 'PUBLISHED';
                const isToggling = togglingId === lesson.lesson_id;
                const isClassLesson = Boolean(lesson.class_id);
                const canModify = isTeacher ? isClassLesson : !isClassLesson;

                return (
                  <tr key={lesson.lesson_id}>
                    <td className="text-muted" style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: '0.8rem', textAlign: 'center' }}>
                      {lesson.lesson_order}
                    </td>
                    <td style={{ minWidth: 160 }}>
                      <span style={{ fontWeight: 600, color: 'var(--color-text)', display: 'block', lineHeight: 1.25 }}>
                        {lesson.lesson_title}
                      </span>
                      <span className="text-muted" style={{ fontSize: '0.73rem' }}>
                        {lesson.lesson_type}
                      </span>
                    </td>
                    <td style={{ verticalAlign: 'middle', whiteSpace: 'nowrap' }}>
                      {lesson.class_id ? (
                        <div style={{ display: 'inline-flex', flexDirection: 'column', gap: '2px' }}>
                          <span
                            style={{
                              display: 'inline-flex',
                              alignItems: 'center',
                              gap: '5px',
                              padding: '3px 8px',
                              borderRadius: '6px',
                              fontSize: '0.75rem',
                              fontWeight: 700,
                              background: 'rgba(37, 99, 235, 0.10)',
                              color: 'var(--primary-mid)',
                              border: '1px solid rgba(37, 99, 235, 0.25)',
                              whiteSpace: 'nowrap',
                            }}
                          >
                            <span>🏫</span>
                            <span>{lesson.class_name || 'Class Lesson'}</span>
                          </span>
                          {lesson.class_code && (
                            <span style={{ fontSize: '0.7rem', color: 'var(--color-text-dim)', paddingLeft: '2px', whiteSpace: 'nowrap' }}>
                              Code: <code style={{ fontWeight: 700, letterSpacing: '0.5px' }}>{lesson.class_code}</code>
                            </span>
                          )}
                        </div>
                      ) : (
                        <span
                          style={{
                            display: 'inline-flex',
                            alignItems: 'center',
                            gap: '5px',
                            padding: '3px 8px',
                            borderRadius: '6px',
                            fontSize: '0.75rem',
                            fontWeight: 600,
                            background: 'rgba(16, 185, 129, 0.10)',
                            color: '#059669',
                            border: '1px solid rgba(16, 185, 129, 0.22)',
                            whiteSpace: 'nowrap',
                          }}
                        >
                          <span>🌍</span>
                          <span>Global Curriculum</span>
                        </span>
                      )}
                    </td>
                    <td className="text-muted" style={{ whiteSpace: 'nowrap' }}>{lesson.category_name}</td>
                    <td className="text-muted" style={{ whiteSpace: 'nowrap', fontSize: '0.8rem' }}>
                      {lesson.grade_level ? lesson.grade_level.replace('GRADE_', 'Grade ') : ''}
                    </td>
                    <td style={{ textAlign: 'center' }}>
                      <span className="word-count-badge">{lesson.total_word_count}</span>
                    </td>
                    <td>
                      <div style={{ display: 'inline-flex', alignItems: 'center', gap: 8, whiteSpace: 'nowrap' }}>
                        <label
                          className="toggle-switch"
                          title={!canModify ? 'Teacher-authored classroom lesson. View-only for administrator.' : (isPublished ? 'Click to unpublish (set to Draft)' : 'Click to publish lesson')}
                          style={!canModify ? { cursor: 'not-allowed', opacity: 0.6 } : {}}
                        >
                          <input
                            type="checkbox"
                            checked={isPublished}
                            disabled={isToggling || !canModify}
                            onChange={() => canModify && onTogglePublish && onTogglePublish(lesson)}
                          />
                          <span className="toggle-slider" />
                        </label>
                        <LessonStatusBadge status={lesson.content_status} />
                      </div>
                    </td>
                    <td className="text-muted" style={{ fontSize: '0.78rem', whiteSpace: 'nowrap' }}>
                      {new Date(lesson.created_at).toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' })}
                    </td>
                    <td style={{ textAlign: 'right', whiteSpace: 'nowrap' }}>
                      <div className="lesson-table-actions">
                        <button
                          className="btn btn--sm btn--ghost btn-lesson-action"
                          onClick={() => onViewWords(lesson)}
                          title={canModify ? 'Manage vocabulary words' : 'View vocabulary words'}
                        >
                          {canModify ? '📝 Words' : '👁️ View Words'}
                        </button>
                        {canModify ? (
                          <>
                            <button
                              className="btn btn--sm btn--ghost btn-lesson-action"
                              onClick={() => onPublish(lesson)}
                              title="Configure advanced publish settings (target grades, archive)"
                            >
                              🚦 Workflow
                            </button>
                            <button
                              className="btn-lesson-icon"
                              onClick={() => onEdit(lesson)}
                              title="Edit lesson details"
                            >
                              ✏️
                            </button>
                            <button
                              className="btn-lesson-icon btn-lesson-icon--danger"
                              onClick={() => onDelete(lesson)}
                              title="Delete lesson"
                            >
                              🗑️
                            </button>
                          </>
                        ) : (
                          <span
                            style={{
                              display: 'inline-flex',
                              alignItems: 'center',
                              padding: '4px 8px',
                              borderRadius: '6px',
                              fontSize: '0.72rem',
                              fontWeight: 700,
                              color: '#64748b',
                              background: 'rgba(100, 116, 139, 0.1)',
                              border: '1px solid rgba(100, 116, 139, 0.25)',
                              whiteSpace: 'nowrap',
                            }}
                            title="Teacher-authored classroom lesson. Administrators have view-only access."
                          >
                            👁️ View Only
                          </span>
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

      {!loading && (
        <div className="table-meta">
          Showing {filtered.length} of {lessons.length} lessons
        </div>
      )}
    </div>
  );
}
