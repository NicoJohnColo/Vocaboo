import { useState } from 'react';
import { NavLink, useNavigate } from 'react-router-dom';
import { useAdminAuth } from '../hooks/useAdminAuth';

// ── SVG Icons ────────────────────────────────────────────────────────────
const Icons = {
  Dashboard: () => (
    <svg width="17" height="17" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="3" width="7" height="7" rx="1.5" />
      <rect x="14" y="3" width="7" height="7" rx="1.5" />
      <rect x="14" y="14" width="7" height="7" rx="1.5" />
      <rect x="3" y="14" width="7" height="7" rx="1.5" />
    </svg>
  ),
  Trophy: () => (
    <svg width="17" height="17" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M8 21h8M12 21v-4M7 4H4a1 1 0 0 0-1 1v3a4 4 0 0 0 4 4h1M17 4h3a1 1 0 0 1 1 1v3a4 4 0 0 1-4 4h-1" />
      <path d="M7 4h10v7a5 5 0 0 1-10 0V4z" />
    </svg>
  ),
  Users: () => (
    <svg width="17" height="17" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M16 11c1.66 0 3-1.34 3-3s-1.34-3-3-3" />
      <path d="M21 20c0-2.67-1.34-4.88-3.27-6.12" />
      <circle cx="9" cy="8" r="3" />
      <path d="M3 20c0-3.31 2.69-6 6-6s6 2.69 6 6" />
    </svg>
  ),
  School: () => (
    <svg width="17" height="17" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 3L2 8l10 5 10-5-10-5z" />
      <path d="M2 8v9M22 8v9" />
      <path d="M6 10.5v6.5a6 6 0 0 0 12 0v-6.5" />
    </svg>
  ),
  BarChart: () => (
    <svg width="17" height="17" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="12" width="4" height="9" rx="1" />
      <rect x="10" y="7" width="4" height="14" rx="1" />
      <rect x="17" y="4" width="4" height="17" rx="1" />
    </svg>
  ),
  Book: () => (
    <svg width="17" height="17" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20" />
      <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z" />
    </svg>
  ),
  Tag: () => (
    <svg width="17" height="17" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M20.59 13.41l-7.17 7.17a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82z" />
      <line x1="7" y1="7" x2="7.01" y2="7" />
    </svg>
  ),
  Search: () => (
    <svg width="17" height="17" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="11" cy="11" r="8" />
      <path d="M21 21l-4.35-4.35" />
    </svg>
  ),
  Shield: () => (
    <svg width="17" height="17" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 2l9 4v6c0 5-3.81 9.61-9 11C3.81 21.61 3 17 3 12V6l9-4z" />
    </svg>
  ),
  FileText: () => (
    <svg width="17" height="17" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
      <polyline points="14 2 14 8 20 8" />
      <line x1="16" y1="13" x2="8" y2="13" />
      <line x1="16" y1="17" x2="8" y2="17" />
      <polyline points="10 9 9 9 8 9" />
    </svg>
  ),
  Award: () => (
    <svg width="17" height="17" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="8" r="6" />
      <polyline points="8.21 13.89 7 23 12 20 17 23 15.79 13.88" />
    </svg>
  ),
  LogOut: () => (
    <svg width="15" height="15" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
      <polyline points="16 17 21 12 16 7" />
      <line x1="21" y1="12" x2="9" y2="12" />
    </svg>
  ),
};

