import { apiFetch } from './AuthService';

export const CategoryService = {
  async getAll(classId) {
    const url = classId ? `/api/admin/categories?classId=${encodeURIComponent(classId)}` : '/api/admin/categories';
    const res = await apiFetch(url);
    if (!res.ok) throw new Error('Failed to fetch categories');
    return res.json();
  },

  async create(payload) {
    const backendPayload = {
      category_name: payload.category_name,
      description: payload.description,
      sort_order: payload.sort_order,
      class_id: payload.class_id || null,
    };
    const res = await apiFetch('/api/admin/categories', {
      method: 'POST',
      body: JSON.stringify(backendPayload),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.message || 'Failed to create category');
    }
    return res.json();
  },

  async update(id, payload) {
    const backendPayload = {
      category_name: payload.category_name,
      description: payload.description,
      sort_order: payload.sort_order,
      class_id: payload.class_id || null,
    };
    const res = await apiFetch(`/api/admin/categories/${id}`, {
      method: 'PUT',
      body: JSON.stringify(backendPayload),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.message || 'Failed to update category');
    }
    return res.json();
  },

  async delete(id) {
    const res = await apiFetch(`/api/admin/categories/${id}`, { method: 'DELETE' });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.message ?? 'Cannot delete category');
    }
  },

  async reorder(orders) {
    const res = await apiFetch('/api/admin/categories/reorder', {
      method: 'POST',
      body: JSON.stringify(orders),
    });
    if (!res.ok) throw new Error('Failed to reorder categories');
  },
};
