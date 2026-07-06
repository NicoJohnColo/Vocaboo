import { useState, useEffect } from 'react';
import { useSearchParams, useNavigate } from 'react-router-dom';

const API = import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:8080';

type Stage = 'form' | 'success' | 'invalid';

export default function ResetPasswordPage() {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const token = searchParams.get('token') ?? '';

  const [stage, setStage]           = useState<Stage>(token ? 'form' : 'invalid');
  const [newPassword, setNewPassword] = useState('');
  const [confirm, setConfirm]       = useState('');
  const [showPw, setShowPw]         = useState(false);
  const [loading, setLoading]       = useState(false);
  const [error, setError]           = useState('');

  useEffect(() => {
    if (!token) setStage('invalid');
  }, [token]);

  const validate = (): string => {
    if (newPassword.length < 8) return 'Password must be at least 8 characters.';
    if (newPassword !== confirm) return 'Passwords do not match.';
    return '';
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const err = validate();
    if (err) { setError(err); return; }

    setLoading(true);
    setError('');
    try {
      const res = await fetch(`${API}/api/admin/accounts/complete-reset`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ token, new_password: newPassword }),
      });
      if (!res.ok) {
        const data = await res.json().catch(() => ({}));
        throw new Error(data.error ?? data.message ?? 'Invalid or expired reset link.');
      }
      setStage('success');
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Something went wrong.');
    } finally {
      setLoading(false);
    }
  };

  // ── Invalid / expired token ──────────────────────────────────────────────
  if (stage === 'invalid') {
    return (
      <div className="auth-page">
        <div className="auth-card">
          <div className="auth-card__icon">⚠️</div>
          <h1 className="auth-card__title">Invalid Link</h1>
          <p className="auth-card__subtitle">
            This password reset link is invalid or has expired.<br />
            Please ask an administrator to send a new reset link.
          </p>
          <button className="btn btn--primary" style={{ width: '100%' }} onClick={() => navigate('/login')}>
            Back to Login
          </button>
        </div>
      </div>
    );
  }

  // ── Success ──────────────────────────────────────────────────────────────
  if (stage === 'success') {
    return (
      <div className="auth-page">
        <div className="auth-card">
          <div className="auth-card__icon">✅</div>
          <h1 className="auth-card__title">Password Updated!</h1>
          <p className="auth-card__subtitle">
            Your password has been reset successfully.<br />
            You can now log in with your new password.
          </p>
          <button className="btn btn--primary" style={{ width: '100%' }} onClick={() => navigate('/login')}>
            Go to Login
          </button>
        </div>
      </div>
    );
  }

  // ── Form ─────────────────────────────────────────────────────────────────
  return (
    <div className="auth-page">
      <div className="auth-card">
        <div className="auth-card__icon">🔑</div>
        <h1 className="auth-card__title">Set New Password</h1>
        <p className="auth-card__subtitle">
          Choose a strong new password for your Vocaboo admin account.
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
              className={`form-input ${confirm && confirm !== newPassword ? 'form-input--error' : ''}`}
              placeholder="Repeat your new password"
              value={confirm}
              onChange={e => { setConfirm(e.target.value); setError(''); }}
              required
            />
            {confirm && confirm !== newPassword && (
              <span className="form-error">Passwords do not match</span>
            )}
          </div>

          <button
            id="reset-password-submit-btn"
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
