import { apiFetch } from './AuthService';

export const AnalyticsService = {
  /**
   * Fetch school-level, independent cohort, or class-level analytics payload.
   * @param {Object} params
   * @param {string} [params.sectionId]
   * @param {string} [params.gradeLevel]
   * @param {string} [params.timeRange='7d']
   * @param {string} [params.cohortType] - 'ALL' | 'INDEPENDENT' | 'ENROLLED'
   */
  async getDashboardAnalytics({ sectionId, gradeLevel, timeRange = '7d', cohortType } = {}) {
    const query = new URLSearchParams();
    if (sectionId) query.set('sectionId', sectionId);
    if (gradeLevel) query.set('gradeLevel', gradeLevel);
    if (timeRange) query.set('timeRange', timeRange);
    if (cohortType) query.set('cohortType', cohortType);

    const res = await apiFetch(`/api/admin/analytics/dashboard?${query.toString()}`);
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.message || 'Failed to fetch dashboard analytics');
    }
    return res.json();
  },

  /**
   * Fetch global demographics (Independent vs Enrolled ratios, language preference distributions).
   */
  async getDemographics() {
    const res = await apiFetch('/api/admin/analytics/demographics');
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.message || 'Failed to fetch demographics');
    }
    return res.json();
  },

  /**
   * Fetch live leaderboard rankings and gamification analytics summary.
   * @param {Object} params
   * @param {string} [params.range='weekly'] - 'weekly' | 'all_time'
   * @param {string} [params.cohortType] - 'ALL' | 'INDEPENDENT' | 'ENROLLED'
   * @param {string} [params.sectionId]
   */
  async getLeaderboardStats({ range = 'weekly', cohortType, sectionId } = {}) {
    const query = new URLSearchParams();
    if (range) query.set('range', range);
    if (cohortType) query.set('cohortType', cohortType);
    if (sectionId) query.set('sectionId', sectionId);

    const res = await apiFetch(`/api/admin/analytics/leaderboard-stats?${query.toString()}`);
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.message || 'Failed to fetch leaderboard statistics');
    }
    return res.json();
  },
};
