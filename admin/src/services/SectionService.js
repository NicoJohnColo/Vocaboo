import { apiFetch } from './AuthService';

export const SectionService = {
  /**
   * GET /api/admin/classes
   */
  async getAllSections() {
    const res = await apiFetch('/api/admin/classes');
    if (!res.ok) throw new Error('Failed to fetch classes/sections');
    return res.json();
  },

  /**
   * GET /api/admin/classes/{id}
   */
  async getSectionById(id) {
    const res = await apiFetch(`/api/admin/classes/${id}`);
    if (!res.ok) throw new Error('Failed to fetch class/section');
    return res.json();
  },

  /**
   * POST /api/admin/classes
   */
  async createSection(sectionName) {
    const res = await apiFetch('/api/admin/classes', {
      method: 'POST',
      body: JSON.stringify({ section_name: sectionName }),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.message || 'Failed to create section');
    }
    return res.json();
  },

  /**
   * PATCH /api/admin/classes/{id}
   */
  async updateSection(id, sectionName) {
    const res = await apiFetch(`/api/admin/classes/${id}`, {
      method: 'PATCH',
      body: JSON.stringify({ section_name: sectionName }),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.message || 'Failed to update section');
    }
    return res.json();
  },

  /**
   * DELETE /api/admin/classes/{id}
   */
  async deleteSection(id) {
    const res = await apiFetch(`/api/admin/classes/${id}`, {
      method: 'DELETE',
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.message || 'Failed to delete section');
    }
    return res.json();
  },
};
