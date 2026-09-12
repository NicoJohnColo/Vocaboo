import { useState, useEffect, useCallback } from 'react';
import AdminNav from '../components/AdminNav';
import { apiFetch } from '../services/AuthService';
import { useAdminAuth } from '../hooks/useAdminAuth';

export default function AdminAccountsPage() {
  const { admin: self } = useAdminAuth();
  const [accounts, setAccounts]       = useState([]);
  const [loading, setLoading]         = useState(true);
  const [error, setError]             = useState('');
  const [success, setSuccess]         = useState('');
  const [modal, setModal]             = useState(null);
  const [selectedId, setSelectedId]   = useState(null);
  const [activeTab, setActiveTab]     = useState('ALL'); // 'ALL' | 'ADMIN' | 'TEACHER'

  const [form, setForm] = useState({
    username: '',
    email: '',
    role: 'ADMIN', // 'ADMIN' | 'TEACHER'
    school: '',
    firstname: '',
    lastname: '',
  });
  const [submitting, setSubmitting]   = useState(false);

  const fetchAccounts = useCallback(() => {
    setLoading(true);
    apiFetch('/api/admin/accounts')
      .then(r => r.ok ? r.json() : Promise.reject(r.statusText))
      .then(setAccounts)
      .catch(() => setError('Failed to load accounts.'))
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => { fetchAccounts(); }, [fetchAccounts]);

  const flash = (msg) => {
    setSuccess(msg);
    setTimeout(() => setSuccess(''), 3500);
  };

  const handleToggleStatus = async (id, currentActive) => {
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

  const handleResetPassword = async (id) => {
    setSubmitting(true);
    try {
      const res = await apiFetch(`/api/admin/accounts/${id}/reset-password`, { method: 'POST' });
      if (!res.ok) throw new Error();
      flash('Password reset link sent to account email.');
      setModal(null);
    } catch {
      setError('Failed to send password reset email.');
    } finally {
      setSubmitting(false);
    }
  };

  const handleCreate = async (e) => {
    e.preventDefault();
    if (!form.username.trim() || !form.email.trim()) return;
    setSubmitting(true);
    try {
      const res = await apiFetch('/api/admin/accounts', {
        method: 'POST',
        body: JSON.stringify({
          username: form.username.trim(),
          email: form.email.trim(),
          role: form.role,
          school: form.school.trim(),
          firstname: form.firstname.trim(),
          lastname: form.lastname.trim(),
        }),
      });
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        throw new Error(body.message ?? 'Failed to create account.');
      }
      flash(`${form.role === 'TEACHER' ? 'Teacher' : 'Admin'} account created. Temporary password sent to email.`);
      setModal(null);
      setForm({ username: '', email: '', role: 'ADMIN', school: '', firstname: '', lastname: '' });
      fetchAccounts();
    } catch (err) {
      setError(err?.message || 'Failed to create account.');
    } finally {
      setSubmitting(false);
    }
  };

  const filteredAccounts = accounts.filter(acc => {
    if (activeTab === 'ADMIN') return acc.role === 'ADMIN';
    if (activeTab === 'TEACHER') return acc.role === 'TEACHER';
    return true;
  });

  const adminCount = accounts.filter(a => a.role === 'ADMIN').length;
  const teacherCount = accounts.filter(a => a.role === 'TEACHER').length;

  return (
    <div className="admin-layout">
      <AdminNav />
      <main className="admin-main">
        <header className="admin-main__header">
          <div>
            <h1 className="admin-main__title">Staff & Admin Accounts</h1>
            <p className="admin-main__subtitle">Manage Administrator and Teacher accounts for the Vocaboo management console</p>
          </div>
          <button
            id="create-admin-btn"
            className="btn btn--primary"
            onClick={() => setModal('create')}
            style={{ display: 'flex', alignItems: 'center', gap: 8 }}
          >
            <span>+</span> New Account
          </button>
        </header>

        {error   && <div className="alert alert--error"   onClick={() => setError('')} style={{ cursor: 'pointer' }}>{error}</div>}
        {success && <div className="alert alert--success">{success}</div>}

        {/* Filter Tabs */}
        <div style={{ display: 'flex', gap: 10, marginBottom: 20 }}>
          <button
            type="button"
            className={`btn btn--sm ${activeTab === 'ALL' ? 'btn--primary' : 'btn--ghost'}`}
            onClick={() => setActiveTab('ALL')}
            style={{ fontWeight: 700 }}
          >
            All Accounts ({accounts.length})
          </button>
          <button
            type="button"
            className={`btn btn--sm ${activeTab === 'ADMIN' ? 'btn--primary' : 'btn--ghost'}`}
            onClick={() => setActiveTab('ADMIN')}
            style={{ fontWeight: 700 }}
          >
            🛡️ Administrators ({adminCount})
          </button>
          <button
            type="button"
            className={`btn btn--sm ${activeTab === 'TEACHER' ? 'btn--primary' : 'btn--ghost'}`}
            onClick={() => setActiveTab('TEACHER')}
            style={{ fontWeight: 700 }}
          >
            🎓 Teachers ({teacherCount})
          </button>
        </div>

        {loading ? (
          <div className="auth-loading" style={{ minHeight: 300 }}><div className="spinner" /></div>
        ) : (
          <div className="accounts-table-wrap">
            <table className="accounts-table">
              <thead>
                <tr>
                  <th>Username / Name</th>
                  <th>Email</th>
                  <th>Role</th>
                  <th>School / Affiliation</th>
                  <th>Status</th>
                  <th>Joined / Last Login</th>
                  <th style={{ textAlign: 'right' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {filteredAccounts.length === 0 && (
                  <tr>
                    <td colSpan={7} style={{ textAlign: 'center', color: 'var(--color-text-muted)', padding: '40px' }}>
                      No accounts found in this category.
                    </td>
                  </tr>
                )}
                {filteredAccounts.map(acc => {
                  const isSelf = acc.account_id === self?.adminId || acc.admin_id === self?.adminId;
                  const isTeacher = acc.role === 'TEACHER';

                  return (
                    <tr key={acc.account_id || acc.admin_id} className={acc.is_active === false ? 'row--disabled' : ''}>
                      <td>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                          <div style={{
                            width: 34, height: 34, borderRadius: 10,
                            background: isTeacher
                              ? 'linear-gradient(135deg, #10b981, #059669)'
                              : 'linear-gradient(135deg, #3b82f6, #1d4ed8)',
                            display: 'grid', placeItems: 'center',
                            color: '#fff', fontSize: '0.85rem', fontWeight: 800, flexShrink: 0,
                            boxShadow: isTeacher ? '0 2px 8px rgba(16,185,129,0.25)' : '0 2px 8px rgba(37,99,235,0.25)',
                          }}>
                            {isTeacher ? '🎓' : '🛡️'}
                          </div>
                          <div>
                            <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                              <span className="account-username" style={{ fontWeight: 700, color: 'var(--color-text)' }}>
                                {acc.username}
                              </span>
                              {isSelf && <span className="badge badge--self" style={{ fontSize: '0.65rem' }}>You</span>}
                            </div>
                            {(acc.firstname || acc.lastname) && (
                              <div style={{ fontSize: '0.75rem', color: 'var(--color-text-muted)' }}>
                                {acc.firstname} {acc.lastname}
                              </div>
                            )}
                          </div>
                        </div>
                      </td>
                      <td className="text-muted" style={{ fontSize: '0.85rem' }}>{acc.email}</td>
                      <td>
                        {isTeacher ? (
                          <span
                            className="status-pill"
                            style={{
                              background: 'rgba(16, 185, 129, 0.12)',
                              color: '#059669',
                              border: '1px solid rgba(16, 185, 129, 0.3)',
                              fontWeight: 800,
                              fontSize: '0.78rem',
                              padding: '3px 8px',
                            }}
                          >
                            🎓 Teacher
                          </span>
                        ) : (
                          <span
                            className="status-pill"
                            style={{
                              background: 'rgba(37, 99, 235, 0.12)',
                              color: 'var(--primary-mid)',
                              border: '1px solid rgba(37, 99, 235, 0.3)',
                              fontWeight: 800,
                              fontSize: '0.78rem',
                              padding: '3px 8px',
                            }}
                          >
                            🛡️ Administrator
                          </span>
                        )}
                      </td>
                      <td>
                        {acc.school ? (
                          <span style={{ fontSize: '0.82rem', fontWeight: 600, color: 'var(--color-text)' }}>
                            {acc.school}
                          </span>
                        ) : (
                          <span style={{ fontSize: '0.8rem', color: 'var(--color-text-dim)' }}>—</span>
                        )}
                      </td>
                      <td>
                        <span className={`status-pill ${acc.is_active !== false ? 'status-pill--active' : 'status-pill--inactive'}`}>
                          {acc.is_active !== false ? 'Active' : 'Disabled'}
                        </span>
                      </td>
                      <td className="text-muted" style={{ fontSize: '0.8rem' }}>
                        {acc.last_login ? (
                          <span>Login: {new Date(acc.last_login).toLocaleDateString()}</span>
                        ) : acc.created_at ? (
                          <span>Created: {new Date(acc.created_at).toLocaleDateString()}</span>
                        ) : '—'}
                      </td>
                      <td style={{ textAlign: 'right' }}>
                        <div style={{ display: 'flex', gap: 6, justifyContent: 'flex-end' }}>
                          {!isTeacher && (
                            <button
                              type="button"
                              className={`btn btn--xs ${acc.is_active ? 'btn--danger-ghost' : 'btn--ghost'}`}
                              onClick={() => handleToggleStatus(acc.account_id || acc.admin_id, acc.is_active)}
                              disabled={isSelf}
                              title={isSelf ? "Can't disable your own account" : ''}
                            >
                              {acc.is_active ? 'Disable' : 'Enable'}
                            </button>
                          )}
                          <button
                            type="button"
                            className="btn btn--xs btn--ghost"
                            onClick={() => { setSelectedId(acc.account_id || acc.admin_id); setModal('reset'); }}
                          >
                            Reset PW
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}

        {/* ── Create Account Modal ────────────────────────────────────────── */}
        {modal === 'create' && (
          <div className="modal-overlay" onClick={() => setModal(null)}>
            <div className="modal modal--sm" onClick={e => e.stopPropagation()}>
              <div className="modal__header">
                <div>
                  <h2 className="modal__title">➕ Create Account</h2>
                  <p className="modal__subtitle">Select role and register a new staff member</p>
                </div>
                <button type="button" className="modal__close-btn" onClick={() => setModal(null)}>✕</button>
              </div>

              <form onSubmit={handleCreate}>
                {/* Role Selector */}
                <div className="form-field" style={{ marginBottom: 14 }}>
                  <label className="form-label">Account Role *</label>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
                    <button
                      type="button"
                      className={`btn btn--sm ${form.role === 'ADMIN' ? 'btn--primary' : 'btn--ghost'}`}
                      onClick={() => setForm(f => ({ ...f, role: 'ADMIN' }))}
                      style={{ fontWeight: 700, padding: '10px 8px', justifyContent: 'center' }}
                    >
                      🛡️ Administrator
                    </button>
                    <button
                      type="button"
                      className={`btn btn--sm ${form.role === 'TEACHER' ? 'btn--primary' : 'btn--ghost'}`}
                      onClick={() => setForm(f => ({ ...f, role: 'TEACHER' }))}
                      style={{
                        fontWeight: 700,
                        padding: '10px 8px',
                        justifyContent: 'center',
                        background: form.role === 'TEACHER' ? '#10b981' : undefined,
                        borderColor: form.role === 'TEACHER' ? '#10b981' : undefined,
                      }}
                    >
                      🎓 Teacher
                    </button>
                  </div>
                  <span className="form-hint" style={{ fontSize: '0.75rem', color: 'var(--color-text-muted)', marginTop: 4 }}>
                    {form.role === 'ADMIN'
                      ? 'Admins have full access to system logs, settings, and user management.'
                      : 'Teachers have access to classroom rosters, join codes, and lesson authoring.'}
                  </span>
                </div>

                <div className="form-field" style={{ marginBottom: 12 }}>
                  <label className="form-label">Username *</label>
                  <input
                    className="form-input"
                    value={form.username}
                    onChange={e => setForm(f => ({ ...f, username: e.target.value }))}
                    placeholder={form.role === 'TEACHER' ? 'teacher_maria' : 'admin_alex'}
                    required
                    autoFocus
                  />
                </div>

                <div className="form-field" style={{ marginBottom: 12 }}>
                  <label className="form-label">Email *</label>
                  <input
                    className="form-input"
                    type="email"
                    value={form.email}
                    onChange={e => setForm(f => ({ ...f, email: e.target.value }))}
                    placeholder={form.role === 'TEACHER' ? 'maria@school.edu.ph' : 'admin@vocaboo.edu'}
                    required
                  />
                </div>

                {form.role === 'TEACHER' && (
                  <>
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 12 }}>
                      <div className="form-field">
                        <label className="form-label">First Name</label>
                        <input
                          className="form-input"
                          value={form.firstname}
                          onChange={e => setForm(f => ({ ...f, firstname: e.target.value }))}
                          placeholder="Maria"
                        />
                      </div>
                      <div className="form-field">
                        <label className="form-label">Last Name</label>
                        <input
                          className="form-input"
                          value={form.lastname}
                          onChange={e => setForm(f => ({ ...f, lastname: e.target.value }))}
                          placeholder="Santos"
                        />
                      </div>
                    </div>

                    <div className="form-field" style={{ marginBottom: 12 }}>
                      <label className="form-label">School / Institution</label>
                      <input
                        className="form-input"
                        value={form.school}
                        onChange={e => setForm(f => ({ ...f, school: e.target.value }))}
                        placeholder="e.g. Central Elementary School"
                      />
                    </div>
                  </>
                )}

                <p className="modal__note" style={{ margin: '14px 0 20px', fontSize: '0.8rem', color: 'var(--color-text-muted)' }}>
                  A temporary password will be generated automatically and sent to the email address.
                </p>

                <div className="modal__actions">
                  <button type="button" className="btn btn--ghost" onClick={() => setModal(null)} disabled={submitting}>
                    Cancel
                  </button>
                  <button
                    type="submit"
                    className="btn btn--primary"
                    disabled={submitting || !form.username.trim() || !form.email.trim()}
                  >
                    {submitting ? <span className="spinner spinner--sm" /> : `Create ${form.role === 'TEACHER' ? 'Teacher' : 'Admin'}`}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* ── Reset Password Confirm Modal ────────────────────────────────── */}
        {modal === 'reset' && selectedId && (
          <div className="modal-overlay" onClick={() => setModal(null)}>
            <div className="modal modal--sm" onClick={e => e.stopPropagation()}>
              <div className="modal__header">
                <div>
                  <h2 className="modal__title">Send Password Reset</h2>
                  <p className="modal__subtitle">The link expires in 1 hour.</p>
                </div>
                <button type="button" className="modal__close-btn" onClick={() => setModal(null)}>✕</button>
              </div>

              <p className="modal__note" style={{ margin: '12px 0 20px', fontSize: '0.85rem', color: 'var(--color-text-muted)' }}>
                This will send a secure password reset link to the account's registered email address.
              </p>

              <div className="modal__actions">
                <button type="button" className="btn btn--ghost" onClick={() => setModal(null)} disabled={submitting}>
                  Cancel
                </button>
                <button
                  type="button"
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
