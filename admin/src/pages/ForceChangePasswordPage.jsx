import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { apiFetch, AuthService } from '../services/AuthService';

export default function ForceChangePasswordPage() {
  const navigate = useNavigate();
  const [newPassword, setNewPassword]       = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPw, setShowPw]                 = useState(false);
  const [error, setError]                   = useState('');
  const [loading, setLoading]               = useState(false);

  const validate = () => {
    if (newPassword.length < 8) return 'Password must be at least 8 characters.';
    if (newPassword !== confirmPassword) return 'Passwords do not match.';
    return '';
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const err = validate();
    if (err) { setError(err); return; }

    setLoading(true);
    setError('');

    try {
      const res = await apiFetch('/api/admin/accounts/me/password', {
        method: 'PUT',
        body: JSON.stringify({ new_password: newPassword }),
      });

      if (!res.ok) {
        const data = await res.json().catch(() => ({}));
        throw new Error(data.error ?? data.message ?? 'Failed to change password.');
      }

      AuthService.resolvePasswordChange();
      navigate('/dashboard', { replace: true });
    } catch (err) {
      setError(err?.message || 'Something went wrong.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-page">
      <div className="auth-card">
        <div className="auth-card__icon">🔐</div>
        <h1 className="auth-card__title">Mandatory Password Change</h1>
        <p className="auth-card__subtitle">
          Your account requires a password change before you can continue.
        </p>

        {error && (
          <div className="alert alert--error" style={{ marginBottom: 16 }}>
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
          <div className="form-group">
            <label className="form-label" htmlFor="new-password">New Password *</label>
            <div style={{ position: 'relative' }}>
              <input
                id="new-password"
                type={showPw ? 'text' : 'password'}
                className="form-input"
                placeholder="At least 8 characters"
                value={newPassword}
                onChange={e => { setNewPassword(e.target.value); setError(''); }}
                required
                disabled={loading}
              />
              <button
                type="button"
                onClick={() => setShowPw(s => !s)}
                style={{
                  position: 'absolute', right: 12, top: '50%', transform: 'translateY(-50%)',
                  background: 'none', border: 'none', cursor: 'pointer',
                  color: 'var(--color-text-muted)', fontSize: '1rem',
                }}
                aria-label="Toggle password visibility"
                disabled={loading}
              >
                {showPw ? '🙈' : '👁️'}
              </button>
            </div>
          </div>

          <div className="form-group">
            <label className="form-label" htmlFor="confirm-password">Confirm Password *</label>
            <input
              id="confirm-password"
              type={showPw ? 'text' : 'password'}
              className={`form-input ${confirmPassword && confirmPassword !== newPassword ? 'form-input--error' : ''}`}
              placeholder="Repeat your new password"
              value={confirmPassword}
              onChange={e => { setConfirmPassword(e.target.value); setError(''); }}
              required
              disabled={loading}
            />
            {confirmPassword && confirmPassword !== newPassword && (
              <span className="form-error">Passwords do not match</span>
            )}
          </div>

          <button
            type="submit"
            className="btn btn--primary"
            style={{ width: '100%', marginTop: 4 }}
            disabled={loading}
          >
            {loading ? <span className="spinner spinner--sm" /> : '🔒 Set New Password'}
          </button>
        </form>
      </div>
    </div>
  );
}
