import { useState } from 'react';
import { NavLink, useNavigate } from 'react-router-dom';
import { useAdminAuth } from '../hooks/useAdminAuth';

const NAV_ITEMS = [
  { to: '/dashboard',          label: 'Analytics Dashboard',    icon: '⬡' },
  { to: '/leaderboard-stats',  label: 'Leaderboards & Rewards', icon: '🏆' },
  { to: '/learners',           label: 'User Management',        icon: '👥' },
  { to: '/classes',            label: 'Class Sections',         icon: '🏫' },
  { to: '/reports',            label: 'Reports & Exports',      icon: '📊' },
  { to: '/lessons',            label: 'Lesson Management',      icon: '📚' },
  { to: '/categories',         label: 'Categories',             icon: '🗂️' },
  { to: '/wrong-answers',      label: 'Wrong Answer Analysis',  icon: '🔍' },
  { to: '/accounts',           label: 'Admin Accounts',         icon: '👤' },
  { to: '/logs',               label: 'System Logs',            icon: '📋' },
];

export default function AdminNav() {
  const { admin, logout } = useAdminAuth();
  const navigate = useNavigate();
  const [mobileOpen, setMobileOpen] = useState(false);

  const handleLogout = () => {
    logout();
    navigate('/login', { replace: true });
  };

  return (
    <>
      {/* Mobile Top Bar */}
      <div className="admin-mobile-header">
        <button
          className="admin-mobile-toggle"
          onClick={() => setMobileOpen(prev => !prev)}
          aria-label="Toggle Navigation Menu"
        >
          {mobileOpen ? '✕' : '☰'}
        </button>
        <div className="admin-mobile-brand">
          <span>🎓</span>
          <strong>Vocaboo Admin</strong>
        </div>
      </div>

      {/* Mobile Backdrop */}
      {mobileOpen && (
        <div
          className="admin-nav-backdrop"
          onClick={() => setMobileOpen(false)}
        />
      )}

      {/* Sidebar Navigation */}
      <aside className={`admin-nav ${mobileOpen ? 'admin-nav--open' : ''}`}>
        <div className="admin-nav__brand">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', width: '100%' }}>
            <div>
              <span className="admin-nav__logo">🎓</span>
              <span className="admin-nav__title">Vocaboo</span>
              <span className="admin-nav__subtitle">Admin Panel</span>
            </div>
            <button
              className="admin-nav__close-btn"
              onClick={() => setMobileOpen(false)}
              aria-label="Close Menu"
            >
              ✕
            </button>
          </div>
        </div>

        <nav className="admin-nav__links">
          {NAV_ITEMS.map(item => (
            <NavLink
              key={item.to}
              to={item.to}
              onClick={() => setMobileOpen(false)}
              className={({ isActive }) =>
                `admin-nav__link ${isActive ? 'admin-nav__link--active' : ''}`
              }
            >
              <span className="admin-nav__icon">{item.icon}</span>
              <span className="admin-nav__label">{item.label}</span>
            </NavLink>
          ))}
        </nav>

        <div className="admin-nav__footer">
          {admin && (
            <div className="admin-nav__user">
              <div className="admin-nav__avatar">
                {admin.username?.charAt(0)?.toUpperCase() || 'A'}
              </div>
              <div className="admin-nav__user-info">
                <span className="admin-nav__username">{admin.username || 'Admin'}</span>
                <span className="admin-nav__email">{admin.email}</span>
              </div>
            </div>
          )}
          <button className="admin-nav__logout" onClick={handleLogout}>
            Sign Out
          </button>
        </div>
      </aside>
    </>
  );
}
