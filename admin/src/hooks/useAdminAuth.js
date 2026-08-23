import { useState, useEffect, useCallback } from 'react';
import { AuthService } from '../services/AuthService';

export function useAdminAuth() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [isLoading, setIsLoading]             = useState(true);
  const [admin, setAdmin]                     = useState(null);

  const verify = useCallback(() => {
    const valid = AuthService.isTokenValid();
    setIsAuthenticated(valid);
    setAdmin(valid ? AuthService.getAdminInfo() : null);
    setIsLoading(false);
  }, []);

  useEffect(() => {
    verify();
    const interval = setInterval(verify, 60_000);
    return () => clearInterval(interval);
  }, [verify]);

  const logout = useCallback(() => {
    AuthService.logout();
    setIsAuthenticated(false);
    setAdmin(null);
  }, []);

  const resolvePasswordChange = useCallback(() => {
    AuthService.resolvePasswordChange();
    setAdmin(AuthService.getAdminInfo());
  }, []);

  return { isAuthenticated, isLoading, admin, logout, resolvePasswordChange };
}
