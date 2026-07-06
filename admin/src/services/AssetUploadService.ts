const BASE_URL = import.meta.env.VITE_API_URL ?? 'http://localhost:8080';

function getAuthHeaders(): Record<string, string> {
  const token = localStorage.getItem('vocaboo_admin_token');
  return token ? { Authorization: `Bearer ${token}` } : {};
}

export const AssetUploadService = {
  async uploadFile(
    file: File,
    assetType: 'AUDIO' | 'IMAGE',
    lessonId: string,
    wordId?: string
  ): Promise<{ asset_url: string; file_type: string; size_kb: number; asset_id: string }> {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('asset_type', assetType);
    formData.append('lesson_id', lessonId);
    if (wordId) formData.append('word_id', wordId);

    const res = await fetch(`${BASE_URL}/api/admin/assets/upload`, {
      method: 'POST',
      headers: getAuthHeaders(),
      body: formData,
    });

    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.message ?? `Upload failed (${res.status})`);
    }
    return res.json();
  },

  async verifyUrl(url: string): Promise<{ accessible: boolean; status_code: number }> {
    const token = localStorage.getItem('vocaboo_admin_token');
    const params = new URLSearchParams({ url });
    const res = await fetch(`${BASE_URL}/api/admin/assets/verify?${params}`, {
      headers: token ? { Authorization: `Bearer ${token}` } : {},
    });
    if (!res.ok) return { accessible: false, status_code: res.status };
    return res.json();
  },

  async deleteAsset(assetId: string): Promise<void> {
    const res = await fetch(`${BASE_URL}/api/admin/assets/${assetId}`, {
      method: 'DELETE',
      headers: getAuthHeaders(),
    });
    if (!res.ok) throw new Error('Failed to delete asset');
  },
};
