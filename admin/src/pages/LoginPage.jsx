import { useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { AuthService } from '../services/AuthService';

function RoleSelectionDialog({ isOpen, onClose, onChooseAdmin }) {
  const [step, setStep] = useState('role');

  // Teacher form fields
  const [tUsername, setTUsername] = useState('');
  const [tEmail, setTEmail] = useState('');
  const [tFirstName, setTFirstName] = useState('');
  const [tMiddleName, setTMiddleName] = useState('');
  const [tLastName, setTLastName] = useState('');
  const [tGender, setTGender] = useState('');
  const [tSchool, setTSchool] = useState('');
  const [tPassword, setTPassword] = useState('');
  const [tConfirmPassword, setTConfirmPassword] = useState('');
  const [tShowPass, setTShowPass] = useState(false);
  const [tError, setTError] = useState('');
  const [tLoading, setTLoading] = useState(false);

  const resetTeacherForm = () => {
    setStep('role');
    setTUsername(''); setTEmail(''); setTFirstName(''); setTMiddleName('');
    setTLastName(''); setTGender(''); setTSchool('');
    setTPassword(''); setTConfirmPassword(''); setTError('');
  };

  const handleClose = () => {
    resetTeacherForm();
    onClose();
  };

  const handleTeacherSubmit = async (e) => {
    e.preventDefault();
    setTError('');

    if (!tUsername.trim()) { setTError('Username is required.'); return; }
    if (tUsername.trim().length < 3) { setTError('Username must be at least 3 characters.'); return; }
    if (!tEmail.trim()) { setTError('Email is required.'); return; }
    if (!tFirstName.trim()) { setTError('First name is required.'); return; }
    if (!tLastName.trim()) { setTError('Last name is required.'); return; }
    if (!tPassword) { setTError('Password is required.'); return; }
    if (tPassword.length < 6) { setTError('Password must be at least 6 characters.'); return; }
    if (tPassword !== tConfirmPassword) { setTError('Passwords do not match.'); return; }

    setTLoading(true);
    try {
      const BASE_URL = import.meta.env.VITE_API_URL ?? 'http://localhost:8081';
      const res = await fetch(`${BASE_URL}/api/teachers/register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          username: tUsername.trim(),
          email: tEmail.trim(),
          password: tPassword,
          firstname: tFirstName.trim(),
          middlename: tMiddleName.trim(),
          lastname: tLastName.trim(),
          gender: tGender,
          school: tSchool.trim(),
        }),
      });
      if (!res.ok) {
        const err = await res.json().catch(() => ({ message: 'Registration failed' }));
        throw new Error(err.message ?? `HTTP ${res.status}`);
      }
      handleClose();
      alert('Teacher account created successfully! Please sign in.');
    } catch (err) {
      setTError(err?.message || 'Registration failed. Please try again.');
    } finally {
      setTLoading(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div
      id="role-dialog-overlay"
      className="role-dialog-overlay"
      onClick={(e) => { if (e.target === e.currentTarget) handleClose(); }}
    >
      <div className="role-dialog" role="dialog" aria-modal="true" aria-labelledby="role-dialog-title">

        {/* Step 1: Choose Role */}
        {step === 'role' && (
          <>
            <div className="role-dialog__header">
              <div className="role-dialog__icon">👤</div>
              <h2 id="role-dialog-title" className="role-dialog__title">Are you a…?</h2>
              <p className="role-dialog__subtitle">Select your role to continue with account creation.</p>
            </div>

            <div className="role-dialog__options">
              <button
                id="role-choose-admin"
                type="button"
                className="role-option-btn"
                onClick={() => { handleClose(); onChooseAdmin(); }}
              >
                <span className="role-option-btn__icon">🛡️</span>
                <span className="role-option-btn__label">Admin</span>
                <span className="role-option-btn__desc">Full management access</span>
              </button>

              <button
                id="role-choose-teacher"
                type="button"
                className="role-option-btn"
                onClick={() => setStep('details')}
              >
                <span className="role-option-btn__icon">📚</span>
                <span className="role-option-btn__label">Teacher</span>
                <span className="role-option-btn__desc">Classroom management access</span>
              </button>
            </div>

            <button
              id="role-dialog-cancel"
              type="button"
              className="role-dialog__cancel"
              onClick={handleClose}
            >
              Cancel
            </button>
          </>
        )}

        {/* Step 2: Teacher Details Form */}
        {step === 'details' && (
          <>
            <div className="role-dialog__header">
              <div className="role-dialog__icon">📚</div>
              <h2 id="role-dialog-title" className="role-dialog__title">Create Teacher Account</h2>
              <p className="role-dialog__subtitle">Fill in your details to register as a teacher.</p>
            </div>

            <form className="role-dialog__form" onSubmit={handleTeacherSubmit} noValidate>
              {tError && (
                <div className="login-form__error" role="alert" style={{ marginBottom: '12px' }}>
                  <span>⚠</span> {tError}
                </div>
              )}

              {/* Username */}
              <div className="login-form__field">
                <label htmlFor="t-username" className="login-form__label">Username</label>
                <input
                  id="t-username"
                  type="text"
                  className="login-form__input"
                  value={tUsername}
                  onChange={e => setTUsername(e.target.value)}
                  placeholder="teacher_username"
                  autoComplete="username"
                  autoFocus
                  required
                  disabled={tLoading}
                />
              </div>

              {/* Email */}
              <div className="login-form__field">
                <label htmlFor="t-email" className="login-form__label">Email Address</label>
                <input
                  id="t-email"
                  type="email"
                  className="login-form__input"
                  value={tEmail}
                  onChange={e => setTEmail(e.target.value)}
                  placeholder="teacher@school.edu.ph"
                  autoComplete="email"
                  required
                  disabled={tLoading}
                />
              </div>

              {/* Name row */}
              <div className="role-dialog__name-row">
                <div className="login-form__field">
                  <label htmlFor="t-firstname" className="login-form__label">First Name</label>
                  <input
                    id="t-firstname"
                    type="text"
                    className="login-form__input"
                    value={tFirstName}
                    onChange={e => setTFirstName(e.target.value)}
                    placeholder="Juan"
                    required
                    disabled={tLoading}
                  />
                </div>
                <div className="login-form__field">
                  <label htmlFor="t-middlename" className="login-form__label">Middle Name</label>
                  <input
                    id="t-middlename"
                    type="text"
                    className="login-form__input"
                    value={tMiddleName}
                    onChange={e => setTMiddleName(e.target.value)}
                    placeholder="(Optional)"
                    disabled={tLoading}
                  />
                </div>
                <div className="login-form__field">
                  <label htmlFor="t-lastname" className="login-form__label">Last Name</label>
                  <input
                    id="t-lastname"
                    type="text"
                    className="login-form__input"
                    value={tLastName}
                    onChange={e => setTLastName(e.target.value)}
                    placeholder="Dela Cruz"
                    required
                    disabled={tLoading}
                  />
                </div>
              </div>

              {/* Gender */}
              <div className="login-form__field">
                <label htmlFor="t-gender" className="login-form__label">Gender</label>
                <select
                  id="t-gender"
                  className="login-form__input"
                  value={tGender}
                  onChange={e => setTGender(e.target.value)}
                  disabled={tLoading}
                  style={{ cursor: 'pointer' }}
                >
                  <option value="">Select gender…</option>
                  <option value="Male">Male</option>
                  <option value="Female">Female</option>
                  <option value="Other">Other</option>
                  <option value="Prefer not to say">Prefer not to say</option>
                </select>
              </div>

              {/* School */}
              <div className="login-form__field">
                <label htmlFor="t-school" className="login-form__label">School</label>
                <input
                  id="t-school"
                  type="text"
                  className="login-form__input"
                  value={tSchool}
                  onChange={e => setTSchool(e.target.value)}
                  placeholder="School name"
                  disabled={tLoading}
                />
              </div>

              {/* Password */}
              <div className="login-form__field">
                <label htmlFor="t-password" className="login-form__label">Password</label>
                <div className="login-form__input-wrapper">
                  <input
                    id="t-password"
                    type={tShowPass ? 'text' : 'password'}
                    className="login-form__input"
                    value={tPassword}
                    onChange={e => setTPassword(e.target.value)}
                    placeholder="••••••••"
                    autoComplete="new-password"
                    required
                    disabled={tLoading}
                  />
                  <button
                    type="button"
                    className="login-form__toggle-pass"
                    onClick={() => setTShowPass(s => !s)}
                    tabIndex={-1}
                    aria-label={tShowPass ? 'Hide password' : 'Show password'}
                  >
                    {tShowPass ? '🙈' : '👁'}
                  </button>
                </div>
              </div>

              {/* Confirm Password */}
              <div className="login-form__field">
                <label htmlFor="t-confirm-password" className="login-form__label">Confirm Password</label>
                <input
                  id="t-confirm-password"
                  type={tShowPass ? 'text' : 'password'}
                  className="login-form__input"
                  value={tConfirmPassword}
                  onChange={e => setTConfirmPassword(e.target.value)}
                  placeholder="••••••••"
                  autoComplete="new-password"
                  required
                  disabled={tLoading}
                />
              </div>

              <div className="role-dialog__actions">
                <button
                  id="teacher-back-to-role"
                  type="button"
                  className="role-dialog__cancel"
                  onClick={() => { setStep('role'); setTError(''); }}
                  disabled={tLoading}
                >
                  ← Back
                </button>
                <button
                  id="teacher-register-submit"
                  type="submit"
                  className={`login-form__submit ${tLoading ? 'login-form__submit--loading' : ''}`}
                  disabled={tLoading || !tUsername || !tEmail || !tFirstName || !tLastName || !tPassword || !tConfirmPassword}
                  style={{ flex: 1 }}
                >
                  {tLoading ? <span className="spinner spinner--sm" /> : 'Create Teacher Account'}
                </button>
              </div>
            </form>
          </>
        )}
      </div>
    </div>
  );
}

export default function LoginPage() {
  const [view, setView] = useState('login');

  // Login / Register state
  const [username, setUsername] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [showPass, setShowPass] = useState(false);
  const [isRegistering, setIsRegistering] = useState(false);

  // Role dialog state
  const [showRoleDialog, setShowRoleDialog] = useState(false);

  // Forgot password state
  const [forgotEmail, setForgotEmail] = useState('');
  const [forgotRole, setForgotRole] = useState('admin');
  const [forgotError, setForgotError] = useState('');
  const [forgotLoading, setForgotLoading] = useState(false);

  const navigate = useNavigate();
  const location = useLocation();
  const from = location.state?.from?.pathname ?? '/dashboard';

  const handleSubmit = async (e) => {
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
    } catch (err) {
      setError(err?.message || `${isRegistering ? 'Registration' : 'Login'} failed. Please try again.`);
    } finally {
      setLoading(false);
    }
  };

  const handleForgotSubmit = async (e) => {
    e.preventDefault();
    setForgotError('');
    if (!forgotEmail.trim()) {
      setForgotError('Please enter your email address.');
      return;
    }
    setForgotLoading(true);
    try {
      if (forgotRole === 'teacher') {
        await AuthService.teacherForgotPassword(forgotEmail.trim());
      } else {
        await AuthService.forgotPassword(forgotEmail.trim());
      }
      setView('forgot-sent');
    } catch (err) {
      setForgotError(err?.message || 'Something went wrong. Please try again.');
    } finally {
      setForgotLoading(false);
    }
  };

  const goBackToLogin = () => {
    setView('login');
    setForgotEmail('');
    setForgotError('');
    setError('');
  };

  const Bg = () => (
    <div className="login-bg">
      <div className="login-bg__blob login-bg__blob--1" />
      <div className="login-bg__blob login-bg__blob--2" />
      <div className="login-bg__blob login-bg__blob--3" />
    </div>
  );

  if (view === 'forgot-sent') {
    return (
      <div className="login-root">
        <Bg />
        <main className="login-card">
          <div className="login-card__header">
            <div className="login-card__logo">📧</div>
            <h1 className="login-card__title">Check Your Email</h1>
            <p className="login-card__subtitle">
              If <strong>{forgotEmail}</strong> is registered, a password reset link has been sent.
              The link expires in <strong>1 hour</strong>.
            </p>
          </div>
          <div style={{ padding: '0 0 8px' }}>
            <button
              id="forgot-back-to-login"
              type="button"
              className="login-form__submit"
              onClick={goBackToLogin}
              style={{ width: '100%' }}
            >
              ← Back to Sign In
            </button>
          </div>
          <p className="login-card__footer">
            Didn't receive it? Check your spam folder or contact another admin.
          </p>
        </main>
      </div>
    );
  }

  if (view === 'forgot') {
    return (
      <div className="login-root">
        <Bg />
        <main className="login-card">
          <div className="login-card__header">
            <div className="login-card__logo">🔑</div>
            <h1 className="login-card__title">Forgot Password</h1>
            <p className="login-card__subtitle">
              Enter the email linked to your {forgotRole} account and we'll send a reset link.
            </p>
          </div>

          <form className="login-form" onSubmit={handleForgotSubmit} noValidate>
            {forgotError && (
              <div className="login-form__error" role="alert">
                <span>⚠</span> {forgotError}
              </div>
            )}

            {/* Role toggle */}
            <div className="forgot-role-toggle">
              <button
                id="forgot-role-admin"
                type="button"
                className={`forgot-role-toggle__btn ${forgotRole === 'admin' ? 'forgot-role-toggle__btn--active' : ''}`}
                onClick={() => setForgotRole('admin')}
                disabled={forgotLoading}
              >
                🛡️ Admin
              </button>
              <button
                id="forgot-role-teacher"
                type="button"
                className={`forgot-role-toggle__btn ${forgotRole === 'teacher' ? 'forgot-role-toggle__btn--active' : ''}`}
                onClick={() => setForgotRole('teacher')}
                disabled={forgotLoading}
              >
                📚 Teacher
              </button>
            </div>

            <div className="login-form__field">
              <label htmlFor="forgot-email" className="login-form__label">Email Address</label>
              <input
                id="forgot-email"
                type="email"
                className="login-form__input"
                value={forgotEmail}
                onChange={e => setForgotEmail(e.target.value)}
                placeholder={forgotRole === 'teacher' ? 'teacher@school.edu.ph' : 'admin@school.edu.ph'}
                autoComplete="email"
                autoFocus
                required
                disabled={forgotLoading}
              />
            </div>

            <button
              id="forgot-submit"
              type="submit"
              className={`login-form__submit ${forgotLoading ? 'login-form__submit--loading' : ''}`}
              disabled={forgotLoading || !forgotEmail}
            >
              {forgotLoading ? <span className="spinner spinner--sm" /> : 'Send Reset Link'}
            </button>

            <div className="login-form__separator"><span>OR</span></div>

            <button
              id="forgot-back"
              type="button"
              className="login-form__switch"
              onClick={goBackToLogin}
              disabled={forgotLoading}
            >
              ← Back to Sign In
            </button>
          </form>

          <p className="login-card__footer">
            Vocaboo — Cebuano Vocabulary Learning Platform
          </p>
        </main>
      </div>
    );
  }

  return (
    <div className="login-root">
      <Bg />

      <RoleSelectionDialog
        isOpen={showRoleDialog}
        onClose={() => setShowRoleDialog(false)}
        onChooseAdmin={() => {
          setError('');
          setPassword('');
          setConfirmPassword('');
          setIsRegistering(true);
        }}
      />

      <main className="login-card">
        <div className="login-card__header">
          <div className="login-card__logo">🎓</div>
          <h1 className="login-card__title">Vocaboo Admin</h1>
          <p className="login-card__subtitle">
            {isRegistering ? 'Create your administrator account' : 'Sign in to the management panel'}
          </p>
        </div>

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
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
              <label htmlFor="password" className="login-form__label">Password</label>
              {!isRegistering && (
                <button
                  id="forgot-password-link"
                  type="button"
                  onClick={() => { setError(''); setView('forgot'); }}
                  disabled={loading}
                  style={{
                    background: 'none',
                    border: 'none',
                    padding: 0,
                    cursor: 'pointer',
                    fontSize: '0.8rem',
                    color: 'var(--color-primary)',
                    fontWeight: 500,
                    textDecoration: 'underline',
                    opacity: loading ? 0.5 : 1,
                  }}
                >
                  Forgot password?
                </button>
              )}
            </div>
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
              if (!isRegistering) {
                setShowRoleDialog(true);
              } else {
                setError('');
                setPassword('');
                setConfirmPassword('');
                setIsRegistering(false);
              }
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
