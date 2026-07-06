import { useState, useEffect, useCallback } from 'react';
import AdminNav from '../components/AdminNav';
import { apiFetch } from '../services/AuthService';
import { useAdminAuth } from '../hooks/useAdminAuth';
import type { AdminAccount } from '../types';

type ModalMode = 'create' | 'reset' | null;

export default function AdminAccountsPage() {
  const { admin: self } = useAdminAuth();
  const [accounts, setAccounts]       = useState<AdminAccount[]>([]);
  const [loading, setLoading]         = useState(true);
  const [error, setError]             = useState('');
  const [success, setSuccess]         = useState('');
  const [modal, setModal]             = useState<ModalMode>(null);
  const [selectedId, setSelectedId]   = useState<string | null>(null);
  const [form, setForm]               = useState({ username: '', email: '' });
  const [submitting, setSubmitting]   = useState(false);

  const fetchAccounts = useCallback(() => {
    setLoading(true);
    apiFetch('/api/admin/accounts')
      .then(r => r.ok ? r.json() : Promise.reject(r.statusText))
      .then(setAccounts)
      .catch(() => setError('Failed to load admin accounts.'))
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => { fetchAccounts(); }, [fetchAccounts]);

  const flash = (msg: string) => {
    setSuccess(msg);
    setTimeout(() => setSuccess(''), 3500);
  };

  const handleToggleStatus = async (id: string, currentActive: boolean) => {
    try {
      const res = await apiFetch(`/api/admin/accounts/${id}/status`, {
        method: 'PUT',
        body: JSON.stringify({ is_active: !currentActive }),
      });
      if (!res.ok) throw new Error();
      flash(`Account ${currentActive ? 'disabled' : 'enabled'} successfully.`);
      fetchAccounts();
    } catch {
      setError('Failed to update account status.');
    }
  };

  const handleResetPassword = async (id: string) => {
    setSubmitting(true);
    try {
      const res = await apiFetch(`/api/admin/accounts/${id}/reset-password`, { method: 'POST' });
      if (!res.ok) throw new Error();
      flash('Password reset link sent to admin email.');
      setModal(null);
    } catch {
      setError('Failed to send password reset email.');
    } finally {
      setSubmitting(false);
    }
  };

  const handleCreate = async () => {
    if (!form.username.trim() || !form.email.trim()) return;
    setSubmitting(true);
    try {
      const res = await apiFetch('/api/admin/accounts', {
        method: 'POST',
        body: JSON.stringify({ username: form.username.trim(), email: form.email.trim() }),
      });
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        throw new Error(body.message ?? 'Failed to create account.');
      }
      flash('Admin account created. Temporary password sent to email.');
      setModal(null);
      setForm({ username: '', email: '' });
      fetchAccounts();
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed to create account.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="admin-layout">
      <AdminNav />
      <main className="admin-main">
        <header className="admin-main__header">
          <div>
            <h1 className="admin-main__title">Admin Accounts</h1>
            <p className="admin-main__subtitle">Manage administrator access to the Vocaboo panel</p>
          </div>
          <button
            id="create-admin-btn"
            className="btn btn--primary"
            onClick={() => setModal('create')}
          >
            + New Admin
          </button>
        </header>

        {error   && <div className="alert alert--error"   onClick={() => setError('')}>{error}</div>}
        {success && <div className="alert alert--success">{success}</div>}

        {loading ? (
          <div className="auth-loading" style={{ minHeight: 300 }}><div className="spinner" /></div>
        ) : (
          <div className="accounts-table-wrap">
            <table className="accounts-table">
              <thead>
                <tr>
                  <th>Username</th>
                  <th>Email</th>
                  <th>Status</th>
                  <th>Last Login</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {accounts.length === 0 && (
                  <tr><td colSpan={5} style={{ textAlign: 'center', color: 'var(--color-text-muted)', padding: '40px' }}>No admin accounts found.</td></tr>
                )}
                {accounts.map(acc => (
                  <tr key={acc.admin_id} className={!acc.is_active ? 'row--disabled' : ''}>
                    <td>
                      <span className="account-username">{acc.username}</span>
                      {acc.admin_id === self?.adminId && <span className="badge badge--self">You</span>}
                    </td>
                    <td className="text-muted">{acc.email}</td>
                    <td>
                      <span className={`status-dot ${acc.is_active ? 'status-dot--active' : 'status-dot--inactive'}`}>
                        {acc.is_active ? 'Active' : 'Disabled'}
                      </span>
                    </td>
                    <td className="text-muted">
                      {acc.last_login ? new Date(acc.last_login).toLocaleDateString() : '—'}
                    </td>
                    <td className="actions-cell">
                      <button
                        className={`btn btn--sm ${acc.is_active ? 'btn--danger-ghost' : 'btn--ghost'}`}
                        onClick={() => handleToggleStatus(acc.admin_id, acc.is_active)}
                        disabled={acc.admin_id === self?.adminId}
                        title={acc.admin_id === self?.adminId ? "Can't disable your own account" : ''}
                      >
                        {acc.is_active ? 'Disable' : 'Enable'}
                      </button>
                      <button
                        className="btn btn--sm btn--ghost"
                        onClick={() => { setSelectedId(acc.admin_id); setModal('reset'); }}
                      >
                        Reset PW
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* Create Admin Modal */}
        {modal === 'create' && (
          <div className="modal-overlay" onClick={() => setModal(null)}>
            <div className="modal" onClick={e => e.stopPropagation()}>
              <h2 className="modal__title">Create New Admin</h2>
              <div className="login-form__field">
                <label className="login-form__label">Username</label>
                <input
                  className="login-form__input"
                  value={form.username}
                  onChange={e => setForm(f => ({ ...f, username: e.target.value }))}
                  placeholder="admin_username"
                  autoFocus
                />
              </div>
              <div className="login-form__field">
                <label className="login-form__label">Email</label>
                <input
                  className="login-form__input"
                  type="email"
                  value={form.email}
                  onChange={e => setForm(f => ({ ...f, email: e.target.value }))}
                  placeholder="admin@school.edu.ph"
                />
              </div>
              <p className="modal__note">A temporary password will be sent to the email address.</p>
              <div className="modal__actions">
                <button className="btn btn--ghost" onClick={() => setModal(null)}>Cancel</button>
                <button
                  className="btn btn--primary"
                  onClick={handleCreate}
                  disabled={submitting || !form.username || !form.email}
                >
                  {submitting ? <span className="spinner spinner--sm" /> : 'Create Account'}
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Reset Password Confirm Modal */}
        {modal === 'reset' && selectedId && (
          <div className="modal-overlay" onClick={() => setModal(null)}>
            <div className="modal" onClick={e => e.stopPropagation()}>
              <h2 className="modal__title">Send Password Reset</h2>
              <p className="modal__note">
                This will send a password reset link to the admin's email address.
                The link expires in 1 hour.
              </p>
              <div className="modal__actions">
                <button className="btn btn--ghost" onClick={() => setModal(null)}>Cancel</button>
                <button
                  className="btn btn--primary"
                  onClick={() => handleResetPassword(selectedId)}
                  disabled={submitting}
                >
                  {submitting ? <span className="spinner spinner--sm" /> : 'Send Reset Link'}
                </button>
              </div>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
