import { apiFetch } from './AuthService';

export const LearnerService = {
  /**
   * Search and filter learners with pagination.
   * @param {Object} params
   * @param {string} [params.search]
   * @param {string} [params.sectionId]
   * @param {string} [params.gradeLevel]
   * @param {boolean|string} [params.isActive]
   * @param {string} [params.cohortType] - 'ALL' | 'INDEPENDENT' | 'ENROLLED'
   * @param {number} [params.page=0]
   * @param {number} [params.size=20]
   * @param {string} [params.sortBy='displayName']
   * @param {string} [params.sortDir='asc']
   */
  async getLearners({
    search,
    sectionId,
    gradeLevel,
    isActive,
    cohortType,
    page = 0,
    size = 20,
    sortBy = 'displayName',
    sortDir = 'asc',
  } = {}) {
    const query = new URLSearchParams();
    if (search) query.set('search', search);
    if (sectionId) query.set('sectionId', sectionId);
    if (gradeLevel) query.set('gradeLevel', gradeLevel);
    if (isActive !== undefined && isActive !== '') query.set('isActive', String(isActive));
    if (cohortType) query.set('cohortType', cohortType);
    query.set('page', String(page));
    query.set('size', String(size));
    query.set('sortBy', sortBy);
    query.set('sortDir', sortDir);

    const res = await apiFetch(`/api/admin/learners?${query.toString()}`);
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.message || 'Failed to fetch learners');
    }
    return res.json();
  },

  /**
   * Get detailed diagnostic report and breakdown for a student.
   * @param {string} learnerId
   * @param {string} [classId] - optional class context filter
   */
  async getLearnerDetail(learnerId, classId) {
    const url = classId ? `/api/admin/learners/${learnerId}?classId=${encodeURIComponent(classId)}` : `/api/admin/learners/${learnerId}`;
    const res = await apiFetch(url);
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.message || 'Failed to fetch learner detail');
    }
    return res.json();
  },

  /**
   * Update student profile fields.
   * @param {string} learnerId
   * @param {Object} data
   */
  async updateLearner(learnerId, data) {
    const res = await apiFetch(`/api/admin/learners/${learnerId}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.message || 'Failed to update learner');
    }
    return res.json();
  },

  /**
   * Assign a student to a class section.
   * @param {string} learnerId
   * @param {string} sectionId
   */
  async assignClass(learnerId, sectionId) {
    const res = await apiFetch(`/api/admin/learners/${learnerId}/assign-class`, {
      method: 'POST',
      body: JSON.stringify({ section_id: sectionId }),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.message || 'Failed to assign class');
    }
    return res.json();
  },

  /**
   * Soft-deactivate student account.
   * @param {string} learnerId
   */
  async deactivateLearner(learnerId) {
    const res = await apiFetch(`/api/admin/learners/${learnerId}/deactivate`, {
      method: 'POST',
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.message || 'Failed to deactivate learner');
    }
    return res.json();
  },

  /**
   * Reactivate student account.
   * @param {string} learnerId
   */
  async reactivateLearner(learnerId) {
    const res = await apiFetch(`/api/admin/learners/${learnerId}/reactivate`, {
      method: 'POST',
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.message || 'Failed to reactivate learner');
    }
    return res.json();
  },

  /**
   * Permanently delete student account and all related learning records.
   * @param {string} learnerId
   */
  async deleteLearner(learnerId) {
    const res = await apiFetch(`/api/admin/learners/${learnerId}`, {
      method: 'DELETE',
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.message || 'Failed to delete student account');
    }
    return res.json();
  },

  /**
   * Reset learner progress (full or lesson-specific).
   * @param {string} learnerId
   * @param {string} [lessonId]
   */
  async resetProgress(learnerId, lessonId = null) {
    const res = await apiFetch(`/api/admin/learners/${learnerId}/reset-progress`, {
      method: 'POST',
      body: lessonId ? JSON.stringify({ lesson_id: lessonId }) : undefined,
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.message || 'Failed to reset progress');
    }
    return res.json();
  },

  /**
   * Execute bulk actions on selected learners.
   * @param {'ASSIGN_SECTION' | 'DEACTIVATE' | 'REACTIVATE' | 'RESET_PROGRESS'} action
   * @param {string[]} learnerIds
   * @param {string} [sectionId]
   * @param {string} [lessonId]
   */
  async executeBulkAction(action, learnerIds, sectionId = null, lessonId = null) {
    const payload = {
      action,
      learner_ids: learnerIds,
      section_id: sectionId,
      lesson_id: lessonId,
    };
    const res = await apiFetch('/api/admin/learners/bulk-action', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.message || 'Bulk action failed');
    }
    return res.json();
  },

  /**
   * Fetch learners flagged for teacher intervention.
   * @param {Object} [params]
   * @param {string} [params.sectionId]
   * @param {string} [params.gradeLevel]
   */
  async getFlaggedLearners({ sectionId, gradeLevel } = {}) {
    const query = new URLSearchParams();
    if (sectionId) query.set('sectionId', sectionId);
    if (gradeLevel) query.set('gradeLevel', gradeLevel);

    const res = await apiFetch(`/api/admin/learners/flagged?${query.toString()}`);
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.message || 'Failed to fetch flagged learners');
    }
    return res.json();
  },

  /**
   * Resolve / clear a teacher review flag on a learner's difficulty progress.
   * @param {string} progressId
   */
  async resolveFlagged(progressId) {
    const res = await apiFetch(`/api/admin/learners/flagged/${progressId}/resolve`, {
      method: 'POST',
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.message || 'Failed to resolve flag');
    }
    return res.json();
  },
};
