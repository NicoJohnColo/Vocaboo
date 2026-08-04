import type { AdminAuthResponse } from '../types';

const BASE_URL = import.meta.env.VITE_API_URL ?? 'http://localhost:8080';
const TOKEN_KEY = 'vocaboo_admin_token';
const ADMIN_KEY = 'vocaboo_admin_info';

export const AuthService = {

  async adminLogin(username: string, password: string): Promise<AdminAuthResponse> {
    const res = await fetch(`${BASE_URL}/api/admin/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, password }),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({ message: 'Login failed' }));
      throw new Error(err.message ?? `HTTP ${res.status}`);
    }
    const data: AdminAuthResponse = await res.json();
    localStorage.setItem(TOKEN_KEY, data.token);
    localStorage.setItem(ADMIN_KEY, JSON.stringify({
      adminId: data.adminId,
      username: data.username,
      email: data.email,
      mustChangePassword: !!data.mustChangePassword,
    }));
    return data;
  },

  async adminRegister(username: string, email: string, password: string): Promise<AdminAuthResponse> {
    const res = await fetch(`${BASE_URL}/api/admin/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, email, password }),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({ message: 'Registration failed' }));
      throw new Error(err.message ?? `HTTP ${res.status}`);
    }
    const data: AdminAuthResponse = await res.json();
    localStorage.setItem(TOKEN_KEY, data.token);
    localStorage.setItem(ADMIN_KEY, JSON.stringify({
      adminId: data.adminId,
      username: data.username,
      email: data.email,
      mustChangePassword: !!data.mustChangePassword,
    }));
    return data;
  },

  logout(): void {
    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(ADMIN_KEY);
  },

  getToken(): string | null {
    return localStorage.getItem(TOKEN_KEY);
  },

  getAdminInfo(): { adminId: string; username: string; email: string; mustChangePassword?: boolean } | null {
    const raw = localStorage.getItem(ADMIN_KEY);
    if (!raw) return null;
    try { return JSON.parse(raw); }
    catch { return null; }
  },

  resolvePasswordChange(): void {
    const info = AuthService.getAdminInfo();
    if (info) {
      info.mustChangePassword = false;
      localStorage.setItem(ADMIN_KEY, JSON.stringify(info));
    }
  },

  isTokenValid(): boolean {
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

  async forgotPassword(email: string): Promise<void> {
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
};

export async function apiFetch(path: string, options: RequestInit = {}): Promise<Response> {
  const token = AuthService.getToken();
  const headers: HeadersInit = {
    'Content-Type': 'application/json',
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
    ...(options.headers as Record<string, string> ?? {}),
  };
  return fetch(`${BASE_URL}${path}`, { ...options, headers });
}
