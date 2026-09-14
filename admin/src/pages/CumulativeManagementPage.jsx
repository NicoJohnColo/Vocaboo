import { useState, useEffect, useCallback, useMemo } from 'react';
import AdminNav from '../components/AdminNav';
import { CategoryService } from '../services/CategoryService';
import { LessonService } from '../services/LessonService';
import { SectionService } from '../services/SectionService';
import { useAdminAuth } from '../hooks/useAdminAuth';

const MODULE_4_OPTIONS = [
  { id: 'MULTIPLE_CHOICE',          label: 'Multiple Choice',         desc: '4-option recognition question' },
  { id: 'MATCHING',                 label: 'Word Matching',            desc: 'Match word to English/Cebuano meaning' },
  { id: 'FILL_IN_BLANK',            label: 'Fill in Blank',            desc: 'Type the missing word in context' },
  { id: 'WORD_SCRAMBLE',            label: 'Word Scramble',            desc: 'Arrange scrambled letter tiles' },
  { id: 'SENTENCE_RECONSTRUCTION',  label: 'Sentence Reconstruction',  desc: 'Arrange scrambled sentence tiles' },
  { id: 'TRUE_OR_FALSE',            label: 'True or False',            desc: 'Evaluate word/definition validity' },
];

function parseActivities(str) {
  if (!str) return [];
  return str.split(';').filter(Boolean)
    .map(x => x === 'IMAGE_MATCHING' ? 'MATCHING' : x === 'FILL_IN_THE_BLANK' ? 'FILL_IN_BLANK' : x);
}

