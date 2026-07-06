import { apiFetch } from './AuthService';

export interface AdminCategory {
  category_id: string;
  category_name: string;
  description: string;
  sort_order: number;
  created_at: string;
}

export const CategoryService = {
  async getAll(): Promise<AdminCategory[]> {
    const res = await apiFetch('/api/admin/categories');
    if (!res.ok) throw new Error('Failed to fetch categories');
    return res.json();
  },

  async create(payload: { category_name: string; description?: string; sort_order?: number }): Promise<AdminCategory> {
    const backendPayload = {
      category_name: payload.category_name,
      description: payload.description,
      sort_order: payload.sort_order,
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

  async update(id: string, payload: { category_name?: string; description?: string; sort_order?: number }): Promise<AdminCategory> {
    const backendPayload = {
      category_name: payload.category_name,
      description: payload.description,
      sort_order: payload.sort_order,
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

  async delete(id: string): Promise<void> {
    const res = await apiFetch(`/api/admin/categories/${id}`, { method: 'DELETE' });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.message ?? 'Cannot delete category');
    }
  },

  async reorder(orders: Record<string, number>): Promise<void> {
    const res = await apiFetch('/api/admin/categories/reorder', {
      method: 'POST',
      body: JSON.stringify(orders),
    });
    if (!res.ok) throw new Error('Failed to reorder categories');
  },
};
