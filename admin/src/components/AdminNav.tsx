import { NavLink, useNavigate } from 'react-router-dom';
import { useAdminAuth } from '../hooks/useAdminAuth';

const NAV_ITEMS = [
  { to: '/dashboard',  label: 'Dashboard',          icon: '⬡' },
  { to: '/lessons',    label: 'Lesson Management',  icon: '📚' },
  { to: '/categories', label: 'Categories',          icon: '🗂️' },
  { to: '/accounts',   label: 'Admin Accounts',      icon: '👤' },
  { to: '/logs',       label: 'System Logs',         icon: '📋' },
];

export default function AdminNav() {
  const { admin, logout } = useAdminAuth();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate('/login', { replace: true });
  };

  return (
    <aside className="admin-nav">
      <div className="admin-nav__brand">
        <span className="admin-nav__logo">🎓</span>
        <span className="admin-nav__title">Vocaboo</span>
        <span className="admin-nav__subtitle">Admin Panel</span>
      </div>

      <nav className="admin-nav__links">
        {NAV_ITEMS.map(item => (
          <NavLink
            key={item.to}
            to={item.to}
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
              {admin.username?.charAt(0)?.toUpperCase()}
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
  );
}