export default function CumulativeManagementPage() {
  const { admin } = useAdminAuth();
  const isTeacher = admin?.role?.toLowerCase() === 'teacher' || admin?.role?.toUpperCase() === 'ROLE_TEACHER';

  const [categories, setCategories]         = useState([]);
  const [lessons, setLessons]               = useState([]);
  const [classes, setClasses]               = useState([]);
  const [loading, setLoading]               = useState(true);
  const [error, setError]                   = useState('');
  const [success, setSuccess]               = useState('');

  const [editingFormats, setEditingFormats] = useState({});
  const [savingCatId, setSavingCatId]       = useState(null);
  const [savingAll, setSavingAll]           = useState(false);
  const [formatModalCat, setFormatModalCat] = useState(null);

  const [sessionClass, setSessionClass]               = useState('');
  const [selectedCategoryIds, setSelectedCategoryIds] = useState(new Set());
  const [selectedLessonIds, setSelectedLessonIds]     = useState(new Set());

  const flash = (msg) => { setSuccess(msg); setTimeout(() => setSuccess(''), 3500); };

  const loadData = useCallback(async () => {
    setLoading(true); setError('');
    try {
      const [catList, lesList, clsList] = await Promise.all([
        CategoryService.getAll(),
        LessonService.getAll().catch(() => []),
        SectionService.getAllSections().catch(() => []),
      ]);
      setCategories(catList || []);
      setLessons(lesList || []);
      if (clsList) setClasses(clsList);
    } catch {
      setError('Unable to connect to backend server on port 8081. Please ensure the backend is running.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { loadData(); }, [loadData]);

  const getCatActivities = (cat) => {
    if (!cat) return 'MULTIPLE_CHOICE;MATCHING;FILL_IN_BLANK;WORD_SCRAMBLE;SENTENCE_RECONSTRUCTION;TRUE_OR_FALSE';
    const cid = String(cat.category_id || cat.categoryId);
    if (editingFormats[cid] !== undefined) return editingFormats[cid];
    return cat.module4_activities || cat.module4Activities || 'MULTIPLE_CHOICE;MATCHING;FILL_IN_BLANK;WORD_SCRAMBLE;SENTENCE_RECONSTRUCTION;TRUE_OR_FALSE';
  };

  const toggleFormat = (cat, optId) => {
    if (!cat) return;
    const cid = String(cat.category_id || cat.categoryId);
    let list = Array.from(new Set(parseActivities(getCatActivities(cat))));
    if (list.includes(optId)) {
      if (list.length <= 1) return;
      list = list.filter(x => x !== optId);
    } else {
      list = [...list, optId];
    }
    setEditingFormats(prev => ({ ...prev, [cid]: list.join(';') }));
  };

  const handleSaveCatFormats = async (cat) => {
    if (!cat) return;
    const cid = String(cat.category_id || cat.categoryId);
    const activities = editingFormats[cid] ?? getCatActivities(cat);
    setSavingCatId(cid);
    try {
      await CategoryService.update(cat.category_id || cat.categoryId, {
        category_name: cat.category_name || cat.categoryName,
        description: cat.description || '',
        class_id: cat.class_id || cat.classId || null,
        module4_activities: activities,
      });
      flash(`Saved activity formats for "${cat.category_name || cat.categoryName}"!`);
      setCategories(prev => prev.map(c =>
        String(c.category_id || c.categoryId) === cid ? { ...c, module4_activities: activities } : c
      ));
      setEditingFormats(prev => { const n = { ...prev }; delete n[cid]; return n; });
      setFormatModalCat(null);
    } catch (err) {
      setError(err?.message || 'Failed to save formats.');
    } finally {
      setSavingCatId(null);
    }
  };

  const handleSaveAllSelected = async () => {
    if (selectedCatObjs.length === 0) return;
    setSavingAll(true);
    try {
      await Promise.all(
        selectedCatObjs.map(cat => {
          const cid = String(cat.category_id || cat.categoryId);
          const activities = editingFormats[cid] ?? getCatActivities(cat);
          return CategoryService.update(cat.category_id || cat.categoryId, {
            category_name: cat.category_name || cat.categoryName,
            description: cat.description || '',
            class_id: cat.class_id || cat.classId || null,
            module4_activities: activities,
          });
        })
      );
      flash(`🎉 Saved & Published Cumulative Review settings for ${selectedCatObjs.length} categor${selectedCatObjs.length > 1 ? 'ies' : 'y'}!`);
      setFormatModalCat(null);
      setEditingFormats({});
      setSelectedCategoryIds(new Set());
      setSelectedLessonIds(new Set());
      loadData();
    } catch (err) {
      setError(err?.message || 'Failed to save cumulative review settings.');
    } finally {
      setSavingAll(false);
    }
  };

  const handleCancelEdit = (cat) => {
    if (!cat) { setFormatModalCat(null); return; }
    const cid = String(cat.category_id || cat.categoryId);
    setEditingFormats(prev => { const n = { ...prev }; delete n[cid]; return n; });
    setFormatModalCat(null);
  };

  const visibleCategories = useMemo(() => {
    if (!isTeacher) return categories;
    return categories.filter(c => {
      const hasClass = c.class_id || c.classId;
      if (!hasClass) return true;
      if (!sessionClass) return true;
      return String(c.class_id || c.classId) === String(sessionClass);
    });
  }, [categories, isTeacher, sessionClass]);

  const sessionLessons = useMemo(() => {
    if (selectedCategoryIds.size === 0) return [];
    return lessons.filter(l => {
      const matchCat = selectedCategoryIds.has(String(l.category_id || l.categoryId));
      const matchClass = !sessionClass || String(l.class_id || l.classId) === String(sessionClass);
      return matchCat && matchClass;
    });
  }, [lessons, selectedCategoryIds, sessionClass]);

  const toggleLesson = (id) => {
    setSelectedLessonIds(prev => { const n = new Set(prev); if (n.has(id)) n.delete(id); else n.add(id); return n; });
  };

  const toggleCategory = (catId) => {
    const id = String(catId);
    setSelectedCategoryIds(prev => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
        const ids = new Set(lessons.filter(l => String(l.category_id || l.categoryId) === id).map(l => l.lesson_id || l.lessonId));
        setSelectedLessonIds(p2 => { const n2 = new Set(p2); ids.forEach(lid => n2.delete(lid)); return n2; });
      } else { next.add(id); }
      return next;
    });
  };

  const handleClassChange = (classId) => {
    setSessionClass(classId); setSelectedCategoryIds(new Set()); setSelectedLessonIds(new Set());
  };

  const selectedCatFormats = useMemo(() => {
    const all = new Set();
    categories.filter(c => selectedCategoryIds.has(String(c.category_id || c.categoryId)))
      .forEach(c => parseActivities(getCatActivities(c)).forEach(f => all.add(f)));
    return Array.from(all);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [categories, selectedCategoryIds, editingFormats]);

  const selectedCatObjs = useMemo(() =>
    categories.filter(c => selectedCategoryIds.has(String(c.category_id || c.categoryId))),
    [categories, selectedCategoryIds]);

  const stepBadge = { background: '#4f46e5', color: '#fff', borderRadius: '50%', width: 24, height: 24, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', fontSize: '0.8rem', fontWeight: 900, flexShrink: 0 };

  return (
    <div className="admin-layout">
      <AdminNav />
      <main className="admin-main">
        <div className="admin-header" style={{ marginBottom: 20 }}>
          <div>
            <h1 className="admin-title" style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <span>🎓</span> Cumulative Review Management
            </h1>
            <p className="admin-subtitle">
              {isTeacher
                ? 'Select categories, configure their activity formats, pick lessons, and preview the review session for your classes.'
                : 'Select categories, configure their activity formats, pick lessons, and preview the review session for your global curriculum.'}
            </p>
          </div>
          <button className="btn btn--ghost" onClick={loadData} disabled={loading}>🔄 Refresh</button>
        </div>

        {error   && <div className="alert alert--error"   style={{ marginBottom: 16 }}>{error}</div>}
        {success && <div className="alert alert--success" style={{ marginBottom: 16 }}>{success}</div>}

        <div className="admin-stat-grid" style={{ marginBottom: 24 }}>
          <div className="stat-card">
            <div className="stat-card__label">Activity Formats</div>
            <div className="stat-card__val" style={{ color: '#4f46e5' }}>6 Types</div>
            <div className="stat-card__sub">MC, Matching, Fill-in-Blank, Scramble, Sentence Recon, True/False</div>
          </div>
          <div className="stat-card">
            <div className="stat-card__label">{isTeacher ? 'My Categories' : 'Total Categories'}</div>
            <div className="stat-card__val">{categories.length}</div>
            <div className="stat-card__sub">{isTeacher ? 'Classroom + Global' : 'Global & School'}</div>
          </div>
          <div className="stat-card">
            <div className="stat-card__label">{isTeacher ? 'My Lessons' : 'Total Lessons'}</div>
            <div className="stat-card__val">{lessons.length}</div>
            <div className="stat-card__sub">Available to include in reviews</div>
          </div>
          <div className="stat-card">
            <div className="stat-card__label">Mastery Qualification</div>
            <div className="stat-card__val" style={{ color: '#059669' }}>Mastered</div>
            <div className="stat-card__sub">Words at terminal difficulty tested</div>
          </div>
        </div>

        {/* STEP 1 */}
        <div className="section-card" style={{ marginBottom: 20 }}>
          <div style={{ padding: '14px 20px', borderBottom: '1px solid #e2e8f0', background: '#f8fafc', borderRadius: '12px 12px 0 0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <h2 style={{ margin: 0, fontSize: '1rem', fontWeight: 800, color: '#1e293b', display: 'flex', alignItems: 'center', gap: 8 }}>
              <span style={stepBadge}>1</span>
              Select Categories &amp; Configure Formats
            </h2>
            {selectedCategoryIds.size > 0 && (
              <button type="button" className="btn btn--xs btn--ghost"
                onClick={() => { setSelectedCategoryIds(new Set()); setSelectedLessonIds(new Set()); }}>
                ✕ Clear All
              </button>
            )}
          </div>

          {isTeacher && classes.length > 0 && (
            <div style={{ padding: '12px 20px', borderBottom: '1px solid #f1f5f9', display: 'flex', alignItems: 'center', gap: 12 }}>
              <label className="form-label" style={{ margin: 0, whiteSpace: 'nowrap' }}>🏫 Filter by Class:</label>
              <select className="form-select" value={sessionClass} onChange={(e) => handleClassChange(e.target.value)} style={{ maxWidth: 260 }}>
                <option value="">— All My Classes —</option>
                {classes.map(c => (
                  <option key={c.section_id || c.class_id} value={c.section_id || c.class_id}>{c.section_name || c.name}</option>
                ))}
              </select>
            </div>
          )}

          <div style={{ padding: '16px 20px' }}>
            {loading ? (
              <div style={{ textAlign: 'center', padding: '30px 0', color: '#94a3b8' }}>Loading categories...</div>
            ) : visibleCategories.length === 0 ? (
              <div style={{ textAlign: 'center', padding: '30px 0', color: '#94a3b8' }}>No categories found.</div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                {visibleCategories.map(cat => {
                  const cid = String(cat.category_id || cat.categoryId);
                  const cname = cat.category_name || cat.categoryName;
                  const isGlobal = !cat.class_id && !cat.classId;
                  const isSel = selectedCategoryIds.has(cid);
                  const currentActs = parseActivities(getCatActivities(cat));
                  const lessonCount = lessons.filter(l =>
                    String(l.category_id || l.categoryId) === cid &&
                    (!sessionClass || String(l.class_id || l.classId) === String(sessionClass))
                  ).length;

                  return (
                    <div key={cid} style={{ border: isSel ? '2px solid #4f46e5' : '1.5px solid #cbd5e1', borderRadius: 12, overflow: 'hidden', transition: 'all 0.15s', boxShadow: isSel ? '0 0 0 3px rgba(79,70,229,0.1)' : 'none', background: isSel ? '#f0f4ff' : '#fff' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '14px 18px' }}>
                        <div style={{ width: 22, height: 22, borderRadius: 6, border: isSel ? '2px solid #4f46e5' : '2px solid #cbd5e1', background: isSel ? '#4f46e5' : '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, cursor: 'pointer' }}
                          onClick={() => toggleCategory(cid)}>
                          {isSel && <span style={{ color: '#fff', fontSize: '0.75rem', fontWeight: 900 }}>✓</span>}
                        </div>
                        <div style={{ flex: 1, minWidth: 0, cursor: 'pointer' }} onClick={() => toggleCategory(cid)}>
                          <div style={{ fontWeight: 800, color: isSel ? '#312e81' : '#0f172a', fontSize: '0.95rem' }}>{cname}</div>
                          <div style={{ display: 'flex', gap: 8, marginTop: 4, alignItems: 'center', flexWrap: 'wrap' }}>
                            <span style={{ fontSize: '0.75rem', padding: '2px 8px', borderRadius: 4, background: isGlobal ? '#dcfce7' : '#e0e7ff', color: isGlobal ? '#15803d' : '#4338ca', fontWeight: 700 }}>
                              {isGlobal ? '🌍 Global' : '🏫 Classroom'}
                            </span>
                            <span style={{ fontSize: '0.75rem', color: '#64748b', fontWeight: 600 }}>{lessonCount} lesson{lessonCount !== 1 ? 's' : ''}</span>
                          </div>
                        </div>

                        {/* Activity Formats Pill Container & Edit Button */}
                        <div style={{ display: 'flex', alignItems: 'center', gap: 12, flexShrink: 0 }}>
                          <div style={{ display: 'flex', gap: 4, flexWrap: 'wrap', maxWidth: 380, justifyContent: 'flex-end', cursor: 'pointer' }}
                            onClick={(e) => { e.stopPropagation(); setFormatModalCat(cat); }}
                            title="Click to edit activity formats">
                            {MODULE_4_OPTIONS.map(opt => {
                              const active = currentActs.includes(opt.id);
                              return (
                                <span key={opt.id} style={{ fontSize: '0.72rem', padding: '3px 8px', borderRadius: 5, background: active ? '#eef2ff' : '#f1f5f9', color: active ? '#4f46e5' : '#94a3b8', fontWeight: active ? 700 : 500, border: active ? '1px solid #c7d2fe' : '1px solid #e2e8f0' }}>
                                  {active ? '✓' : '–'} {opt.label}
                                </span>
                              );
                            })}
                          </div>
                          <button type="button"
                            onClick={(e) => { e.stopPropagation(); setFormatModalCat(cat); }}
                            style={{ padding: '8px 14px', background: '#4f46e5', color: '#fff', fontWeight: 700, fontSize: '0.82rem', borderRadius: 8, border: 'none', cursor: 'pointer', whiteSpace: 'nowrap', display: 'flex', alignItems: 'center', gap: 6, boxShadow: '0 2px 4px rgba(79,70,229,0.2)' }}>
                            ⚙️ Edit Formats
                          </button>
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
            {selectedCategoryIds.size > 0 && (
              <div style={{ marginTop: 12, fontSize: '0.83rem', color: '#4f46e5', fontWeight: 600 }}>
                ✅ {selectedCategoryIds.size} categor{selectedCategoryIds.size !== 1 ? 'ies' : 'y'} selected
              </div>
            )}
          </div>
        </div>

        {/* STEP 2 */}
        <div className="section-card" style={{ marginBottom: 20 }}>
          <div style={{ padding: '14px 20px', borderBottom: '1px solid #e2e8f0', background: '#f8fafc', borderRadius: '12px 12px 0 0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <h2 style={{ margin: 0, fontSize: '1rem', fontWeight: 800, color: '#1e293b', display: 'flex', alignItems: 'center', gap: 8 }}>
              <span style={stepBadge}>2</span>
              Select Lessons to Include in This Review
            </h2>
            {sessionLessons.length > 0 && (
              <div style={{ display: 'flex', gap: 8 }}>
                <button type="button" className="btn btn--xs btn--ghost"
                  onClick={() => setSelectedLessonIds(new Set(sessionLessons.map(l => l.lesson_id || l.lessonId)))}>
                  ✅ Select All
                </button>
                <button type="button" className="btn btn--xs btn--ghost" onClick={() => setSelectedLessonIds(new Set())}>
                  ✕ Clear
                </button>
              </div>
            )}
          </div>
          <div style={{ padding: '16px 20px' }}>
            {selectedCategoryIds.size === 0 ? (
              <div style={{ textAlign: 'center', padding: '36px 20px', color: '#94a3b8' }}>
                <div style={{ fontSize: '2rem', marginBottom: 8 }}>📁</div>
                <div style={{ fontWeight: 600 }}>Select categories above to see their lessons</div>
              </div>
            ) : sessionLessons.length === 0 ? (
              <div style={{ textAlign: 'center', padding: '36px 20px', color: '#94a3b8' }}>
                <div style={{ fontSize: '2rem', marginBottom: 8 }}>📚</div>
                <div style={{ fontWeight: 600 }}>No lessons found in selected categories</div>
              </div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
                {Array.from(selectedCategoryIds).map(catId => {
                  const catObj = categories.find(c => String(c.category_id || c.categoryId) === catId);
                  const catName = catObj?.category_name || catObj?.categoryName || 'Unknown';
                  const catLessons = sessionLessons.filter(l => String(l.category_id || l.categoryId) === catId);
                  if (catLessons.length === 0) return null;
                  const catSelectedCount = catLessons.filter(l => selectedLessonIds.has(l.lesson_id || l.lessonId)).length;
                  return (
                    <div key={catId}>
                      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                          <span style={{ background: '#e0e7ff', color: '#3730a3', borderRadius: 6, padding: '2px 10px', fontSize: '0.82rem', fontWeight: 700 }}>📁 {catName}</span>
                          <span style={{ color: '#64748b', fontSize: '0.8rem' }}>{catSelectedCount}/{catLessons.length} selected</span>
                        </div>
                        <div style={{ display: 'flex', gap: 6 }}>
                          <button type="button" className="btn btn--xs btn--ghost"
                            onClick={() => setSelectedLessonIds(prev => { const n = new Set(prev); catLessons.forEach(l => n.add(l.lesson_id || l.lessonId)); return n; })}>All</button>
                          <button type="button" className="btn btn--xs btn--ghost"
                            onClick={() => setSelectedLessonIds(prev => { const n = new Set(prev); catLessons.forEach(l => n.delete(l.lesson_id || l.lessonId)); return n; })}>None</button>
                        </div>
                      </div>
                      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(240px, 1fr))', gap: 10 }}>
                        {catLessons.map(l => {
                          const lid = l.lesson_id || l.lessonId;
                          const isSel = selectedLessonIds.has(lid);
                          return (
                            <label key={lid} onClick={() => toggleLesson(lid)}
                              style={{ display: 'flex', alignItems: 'flex-start', gap: 12, padding: '12px 14px', borderRadius: 10, border: isSel ? '2px solid #4f46e5' : '1.5px solid #e2e8f0', background: isSel ? '#f0f4ff' : '#fff', cursor: 'pointer', transition: 'all 0.15s', boxShadow: isSel ? '0 0 0 3px rgba(79,70,229,0.1)' : 'none' }}>
                              <div style={{ width: 18, height: 18, borderRadius: 4, border: isSel ? '2px solid #4f46e5' : '2px solid #cbd5e1', background: isSel ? '#4f46e5' : '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, marginTop: 2 }}>
                                {isSel && <span style={{ color: '#fff', fontSize: '0.65rem', fontWeight: 900 }}>✓</span>}
                              </div>
                              <div>
                                <div style={{ fontWeight: 700, color: isSel ? '#312e81' : '#0f172a', fontSize: '0.88rem', lineHeight: 1.3 }}>
                                  {l.lesson_order || l.lessonOrder ? `#${l.lesson_order || l.lessonOrder} ` : ''}{l.lesson_title || l.lessonTitle}
                                </div>
                                <div style={{ fontSize: '0.75rem', color: '#64748b', marginTop: 3 }}>
                                  {(l.grade_level || l.gradeLevel || '').replace('GRADE_', 'Grade ')} · {l.content_status || l.contentStatus || 'DRAFT'}
                                </div>
                              </div>
                            </label>
                          );
                        })}
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </div>

        {/* STEP 3 — Preview & Save */}
        {selectedLessonIds.size > 0 && selectedCatObjs.length > 0 && (
          <div className="section-card" style={{ marginBottom: 20, border: '2px solid #4f46e5' }}>
            <div style={{ padding: '14px 20px', borderBottom: '1px solid #e0e7ff', background: 'linear-gradient(135deg, #eef2ff 0%, #f5f3ff 100%)', borderRadius: '12px 12px 0 0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <h2 style={{ margin: 0, fontSize: '1rem', fontWeight: 800, color: '#312e81', display: 'flex', alignItems: 'center', gap: 8 }}>
                <span style={stepBadge}>3</span>
                Review Session Preview &amp; Save
              </h2>
              <span style={{ fontSize: '0.82rem', color: '#6366f1', fontWeight: 600 }}>
                {selectedLessonIds.size} lesson{selectedLessonIds.size !== 1 ? 's' : ''} · {selectedCategoryIds.size} categor{selectedCategoryIds.size !== 1 ? 'ies' : 'y'}
              </span>
            </div>
            <div style={{ padding: '20px' }}>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: 12, marginBottom: 20 }}>
                <div style={{ padding: '12px 16px', background: '#f8fafc', borderRadius: 10, border: '1px solid #e2e8f0' }}>
                  <div style={{ fontSize: '0.75rem', color: '#64748b', fontWeight: 600, marginBottom: 4 }}>CATEGORIES</div>
                  <div style={{ fontWeight: 800, color: '#4f46e5', fontSize: '0.88rem' }}>{selectedCatObjs.map(c => c.category_name || c.categoryName).join(', ')}</div>
                </div>
                <div style={{ padding: '12px 16px', background: '#f8fafc', borderRadius: 10, border: '1px solid #e2e8f0' }}>
                  <div style={{ fontSize: '0.75rem', color: '#64748b', fontWeight: 600, marginBottom: 4 }}>LESSONS INCLUDED</div>
                  <div style={{ fontWeight: 800, color: '#4f46e5' }}>{selectedLessonIds.size} lesson{selectedLessonIds.size !== 1 ? 's' : ''}</div>
                </div>
                <div style={{ padding: '12px 16px', background: '#f8fafc', borderRadius: 10, border: '1px solid #e2e8f0' }}>
                  <div style={{ fontSize: '0.75rem', color: '#64748b', fontWeight: 600, marginBottom: 4 }}>WORDS TESTED</div>
                  <div style={{ fontWeight: 800, color: '#059669' }}>All Mastered words</div>
                </div>
              </div>
              <div style={{ marginBottom: 16 }}>
                <div style={{ fontWeight: 700, color: '#1e293b', fontSize: '0.88rem', marginBottom: 8 }}>✅ Included Lessons:</div>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
                  {sessionLessons.filter(l => selectedLessonIds.has(l.lesson_id || l.lessonId)).map(l => (
                    <span key={l.lesson_id || l.lessonId}
                      style={{ padding: '4px 12px', borderRadius: 20, background: '#eef2ff', color: '#3730a3', fontSize: '0.8rem', fontWeight: 700, border: '1px solid #c7d2fe' }}>
                      #{l.lesson_order || l.lessonOrder} {l.lesson_title || l.lessonTitle}
                    </span>
                  ))}
                </div>
              </div>
              <div style={{ marginBottom: 20 }}>
                <div style={{ fontWeight: 700, color: '#1e293b', fontSize: '0.88rem', marginBottom: 8 }}>
                  🎯 Activity Formats (combined from selected categories):
                </div>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
                  {selectedCatFormats.map(actId => {
                    const opt = MODULE_4_OPTIONS.find(o => o.id === actId);
                    return (
                      <span key={actId} style={{ padding: '5px 14px', borderRadius: 20, background: '#dcfce7', color: '#15803d', fontSize: '0.82rem', fontWeight: 700, border: '1px solid #bbf7d0' }}>
                        ✓ {opt ? opt.label : actId}
                      </span>
                    );
                  })}
                </div>
              </div>

              {/* SAVE BUTTON BAR */}
              <div style={{ marginTop: 20, paddingTop: 16, borderTop: '1px solid #e0e7ff', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 12 }}>
                <div style={{ fontSize: '0.85rem', color: '#475569' }}>
                  Click <strong>Save Settings</strong> to store and confirm your cumulative review format choices for all selected categories.
                </div>
                <button type="button"
                  style={{ background: '#4f46e5', color: '#fff', padding: '12px 24px', fontWeight: 800, fontSize: '0.95rem', borderRadius: 10, border: 'none', cursor: 'pointer', display: 'inline-flex', alignItems: 'center', gap: 8, boxShadow: '0 4px 12px rgba(79,70,229,0.3)' }}
                  onClick={handleSaveAllSelected}
                  disabled={savingAll}>
                  {savingAll ? <span className="spinner spinner--sm" /> : '💾 Save Cumulative Review Settings'}
                </button>
              </div>
            </div>
          </div>
        )}

        <div style={{ padding: '14px 20px', background: '#f8fafc', borderRadius: 12, border: '1px solid #e2e8f0' }}>
          <h3 style={{ fontSize: '0.9rem', fontWeight: 700, margin: '0 0 6px 0', color: '#1e293b' }}>
            💡 DepEd Mastery Standard for Cumulative Review (Module 4)
          </h3>
          <p style={{ fontSize: '0.83rem', color: '#475569', margin: 0, lineHeight: 1.6 }}>
            Module 4 is the summative evaluation. It automatically pulls words where learners achieved <strong>Mastered</strong> standing
            — with fallback to Proficient if none are mastered yet. Testing across activity formats ensures learners can recognize,
            define, spell, unscramble, evaluate, and reconstruct contextual sentences in English and Cebuano.
          </p>
        </div>
      </main>

      {/* Activity Format Modal Overlay */}
      {formatModalCat && (
        <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, zIndex: 999999, background: 'rgba(15, 23, 42, 0.75)', backdropFilter: 'blur(6px)', display: 'grid', placeItems: 'center', padding: 20 }}
          onClick={() => handleCancelEdit(formatModalCat)}>
          <div style={{ background: '#fff', borderRadius: 16, maxWidth: 560, width: '100%', padding: 24, boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25)', border: '1px solid #e2e8f0' }}
            onClick={(e) => e.stopPropagation()}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 16, borderBottom: '1px solid #e2e8f0', paddingBottom: 12 }}>
              <div>
                <h2 style={{ margin: 0, fontSize: '1.15rem', fontWeight: 800, color: '#0f172a' }}>
                  ⚙️ Activity Formats — {formatModalCat.category_name || formatModalCat.categoryName}
                </h2>
                <p style={{ margin: '4px 0 0', fontSize: '0.82rem', color: '#64748b' }}>
                  Select which activity types will appear during Cumulative Review for this category.
                </p>
              </div>
              <button type="button" style={{ background: 'none', border: 'none', fontSize: '1.2rem', cursor: 'pointer', color: '#64748b' }} onClick={() => handleCancelEdit(formatModalCat)}>✕</button>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(220px, 1fr))', gap: 10, margin: '20px 0' }}>
              {MODULE_4_OPTIONS.map(opt => {
                const active = parseActivities(getCatActivities(formatModalCat)).includes(opt.id);
                return (
                  <label key={opt.id} onClick={() => toggleFormat(formatModalCat, opt.id)}
                    style={{
                      display: 'flex',
                      alignItems: 'flex-start',
                      gap: 10,
                      padding: '12px 14px',
                      borderRadius: 10,
                      border: active ? '2px solid #4f46e5' : '1.5px solid #cbd5e1',
                      background: active ? '#f0f4ff' : '#fff',
                      cursor: 'pointer',
                      transition: 'all 0.12s'
                    }}>
                    <input type="checkbox" checked={active} onChange={() => {}} style={{ marginTop: 2, accentColor: '#4f46e5', width: 16, height: 16 }} />
                    <div>
                      <div style={{ fontWeight: 700, fontSize: '0.88rem', color: active ? '#312e81' : '#1e293b' }}>{opt.label}</div>
                      <div style={{ fontSize: '0.76rem', color: '#64748b', marginTop: 2 }}>{opt.desc}</div>
                    </div>
                  </label>
                );
              })}
            </div>

            <div style={{ display: 'flex', gap: 10, justifyContent: 'flex-end', paddingTop: 16, borderTop: '1px solid #e2e8f0' }}>
              <button type="button" className="btn btn--ghost" onClick={() => handleCancelEdit(formatModalCat)} disabled={savingCatId === String(formatModalCat.category_id || formatModalCat.categoryId)}>
                Cancel
              </button>
              <button type="button" className="btn btn--primary" style={{ background: '#4f46e5', color: '#fff', fontWeight: 800, padding: '8px 20px', borderRadius: 8 }} onClick={() => handleSaveCatFormats(formatModalCat)} disabled={savingCatId === String(formatModalCat.category_id || formatModalCat.categoryId)}>
                {savingCatId === String(formatModalCat.category_id || formatModalCat.categoryId) ? <span className="spinner spinner--sm" /> : '💾 Save Formats'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
