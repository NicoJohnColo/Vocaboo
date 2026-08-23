const BASE_URL = import.meta.env.VITE_API_URL ?? 'http://localhost:8081';
const TOKEN_KEY = 'vocaboo_admin_token';
const ADMIN_KEY = 'vocaboo_admin_info';
const ROLE_KEY  = 'vocaboo_user_role';

export const AuthService = {

  async adminLogin(username, password) {
    const res = await fetch(`${BASE_URL}/api/admin/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, password }),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({ message: 'Login failed' }));
      throw new Error(err.message ?? `HTTP ${res.status}`);
    }
    const data = await res.json();
    localStorage.setItem(TOKEN_KEY, data.token);
    localStorage.setItem(ROLE_KEY, data.role ?? 'admin');
    localStorage.setItem(ADMIN_KEY, JSON.stringify({
      adminId: data.adminId,
      username: data.username,
      email: data.email,
      mustChangePassword: !!data.mustChangePassword,
      role: data.role ?? 'admin',
    }));
    return data;
  },

  async adminRegister(username, email, password) {
    const res = await fetch(`${BASE_URL}/api/admin/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, email, password }),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({ message: 'Registration failed' }));
      throw new Error(err.message ?? `HTTP ${res.status}`);
    }
    const data = await res.json();
    localStorage.setItem(TOKEN_KEY, data.token);
    localStorage.setItem(ADMIN_KEY, JSON.stringify({
      adminId: data.adminId,
      username: data.username,
      email: data.email,
      mustChangePassword: !!data.mustChangePassword,
    }));
    return data;
  },

  logout() {
    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(ADMIN_KEY);
    localStorage.removeItem(ROLE_KEY);
  },

  getToken() {
    return localStorage.getItem(TOKEN_KEY);
  },

  /** Returns "admin" or "teacher" based on the stored login response. */
  getRole() {
    return localStorage.getItem(ROLE_KEY) ?? 'admin';
  },

  getAdminInfo() {
    const raw = localStorage.getItem(ADMIN_KEY);
    if (!raw) return null;
    try { return JSON.parse(raw); }
    catch { return null; }
  },

  resolvePasswordChange() {
    const info = AuthService.getAdminInfo();
    if (info) {
      info.mustChangePassword = false;
      localStorage.setItem(ADMIN_KEY, JSON.stringify(info));
    }
  },

  isTokenValid() {
    const token = AuthService.getToken();
    if (!token) return false;
    try {
      const [, payloadB64] = token.split('.');
      const payload = JSON.parse(atob(payloadB64.replace(/-/g, '+').replace(/_/g, '/')));
      return payload.exp * 1000 > Date.now();
    } catch {
      return false;
    }
  },

  async forgotPassword(email) {
    const res = await fetch(`${BASE_URL}/api/admin/accounts/request-reset`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email }),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({ message: 'Request failed' }));
      throw new Error(err.error ?? err.message ?? `HTTP ${res.status}`);
    }
  },

  async teacherForgotPassword(email) {
    const res = await fetch(`${BASE_URL}/api/teachers/request-reset`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email }),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({ message: 'Request failed' }));
      throw new Error(err.error ?? err.message ?? `HTTP ${res.status}`);
    }
  },

  async teacherCompleteReset(token, newPassword) {
    const res = await fetch(`${BASE_URL}/api/teachers/complete-reset`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ token, new_password: newPassword }),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({ message: 'Reset failed' }));
      throw new Error(err.error ?? err.message ?? `HTTP ${res.status}`);
    }
  },
};

export async function apiFetch(path, options = {}) {
  const token = AuthService.getToken();
  const headers = {
    'Content-Type': 'application/json',
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
    ...(options.headers ?? {}),
  };
  return fetch(`${BASE_URL}${path}`, { ...options, headers });
}
