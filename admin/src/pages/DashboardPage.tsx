import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import AdminNav from '../components/AdminNav';
import { useAdminAuth } from '../hooks/useAdminAuth';
import { apiFetch } from '../services/AuthService';


interface Stats {
  totalLearners: number;
  totalLessons: number;
  activeSessions: number;
  totalAdmins: number;
}

export default function DashboardPage() {
  const { admin } = useAdminAuth();
  const [stats, setStats] = useState<Stats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    apiFetch('/api/v1/dashboard/stats')
      .then(res => res.ok ? res.json() : Promise.reject(res.statusText))
      .then(data => setStats({
        totalLearners: data.totalLearners ?? 0,
        totalLessons: data.totalLessons ?? 0,
        activeSessions: data.activeSessions ?? 0,
        totalAdmins: data.totalAdmins ?? 0,
      }))
      .catch(() => setError('Could not load dashboard stats.'))
      .finally(() => setLoading(false));
  }, []);

  const statCards = [
    { label: 'Total Learners', value: stats?.totalLearners, icon: '👩‍🎓', color: 'var(--color-accent-1)' },
    { label: 'Total Lessons', value: stats?.totalLessons, icon: '📚', color: 'var(--color-accent-2)' },
    { label: 'Active Sessions', value: stats?.activeSessions, icon: '⚡', color: 'var(--color-accent-3)' },
    { label: 'Admin Accounts', value: stats?.totalAdmins, icon: '🛡️', color: 'var(--color-accent-4)' },
  ];

  return (
    <div className="admin-layout">
      <AdminNav />
      <main className="admin-main">
        <header className="admin-main__header">
          <div>
            <h1 className="admin-main__title">Dashboard</h1>
            <p className="admin-main__subtitle">
              Welcome back, <strong>{admin?.username}</strong>
            </p>
          </div>
          <div className="admin-main__badge">ROLE_ADMIN</div>
        </header>

        {error && <div className="alert alert--error">{error}</div>}

        <section className="stat-grid">
          {statCards.map(card => (
            <div key={card.label} className="stat-card" style={{ '--card-accent': card.color } as React.CSSProperties}>
              <div className="stat-card__icon">{card.icon}</div>
              <div className="stat-card__body">
                <span className="stat-card__value">
                  {loading ? <span className="skeleton skeleton--number" /> : (card.value ?? '—')}
                </span>
                <span className="stat-card__label">{card.label}</span>
              </div>
            </div>
          ))}
        </section>

        <section className="dashboard-info">
          <div className="info-card">
            <h2 className="info-card__title">🔐 Security Status</h2>
            <ul className="info-card__list">
              <li>✅ JWT access tokens: 15-minute expiry</li>
              <li>✅ Refresh tokens: 7-day rolling</li>
              <li>✅ Role-based access control (ROLE_ADMIN / ROLE_LEARNER)</li>
              <li>✅ Database indexes applied</li>
              <li>✅ Audit logging active</li>
            </ul>
          </div>
          <div className="info-card">
            <h2 className="info-card__title">📋 Quick Links</h2>
            <ul className="info-card__list">
              <li><Link to="/lessons">→ Manage Lessons</Link></li>
              <li><Link to="/accounts">→ Manage Admin Accounts</Link></li>
              <li><Link to="/logs">→ View System Logs</Link></li>
            </ul>
          </div>
        </section>
      </main>
    </div>
  );
}
