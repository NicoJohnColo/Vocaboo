import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import './index.css';

import ProtectedAdminRoute from './components/ProtectedAdminRoute';
import LoginPage from './pages/LoginPage';
import ResetPasswordPage from './pages/ResetPasswordPage';
import DashboardPage from './pages/DashboardPage';
import LessonManagementPage from './pages/LessonManagementPage';
import VocabularyListPage from './pages/VocabularyListPage';
import BulkImportPage from './pages/BulkImportPage';
import CategoryManagementPage from './pages/CategoryManagementPage';
import AdminAccountsPage from './pages/AdminAccountsPage';
import SystemLogsPage from './pages/SystemLogsPage';
import ConfusablePairsPage from './pages/ConfusablePairsPage';

import ForceChangePasswordPage from './pages/ForceChangePasswordPage';
import ErrorBoundary from './components/ErrorBoundary';

export default function App() {
  return (
    <ErrorBoundary>
      <BrowserRouter>
      <Routes>
        {/* Public */}
        <Route path="/login" element={<LoginPage />} />
        <Route path="/reset-password" element={<ResetPasswordPage />} />

        {/* Protected admin routes */}
        <Route path="/force-change-password"
          element={<ProtectedAdminRoute><ForceChangePasswordPage /></ProtectedAdminRoute>} />
        
        <Route path="/dashboard"
          element={<ProtectedAdminRoute><DashboardPage /></ProtectedAdminRoute>} />

        <Route path="/lessons"
          element={<ProtectedAdminRoute><LessonManagementPage /></ProtectedAdminRoute>} />

        <Route path="/lessons/:lessonId/vocabulary"
          element={<ProtectedAdminRoute><VocabularyListPage /></ProtectedAdminRoute>} />

        <Route path="/lessons/:lessonId/bulk-import"
          element={<ProtectedAdminRoute><BulkImportPage /></ProtectedAdminRoute>} />

        <Route path="/lessons/:lessonId/confusable-pairs"
          element={<ProtectedAdminRoute><ConfusablePairsPage /></ProtectedAdminRoute>} />

        <Route path="/categories"
          element={<ProtectedAdminRoute><CategoryManagementPage /></ProtectedAdminRoute>} />

        <Route path="/accounts"
          element={<ProtectedAdminRoute><AdminAccountsPage /></ProtectedAdminRoute>} />

        <Route path="/logs"
          element={<ProtectedAdminRoute><SystemLogsPage /></ProtectedAdminRoute>} />

        {/* Fallback */}
        <Route path="/" element={<Navigate to="/dashboard" replace />} />
        <Route path="*" element={<Navigate to="/dashboard" replace />} />
      </Routes>
    </BrowserRouter>
    </ErrorBoundary>
  );
}

