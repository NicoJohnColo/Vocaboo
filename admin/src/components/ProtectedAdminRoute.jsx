import React from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { useAdminAuth } from '../hooks/useAdminAuth';

export default function ProtectedAdminRoute({ children, requiredRole }) {
  const { isAuthenticated, isLoading, admin } = useAdminAuth();
  const location = useLocation();

  if (isLoading) {
    return (
      <div className="auth-loading">
        <div className="spinner" />
      </div>
    );
  }

  if (!isAuthenticated || !admin) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  const isForceChangePath = location.pathname === '/force-change-password';

  if (admin.mustChangePassword && !isForceChangePath) {
    return <Navigate to="/force-change-password" replace />;
  }

  if (!admin.mustChangePassword && isForceChangePath) {
    return <Navigate to="/dashboard" replace />;
  }

  if (requiredRole && admin.role !== requiredRole) {
    return <Navigate to="/classes" replace />;
  }

  return children;
}
