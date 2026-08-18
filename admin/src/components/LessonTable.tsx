import type { AdminLesson } from '../services/LessonService';
import LessonStatusBadge from './LessonStatusBadge';
import type { AdminCategory } from '../services/CategoryService';

interface Props {
  lessons: AdminLesson[];
  categories: AdminCategory[];
  searchQuery: string;
  onSearchChange: (q: string) => void;
  filterCategory: string;
  onFilterCategory: (id: string) => void;
  filterGrade: string;
  onFilterGrade: (g: string) => void;
  onCreate: () => void;
  onEdit: (lesson: AdminLesson) => void;
  onDelete: (lesson: AdminLesson) => void;
  onViewWords: (lesson: AdminLesson) => void;
  onPublish: (lesson: AdminLesson) => void;
  loading?: boolean;
}

export default function LessonTable({
  lessons, categories, searchQuery, onSearchChange,
  filterCategory, onFilterCategory, filterGrade, onFilterGrade,
  onCreate, onEdit, onDelete, onViewWords, onPublish, loading
}: Props) {
  const filtered = lessons.filter(l => {
    const q = searchQuery.toLowerCase();
    const matchSearch = !q || l.lesson_title.toLowerCase().includes(q) || l.category_name.toLowerCase().includes(q);
    const matchCat = !filterCategory || l.category_id === filterCategory;
    const matchGrade = !filterGrade || l.grade_level === filterGrade;
    return matchSearch && matchCat && matchGrade;
  });

  return (
    <div>
      {/* Toolbar */}
      <div className="table-toolbar">
        <input
          id="lesson-search"
          className="toolbar-search"
          placeholder="🔍  Search lessons..."
          value={searchQuery}
          onChange={e => onSearchChange(e.target.value)}
        />
        <select
          className="toolbar-select"
          value={filterCategory}
          onChange={e => onFilterCategory(e.target.value)}
        >
          <option value="">All Categories</option>
          {categories.map(c => (
            <option key={c.category_id} value={c.category_id}>{c.category_name}</option>
          ))}
        </select>
        <select
          className="toolbar-select"
          value={filterGrade}
          onChange={e => onFilterGrade(e.target.value)}
        >
          <option value="">All Grades</option>
          <option value="GRADE_3_4">Grade 4</option>
          <option value="GRADE_5">Grade 5</option>
          <option value="GRADE_6">Grade 6</option>
        </select>
        <button id="create-lesson-btn" className="btn btn--primary btn--sm" onClick={onCreate}>
          + New Lesson
        </button>
      </div>

      {/* Table */}
      {loading ? (
        <div className="auth-loading" style={{ minHeight: 300 }}><div className="spinner" /></div>
      ) : (
        <div className="accounts-table-wrap">
          <table className="accounts-table">
            <thead>
              <tr>
                <th>#</th>
                <th>Lesson Title</th>
                <th>Category</th>
                <th>Grade</th>
                <th>Words</th>
                <th>Status</th>
                <th>Created</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 && (
                <tr>
                  <td colSpan={8} style={{ textAlign: 'center', color: 'var(--color-text-muted)', padding: '40px' }}>
                    No lessons found. {!searchQuery && !filterCategory && <span>Click <strong>+ New Lesson</strong> to get started.</span>}
                  </td>
                </tr>
              )}
              {filtered.map(lesson => (
                <tr key={lesson.lesson_id}>
                  <td className="text-muted" style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: '0.8rem' }}>
                    {lesson.lesson_order}
                  </td>
                  <td>
                    <span style={{ fontWeight: 600 }}>{lesson.lesson_title}</span>
                    <br />
                    <span className="text-muted" style={{ fontSize: '0.75rem' }}>
                      {lesson.lesson_type}
                    </span>
                  </td>
                  <td className="text-muted">{lesson.category_name}</td>
                  <td className="text-muted">{lesson.grade_level.replace('_', ' ')}</td>
                  <td>
                    <span className="word-count-badge">{lesson.total_word_count}</span>
                  </td>
                  <td><LessonStatusBadge status={lesson.content_status} /></td>
                  <td className="text-muted" style={{ fontSize: '0.8rem' }}>
                    {new Date(lesson.created_at).toLocaleDateString()}
                  </td>
                  <td className="actions-cell">
                    <button
                      className="btn btn--sm btn--ghost"
                      onClick={() => onViewWords(lesson)}
                      title="Manage vocabulary words"
                    >
                      📝 Words
                    </button>
                    <button
                      className="btn btn--sm btn--ghost"
                      onClick={() => onPublish(lesson)}
                      title="Manage publish status"
                    >
                      {lesson.content_status === 'PUBLISHED' ? '🔒 Unpublish' : '🚀 Publish'}
                    </button>
                    <button
                      className="btn btn--sm btn--ghost"
                      onClick={() => onEdit(lesson)}
                    >
                      ✏️
                    </button>
                    <button
                      className="btn btn--sm btn--danger-ghost"
                      onClick={() => onDelete(lesson)}
                    >
                      🗑️
                    </button>
                  </td>
                </tr>
              ))}
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
