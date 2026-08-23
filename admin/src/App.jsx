import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import './index.css';

import ProtectedAdminRoute from './components/ProtectedAdminRoute';
import LoginPage from './pages/LoginPage';
import ResetPasswordPage from './pages/ResetPasswordPage';
import ForceChangePasswordPage from './pages/ForceChangePasswordPage';
import DashboardPage from './pages/DashboardPage';
import LeaderboardsPage from './pages/LeaderboardsPage';
import LearnerManagementPage from './pages/LearnerManagementPage';
import ClassManagementPage from './pages/ClassManagementPage';
import ReportsPage from './pages/ReportsPage';
import LessonManagementPage from './pages/LessonManagementPage';
import VocabularyListPage from './pages/VocabularyListPage';
import BulkImportPage from './pages/BulkImportPage';
import CategoryManagementPage from './pages/CategoryManagementPage';
import AdminAccountsPage from './pages/AdminAccountsPage';
import SystemLogsPage from './pages/SystemLogsPage';
import ConfusablePairsPage from './pages/ConfusablePairsPage';
import WrongAnswersAnalysisPage from './pages/WrongAnswersAnalysisPage';
import ErrorBoundary from './components/ErrorBoundary';

export default function App() {
  return (
    <ErrorBoundary>
      <BrowserRouter>
        <Routes>
          {/* Public routes */}
          <Route path="/login" element={<LoginPage />} />
          <Route path="/reset-password" element={<ResetPasswordPage />} />

          {/* Protected admin routes */}
          <Route
            path="/force-change-password"
            element={<ProtectedAdminRoute><ForceChangePasswordPage /></ProtectedAdminRoute>}
          />
          
          <Route
            path="/dashboard"
            element={<ProtectedAdminRoute><DashboardPage /></ProtectedAdminRoute>}
          />

          <Route
            path="/leaderboard-stats"
            element={<ProtectedAdminRoute><LeaderboardsPage /></ProtectedAdminRoute>}
          />

          <Route
            path="/learners"
            element={<ProtectedAdminRoute><LearnerManagementPage /></ProtectedAdminRoute>}
          />

          <Route
            path="/classes"
            element={<ProtectedAdminRoute><ClassManagementPage /></ProtectedAdminRoute>}
          />

          <Route
            path="/reports"
            element={<ProtectedAdminRoute><ReportsPage /></ProtectedAdminRoute>}
          />

          <Route
            path="/lessons"
            element={<ProtectedAdminRoute><LessonManagementPage /></ProtectedAdminRoute>}
          />

          <Route
            path="/lessons/:lessonId/vocabulary"
            element={<ProtectedAdminRoute><VocabularyListPage /></ProtectedAdminRoute>}
          />

          <Route
            path="/lessons/:lessonId/bulk-import"
            element={<ProtectedAdminRoute><BulkImportPage /></ProtectedAdminRoute>}
          />

          <Route
            path="/lessons/:lessonId/confusable-pairs"
            element={<ProtectedAdminRoute><ConfusablePairsPage /></ProtectedAdminRoute>}
          />

          <Route
            path="/categories"
            element={<ProtectedAdminRoute><CategoryManagementPage /></ProtectedAdminRoute>}
          />

          <Route
            path="/wrong-answers"
            element={<ProtectedAdminRoute><WrongAnswersAnalysisPage /></ProtectedAdminRoute>}
          />

          <Route
            path="/accounts"
            element={<ProtectedAdminRoute><AdminAccountsPage /></ProtectedAdminRoute>}
          />

          <Route
            path="/logs"
            element={<ProtectedAdminRoute><SystemLogsPage /></ProtectedAdminRoute>}
          />

          {/* Fallback redirects */}
          <Route path="/" element={<Navigate to="/dashboard" replace />} />
          <Route path="*" element={<Navigate to="/dashboard" replace />} />
        </Routes>
      </BrowserRouter>
    </ErrorBoundary>
  );
}
