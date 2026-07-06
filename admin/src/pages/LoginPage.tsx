import { useState, type FormEvent } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { AuthService } from '../services/AuthService';

export default function LoginPage() {
  const [username, setUsername] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [showPass, setShowPass] = useState(false);
  const [isRegistering, setIsRegistering] = useState(false);

  const navigate = useNavigate();
  const location = useLocation();
  const from = (location.state as { from?: { pathname: string } })?.from?.pathname ?? '/dashboard';

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError('');

    const cleanUsername = username.trim();
    const cleanEmail = email.trim();

    if (!cleanUsername) {
      setError('Username is required.');
      return;
    }

    if (isRegistering) {
      if (!cleanEmail) {
        setError('Email address is required.');
        return;
      }
      if (!password) {
        setError('Password is required.');
        return;
      }
      if (password.length < 6) {
        setError('Password must be at least 6 characters.');
        return;
      }
      if (password !== confirmPassword) {
        setError('Passwords do not match.');
        return;
      }
    } else {
      if (!password) {
        setError('Password is required.');
        return;
      }
    }

    setLoading(true);
    try {
      if (isRegistering) {
        const data = await AuthService.adminRegister(cleanUsername, cleanEmail, password);
        navigate(data.mustChangePassword ? '/force-change-password' : from, { replace: true });
      } else {
        const data = await AuthService.adminLogin(cleanUsername, password);
        navigate(data.mustChangePassword ? '/force-change-password' : from, { replace: true });
      }
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : `${isRegistering ? 'Registration' : 'Login'} failed. Please try again.`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-root">
      {/* Background decoration */}
      <div className="login-bg">
        <div className="login-bg__blob login-bg__blob--1" />
        <div className="login-bg__blob login-bg__blob--2" />
        <div className="login-bg__blob login-bg__blob--3" />
      </div>

      <main className="login-card">
        {/* Header */}
        <div className="login-card__header">
          <div className="login-card__logo">🎓</div>
          <h1 className="login-card__title">Vocaboo Admin</h1>
          <p className="login-card__subtitle">
            {isRegistering ? 'Create your administrator account' : 'Sign in to the management panel'}
          </p>
        </div>

        {/* Form */}
        <form className="login-form" onSubmit={handleSubmit} noValidate>
          {error && (
            <div className="login-form__error" role="alert">
              <span>⚠</span> {error}
            </div>
          )}

          <div className="login-form__field">
            <label htmlFor="username" className="login-form__label">Username</label>
            <input
              id="username"
              type="text"
              className="login-form__input"
              value={username}
              onChange={e => setUsername(e.target.value)}
              placeholder="admin_username"
              autoComplete="username"
              autoFocus
              required
              disabled={loading}
            />
          </div>

          {isRegistering && (
            <div className="login-form__field">
              <label htmlFor="email" className="login-form__label">Email Address</label>
              <input
                id="email"
                type="email"
                className="login-form__input"
                value={email}
                onChange={e => setEmail(e.target.value)}
                placeholder="admin@school.edu.ph"
                autoComplete="email"
                required
                disabled={loading}
              />
            </div>
          )}

          <div className="login-form__field">
            <label htmlFor="password" className="login-form__label">Password</label>
            <div className="login-form__input-wrapper">
              <input
                id="password"
                type={showPass ? 'text' : 'password'}
                className="login-form__input"
                value={password}
                onChange={e => setPassword(e.target.value)}
                placeholder="••••••••"
                autoComplete={isRegistering ? 'new-password' : 'current-password'}
                required
                disabled={loading}
              />
              <button
                type="button"
                className="login-form__toggle-pass"
                onClick={() => setShowPass(s => !s)}
                tabIndex={-1}
                aria-label={showPass ? 'Hide password' : 'Show password'}
              >
                {showPass ? '🙈' : '👁'}
              </button>
            </div>
          </div>

          {isRegistering && (
            <div className="login-form__field">
              <label htmlFor="confirmPassword" className="login-form__label">Confirm Password</label>
              <div className="login-form__input-wrapper">
                <input
                  id="confirmPassword"
                  type={showPass ? 'text' : 'password'}
                  className="login-form__input"
                  value={confirmPassword}
                  onChange={e => setConfirmPassword(e.target.value)}
                  placeholder="••••••••"
                  autoComplete="new-password"
                  required
                  disabled={loading}
                />
              </div>
            </div>
          )}

          <button
            id="login-submit"
            type="submit"
            className={`login-form__submit ${loading ? 'login-form__submit--loading' : ''}`}
            disabled={loading || !username || !password || (isRegistering && (!email || !confirmPassword))}
          >
            {loading ? (
              <span className="spinner spinner--sm" />
            ) : isRegistering ? (
              'Create Account'
            ) : (
              'Sign In'
            )}
          </button>

          <div className="login-form__separator">
            <span>OR</span>
          </div>

          <button
            id="login-switch"
            type="button"
            className="login-form__switch"
            onClick={() => {
              setError('');
              setPassword('');
              setConfirmPassword('');
              setIsRegistering(!isRegistering);
            }}
            disabled={loading}
          >
            {isRegistering ? 'Back to Sign In' : 'Create an account'}
          </button>
        </form>

        <p className="login-card__footer">
          Vocaboo — Cebuano Vocabulary Learning Platform
        </p>
      </main>
    </div>
  );
}
