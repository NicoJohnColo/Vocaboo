import { BrowserRouter, Routes, Route, Navigate, useParams } from 'react-router-dom';
import './index.css';

import ProtectedAdminRoute from './components/ProtectedAdminRoute';
import LoginPage from './pages/LoginPage';
import ResetPasswordPage from './pages/ResetPasswordPage';
import ForceChangePasswordPage from './pages/ForceChangePasswordPage';
import DashboardPage from './pages/DashboardPage';
import LeaderboardsPage from './pages/LeaderboardsPage';
import LearnerManagementPage from './pages/LearnerManagementPage';
import ClassManagementPage from './pages/ClassManagementPage';
import TeacherClassManagementPage from './pages/TeacherClassManagementPage';
import ReportsPage from './pages/ReportsPage';
import LessonManagementPage from './pages/LessonManagementPage';
import VocabularyListPage from './pages/VocabularyListPage';
import CategoryManagementPage from './pages/CategoryManagementPage';
import CumulativeManagementPage from './pages/CumulativeManagementPage';
import AdminAccountsPage from './pages/AdminAccountsPage';
import SystemLogsPage from './pages/SystemLogsPage';
import WrongAnswersAnalysisPage from './pages/WrongAnswersAnalysisPage';
import ErrorBoundary from './components/ErrorBoundary';

function RedirectToVocabularyWithModal({ modal }) {
  const { lessonId } = useParams();
  return <Navigate to={`/lessons/${lessonId}/vocabulary`} replace state={{ openModal: modal }} />;
}

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
            element={<ProtectedAdminRoute><TeacherClassManagementPage /></ProtectedAdminRoute>}
          />

          <Route
            path="/sections"
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
            element={<ProtectedAdminRoute><RedirectToVocabularyWithModal modal="bulk-import" /></ProtectedAdminRoute>}
          />

          <Route
            path="/lessons/:lessonId/confusable-pairs"
            element={<ProtectedAdminRoute><RedirectToVocabularyWithModal modal="confusable-pairs" /></ProtectedAdminRoute>}
          />

          <Route
            path="/categories"
            element={<ProtectedAdminRoute><CategoryManagementPage /></ProtectedAdminRoute>}
          />

          <Route
            path="/cumulative"
            element={<ProtectedAdminRoute><CumulativeManagementPage /></ProtectedAdminRoute>}
          />

          <Route
            path="/wrong-answers"
            element={<ProtectedAdminRoute><WrongAnswersAnalysisPage /></ProtectedAdminRoute>}
          />

          <Route
            path="/accounts"
            element={<ProtectedAdminRoute requiredRole="admin"><AdminAccountsPage /></ProtectedAdminRoute>}
          />

          <Route
            path="/logs"
            element={<ProtectedAdminRoute requiredRole="admin"><SystemLogsPage /></ProtectedAdminRoute>}
          />

          {/* Fallback redirects */}
          <Route path="/" element={<Navigate to="/dashboard" replace />} />
          <Route path="*" element={<Navigate to="/dashboard" replace />} />
        </Routes>
      </BrowserRouter>
    </ErrorBoundary>
  );
}