const NAV_ITEMS = [
  { to: '/dashboard',         label: 'Analytics Dashboard',   Icon: Icons.Dashboard,  section: 'Overview' },
  { to: '/leaderboard-stats', label: 'Leaderboards',          Icon: Icons.Trophy,     section: 'Overview' },
  { to: '/classes',           label: 'Classrooms',            Icon: Icons.School,     section: 'Management' },
  { to: '/learners',          label: 'User Management',       Icon: Icons.Users,      section: 'Management' },
  { to: '/reports',           label: 'Reports & Exports',     Icon: Icons.BarChart,   section: 'Management' },
  { to: '/lessons',           label: 'Lesson Management',     Icon: Icons.Book,       section: 'Curriculum' },
  { to: '/cumulative',        label: 'Cumulative Review',     Icon: Icons.Award,      section: 'Curriculum' },
  { to: '/categories',        label: 'Categories',            Icon: Icons.Tag,        section: 'Curriculum' },
  { to: '/wrong-answers',     label: 'Wrong Answer Analysis', Icon: Icons.Search,     section: 'Curriculum' },
  { to: '/accounts',          label: 'Admin Accounts',        Icon: Icons.Shield,     section: 'System', adminOnly: true },
  { to: '/logs',              label: 'System Logs',           Icon: Icons.FileText,   section: 'System', adminOnly: true },
];

// Group nav items by section
const SECTIONS = ['Overview', 'Management', 'Curriculum', 'System'];

export default function AdminNav() {
  const { admin, logout } = useAdminAuth();
  const isTeacher = admin?.role === 'teacher';
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
          <strong style={{ fontSize: '1.05rem', letterSpacing: '-0.02em', fontWeight: 800, color: 'var(--color-text-main)' }}>
            {isTeacher ? 'Teacher Portal' : 'Admin Console'}
          </strong>
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

        {/* Brand */}
        <div className="admin-nav__brand">
          <div className="admin-nav__brand-inner">
            <div className="admin-nav__brand-left">
              <div className="admin-nav__logo-row">
                <span className="admin-nav__title" style={{ fontSize: '1.25rem' }}>
                  {isTeacher ? 'Teacher Portal' : 'Admin Console'}
                </span>
              </div>
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

        {/* Navigation Links */}
        <nav className="admin-nav__links">
          {SECTIONS.map(section => {
            const items = NAV_ITEMS.filter(i => {
              if (i.section !== section) return false;
              if (i.adminOnly && isTeacher) return false;
              return true;
            });
            if (items.length === 0) return null;
            return (
              <div key={section}>
                <div className="admin-nav__section-label">{section}</div>
                {items.map(item => (
                  <NavLink
                    key={item.to}
                    to={item.to}
                    onClick={() => setMobileOpen(false)}
                    className={({ isActive }) =>
                      `admin-nav__link ${isActive ? 'admin-nav__link--active' : ''}`
                    }
                  >
                    <span className="admin-nav__icon">
                      <item.Icon />
                    </span>
                    <span className="admin-nav__label">{item.label}</span>
                  </NavLink>
                ))}
              </div>
            );
          })}
        </nav>

        {/* Footer */}
        <div className="admin-nav__footer">
          {admin && (
            <div className="admin-nav__user">
              <div className="admin-nav__avatar">
                {admin.username?.charAt(0)?.toUpperCase() || 'A'}
              </div>
              <div className="admin-nav__user-info">
                <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                  <span className="admin-nav__username">{admin.username || 'Admin'}</span>
                  <span
                    style={{
                      fontSize: '0.65rem',
                      padding: '1px 6px',
                      borderRadius: 6,
                      fontWeight: 800,
                      background: admin.role === 'teacher' ? 'rgba(16, 185, 129, 0.12)' : 'rgba(37, 99, 235, 0.12)',
                      color: admin.role === 'teacher' ? '#059669' : 'var(--primary-mid)',
                      border: `1px solid ${admin.role === 'teacher' ? 'rgba(16, 185, 129, 0.3)' : 'rgba(37, 99, 235, 0.3)'}`,
                    }}
                  >
                    {admin.role === 'teacher' ? 'TEACHER' : 'ADMIN'}
                  </span>
                </div>
                <span className="admin-nav__email">{admin.email}</span>
              </div>
            </div>
          )}
          <button className="admin-nav__logout" onClick={handleLogout}>
            <Icons.LogOut />
            Sign Out
          </button>
        </div>
      </aside>
    </>
  );
}
